import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../utils/uuid_helper.dart';
import 'audit_log_service.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class RestaurantStoreService {
  /// In-memory override store for reviewed outlet statuses: restaurantId -> status string
  static final Map<String, String> _reviewedOutletStatuses = {};
  static final Map<String, String> _reviewedOutletRegNos = {};

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

    // 2. Append to active restaurants store for immediate UI updates
    MockSeedData.restaurants.insert(0, newRestaurant);

    return newRestaurant;
  }

  /// Fetches all restaurants belonging to the given owner from Supabase.
  /// Merges with local mock seed data if appropriate.
  static Future<List<RestaurantModel>> fetchOwnerRestaurants(String? ownerId, {String? ownerEmail}) async {
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> rows;

      if (ownerId != null && ownerId.isNotEmpty && _isValidUuid(ownerId)) {
        final res = await supabase
            .from('restaurants')
            .select()
            .eq('owner_id', ownerId);
        rows = res as List<dynamic>;
      } else {
        final res = await supabase.from('restaurants').select();
        rows = res as List<dynamic>;
      }

      final List<RestaurantModel> fetchedList = [];
      for (final r in rows) {
        final mapData = Map<String, dynamic>.from(r as Map<String, dynamic>);
        await _applyOverridesToMap(mapData);
        fetchedList.add(RestaurantModel.fromMap(mapData));
      }

      // Merge any local session restaurants that might not yet be in fetchedList
      for (final local in MockSeedData.restaurants) {
        if (!fetchedList.any((r) => r.id == local.id)) {
          if (ownerId == null || local.ownerId == ownerId || local.ownerId == 'own_001' || (ownerEmail != null && local.ownerId == ownerEmail)) {
            final mapData = local.toMap();
            await _applyOverridesToMap(mapData);
            fetchedList.add(RestaurantModel.fromMap(mapData));
          }
        }
      }

      return fetchedList;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching restaurants from Supabase: $e');
      }
    }

    if (ownerId != null && ownerId.isNotEmpty) {
      return MockSeedData.restaurants.where((r) {
        return r.ownerId == ownerId ||
            (ownerEmail != null && r.ownerId == ownerEmail) ||
            (ownerId == 'own_001' && r.ownerId == 'own_001');
      }).map((r) {
        final mapData = r.toMap();
        final String id = mapData['id']?.toString() ?? '';
        if (_reviewedOutletStatuses.containsKey(id)) {
          mapData['status'] = _reviewedOutletStatuses[id];
        }
        if (_reviewedOutletRegNos.containsKey(id)) {
          mapData['business_reg_no'] = _reviewedOutletRegNos[id];
        }
        return RestaurantModel.fromMap(mapData);
      }).toList();
    }
    return List.from(MockSeedData.restaurants);
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
}
