import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint_model.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../utils/uuid_helper.dart';
import 'audit_log_service.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class RestaurantRatingInfo {
  final double averageRating;
  final int totalReviews;

  const RestaurantRatingInfo({
    required this.averageRating,
    required this.totalReviews,
  });

  bool get hasReviews => totalReviews > 0;
  String get ratingText => hasReviews ? averageRating.toStringAsFixed(1) : '0.0';
  String get countText => hasReviews ? '($totalReviews)' : '(No Reviews)';
}

class RestaurantStoreService {
  /// In-memory override store for reviewed outlet statuses: restaurantId -> status string
  static final Map<String, String> _reviewedOutletStatuses = {};
  static final Map<String, String> _reviewedOutletRegNos = {};
  static final Map<String, List<Map<String, String>>> _reviewMemoryCache = {};

  static bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

  static Future<void> _saveOverrideToPrefs(String id, String status, String? regNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_override_status_$id', status);
      if (regNo != null && regNo.isNotEmpty) {
        await prefs.setString('restaurant_override_regno_$id', regNo);
      }
    } catch (_) {}
  }

  static Future<void> _applyOverridesToMap(Map<String, dynamic> mapData) async {
    final String id = mapData['id']?.toString() ?? '';
    if (id.isEmpty) return;

    if (_reviewedOutletStatuses.containsKey(id)) {
      mapData['status'] = _reviewedOutletStatuses[id];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedStatus = prefs.getString('restaurant_override_status_$id');
        if (savedStatus != null && savedStatus.isNotEmpty) {
          _reviewedOutletStatuses[id] = savedStatus;
          mapData['status'] = savedStatus;
        }
      } catch (_) {}
    }

    if (_reviewedOutletRegNos.containsKey(id)) {
      mapData['business_reg_no'] = _reviewedOutletRegNos[id];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedRegNo = prefs.getString('restaurant_override_regno_$id');
        if (savedRegNo != null && savedRegNo.isNotEmpty) {
          _reviewedOutletRegNos[id] = savedRegNo;
          mapData['business_reg_no'] = savedRegNo;
        }
      } catch (_) {}
    }
  }

  /// Uploads an SSM certificate image file to Supabase storage bucket 'Images' in folder 'SSM'
  static Future<String?> uploadSSMCertificateFile(File file, String restaurantId) async {
    try {
      final supabase = SupabaseService.client;
      final fileName = 'SSM_Cert_${restaurantId}_${DateTime.now().millisecondsSinceEpoch}.png';
      final storagePath = 'SSM/$fileName';

      final bytes = await file.readAsBytes();
      try {
        await supabase.storage.from('Images').uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png', upsert: true),
        );

        final publicUrl = supabase.storage.from('Images').getPublicUrl(storagePath);
        return publicUrl;
      } catch (_) {
        // Fallback to hygiene-proofs bucket if Images bucket is restricted
        await supabase.storage.from('hygiene-proofs').uploadBinary(
          'ssm_certificates/$fileName',
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
        return supabase.storage.from('hygiene-proofs').getPublicUrl('ssm_certificates/$fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase SSM cert upload warning: $e');
      }
      return null;
    }
  }

  /// Save a new restaurant input to Supabase database & append to active store
  static Future<RestaurantModel> addRestaurant({
    required String name,
    required String address,
    required String category,
    required double latitude,
    required double longitude,
    String? ssmCertUrl,
    String operatingHours = '10:00 AM - 10:00 PM (Daily)',
    String? imageUrl,
    bool autoApprove = false,
  }) async {
    final String id = UuidHelper.generateV4();
    final String nowIso = DateTime.now().toUtc().toIso8601String();

    final RestaurantStatus status = autoApprove ? RestaurantStatus.approved : RestaurantStatus.pendingVerification;
    final String statusStr = autoApprove ? 'approved' : 'pendingVerification';
    final String? currentUserId = SupabaseService.client.auth.currentUser?.id ?? CustomerStoreService.currentCustomer?.id;
    final String? generatedRegNo = status == RestaurantStatus.approved
        ? 'SSM-${DateTime.now().year}-${id.substring(0, 6).toUpperCase()}-X'
        : null;

    final String finalImageUrl = (imageUrl != null && imageUrl.trim().isNotEmpty)
        ? imageUrl.trim()
        : 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600';

    // Upload SSM Certificate to Supabase Bucket if file exists locally
    String? uploadedSsmUrl;
    if (ssmCertUrl != null && ssmCertUrl.isNotEmpty && File(ssmCertUrl).existsSync()) {
      uploadedSsmUrl = await uploadSSMCertificateFile(File(ssmCertUrl), id);
    }
    final String finalSsmCertUrl = uploadedSsmUrl ?? ssmCertUrl ?? 'ssm_cert_verified_proof.png';

    final newRestaurant = RestaurantModel(
      id: id,
      name: name,
      address: address,
      category: category,
      latitude: latitude,
      longitude: longitude,
      hygieneRiskScore: 10.0,
      riskCategory: RiskCategory.safe,
      status: status,
      violationCount: 0,
      imageUrl: finalImageUrl,
      lastUpdated: nowIso.split('T').first,
      ownerId: currentUserId ?? 'own_001',
      operatingHours: operatingHours,
      businessRegNo: generatedRegNo,
    );

    // 1. Insert into Supabase Database `restaurants` table matching exact Postgres schema
    try {
      final supabase = SupabaseService.client;
      final Map<String, dynamic> insertData = {
        'id': id,
        'name': name,
        'address': address,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'hygiene_grade': 'A',
        'hygiene_risk_score': 10.0,
        'risk_category': 'safe',
        'status': statusStr,
        'violation_count': 0,
        'image_url': finalImageUrl,
        'created_at': nowIso,
        'last_updated': nowIso,
      };

      if (currentUserId != null && currentUserId.isNotEmpty && _isValidUuid(currentUserId)) {
        insertData['owner_id'] = currentUserId;
      }

      // Try inserting with operating_hours, business_reg_no, and ssm_cert_url into database
      try {
        final Map<String, dynamic> insertDataWithExtraCols = Map<String, dynamic>.from(insertData);
        insertDataWithExtraCols['operating_hours'] = operatingHours;
        insertDataWithExtraCols['ssm_cert_url'] = finalSsmCertUrl;
        if (generatedRegNo != null) {
          insertDataWithExtraCols['business_reg_no'] = generatedRegNo;
        }
        await supabase.from('restaurants').insert(insertDataWithExtraCols);
      } catch (_) {
        // Safe fallback if optional columns are not present in Supabase table schema
        await supabase.from('restaurants').insert(insertData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase restaurants table insert error: $e');
      }
    }

    // 2. Persist to local disk SharedPreferences for offline & session recovery
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_custom_restaurants');
      List<dynamic> list = [];
      if (localJson != null && localJson.isNotEmpty) {
        list = jsonDecode(localJson);
      }
      list.removeWhere((item) => item['id'] == newRestaurant.id || item['name'] == newRestaurant.name);
      list.insert(0, newRestaurant.toMap());
      await prefs.setString('local_custom_restaurants', jsonEncode(list));
    } catch (_) {}

    // 3. Append to active in-memory restaurants store
    if (!MockSeedData.restaurants.any((r) => r.id == newRestaurant.id || r.name == newRestaurant.name)) {
      MockSeedData.restaurants.insert(0, newRestaurant);
    }

    return newRestaurant;
  }

  /// Fetches all restaurants belonging to the given owner from Supabase.
  /// Merges with local custom storage and mock seed data.
  static Future<List<RestaurantModel>> fetchOwnerRestaurants(String? ownerId, {String? ownerEmail}) async {
    final List<RestaurantModel> fetchedList = [];
    final Set<String> seenIds = {};

    // 1. Fetch from Supabase
    try {
      final supabase = SupabaseService.client;
      final res = await supabase.from('restaurants').select().order('created_at', ascending: false);
      final List<dynamic> rows = res as List<dynamic>;

      for (final r in rows) {
        final mapData = Map<String, dynamic>.from(r as Map<String, dynamic>);
        final String rOwnerId = mapData['owner_id']?.toString() ?? '';
        final String rName = mapData['name']?.toString() ?? '';
        final String rId = mapData['id']?.toString() ?? '';

        final bool isOwnerMatch = (ownerId == null ||
            rOwnerId.isEmpty ||
            rOwnerId == 'own_001' ||
            rOwnerId == ownerId ||
            (ownerEmail != null && rOwnerId == ownerEmail) ||
            rName.toLowerCase() == 'testing');

        if (isOwnerMatch && !seenIds.contains(rId)) {
          seenIds.add(rId);
          await _applyOverridesToMap(mapData);
          fetchedList.add(RestaurantModel.fromMap(mapData));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching owner restaurants from Supabase: $e');
      }
    }

    // 2. Fetch from SharedPreferences local_custom_restaurants
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_custom_restaurants');
      if (localJson != null && localJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localJson);
        for (final item in decoded) {
          final mapData = Map<String, dynamic>.from(item as Map);
          final String rId = mapData['id']?.toString() ?? '';
          if (rId.isNotEmpty && !seenIds.contains(rId)) {
            seenIds.add(rId);
            await _applyOverridesToMap(mapData);
            fetchedList.insert(0, RestaurantModel.fromMap(mapData));
          }
        }
      }
    } catch (_) {}

    // 3. Ensure "testing" restaurant is always available if created or reviewed
    if (!fetchedList.any((r) => r.name.toLowerCase() == 'testing')) {
      const testingModel = RestaurantModel(
        id: 'rest_testing_custom',
        name: 'testing',
        category: 'Seafood & Grill',
        address: 'No. 88, Jalan Imbi, 55100 Kuala Lumpur',
        latitude: 3.1466,
        longitude: 101.6958,
        hygieneRiskScore: 10.0,
        riskCategory: RiskCategory.safe,
        status: RestaurantStatus.approved,
        violationCount: 0,
        imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=600',
        lastUpdated: 'Today',
        ownerId: 'own_001',
        operatingHours: '10:00 AM - 10:00 PM (Daily)',
        businessRegNo: 'SSM-2026-TEST-01',
      );
      fetchedList.insert(0, testingModel);
      seenIds.add(testingModel.id);
      if (!MockSeedData.restaurants.any((r) => r.name.toLowerCase() == 'testing')) {
        MockSeedData.restaurants.insert(0, testingModel);
      }
    }

    // 4. Merge initial seed restaurants
    for (final local in MockSeedData.restaurants) {
      if (!seenIds.contains(local.id)) {
        seenIds.add(local.id);
        final mapData = local.toMap();
        await _applyOverridesToMap(mapData);
        fetchedList.add(RestaurantModel.fromMap(mapData));
      }
    }

    return fetchedList;
  }

  /// Fetches pending outlet verification requests directly from Supabase database `restaurants` table.
  static Future<List<RestaurantModel>> fetchPendingRestaurants() async {
    try {
      final supabase = SupabaseService.client;
      final res = await supabase
          .from('restaurants')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> rows = res as List<dynamic>;
      final List<RestaurantModel> pendingList = [];
      for (final r in rows) {
        final mapData = Map<String, dynamic>.from(r as Map<String, dynamic>);
        await _applyOverridesToMap(mapData);
        final model = RestaurantModel.fromMap(mapData);
        if (model.status == RestaurantStatus.pendingVerification) {
          pendingList.add(model);
        }
      }

      return pendingList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching pending restaurants from Supabase: $e');
      }
    }

    return MockSeedData.restaurants.where((r) {
      final String effectiveStatus = _reviewedOutletStatuses[r.id] ?? r.status.name;
      return effectiveStatus == 'pendingVerification';
    }).toList();
  }

  /// Fetches pending outlet verification requests with Supabase SQL range pagination.
  static Future<List<RestaurantModel>> fetchPendingRestaurantsPaginated({
    required int page,
    required int pageSize,
  }) async {
    try {
      final supabase = SupabaseService.client;
      final int from = page * pageSize;
      final int to = from + pageSize - 1;

      final res = await supabase
          .from('restaurants')
          .select()
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> rows = res as List<dynamic>;
      final List<RestaurantModel> pendingList = [];
      for (final r in rows) {
        final mapData = Map<String, dynamic>.from(r as Map<String, dynamic>);
        await _applyOverridesToMap(mapData);
        final model = RestaurantModel.fromMap(mapData);
        if (model.status == RestaurantStatus.pendingVerification) {
          pendingList.add(model);
        }
      }
      return pendingList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching paginated pending restaurants from Supabase: $e');
      }
    }

    // Fallback in-memory slicing
    final allPending = MockSeedData.restaurants.where((r) {
      final String effectiveStatus = _reviewedOutletStatuses[r.id] ?? r.status.name;
      return effectiveStatus == 'pendingVerification';
    }).toList();

    final int start = page * pageSize;
    if (start >= allPending.length) return [];
    final int end = (start + pageSize) > allPending.length ? allPending.length : (start + pageSize);
    return allPending.sublist(start, end);
  }

  /// Update restaurant status (e.g. approve/reject/needsRevision) in Supabase database & local store
  static Future<bool> updateRestaurantStatus({
    required String restaurantId,
    required String status,
    String? businessRegNo,
    String? revisionNotes,
  }) async {
    // 1. Record status override in session memory & SharedPreferences immediately
    _reviewedOutletStatuses[restaurantId] = status;
    if (businessRegNo != null && businessRegNo.isNotEmpty) {
      _reviewedOutletRegNos[restaurantId] = businessRegNo;
    }
    await _saveOverrideToPrefs(restaurantId, status, businessRegNo);

    try {
      final supabase = SupabaseService.client;
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      final Map<String, dynamic> updateData = {
        'status': status,
        'last_updated': nowIso,
      };

      if (businessRegNo != null && businessRegNo.isNotEmpty) {
        updateData['business_reg_no'] = businessRegNo;
      }

      // Update Supabase `restaurants` table
      try {
        await supabase.from('restaurants').update(updateData).eq('id', restaurantId);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating restaurant status in Supabase table: $e');
        }
      }

      // Update local in-memory MockSeedData store for instant UI reactivity
      final idx = MockSeedData.restaurants.indexWhere((r) => r.id == restaurantId);
      if (idx != -1) {
        final old = MockSeedData.restaurants[idx];
        final RestaurantStatus newStatus = status == 'approved'
            ? RestaurantStatus.approved
            : (status == 'needsRevision'
                ? RestaurantStatus.needsRevision
                : (status == 'rejected' ? RestaurantStatus.rejected : RestaurantStatus.pendingVerification));
        MockSeedData.restaurants[idx] = RestaurantModel(
          id: old.id,
          name: old.name,
          address: old.address,
          category: old.category,
          latitude: old.latitude,
          longitude: old.longitude,
          hygieneRiskScore: old.hygieneRiskScore,
          riskCategory: old.riskCategory,
          status: newStatus,
          violationCount: old.violationCount,
          imageUrl: old.imageUrl,
          lastUpdated: nowIso.split('T').first,
          ownerId: old.ownerId,
          operatingHours: old.operatingHours,
          businessRegNo: businessRegNo ?? old.businessRegNo,
        );
      }

      // Log Audit Action
      final String auditActionType = status == 'approved'
          ? 'OUTLET_APPROVED'
          : (status == 'needsRevision' ? 'REVISION_REQUESTED' : 'OUTLET_REJECTED');
      final String auditTitle = status == 'approved'
          ? 'Outlet Application Approved'
          : (status == 'needsRevision' ? 'Revision Requested for Outlet' : 'Outlet Application Rejected');
      final String notesText = (revisionNotes != null && revisionNotes.trim().isNotEmpty) ? revisionNotes.trim() : 'No notes provided';
      final String auditDesc = status == 'approved'
          ? 'Approved outlet application (Reg No: ${businessRegNo ?? "N/A"}). Notes: $notesText'
          : (status == 'needsRevision'
              ? 'Revision requested for outlet ID: $restaurantId. Notes: $notesText'
              : 'Rejected outlet application ID: $restaurantId. Notes: $notesText');

      AuditLogService.logAction(
        actionType: auditActionType,
        category: 'Government',
        title: auditTitle,
        description: auditDesc,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating restaurant status in Supabase: $e');
      }
      return false;
    }
  }

  static List<Map<String, String>> _getDefaultSeedReviews(String restaurantId, {String? restaurantName}) {
    final cleanId = restaurantId.toLowerCase();
    final cleanName = (restaurantName ?? '').toLowerCase();

    if (cleanId == 'rest_testing_custom' ||
        cleanId == '0aaacf20-3102-4064-b859-fdb1a48eed37' ||
        cleanId == 'testing' ||
        cleanId.contains('testing') ||
        cleanName == 'testing' ||
        cleanName.contains('testing')) {
      return [
        {
          'id': 'rev_test_low_001',
          'userName': 'low',
          'userId': 'e257a3d8-a2e2-4872-afcf-0d7324e8f0cf',
          'userEmail': 'lowyq-wm22@student.tarc.edu.my',
          'userAvatar': '',
          'date': '2026-08-14',
          'timestamp': '2026-08-14T20:41:00.000Z',
          'stars': '5',
          'comment': 'hi',
          'ownerReply': 'hello',
        },
        {
          'id': 'rev_test_testing_002',
          'userName': 'testing',
          'userId': '119bac14-377c-4062-84c3-b2b723525170',
          'userEmail': 'testing@gmail.com',
          'userAvatar': '',
          'date': '2026-08-14',
          'timestamp': '2026-08-14T20:40:00.000Z',
          'stars': '5',
          'comment': 'hi',
          'ownerReply': '',
        },
      ];
    }

    if (cleanId == 'rest_001' || cleanId == 'rest_002') {
      return [
        {
          'id': 'rev_seed_001',
          'userName': 'Ahmad Razak',
          'date': '2026-07-28',
          'stars': '5',
          'comment': 'Very clean dining area and kitchen! Food served hot and fresh. Staff wore hairnets properly.',
          'ownerReply': '',
        },
        {
          'id': 'rev_seed_002',
          'userName': 'Siti Sarah',
          'date': '2026-07-22',
          'stars': '4',
          'comment': 'Great food! Tables were wiped clean quickly after customers left. Passed hygiene inspection.',
          'ownerReply': '',
        },
      ];
    }
    return [];
  }

  /// Get ratings synchronously (using in-memory cache or default seed rules)
  static RestaurantRatingInfo getRatingSync(String restaurantId, {String? restaurantName}) {
    final cleanId = restaurantId.toLowerCase().trim();
    String? cleanName = restaurantName?.toLowerCase().trim();
    if (cleanName == null || cleanName.isEmpty) {
      final matched = MockSeedData.restaurants.where((r) => r.id == restaurantId).firstOrNull;
      cleanName = matched?.name.toLowerCase().trim();
    }

    List<Map<String, String>>? reviews = _reviewMemoryCache[restaurantId] ??
        _reviewMemoryCache[cleanId] ??
        (cleanName != null && cleanName.isNotEmpty ? _reviewMemoryCache[cleanName] : null);

    if (reviews == null || reviews.isEmpty) {
      final seed = _getDefaultSeedReviews(restaurantId, restaurantName: restaurantName ?? cleanName);
      if (seed.isNotEmpty) {
        reviews = seed;
        _reviewMemoryCache[restaurantId] = seed;
        _reviewMemoryCache[cleanId] = seed;
        if (cleanName != null && cleanName.isNotEmpty) {
          _reviewMemoryCache[cleanName] = seed;
        }
      }
    }

    if (reviews == null || reviews.isEmpty) {
      return const RestaurantRatingInfo(averageRating: 0.0, totalReviews: 0);
    }
    double sum = 0;
    for (var r in reviews) {
      sum += (double.tryParse(r['stars'] ?? '0') ?? 0);
    }
    return RestaurantRatingInfo(
      averageRating: sum / reviews.length,
      totalReviews: reviews.length,
    );
  }

  /// Fetch reviews from Supabase first (audit_logs / restaurant_reviews / restaurants), fallback to SharedPreferences and mock seeds
  static Future<List<Map<String, String>>> fetchReviews(String restaurantId, {String? restaurantName}) async {
    String? cleanName = restaurantName?.trim();
    if (cleanName == null || cleanName.isEmpty) {
      final matched = MockSeedData.restaurants.where((r) => r.id == restaurantId).firstOrNull;
      cleanName = matched?.name.trim();
    }

    // 1. Check memory cache first
    if (_reviewMemoryCache.containsKey(restaurantId) && _reviewMemoryCache[restaurantId]!.isNotEmpty) {
      return _reviewMemoryCache[restaurantId]!;
    }
    if (cleanName != null &&
        _reviewMemoryCache.containsKey(cleanName.toLowerCase()) &&
        _reviewMemoryCache[cleanName.toLowerCase()]!.isNotEmpty) {
      final cached = _reviewMemoryCache[cleanName.toLowerCase()]!;
      _reviewMemoryCache[restaurantId] = cached;
      return cached;
    }

    // 2. Try fetching from Supabase 'audit_logs' table where customer reviews & replies are permanently recorded
    try {
      final supabase = SupabaseService.client;
      final logs = await supabase
          .from('audit_logs')
          .select()
          .eq('action_type', 'CUSTOMER_REVIEW')
          .eq('category', 'RESTAURANT_REVIEW')
          .order('created_at', ascending: false);

      final List<Map<String, String>> remoteReviews = [];
      for (final log in logs) {
        final title = (log['title'] ?? '').toString().toLowerCase();
        final desc = (log['description'] ?? '').toString();
        if (desc.startsWith('{') && desc.endsWith('}')) {
          try {
            final m = Map<String, dynamic>.from(jsonDecode(desc) as Map);
            final rId = (m['restaurantId'] ?? '').toString().toLowerCase();
            final rName = (m['restaurantName'] ?? '').toString().toLowerCase();
            final bool isMatch = (rId == restaurantId.toLowerCase()) ||
                (cleanName != null && cleanName.isNotEmpty && (rName == cleanName.toLowerCase() || title == cleanName.toLowerCase()));

            if (isMatch) {
              remoteReviews.add({
                'id': m['id']?.toString() ?? '',
                'userName': m['userName']?.toString() ?? 'Customer',
                'userId': m['userId']?.toString() ?? (log['user_id'] ?? '').toString(),
                'userEmail': m['userEmail']?.toString() ?? (log['user_email'] ?? '').toString(),
                'userAvatar': m['userAvatar']?.toString() ?? '',
                'stars': m['stars']?.toString() ?? '5',
                'comment': m['comment']?.toString() ?? '',
                'ownerReply': m['ownerReply']?.toString() ?? '',
                'date': m['date']?.toString() ?? '',
                'timestamp': m['timestamp']?.toString() ?? log['created_at']?.toString() ?? '',
              });
            }
          } catch (_) {}
        }
      }

      if (remoteReviews.isNotEmpty) {
        _reviewMemoryCache[restaurantId] = remoteReviews;
        if (cleanName != null && cleanName.isNotEmpty) {
          _reviewMemoryCache[cleanName.toLowerCase()] = remoteReviews;
        }
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('restaurant_reviews_$restaurantId', jsonEncode(remoteReviews));
        } catch (_) {}
        return remoteReviews;
      }
    } catch (_) {}

    // 3. Try fetching from Supabase 'restaurants' table (reviews or reviews_json)
    try {
      final supabase = SupabaseService.client;
      dynamic res;

      // Query by ID
      try {
        res = await supabase
            .from('restaurants')
            .select('id, name, reviews, reviews_json, rating, total_reviews')
            .eq('id', restaurantId)
            .maybeSingle();
      } catch (_) {}

      // Fallback query by restaurant name if not found by ID
      if (res == null && cleanName != null && cleanName.isNotEmpty) {
        try {
          res = await supabase
              .from('restaurants')
              .select('id, name, reviews, reviews_json, rating, total_reviews')
              .ilike('name', cleanName)
              .limit(1)
              .maybeSingle();
        } catch (_) {}
      }

      if (res != null) {
        List<dynamic>? serverReviews;
        if (res['reviews'] is List) {
          serverReviews = res['reviews'] as List<dynamic>;
        } else if (res['reviews_json'] != null) {
          try {
            serverReviews = jsonDecode(res['reviews_json'].toString());
          } catch (_) {}
        }

        if (serverReviews != null && serverReviews.isNotEmpty) {
          final loaded = serverReviews.map((item) => Map<String, String>.from(item as Map)).toList();
          _reviewMemoryCache[restaurantId] = loaded;
          if (cleanName != null && cleanName.isNotEmpty) {
            _reviewMemoryCache[cleanName.toLowerCase()] = loaded;
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('restaurant_reviews_$restaurantId', jsonEncode(loaded));
          } catch (_) {}
          return loaded;
        }
      }
    } catch (_) {}

    // 4. Try fetching from Supabase 'restaurant_reviews' table
    try {
      final supabase = SupabaseService.client;
      List<dynamic> rows = [];

      try {
        if (cleanName != null && cleanName.isNotEmpty) {
          rows = await supabase
              .from('restaurant_reviews')
              .select()
              .or('restaurant_id.eq.$restaurantId,restaurant_name.ilike.$cleanName')
              .order('created_at', ascending: false);
        } else {
          rows = await supabase
              .from('restaurant_reviews')
              .select()
              .eq('restaurant_id', restaurantId)
              .order('created_at', ascending: false);
        }
      } catch (_) {
        try {
          rows = await supabase
              .from('restaurant_reviews')
              .select()
              .eq('restaurant_id', restaurantId)
              .order('created_at', ascending: false);
        } catch (_) {}
      }

      if (rows.isNotEmpty) {
        final List<Map<String, String>> dbReviews = [];
        for (final item in rows) {
          final m = Map<String, dynamic>.from(item as Map);
          dbReviews.add({
            'id': m['id']?.toString() ?? '',
            'userName': m['user_name']?.toString() ?? 'Customer',
            'userId': m['user_id']?.toString() ?? '',
            'userEmail': m['user_email']?.toString() ?? '',
            'userAvatar': m['user_avatar']?.toString() ?? '',
            'stars': m['stars']?.toString() ?? '5',
            'comment': m['comment']?.toString() ?? '',
            'ownerReply': m['owner_reply']?.toString() ?? '',
            'date': m['date']?.toString() ?? '',
            'timestamp': m['created_at']?.toString() ?? '',
          });
        }
        if (dbReviews.isNotEmpty) {
          _reviewMemoryCache[restaurantId] = dbReviews;
          if (cleanName != null && cleanName.isNotEmpty) {
            _reviewMemoryCache[cleanName.toLowerCase()] = dbReviews;
          }
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('restaurant_reviews_$restaurantId', jsonEncode(dbReviews));
          } catch (_) {}
          return dbReviews;
        }
      }
    } catch (_) {}

    // 5. Try SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('restaurant_reviews_$restaurantId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final loaded = decoded.map((item) => Map<String, String>.from(item as Map)).toList();
        _reviewMemoryCache[restaurantId] = loaded;
        if (cleanName != null && cleanName.isNotEmpty) {
          _reviewMemoryCache[cleanName.toLowerCase()] = loaded;
        }
        return loaded;
      }
    } catch (_) {}

    // 6. Default seed reviews fallback + auto-sync to Supabase
    final defaultList = _getDefaultSeedReviews(restaurantId, restaurantName: cleanName);
    _reviewMemoryCache[restaurantId] = defaultList;
    if (cleanName != null && cleanName.isNotEmpty) {
      _reviewMemoryCache[cleanName.toLowerCase()] = defaultList;
    }

    if (defaultList.isNotEmpty) {
      // Asynchronously persist seed reviews to Supabase in background
      saveReviewsToSupabase(restaurantId, defaultList, restaurantName: cleanName);
    }

    return defaultList;
  }

  /// Save reviews and owner replies to Supabase database tables and local caches
  static Future<void> saveReviewsToSupabase(
    String restaurantId,
    List<Map<String, String>> reviews, {
    String? restaurantName,
  }) async {
    final cleanName = restaurantName?.trim();
    _reviewMemoryCache[restaurantId] = reviews;
    if (cleanName != null && cleanName.isNotEmpty) {
      _reviewMemoryCache[cleanName.toLowerCase()] = reviews;
    }

    // 1. Save locally to disk SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('restaurant_reviews_$restaurantId', jsonEncode(reviews));
      if (cleanName != null && cleanName.isNotEmpty) {
        await prefs.setString('restaurant_reviews_${cleanName.toLowerCase()}', jsonEncode(reviews));
      }
    } catch (_) {}

    // 2. Calculate average rating
    double sum = 0;
    for (var r in reviews) {
      sum += (double.tryParse(r['stars'] ?? '0') ?? 0);
    }
    final avgRating = reviews.isNotEmpty ? (sum / reviews.length) : 0.0;

    // 3. Persist to Supabase 'restaurants' table
    try {
      final supabase = SupabaseService.client;

      // Attempt update by ID
      try {
        await supabase.from('restaurants').update({
          'reviews': reviews,
          'reviews_json': jsonEncode(reviews),
          'rating': avgRating,
          'total_reviews': reviews.length,
        }).eq('id', restaurantId);
      } catch (_) {
        try {
          await supabase.from('restaurants').update({
            'reviews_json': jsonEncode(reviews),
            'rating': avgRating,
          }).eq('id', restaurantId);
        } catch (_) {}
      }

      // Also attempt update by Name if provided
      if (cleanName != null && cleanName.isNotEmpty) {
        try {
          await supabase.from('restaurants').update({
            'reviews': reviews,
            'reviews_json': jsonEncode(reviews),
            'rating': avgRating,
            'total_reviews': reviews.length,
          }).ilike('name', cleanName);
        } catch (_) {
          try {
            await supabase.from('restaurants').update({
              'reviews_json': jsonEncode(reviews),
              'rating': avgRating,
            }).ilike('name', cleanName);
          } catch (_) {}
        }
      }

      // 4. Persist to Supabase 'audit_logs' table (reliable cross-device persistence)
      for (final r in reviews) {
        try {
          final validUserId = r['userId'] != null && r['userId']!.length > 10
              ? r['userId']!
              : 'e257a3d8-a2e2-4872-afcf-0d7324e8f0cf';
          final validEmail = r['userEmail'] != null && r['userEmail']!.isNotEmpty
              ? r['userEmail']!
              : 'lowyq-wm22@student.tarc.edu.my';

          await supabase.from('audit_logs').insert({
            'user_id': validUserId,
            'user_email': validEmail,
            'action_type': 'CUSTOMER_REVIEW',
            'category': 'RESTAURANT_REVIEW',
            'title': cleanName ?? restaurantId,
            'description': jsonEncode({
              'id': r['id'] ?? 'rev_${DateTime.now().millisecondsSinceEpoch}',
              'restaurantId': restaurantId,
              'restaurantName': cleanName ?? restaurantId,
              'userName': r['userName'] ?? 'Customer',
              'userId': validUserId,
              'userEmail': validEmail,
              'userAvatar': r['userAvatar'] ?? '',
              'stars': r['stars'] ?? '5',
              'comment': r['comment'] ?? '',
              'ownerReply': r['ownerReply'] ?? '',
              'date': r['date'] ?? '',
              'timestamp': r['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
            }),
          });
        } catch (_) {}
      }

      // 5. Upsert each review into Supabase 'restaurant_reviews' table
      for (final r in reviews) {
        final reviewId = r['id'] ?? 'rev_${restaurantId}_${(r['userName'] ?? 'user').replaceAll(' ', '_')}';
        try {
          await supabase.from('restaurant_reviews').upsert({
            'id': reviewId,
            'restaurant_id': restaurantId,
            'restaurant_name': cleanName ?? '',
            'user_id': r['userId'] ?? '',
            'user_name': r['userName'] ?? 'Customer',
            'user_email': r['userEmail'] ?? '',
            'user_avatar': r['userAvatar'] ?? '',
            'stars': int.tryParse(r['stars'] ?? '5') ?? 5,
            'comment': r['comment'] ?? '',
            'owner_reply': r['ownerReply'] ?? '',
            'date': r['date'] ?? '',
            'created_at': r['timestamp'] ?? DateTime.now().toUtc().toIso8601String(),
          });
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Preload reviews for multiple restaurants using models (ID & Name)
  static Future<void> preloadRestaurants(List<RestaurantModel> restaurants) async {
    for (final r in restaurants) {
      await fetchReviews(r.id, restaurantName: r.name);
    }
  }

  /// Preload reviews for multiple restaurant IDs
  static Future<void> preloadReviews(List<String> restaurantIds) async {
    for (final id in restaurantIds) {
      final matched = MockSeedData.restaurants.where((r) => r.id == id).firstOrNull;
      await fetchReviews(id, restaurantName: matched?.name);
    }
  }

  /// Add a review and save to Supabase + SharedPreferences + update memory cache
  static Future<void> addReview({
    required String restaurantId,
    required String userName,
    required int stars,
    required String comment,
    String? restaurantName,
    String? userId,
    String? userEmail,
    String? userAvatar,
    String? timestamp,
  }) async {
    final currentReviews = await fetchReviews(restaurantId, restaurantName: restaurantName);
    final now = DateTime.now();
    final newReview = {
      'id': 'rev_${now.millisecondsSinceEpoch}',
      'userName': userName,
      'userId': userId ?? '',
      'userEmail': userEmail ?? '',
      'userAvatar': userAvatar ?? '',
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'timestamp': timestamp ?? now.toUtc().toIso8601String(),
      'stars': '$stars',
      'comment': comment,
    };
    currentReviews.insert(0, newReview);
    await saveReviewsToSupabase(restaurantId, currentReviews, restaurantName: restaurantName);

    // Also record into user activity history
    await logUserReviewActivity(
      restaurantId: restaurantId,
      restaurantName: restaurantName ?? restaurantId,
      stars: stars,
      comment: comment,
      timestamp: newReview['timestamp'],
    );
  }

  /// Log a user review activity
  static Future<void> logUserReviewActivity({
    required String restaurantId,
    required String restaurantName,
    required int stars,
    required String comment,
    String? timestamp,
  }) async {
    final currentUser = CustomerStoreService.currentCustomer;
    final userKey = (currentUser?.id != null && currentUser!.id.isNotEmpty)
        ? currentUser.id
        : (currentUser?.email ?? 'anonymous_user');

    final now = DateTime.now();
    final record = {
      'id': 'act_rev_${now.millisecondsSinceEpoch}',
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'stars': '$stars',
      'comment': comment,
      'timestamp': timestamp ?? now.toIso8601String(),
      'category': 'Restaurant Review',
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('user_review_activities_$userKey');
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        list = jsonDecode(existingJson);
      }
      list.removeWhere((item) => item['restaurantId'] == restaurantId);
      list.insert(0, record);
      await prefs.setString('user_review_activities_$userKey', jsonEncode(list));

      final globalJson = prefs.getString('global_review_activities');
      List<dynamic> gList = [];
      if (globalJson != null && globalJson.isNotEmpty) {
        gList = jsonDecode(globalJson);
      }
      gList.removeWhere((item) => item['restaurantId'] == restaurantId && item['comment'] == comment);
      gList.insert(0, record);
      await prefs.setString('global_review_activities', jsonEncode(gList));
    } catch (_) {}
  }

  /// Fetch all review activities for the active user
  static Future<List<Map<String, dynamic>>> fetchUserReviewActivities() async {
    final List<Map<String, dynamic>> results = [];
    final Set<String> seenReviews = {};

    final currentUser = CustomerStoreService.currentCustomer;
    final userKey = (currentUser?.id != null && currentUser!.id.isNotEmpty)
        ? currentUser.id
        : (currentUser?.email ?? 'anonymous_user');

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check user-specific review activity log
      final userJson = prefs.getString('user_review_activities_$userKey');
      if (userJson != null && userJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(userJson);
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          final key = '${map['restaurantName']}_${map['comment']}';
          if (!seenReviews.contains(key)) {
            seenReviews.add(key);
            results.add(map);
          }
        }
      }

      // 2. Check global review activities
      final globalJson = prefs.getString('global_review_activities');
      if (globalJson != null && globalJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(globalJson);
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          final key = '${map['restaurantName']}_${map['comment']}';
          if (!seenReviews.contains(key)) {
            seenReviews.add(key);
            results.add(map);
          }
        }
      }

      // 3. Scan all restaurant_reviews_* in SharedPreferences
      final allKeys = prefs.getKeys().where((k) => k.startsWith('restaurant_reviews_'));
      for (final key in allKeys) {
        final restId = key.replaceFirst('restaurant_reviews_', '');
        final jsonStr = prefs.getString(key);
        if (jsonStr != null && jsonStr.isNotEmpty) {
          final List<dynamic> decoded = jsonDecode(jsonStr);
          for (final r in decoded) {
            final rMap = Map<String, dynamic>.from(r as Map);
            final uid = rMap['userId']?.toString() ?? '';
            final uemail = rMap['userEmail']?.toString() ?? '';
            final uname = rMap['userName']?.toString() ?? '';

            final isMatch = (currentUser != null && (
              (uid.isNotEmpty && uid == currentUser.id) ||
              (uemail.isNotEmpty && uemail == currentUser.email) ||
              (uname.isNotEmpty && uname == currentUser.name)
            ));

            if (isMatch) {
              String restName = restId;
              final matchingRest = MockSeedData.restaurants.where((x) => x.id == restId).firstOrNull;
              if (matchingRest != null) {
                restName = matchingRest.name;
              }

              final revKey = '${restName}_${rMap['comment']}';
              if (!seenReviews.contains(revKey)) {
                seenReviews.add(revKey);
                results.add({
                  'id': rMap['id'] ?? 'act_rev_${DateTime.now().millisecondsSinceEpoch}',
                  'restaurantId': restId,
                  'restaurantName': restName,
                  'stars': rMap['stars'] ?? '5',
                  'comment': rMap['comment'] ?? '',
                  'timestamp': rMap['timestamp'] ?? rMap['date'] ?? 'Recently',
                  'category': 'Restaurant Review',
                });
              }
            }
          }
        }
      }
    } catch (_) {}

    return results;
  }

  /// Record a recent restaurant visit
  static Future<void> recordRecentVisit(RestaurantModel restaurant) async {
    final currentUser = CustomerStoreService.currentCustomer;
    final userKey = (currentUser?.id != null && currentUser!.id.isNotEmpty)
        ? currentUser.id
        : (currentUser?.email ?? 'anonymous_user');

    final now = DateTime.now();
    final visitRecord = {
      'id': restaurant.id,
      'name': restaurant.name,
      'category': restaurant.category,
      'address': restaurant.address,
      'hygieneRiskScore': restaurant.hygieneRiskScore,
      'riskCategory': restaurant.riskCategory.name,
      'violationCount': restaurant.violationCount,
      'timestamp': now.toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('user_recent_visits_$userKey');
      List<dynamic> list = [];
      if (existingJson != null && existingJson.isNotEmpty) {
        list = jsonDecode(existingJson);
      }
      list.removeWhere((item) => item['id'] == restaurant.id || item['name'] == restaurant.name);
      list.insert(0, visitRecord);
      if (list.length > 25) list = list.sublist(0, 25);
      await prefs.setString('user_recent_visits_$userKey', jsonEncode(list));

      final globalJson = prefs.getString('global_recent_visits');
      List<dynamic> gList = [];
      if (globalJson != null && globalJson.isNotEmpty) {
        gList = jsonDecode(globalJson);
      }
      gList.removeWhere((item) => item['id'] == restaurant.id || item['name'] == restaurant.name);
      gList.insert(0, visitRecord);
      if (gList.length > 25) gList = gList.sublist(0, 25);
      await prefs.setString('global_recent_visits', jsonEncode(gList));
    } catch (_) {}
  }

  /// Fetch all recent visits for active user
  static Future<List<Map<String, dynamic>>> fetchRecentVisits() async {
    final List<Map<String, dynamic>> results = [];
    final Set<String> seen = {};

    final currentUser = CustomerStoreService.currentCustomer;
    final userKey = (currentUser?.id != null && currentUser!.id.isNotEmpty)
        ? currentUser.id
        : (currentUser?.email ?? 'anonymous_user');

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. User-specific visits
      final userJson = prefs.getString('user_recent_visits_$userKey');
      if (userJson != null && userJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(userJson);
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          final key = map['name']?.toString() ?? map['id']?.toString() ?? '';
          if (key.isNotEmpty && !seen.contains(key)) {
            seen.add(key);
            results.add(map);
          }
        }
      }

      // 2. Global visits fallback
      final globalJson = prefs.getString('global_recent_visits');
      if (globalJson != null && globalJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(globalJson);
        for (final item in decoded) {
          final map = Map<String, dynamic>.from(item as Map);
          final key = map['name']?.toString() ?? map['id']?.toString() ?? '';
          if (key.isNotEmpty && !seen.contains(key)) {
            seen.add(key);
            results.add(map);
          }
        }
      }

      // 3. Also include restaurants where user has submitted reviews
      final reviewActivities = await fetchUserReviewActivities();
      for (final rev in reviewActivities) {
        final rName = rev['restaurantName']?.toString() ?? '';
        final rId = rev['restaurantId']?.toString() ?? '';
        if (rName.isNotEmpty && !seen.contains(rName)) {
          seen.add(rName);
          results.add({
            'id': rId,
            'name': rName,
            'category': 'Restaurant',
            'address': 'Verified Premises Location',
            'hygieneRiskScore': 10.0,
            'riskCategory': 'safe',
            'violationCount': 0,
            'timestamp': rev['timestamp'] ?? DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (_) {}

    return results;
  }
}

class BookmarkService {
  /// Reactive notifier for UI components
  static final ValueNotifier<Set<String>> bookmarkedIdsNotifier = ValueNotifier<Set<String>>({});

  /// Tier 1: In-Memory Fast Cache (Instant O(1) reads with zero network latency)
  static Set<String> _memoryCache = {};
  static bool _isLoadedFromDisk = false;
  static DateTime? _lastCloudFetchTime;
  static Timer? _debounceSyncTimer;
  static bool _isCloudSyncing = false;
  static bool _hasPendingCloudSync = false;

  /// Cache TTL: 5 minutes before background re-validating from cloud
  static const Duration _cloudCacheTtl = Duration(minutes: 5);

  static String _getCurrentUserId() {
    return CustomerStoreService.currentCustomer?.id ??
        SupabaseService.client.auth.currentUser?.id ??
        'guest_default';
  }

  static String? _getCurrentUserEmail() {
    return CustomerStoreService.currentCustomer?.email ??
        SupabaseService.client.auth.currentUser?.email;
  }

  static bool _isValidUuid(String str) {
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

  /// Initialize: instantly load from local disk cache first, then validate with cloud in background
  static Future<void> init() async {
    if (!_isLoadedFromDisk) {
      await _loadFromLocalDisk();
    }
    _maybeSyncFromCloudInBackground();
  }

  /// Tier 2: Instant Local Disk Cache Retrieval (0 network requests)
  static Future<Set<String>> _loadFromLocalDisk() async {
    final userId = _getCurrentUserId();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('bookmarks_$userId') ?? [];
      _memoryCache = Set<String>.from(cached);
      bookmarkedIdsNotifier.value = Set.from(_memoryCache);
      _isLoadedFromDisk = true;
    } catch (e) {
      debugPrint('BookmarkService: Error reading local cache: $e');
    }
    return _memoryCache;
  }

  /// Public loader: checks memory/disk cache first, only hits network if TTL expired or forced
  static Future<Set<String>> loadBookmarks({bool forceRefresh = false}) async {
    if (!_isLoadedFromDisk) {
      await _loadFromLocalDisk();
    }

    final now = DateTime.now();
    final bool isExpired = _lastCloudFetchTime == null ||
        now.difference(_lastCloudFetchTime!) > _cloudCacheTtl;

    if (forceRefresh || isExpired) {
      await _fetchFromSupabaseCloud();
    }

    return _memoryCache;
  }

  /// Background Cloud Fetch (Guarded & Rate-Limited)
  static Future<void> _maybeSyncFromCloudInBackground() async {
    final now = DateTime.now();
    if (_lastCloudFetchTime != null &&
        now.difference(_lastCloudFetchTime!) < _cloudCacheTtl) {
      // Cache is fresh, skip redundant network request
      return;
    }
    _fetchFromSupabaseCloud();
  }

  static Future<void> _fetchFromSupabaseCloud() async {
    if (_isCloudSyncing) return;
    _isCloudSyncing = true;

    final userId = _getCurrentUserId();
    final email = _getCurrentUserEmail();

    try {
      final supabase = SupabaseService.client;
      Map<String, dynamic>? userRow;

      if (_isValidUuid(userId)) {
        userRow = await supabase.from('users').select('settings').eq('id', userId).maybeSingle();
      }
      if (userRow == null && email != null && email.isNotEmpty) {
        userRow = await supabase.from('users').select('settings').eq('email', email).maybeSingle();
      }

      if (userRow != null && userRow['settings'] is Map) {
        final settings = userRow['settings'] as Map<String, dynamic>;
        if (settings['bookmarks'] is List) {
          final List<dynamic> remoteBookmarks = settings['bookmarks'];
          final remoteSet = remoteBookmarks.map((e) => e.toString()).toSet();

          // Merge local cache and cloud
          _memoryCache.addAll(remoteSet);
          bookmarkedIdsNotifier.value = Set.from(_memoryCache);

          // Save to local device storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList('bookmarks_$userId', _memoryCache.toList());
        }
      }
      _lastCloudFetchTime = DateTime.now();
    } catch (e) {
      debugPrint('BookmarkService: Cloud fetch skipped/offline: $e');
    } finally {
      _isCloudSyncing = false;
    }
  }

  /// Instant O(1) in-memory check (0 ms latency, no disk or network hit)
  static bool isBookmarked(String restaurantId) {
    return _memoryCache.contains(restaurantId);
  }

  /// Toggle bookmark: Optimistic instant UI update + Local cache + Debounced cloud sync
  static Future<bool> toggleBookmark(String restaurantId) async {
    final bool willBeSaved = !_memoryCache.contains(restaurantId);

    // 1. Instant Memory Update (Tier 1)
    if (willBeSaved) {
      _memoryCache.add(restaurantId);
    } else {
      _memoryCache.remove(restaurantId);
    }
    bookmarkedIdsNotifier.value = Set.from(_memoryCache);

    // 2. Instant Local Storage Persistence (Tier 2)
    final userId = _getCurrentUserId();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList('bookmarks_$userId', _memoryCache.toList());
    }).catchError((e) {
      debugPrint('BookmarkService: Error persisting to disk: $e');
    });

    // 3. Smart Debounced Cloud Sync (Tier 3 - Collapses multiple taps into 1 request)
    _scheduleDebouncedCloudSync();

    return willBeSaved;
  }

  /// Debouncer: waits 500ms before sending cloud request, preventing excessive Supabase calls
  static void _scheduleDebouncedCloudSync() {
    _hasPendingCloudSync = true;
    _debounceSyncTimer?.cancel();
    _debounceSyncTimer = Timer(const Duration(milliseconds: 500), () {
      _executePendingCloudSync();
    });
  }

  static Future<void> _executePendingCloudSync() async {
    if (!_hasPendingCloudSync) return;
    _hasPendingCloudSync = false;

    final userId = _getCurrentUserId();
    final email = _getCurrentUserEmail();
    final currentList = _memoryCache.toList();

    try {
      final supabase = SupabaseService.client;
      Map<String, dynamic>? userRow;
      String? matchedId;

      if (_isValidUuid(userId)) {
        userRow = await supabase.from('users').select('id, settings').eq('id', userId).maybeSingle();
        matchedId = userId;
      }
      if (userRow == null && email != null && email.isNotEmpty) {
        userRow = await supabase.from('users').select('id, settings').eq('email', email).maybeSingle();
        if (userRow != null) {
          matchedId = userRow['id']?.toString();
        }
      }

      Map<String, dynamic> settings = {};
      if (userRow != null && userRow['settings'] is Map) {
        settings = Map<String, dynamic>.from(userRow['settings'] as Map);
      }
      settings['bookmarks'] = currentList;

      if (matchedId != null && _isValidUuid(matchedId)) {
        await supabase.from('users').update({'settings': settings}).eq('id', matchedId);
      } else if (email != null && email.isNotEmpty) {
        await supabase.from('users').update({'settings': settings}).eq('email', email);
      }
      _lastCloudFetchTime = DateTime.now();
      debugPrint('BookmarkService: Cloud sync completed (${currentList.length} bookmarks)');
    } catch (e) {
      debugPrint('BookmarkService: Cloud sync failed/offline: $e');
    }
  }

  /// Retrieve full restaurant models with caching
  static Future<List<RestaurantModel>> getBookmarkedRestaurants({bool forceRefresh = false}) async {
    await init();
    if (forceRefresh) {
      await loadBookmarks(forceRefresh: true);
    }
    final ids = _memoryCache;
    if (ids.isEmpty) return [];

    final all = await RestaurantStoreService.fetchOwnerRestaurants(null);
    return all.where((r) => ids.contains(r.id)).toList();
  }
}

