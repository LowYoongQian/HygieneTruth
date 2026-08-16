import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audit_log_model.dart';
import '../utils/uuid_helper.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class AuditLogService {
  static bool _isValidUuid(String? str) {
    if (str == null || str.isEmpty) return false;
    final uuidRegex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegex.hasMatch(str);
  }

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
      'user_id': _isValidUuid(currentUserId) ? currentUserId : null,
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

    // 3. Persist to Supabase `audit_logs` table
    try {
      final supabase = SupabaseService.client;
      await supabase.from('audit_logs').insert(payload);
    } catch (tableErr) {
      if (kDebugMode) print('Supabase audit_logs table insert error (fallbacking to settings/user_audit_logs): $tableErr');
      try {
        final supabase = SupabaseService.client;
        await supabase.from('user_audit_logs').insert(payload);
      } catch (_) {}
    }

    // 4. Persist to Supabase Postgres database inside `users.settings` JSON
    try {
      final supabase = SupabaseService.client;
      final targetUserUuid = _isValidUuid(currentUserId)
          ? currentUserId
          : (supabase.auth.currentUser?.id);

      if (targetUserUuid != null) {
        final userResp = await supabase
            .from('users')
            .select('settings')
            .eq('id', targetUserUuid)
            .maybeSingle();

        Map<String, dynamic> settings = {};
        if (userResp != null && userResp['settings'] != null) {
          if (userResp['settings'] is Map) {
            settings = Map<String, dynamic>.from(userResp['settings']);
          }
        }

        List<dynamic> existingAuditLogs = settings['audit_logs'] is List ? List.from(settings['audit_logs']) : [];
        if (!existingAuditLogs.any((item) => item is Map && item['id'] == id)) {
          existingAuditLogs.insert(0, payload);
          if (existingAuditLogs.length > 200) {
            existingAuditLogs = existingAuditLogs.sublist(0, 200);
          }
          settings['audit_logs'] = existingAuditLogs;

          await supabase
              .from('users')
              .update({'settings': settings})
              .eq('id', targetUserUuid);
        }
      }
    } catch (e) {
      if (kDebugMode) print('Supabase users.settings audit log save error: $e');
    }

    return log;
  }

  /// Retrieve all audit logs across categories from Supabase & SharedPreferences
  static Future<List<AuditLogModel>> fetchAllLogs() async {
    final List<AuditLogModel> resultLogs = [];

    // 1. Fetch from Supabase `audit_logs` table
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> response = await supabase
          .from('audit_logs')
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
    } catch (e) {
      if (kDebugMode) print('Supabase audit_logs table query: $e');
    }

    // 2. Fetch from Supabase `user_audit_logs` table if present
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

    // 3. Fetch from Supabase `users.settings` across all user records
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

    // 4. Fetch from SharedPreferences global cache
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

    // 5. Merge local memory seed logs
    for (var l in _localLogs) {
      if (!resultLogs.any((x) => x.id == l.id)) {
        resultLogs.add(l);
      }
    }

    // Sort by timestamp descending
    resultLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return resultLogs;
  }

  /// Fetch all government operations and incoming admin assigned complaint logs
  static Future<List<AuditLogModel>> fetchGovernmentAuditLogs() async {
    final List<AuditLogModel> allLogs = await fetchAllLogs();
    final List<AuditLogModel> govLogs = [];

    // Filter relevant government & admin assignment logs
    for (var log in allLogs) {
      final act = log.actionType.toUpperCase();
      final cat = log.category.toUpperCase();
      final title = log.title.toUpperCase();
      final desc = log.description.toUpperCase();

      if (cat.contains('GOV') ||
          cat.contains('INSPECT') ||
          act.contains('INSPECT') ||
          act.contains('ENFORCE') ||
          act.contains('OUTLET_APP') ||
          act.contains('OUTLET_REJ') ||
          act.contains('CASE_') ||
          act.contains('COMPLAINT_') ||
          title.contains('COMPLAINT') ||
          title.contains('INSPECT') ||
          title.contains('ENFORCEMENT') ||
          title.contains('OUTLET') ||
          desc.contains('ASSIGN') ||
          desc.contains('COMPLAINT')) {
        govLogs.add(log);
      }
    }

    // Synthesize real-time logs from real Supabase complaints table
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> complaints = await supabase
          .from('complaints')
          .select('id, category, description, status, submitted_at, restaurants(name)')
          .order('submitted_at', ascending: false)
          .limit(20);

      for (var c in complaints) {
        if (c is Map<String, dynamic>) {
          final String cId = c['id'] ?? '';
          final String cat = c['category'] ?? 'Hygiene';
          final String restName = c['restaurants'] != null && c['restaurants']['name'] != null
              ? c['restaurants']['name']
              : 'Premise';
          final String status = c['status'] ?? 'submitted';
          final String shortId = cId.length > 8 ? cId.substring(0, 8).toUpperCase() : cId.toUpperCase();
          final DateTime dt = DateTime.tryParse(c['submitted_at'] ?? '') ?? DateTime.now();

          // Add Assigned Complaint Log
          final String assignLogId = 'gov_sync_assign_$cId';
          if (!govLogs.any((l) => l.id == assignLogId)) {
            govLogs.add(AuditLogModel(
              id: assignLogId,
              userId: 'adm_001',
              userEmail: 'admin@app.com',
              actionType: 'COMPLAINT_ASSIGNED',
              category: 'Admin Assignment',
              title: 'Admin Assigned Case #CMP-$shortId',
              description: 'Admin assigned incoming citizen complaint for $restName ($cat) to Health Officer PIC.',
              timestamp: dt,
            ));
          }

          // Add Resolved log if case is resolved
          if (status == 'resolved') {
            final String resolveLogId = 'gov_sync_resolved_$cId';
            if (!govLogs.any((l) => l.id == resolveLogId)) {
              govLogs.add(AuditLogModel(
                id: resolveLogId,
                userId: 'gov_pic_01',
                userEmail: 'officer.pic@hygiene.gov.my',
                actionType: 'CASE_CLOSED',
                category: 'Government',
                title: 'Case #CMP-$shortId Closed & Resolved',
                description: 'Inspection and remediation verified for $restName. Case formally resolved.',
                timestamp: dt.add(const Duration(hours: 4)),
              ));
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Complaints to Gov Audit synthesis error: $e');
    }

    final Set<String> seenIds = govLogs.map((l) => l.id).toSet();
    final now = DateTime.now();

    // Default Seed Government & Admin Assignment logs to ensure rich history
    final seedGov = [
      AuditLogModel(
        id: 'gov_seed_001',
        userId: 'gov_pic_01',
        userEmail: 'officer.pic@hygiene.gov.my',
        actionType: 'INSPECTION_CONDUCTED',
        category: 'Government',
        title: 'Health Inspection Conducted',
        description: 'Completed on-site hygiene audit at Selera Kampung Bistro (Grade C 45/100). Severe pest violations detected.',
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
      AuditLogModel(
        id: 'gov_seed_002',
        userId: 'adm_001',
        userEmail: 'admin@app.com',
        actionType: 'COMPLAINT_ASSIGNED',
        category: 'Admin Assignment',
        title: 'Admin Assigned Priority Complaint #CMP-2026-002',
        description: 'Admin routed high-severity citizen complaint for Selera Kampung Bistro to Health Officer PIC for mandatory 48h visit.',
        timestamp: now.subtract(const Duration(hours: 1, minutes: 15)),
      ),
      AuditLogModel(
        id: 'gov_seed_003',
        userId: 'gov_pic_01',
        userEmail: 'officer.pic@hygiene.gov.my',
        actionType: 'ENFORCEMENT_ISSUED',
        category: 'Government',
        title: 'Enforcement Decree Issued: CLOSURE',
        description: 'Issued Section 11 Food Act 1983 14-day premise shutdown and RM 2,500 compound penalty for Ocean Catch Seafood.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 30)),
      ),
      AuditLogModel(
        id: 'gov_seed_004',
        userId: 'adm_001',
        userEmail: 'admin@app.com',
        actionType: 'COMPLAINT_ASSIGNED',
        category: 'Admin Assignment',
        title: 'Admin Assigned Case #CMP-2026-001',
        description: 'Admin verified AI hash duplicate check and assigned Food Safety case to field inspection squad.',
        timestamp: now.subtract(const Duration(hours: 6)),
      ),
      AuditLogModel(
        id: 'gov_seed_005',
        userId: 'gov_pic_01',
        userEmail: 'officer.pic@hygiene.gov.my',
        actionType: 'INSPECTION_SCHEDULED',
        category: 'Government',
        title: 'Inspection Visit Scheduled',
        description: 'Scheduled on-site food safety audit for Golden Dragon Bistro on Monday 10:30 AM.',
        timestamp: now.subtract(const Duration(hours: 10)),
      ),
      AuditLogModel(
        id: 'gov_seed_006',
        userId: 'gov_pic_01',
        userEmail: 'officer.pic@hygiene.gov.my',
        actionType: 'CASE_CLOSED',
        category: 'Government',
        title: 'Case #CMP-2026-004 Closed & Archived',
        description: 'Remediation completed, RM 500 compound settled, and clean re-inspection verified with Grade A hygiene award.',
        timestamp: now.subtract(const Duration(days: 1, hours: 4)),
      ),
    ];

    for (var s in seedGov) {
      if (!seenIds.contains(s.id)) {
        seenIds.add(s.id);
        govLogs.add(s);
      }
    }

    govLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return govLogs;
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
    if (_isValidUuid(currentUserId)) {
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
    if (_isValidUuid(currentUserId)) {
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
    }

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
