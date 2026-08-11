import 'package:flutter/foundation.dart';
import '../models/mock_seed_data.dart';
import '../models/restaurant_model.dart';
import '../utils/uuid_helper.dart';
import 'audit_log_service.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class RestaurantStoreService {
  /// In-memory override store for reviewed outlet statuses: restaurantId -> status string
  static final Map<String, String> _reviewedOutletStatuses = {};
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

      if (currentUserId != null && currentUserId.isNotEmpty) {
        insertData['owner_id'] = currentUserId;
      }

      // Try inserting with operating_hours and business_reg_no into database
      try {
        final Map<String, dynamic> insertDataWithExtraCols = Map<String, dynamic>.from(insertData);
        insertDataWithExtraCols['operating_hours'] = operatingHours;
        if (generatedRegNo != null) {
          insertDataWithExtraCols['business_reg_no'] = generatedRegNo;
        }
        await supabase.from('restaurants').insert(insertDataWithExtraCols);
      } catch (_) {
        // Safe fallback if operating_hours column is not yet present in Supabase table schema
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

      if (ownerId != null && ownerId.isNotEmpty) {
        final res = await supabase
            .from('restaurants')
            .select()
            .or('owner_id.eq.$ownerId,owner_id.eq.own_001');
        rows = res as List<dynamic>;
      } else {
        final res = await supabase.from('restaurants').select();
        rows = res as List<dynamic>;
      }

      final List<RestaurantModel> fetchedList = [];
      for (final r in rows) {
        fetchedList.add(RestaurantModel.fromMap(r as Map<String, dynamic>));
      }

      // Merge any local session restaurants that might not yet be in fetchedList
      for (final local in MockSeedData.restaurants) {
        if (!fetchedList.any((r) => r.id == local.id)) {
          if (ownerId == null || local.ownerId == ownerId || local.ownerId == 'own_001' || (ownerEmail != null && local.ownerId == ownerEmail)) {
            fetchedList.add(local);
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
          .eq('status', 'pendingVerification')
          .order('created_at', ascending: false);

      final List<dynamic> rows = res as List<dynamic>;
      final List<RestaurantModel> pendingList = [];
      for (final r in rows) {
        final model = RestaurantModel.fromMap(r as Map<String, dynamic>);
        final String effectiveStatus = _reviewedOutletStatuses[model.id] ?? model.status.name;
        if (effectiveStatus == 'pendingVerification') {
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
          .eq('status', 'pendingVerification')
          .order('created_at', ascending: false)
          .range(from, to);

      final List<dynamic> rows = res as List<dynamic>;
      final List<RestaurantModel> pendingList = [];
      for (final r in rows) {
        final model = RestaurantModel.fromMap(r as Map<String, dynamic>);
        // Check if override status exists in session or local store
        final String effectiveStatus = _reviewedOutletStatuses[model.id] ?? model.status.name;
        if (effectiveStatus == 'pendingVerification') {
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
    // Record status override in session memory immediately
    _reviewedOutletStatuses[restaurantId] = status;
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

      // 1. Update Supabase `restaurants` table
      try {
        await supabase.from('restaurants').update(updateData).eq('id', restaurantId);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating restaurant status in Supabase table: $e');
        }
      }

      // 2. Update local in-memory MockSeedData store for instant UI reactivity
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

      // 3. Log Audit Action
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
