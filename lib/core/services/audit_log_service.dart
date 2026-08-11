import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audit_log_model.dart';
import '../utils/uuid_helper.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class AuditLogService {
  static final List<AuditLogModel> _localLogs = [
    AuditLogModel(
      id: 'log_seed_101',
      userId: 'adm_001',
      userEmail: 'admin@app.com',
      actionType: 'ADMIN_ROLE_CHANGE',
      category: 'Admin',
      title: 'Admin Role Modification',
      description: 'Admin modified role for account Sarah Tan to Businessman',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    AuditLogModel(
      id: 'log_seed_102',
      userId: 'gov_001',
      userEmail: 'officer@gov.my',
      actionType: 'OUTLET_APPROVED',
      category: 'Government',
      title: 'Outlet Application Approved',
      description: 'Approved & Verified New Century Dim Sum (SSM-2026-92631A-X)',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 20)),
    ),
    AuditLogModel(
      id: 'log_seed_103',
      userId: 'biz_002',
      userEmail: 'lim.cafe@gmail.com',
      actionType: 'BUSINESSMAN_REGISTER',
      category: 'Businessman',
      title: 'Businessman Registration',
      description: 'New businessman account registered for Lim Coffee Roasters',
      timestamp: DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
    ),
    AuditLogModel(
      id: 'log_seed_104',
      userId: 'cus_005',
      userEmail: 'alex.wong@gmail.com',
      actionType: 'CUSTOMER_REGISTER',
      category: 'Customer',
      title: 'User Registration',
      description: 'New customer account registered (Alex Wong)',
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    ),
    AuditLogModel(
      id: 'log_seed_105',
      userId: 'gov_001',
      userEmail: 'officer@gov.my',
      actionType: 'GOVERNMENT_INSPECTION',
      category: 'Government',
      title: 'Government Review & Inspection',
      description: 'Completed hygiene audit inspection for Golden Dragon Noodle Bar',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    ),
    AuditLogModel(
      id: 'log_seed_106',
      userId: 'gov_002',
      userEmail: 'inspector.lee@gov.my',
      actionType: 'OUTLET_REJECTED',
      category: 'Government',
      title: 'Outlet Application Rejected',
      description: 'Rejected outlet submission due to incomplete SSM documentation',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    AuditLogModel(
      id: 'log_seed_107',
      userId: 'adm_001',
      userEmail: 'admin@app.com',
      actionType: 'ADMIN_PROFILE_EDIT',
      category: 'Admin',
      title: 'Admin User Profile Updated',
      description: 'Admin updated phone number and state location for David Chen',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
    ),
  ];

  /// Record a new audit log action and persist to Supabase & SharedPreferences
  static Future<AuditLogModel> logAction({
    required String actionType,
    required String category,
    required String title,
    required String description,
    String? userId,
    String? userEmail,
  }) async {
    final String currentUserId = userId ?? CustomerStoreService.currentCustomer?.id ?? SupabaseService.client.auth.currentUser?.id ?? 'own_001';
    final String currentUserEmail = userEmail ?? CustomerStoreService.currentCustomer?.email ?? SupabaseService.client.auth.currentUser?.email ?? 'user@app.com';

    final String id = UuidHelper.generateV4();
    final DateTime now = DateTime.now();

    final log = AuditLogModel(
      id: id,
      userId: currentUserId,
      userEmail: currentUserEmail,
      actionType: actionType,
      category: category,
      title: title,
      description: description,
      timestamp: now,
    );

    // 1. Insert to in-memory list
    _localLogs.insert(0, log);

    final payload = {
      'id': id,
      'user_id': currentUserId,
      'user_email': currentUserEmail,
      'action_type': actionType,
      'category': category,
      'title': title,
      'description': description,
      'created_at': now.toUtc().toIso8601String(),
    };

    // 2. Persist to SharedPreferences local cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'audit_logs_cache_$currentUserId';
      final List<String> cachedList = prefs.getStringList(cacheKey) ?? [];
      cachedList.insert(0, jsonEncode(payload));
      if (cachedList.length > 200) cachedList.removeRange(200, cachedList.length);
      await prefs.setStringList(cacheKey, cachedList);

      final List<String> globalCachedList = prefs.getStringList('audit_logs_cache_global') ?? [];
      globalCachedList.insert(0, jsonEncode(payload));
      if (globalCachedList.length > 300) globalCachedList.removeRange(300, globalCachedList.length);
      await prefs.setStringList('audit_logs_cache_global', globalCachedList);
    } catch (e) {
      if (kDebugMode) print('SharedPreferences audit log save error: $e');
    }

    // 3. Persist to Supabase Postgres database inside `users.settings` JSON
    try {
      final supabase = SupabaseService.client;
      
      // Fetch current settings for user
      final userResp = await supabase
          .from('users')
          .select('settings')
          .eq('id', currentUserId)
          .maybeSingle();

      Map<String, dynamic> settings = {};
      if (userResp != null && userResp['settings'] != null) {
        if (userResp['settings'] is Map) {
          settings = Map<String, dynamic>.from(userResp['settings']);
        }
      }

      List<dynamic> existingAuditLogs = settings['audit_logs'] is List ? List.from(settings['audit_logs']) : [];
      
      // Check if already inserted
      if (!existingAuditLogs.any((item) => item is Map && item['id'] == id)) {
        existingAuditLogs.insert(0, payload);
        if (existingAuditLogs.length > 200) {
          existingAuditLogs = existingAuditLogs.sublist(0, 200);
        }
        settings['audit_logs'] = existingAuditLogs;

        await supabase
            .from('users')
            .update({'settings': settings})
            .eq('id', currentUserId);
      }
    } catch (e) {
      if (kDebugMode) print('Supabase users.settings audit log save error: $e');
    }

    // 4. Try legacy tables `audit_logs` & `user_audit_logs` if exist
    try {
      final supabase = SupabaseService.client;
      try {
        await supabase.from('audit_logs').insert(payload);
      } catch (_) {
        try {
          await supabase.from('user_audit_logs').insert(payload);
        } catch (_) {}
      }
    } catch (_) {}

    return log;
  }

  /// Retrieve all audit logs across categories from Supabase & SharedPreferences
  static Future<List<AuditLogModel>> fetchAllLogs() async {
    final List<AuditLogModel> resultLogs = [];

    // 1. Fetch from Supabase `users.settings` across all user records
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> usersResp = await supabase
          .from('users')
          .select('settings');

      for (var row in usersResp) {
        if (row is Map<String, dynamic> && row['settings'] != null && row['settings']['audit_logs'] is List) {
          final List<dynamic> userLogs = row['settings']['audit_logs'];
          for (var item in userLogs) {
            if (item is Map<String, dynamic>) {
              final model = AuditLogModel.fromJson(item);
              if (!resultLogs.any((x) => x.id == model.id)) {
                resultLogs.add(model);
              }
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Supabase fetchAllLogs settings error: $e');
    }

    // 2. Fetch from legacy `user_audit_logs` or `audit_logs` tables if present
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> response = await supabase
          .from('user_audit_logs')
          .select()
          .order('created_at', ascending: false);

      for (var row in response) {
        if (row is Map<String, dynamic>) {
          final model = AuditLogModel.fromJson(row);
          if (!resultLogs.any((x) => x.id == model.id)) {
            resultLogs.add(model);
          }
        }
      }
    } catch (_) {}

    // 3. Fetch from SharedPreferences global cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cachedList = prefs.getStringList('audit_logs_cache_global') ?? [];
      for (var str in cachedList) {
        final Map<String, dynamic> map = jsonDecode(str);
        final model = AuditLogModel.fromJson(map);
        if (!resultLogs.any((x) => x.id == model.id)) {
          resultLogs.add(model);
        }
      }
    } catch (_) {}

    // 4. Merge local memory seed logs
    for (var l in _localLogs) {
      if (!resultLogs.any((x) => x.id == l.id)) {
        resultLogs.add(l);
      }
    }

    // Sort by timestamp descending
    resultLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return resultLogs;
  }

  /// Retrieve paginated audit logs for infinite scrolling
  static Future<List<AuditLogModel>> fetchPaginatedLogs({
    required int page,
    required int pageSize,
    String? category,
  }) async {
    final List<AuditLogModel> allLogs = await fetchAllLogs();

    final filtered = (category == null || category == 'All')
        ? allLogs
        : allLogs.where((l) => l.category.toLowerCase() == category.toLowerCase()).toList();

    final int start = page * pageSize;
    if (start >= filtered.length) return [];
    final int end = (start + pageSize) > filtered.length ? filtered.length : (start + pageSize);
    return filtered.sublist(start, end);
  }

  /// Retrieve audit logs for a specific user ID
  static Future<List<AuditLogModel>> fetchUserLogs({String? userId}) async {
    final String currentUserId = userId ?? CustomerStoreService.currentCustomer?.id ?? SupabaseService.client.auth.currentUser?.id ?? 'own_001';
    final String? currentUserEmail = CustomerStoreService.currentCustomer?.email ?? SupabaseService.client.auth.currentUser?.email;

    final List<AuditLogModel> resultLogs = [];

    // 1. Fetch from Supabase `users.settings` for this currentUserId
    try {
      final supabase = SupabaseService.client;
      final userResp = await supabase
          .from('users')
          .select('settings')
          .eq('id', currentUserId)
          .maybeSingle();

      if (userResp != null && userResp['settings'] != null && userResp['settings']['audit_logs'] is List) {
        final List<dynamic> userLogs = userResp['settings']['audit_logs'];
        for (var item in userLogs) {
          if (item is Map<String, dynamic>) {
            final model = AuditLogModel.fromJson(item);
            if (!resultLogs.any((x) => x.id == model.id)) {
              resultLogs.add(model);
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Supabase fetchUserLogs settings error: $e');
    }

    // 2. Fetch from SharedPreferences local user cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> cachedList = prefs.getStringList('audit_logs_cache_$currentUserId') ?? [];
      for (var str in cachedList) {
        final Map<String, dynamic> map = jsonDecode(str);
        final model = AuditLogModel.fromJson(map);
        if (!resultLogs.any((x) => x.id == model.id)) {
          resultLogs.add(model);
        }
      }
    } catch (_) {}

    // 3. Attempt fetching from legacy Supabase table `user_audit_logs`
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> response = await supabase
          .from('user_audit_logs')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      for (var row in response) {
        if (row is Map<String, dynamic>) {
          final model = AuditLogModel.fromJson(row);
          if (!resultLogs.any((x) => x.id == model.id)) {
            resultLogs.add(model);
          }
        }
      }
    } catch (_) {}

    // 4. Merge with local memory logs for this user ID or email
    for (var l in _localLogs) {
      if (l.userId == currentUserId || (currentUserEmail != null && l.userEmail == currentUserEmail) || l.userId == 'own_001') {
        if (!resultLogs.any((x) => x.id == l.id)) {
          resultLogs.add(l);
        }
      }
    }

    // Sort by timestamp descending
    resultLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return resultLogs;
  }
}