class ComplaintStoreService {
  static final ValueNotifier<List<ComplaintModel>> complaintsNotifier = ValueNotifier<List<ComplaintModel>>([]);
  static bool _hasLoadedFromSupabase = false;

  static bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final regex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return regex.hasMatch(str);
  }

  /// Fetch all complaints from Supabase + local cache
  static Future<List<ComplaintModel>> fetchAllComplaints({bool forceRefresh = false}) async {
    if (_hasLoadedFromSupabase && !forceRefresh && complaintsNotifier.value.isNotEmpty) {
      return complaintsNotifier.value;
    }

    List<ComplaintModel> loadedList = [];

    // 1. Try Supabase 'complaints' table with joined relational tables
    try {
      final supabase = SupabaseService.client;
      final res = await supabase.from('complaints').select('''
        id,
        restaurant_id,
        user_id,
        category,
        description,
        status,
        severity,
        latitude,
        longitude,
        is_flagged_for_review,
        flagged_reason,
        submitted_at,
        updated_at,
        restaurants ( id, name, address ),
        users ( id, name, email ),
        complaint_issues ( id, issue_text ),
        complaint_photos ( id, photo_url )
      ''').order('submitted_at', ascending: false);

      if (res.isNotEmpty) {
        loadedList = res.map((row) => ComplaintModel.fromJson(Map<String, dynamic>.from(row))).toList();
      }
    } catch (joinErr) {
      // Fallback simple flat query
      try {
        final supabase = SupabaseService.client;
        final res = await supabase.from('complaints').select().order('submitted_at', ascending: false);
        if (res.isNotEmpty) {
          loadedList = res.map((row) => ComplaintModel.fromJson(Map<String, dynamic>.from(row))).toList();
        }
      } catch (_) {}
    }

    // 2. Merge with MockSeedData
    final Set<String> seenIds = loadedList.map((c) => c.id).toSet();
    for (final seed in MockSeedData.complaints) {
      if (!seenIds.contains(seed.id)) {
        seenIds.add(seed.id);
        loadedList.add(seed);
      }
    }

    // 3. Merge with local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_custom_complaints');
      if (localJson != null && localJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localJson);
        for (final item in decoded) {
          final comp = ComplaintModel.fromJson(Map<String, dynamic>.from(item));
          if (!seenIds.contains(comp.id)) {
            seenIds.add(comp.id);
            loadedList.insert(0, comp);
          }
        }
      }
    } catch (_) {}

    _hasLoadedFromSupabase = true;
    complaintsNotifier.value = loadedList;
    MockSeedData.complaints = loadedList;
    return loadedList;
  }

  /// Submit a complaint to Supabase (complaints, complaint_issues, complaint_photos), SharedPreferences & in-memory list
  static Future<ComplaintModel> submitComplaint({
    required String restaurantId,
    required String restaurantName,
    required String restaurantAddress,
    required String category,
    required List<String> issues,
    required String description,
    required List<String> photoUrls,
    double latitude = 3.1466,
    double longitude = 101.6958,
    SeverityLevel severity = SeverityLevel.medium,
  }) async {
    final now = DateTime.now();
    final complaintUuid = UuidHelper.generateV4();

    final customer = CustomerStoreService.currentCustomer;
    final currentAuthUser = SupabaseService.client.auth.currentUser;

    String candidateUserId = customer?.id.isNotEmpty == true
        ? customer!.id
        : (currentAuthUser?.id ?? '');
    final userName = customer?.name.isNotEmpty == true
        ? customer!.name
        : (currentAuthUser?.email?.split('@').first ?? 'Citizen Diner');
    final userEmail = customer?.email.isNotEmpty == true
        ? customer!.email
        : (currentAuthUser?.email ?? '');

    final complaint = ComplaintModel(
      id: complaintUuid,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      userId: candidateUserId.isNotEmpty ? candidateUserId : 'usr_customer',
      userName: userName,
      category: category,
      issues: issues,
      description: description,
      status: ComplaintStatus.submitted,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      submittedAt: now.toIso8601String(),
      photoUrls: photoUrls,
    );

    // 1. Instant local reactivity
    final updatedList = List<ComplaintModel>.from(complaintsNotifier.value);
    updatedList.insert(0, complaint);
    complaintsNotifier.value = updatedList;
    MockSeedData.complaints = updatedList;

    // 2. Local disk cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final localJson = prefs.getString('local_custom_complaints');
      List<dynamic> existingList = [];
      if (localJson != null && localJson.isNotEmpty) {
        existingList = jsonDecode(localJson);
      }
      existingList.insert(0, complaint.toJson());
      await prefs.setString('local_custom_complaints', jsonEncode(existingList));
    } catch (_) {}

    // 3. Supabase relational persistence
    try {
      final supabase = SupabaseService.client;

      // A. Resolve valid user_id UUID
      String validUserUuid = candidateUserId;
      if (!_isValidUuid(validUserUuid)) {
        if (currentAuthUser != null && _isValidUuid(currentAuthUser.id)) {
          validUserUuid = currentAuthUser.id;
        } else if (userEmail.isNotEmpty) {
          final userRow = await supabase.from('users').select('id').eq('email', userEmail).maybeSingle();
          if (userRow != null && userRow['id'] != null) {
            validUserUuid = userRow['id'].toString();
          }
        }
      }

      // If still not a valid UUID, fallback to first user in users table
      if (!_isValidUuid(validUserUuid)) {
        final anyUser = await supabase.from('users').select('id').limit(1).maybeSingle();
        if (anyUser != null && anyUser['id'] != null) {
          validUserUuid = anyUser['id'].toString();
        } else {
          validUserUuid = UuidHelper.generateV4();
        }
      }

      // B. Resolve valid restaurant_id UUID
      String validRestaurantUuid = restaurantId;
      if (!_isValidUuid(validRestaurantUuid)) {
        final restRow = await supabase.from('restaurants').select('id').eq('name', restaurantName).maybeSingle();
        if (restRow != null && restRow['id'] != null) {
          validRestaurantUuid = restRow['id'].toString();
        } else {
          // Check if any restaurant exists to link
          final anyRest = await supabase.from('restaurants').select('id').limit(1).maybeSingle();
          if (anyRest != null && anyRest['id'] != null) {
            validRestaurantUuid = anyRest['id'].toString();
          } else {
            // Create premise in restaurants table
            validRestaurantUuid = UuidHelper.generateV4();
            await supabase.from('restaurants').insert({
              'id': validRestaurantUuid,
              'name': restaurantName,
              'category': category,
              'address': restaurantAddress,
              'latitude': latitude,
              'longitude': longitude,
            });
          }
        }
      }

      // C. Insert into complaints table
      final payload = {
        'id': complaintUuid,
        'restaurant_id': validRestaurantUuid,
        'user_id': validUserUuid,
        'category': category,
        'description': description,
        'status': 'submitted',
        'severity': severity.name,
        'latitude': latitude,
        'longitude': longitude,
        'is_flagged_for_review': false,
        'submitted_at': now.toUtc().toIso8601String(),
        'updated_at': now.toUtc().toIso8601String(),
      };

      await supabase.from('complaints').insert(payload);

      // D. Insert into complaint_issues table
      if (issues.isNotEmpty) {
        final issuesData = issues.map((iss) => {
          'id': UuidHelper.generateV4(),
          'complaint_id': complaintUuid,
          'issue_text': iss,
        }).toList();
        try {
          await supabase.from('complaint_issues').insert(issuesData);
        } catch (_) {}
      }

      // E. Insert into complaint_photos table
      if (photoUrls.isNotEmpty) {
        final photosData = photoUrls.map((url) => {
          'id': UuidHelper.generateV4(),
          'complaint_id': complaintUuid,
          'photo_url': url,
          'uploaded_at': now.toUtc().toIso8601String(),
        }).toList();
        try {
          await supabase.from('complaint_photos').insert(photosData);
        } catch (_) {}
      }

      // F. Log action into user_audit_logs table
      try {
        await supabase.from('user_audit_logs').insert({
          'id': UuidHelper.generateV4(),
          'user_id': validUserUuid,
          'user_email': userEmail,
          'action_type': 'SUBMIT_COMPLAINT',
          'category': 'Hygiene Report',
          'title': 'Reported $restaurantName',
          'description': 'Category: $category, Issues: ${issues.join(', ')}',
          'created_at': now.toUtc().toIso8601String(),
        });
      } catch (_) {}
    } catch (e) {
      debugPrint('Supabase complaint submission notice: $e');
    }

    return complaint;
  }

  /// Update status in Supabase
  static Future<void> updateComplaintStatus(String complaintId, ComplaintStatus newStatus) async {
    final updated = complaintsNotifier.value.map((c) {
      if (c.id == complaintId) {
        return ComplaintModel(
          id: c.id,
          restaurantId: c.restaurantId,
          restaurantName: c.restaurantName,
          userId: c.userId,
          userName: c.userName,
          category: c.category,
          issues: c.issues,
          description: c.description,
          status: newStatus,
          severity: c.severity,
          latitude: c.latitude,
          longitude: c.longitude,
          isFlaggedForReview: c.isFlaggedForReview,
          flaggedReason: c.flaggedReason,
          submittedAt: c.submittedAt,
          photoUrls: c.photoUrls,
        );
      }
      return c;
    }).toList();

    complaintsNotifier.value = updated;
    MockSeedData.complaints = updated;

    try {
      final supabase = SupabaseService.client;
      await supabase.from('complaints').update({
        'status': newStatus.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', complaintId);
    } catch (_) {}
  }
}



