import 'package:flutter/foundation.dart';
import '../models/audit_log_model.dart';
import '../utils/uuid_helper.dart';
import 'customer_store_service.dart';
import 'supabase_service.dart';

class AuditLogService {
  static final List<AuditLogModel> _localLogs = [
    AuditLogModel(
      id: 'log_seed_001',
      userId: 'own_001',
      userEmail: 'low@gmail.com',
      actionType: 'LOGIN',
      category: 'Session Activity',
      title: 'User Login Session',
      description: 'Logged in successfully into account session',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    AuditLogModel(
      id: 'log_seed_002',
      userId: 'own_001',
      userEmail: 'low@gmail.com',
      actionType: 'NAME_CHANGE',
      category: 'Account Modification',
      title: 'User Name Changed',
      description: 'Updated profile full name details',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
  ];

  /// Record a new audit log action for the active logged-in user
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

    _localLogs.insert(0, log);

    // Sync to Supabase Postgres table `user_audit_logs`
    try {
      final supabase = SupabaseService.client;
      await supabase.from('user_audit_logs').insert({
        'id': id,
        'user_id': currentUserId,
        'user_email': currentUserEmail,
        'action_type': actionType,
        'category': category,
        'title': title,
        'description': description,
        'created_at': now.toUtc().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Supabase user_audit_logs insert error: $e');
      }
    }

    return log;
  }

  /// Retrieve audit logs for a specific user ID
  static Future<List<AuditLogModel>> fetchUserLogs({String? userId}) async {
    final String currentUserId = userId ?? CustomerStoreService.currentCustomer?.id ?? SupabaseService.client.auth.currentUser?.id ?? 'own_001';
    final String? currentUserEmail = CustomerStoreService.currentCustomer?.email ?? SupabaseService.client.auth.currentUser?.email;

    final List<AuditLogModel> resultLogs = [];

    // 1. Attempt fetching from Supabase table `user_audit_logs`
    try {
      final supabase = SupabaseService.client;
      final List<dynamic> response = await supabase
          .from('user_audit_logs')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      for (var row in response) {
        if (row is Map<String, dynamic>) {
          resultLogs.add(AuditLogModel.fromJson(row));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase user_audit_logs fetch error: $e');
      }
    }

    // 2. Merge with local memory logs for this user ID or email
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
