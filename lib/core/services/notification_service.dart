import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../notifications/models/notification_model.dart';
import 'supabase_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    print('Handling background FCM message: ${message.messageId}');
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static final List<AppNotificationModel> _notifications = [];
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<List<AppNotificationModel>> notificationsNotifier =
      ValueNotifier<List<AppNotificationModel>>([]);

  static RealtimeChannel? _realtimeChannel;
  static String? _currentSubscribedUserId;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  /// Initialize Firebase & Local Notification channels & permissions
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Initialize Firebase Core
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      if (kDebugMode) {
        print('Firebase init notice: $e');
      }
    }

    // 2. Initialize Local Notifications Plugin
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      );

      await _localNotifPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          if (kDebugMode) {
            print('Notification tapped: ${details.payload}');
          }
        },
      );

      if (Platform.isAndroid) {
        final androidImplementation = _localNotifPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImplementation?.requestNotificationsPermission();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Local notifications init error: $e');
      }
    }

    // 3. Configure FCM Listeners & Request Permission
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _fcmToken = await messaging.getToken();
      if (kDebugMode) {
        print('Device FCM Token: $_fcmToken');
      }

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        final title = notification?.title ?? message.data['title'] ?? 'Hygiene Alert';
        final body = notification?.body ?? message.data['message'] ?? '';
        final typeStr = message.data['type'] ?? 'system';

        final notif = AppNotificationModel(
          id: message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
          userId: _currentSubscribedUserId ?? '',
          title: title,
          message: body,
          type: _parseType(typeStr),
          actionUrl: message.data['action_url'],
          data: message.data,
          isRead: false,
          createdAt: DateTime.now(),
        );

        _handleIncomingNotification(notif);
      });

      // Token refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        if (_currentSubscribedUserId != null) {
          syncFcmTokenToSupabase(_currentSubscribedUserId!);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Messaging setup error: $e');
      }
    }

    _isInitialized = true;
  }

  /// Sync device FCM token to Supabase users and user_devices table
  static Future<void> syncFcmTokenToSupabase(String userId) async {
    if (_fcmToken == null || _fcmToken!.isEmpty || userId.isEmpty) return;
    try {
      final supabase = SupabaseService.client;
      // Update users table
      await supabase.from('users').update({
        'fcm_token': _fcmToken,
        'fcm_updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    } catch (_) {}

    try {
      final supabase = SupabaseService.client;
      // Upsert into user_devices table
      await supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': _fcmToken,
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web'),
        'last_active': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'fcm_token');
    } catch (_) {}
  }

  /// Start Supabase Realtime live WebSocket listener for this user
  static void startRealtimeListener(String userId) {
    if (_currentSubscribedUserId == userId && _realtimeChannel != null) return;
    _currentSubscribedUserId = userId;

    // Sync FCM Token immediately
    syncFcmTokenToSupabase(userId);

    try {
      final supabase = SupabaseService.client;
      if (_realtimeChannel != null) {
        supabase.removeChannel(_realtimeChannel!);
      }

      _realtimeChannel = supabase
          .channel('user-notifications-$userId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              final newRow = payload.newRecord;
              if (newRow.isNotEmpty) {
                final notif = AppNotificationModel.fromMap(newRow);
                _handleIncomingNotification(notif);
              }
            },
          )
          .subscribe();
    } catch (e) {
      if (kDebugMode) {
        print('Error starting Realtime notification listener: $e');
      }
    }
  }

  /// Show heads-up device banner notification
  static Future<void> showLocalNotification({
    required String title,
    required String message,
    String? payload,
    int? notificationId,
  }) async {
    try {
      await initialize();

      const androidDetails = AndroidNotificationDetails(
        'hygienetruth_live_alerts',
        'HygieneTruth Alerts & Updates',
        channelDescription: 'Live updates for food hygiene reports, outlet reviews, and audit actions',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        playSound: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final id = notificationId ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 100000;
      await _localNotifPlugin.show(
        id,
        title,
        message,
        notifDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing local notification: $e');
      }
    }
  }

  static void _handleIncomingNotification(AppNotificationModel notif) {
    final existingIdx = _notifications.indexWhere((n) => n.id == notif.id);
    if (existingIdx != -1) {
      _notifications[existingIdx] = notif;
    } else {
      _notifications.insert(0, notif);
      showLocalNotification(
        title: notif.title,
        message: notif.message,
        payload: notif.actionUrl ?? notif.id,
      );
    }
    _updateStateAndPersist();
  }

  /// Fetch all notifications for the given user from Supabase and local cache
  static Future<List<AppNotificationModel>> fetchNotifications({
    String? userId,
    String? userEmail,
    String? userRole,
  }) async {
    final List<AppNotificationModel> resultList = [];
    final Set<String> seenIds = {};
    final cleanUserId = userId?.trim();
    final cleanEmail = userEmail?.trim().toLowerCase();

    // 1. Try fetching from Supabase public.notifications table
    try {
      final supabase = SupabaseService.client;
      dynamic query = supabase.from('notifications').select().order('created_at', ascending: false);
      if (cleanUserId != null && cleanUserId.isNotEmpty) {
        query = query.eq('user_id', cleanUserId);
      }
      final rows = await query as List<dynamic>;
      for (final r in rows) {
        final map = Map<String, dynamic>.from(r as Map);
        final notif = AppNotificationModel.fromMap(map);
        if (!seenIds.contains(notif.id)) {
          seenIds.add(notif.id);
          resultList.add(notif);
        }
      }
    } catch (_) {}

    // 2. Try fetching notification records stored in Supabase audit_logs table (reliable backup)
    try {
      final supabase = SupabaseService.client;
      final logs = await supabase
          .from('audit_logs')
          .select()
          .eq('action_type', 'USER_NOTIFICATION')
          .order('created_at', ascending: false)
          .limit(30);
      for (final log in logs) {
        final lUserId = (log['user_id'] ?? '').toString();
        final lEmail = (log['user_email'] ?? '').toString().toLowerCase();
        final desc = (log['description'] ?? '').toString();
        final bool isTarget = (cleanUserId != null && lUserId == cleanUserId) ||
            (cleanEmail != null && lEmail == cleanEmail) ||
            (log['title'] ?? '').toString().toLowerCase().contains('broadcast');

        if (isTarget && desc.startsWith('{') && desc.endsWith('}')) {
          try {
            final parsedMap = Map<String, dynamic>.from(jsonDecode(desc) as Map);
            final notif = AppNotificationModel.fromMap(parsedMap);
            if (!seenIds.contains(notif.id)) {
              seenIds.add(notif.id);
              resultList.add(notif);
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 3. Merge with local SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'user_notifications_${cleanUserId ?? "guest"}';
      final localJson = prefs.getString(cacheKey);
      if (localJson != null && localJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localJson);
        for (final item in decoded) {
          final notif = AppNotificationModel.fromMap(Map<String, dynamic>.from(item as Map));
          if (!seenIds.contains(notif.id)) {
            seenIds.add(notif.id);
            resultList.add(notif);
          }
        }
      }
    } catch (_) {}

    // 4. Default Seed Notifications based on role if brand new / empty
    if (resultList.isEmpty) {
      final seedList = _getSeedNotifications(cleanUserId ?? 'usr_current', userRole ?? 'customer');
      for (final s in seedList) {
        if (!seenIds.contains(s.id)) {
          seenIds.add(s.id);
          resultList.add(s);
        }
      }
    }

    // Sort descending by date
    resultList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _notifications.clear();
    _notifications.addAll(resultList);
    _updateStateAndPersist(userId: cleanUserId);

    if (cleanUserId != null && cleanUserId.isNotEmpty) {
      startRealtimeListener(cleanUserId);
    }

    return _notifications;
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String notificationId, {String? userId}) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _updateStateAndPersist(userId: userId);
      try {
        final supabase = SupabaseService.client;
        await supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
      } catch (_) {}
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead({String? userId}) async {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _updateStateAndPersist(userId: userId);
    try {
      final supabase = SupabaseService.client;
      if (userId != null && userId.isNotEmpty) {
        await supabase.from('notifications').update({'is_read': true}).eq('user_id', userId);
      }
    } catch (_) {}
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId, {String? userId}) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateStateAndPersist(userId: userId);
    try {
      final supabase = SupabaseService.client;
      await supabase.from('notifications').delete().eq('id', notificationId);
    } catch (_) {}
  }

  /// Clear all notifications
  static Future<void> clearAll({String? userId}) async {
    _notifications.clear();
    _updateStateAndPersist(userId: userId);
    try {
      final supabase = SupabaseService.client;
      if (userId != null && userId.isNotEmpty) {
        await supabase.from('notifications').delete().eq('user_id', userId);
      }
    } catch (_) {}
  }

  /// Send a new notification to a specific user and broadcast via Supabase & Local Notifications
  static Future<bool> sendNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? actionUrl,
    Map<String, dynamic>? data,
    String? userEmail,
  }) async {
    final notif = AppNotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      message: message,
      type: type,
      actionUrl: actionUrl,
      data: data ?? {},
      isRead: false,
      createdAt: DateTime.now().toUtc(),
    );

    if (_currentSubscribedUserId == userId || _currentSubscribedUserId == null) {
      _notifications.insert(0, notif);
      _updateStateAndPersist(userId: userId);
      showLocalNotification(
        title: title,
        message: message,
        payload: actionUrl,
      );
    }

    try {
      final supabase = SupabaseService.client;
      await supabase.from('notifications').insert(notif.toMap());
    } catch (_) {}

    try {
      final supabase = SupabaseService.client;
      final validUserId = userId.length > 10 ? userId : 'e257a3d8-a2e2-4872-afcf-0d7324e8f0cf';
      await supabase.from('audit_logs').insert({
        'user_id': validUserId,
        'user_email': userEmail ?? 'user@hygienetruth.com',
        'action_type': 'USER_NOTIFICATION',
        'category': 'System Notification',
        'title': title,
        'description': jsonEncode(notif.toMap()),
      });
    } catch (_) {}

    return true;
  }

  static void _updateStateAndPersist({String? userId}) async {
    final unread = _notifications.where((n) => !n.isRead).length;
    unreadCountNotifier.value = unread;
    notificationsNotifier.value = List.from(_notifications);

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'user_notifications_${userId ?? _currentSubscribedUserId ?? "guest"}';
      final encoded = jsonEncode(_notifications.map((n) => n.toMap()).toList());
      await prefs.setString(cacheKey, encoded);
    } catch (_) {}
  }

  static NotificationType _parseType(String typeStr) {
    final s = typeStr.toLowerCase();
    if (s.contains('complaint')) return NotificationType.complaint;
    if (s.contains('outlet') || s.contains('restaurant')) return NotificationType.outlet;
    if (s.contains('review')) return NotificationType.review;
    if (s.contains('alert') || s.contains('hygiene') || s.contains('outbreak')) return NotificationType.hygieneAlert;
    return NotificationType.system;
  }

  static List<AppNotificationModel> _getSeedNotifications(String userId, String role) {
    final now = DateTime.now();
    return [
      AppNotificationModel(
        id: 'seed_notif_001',
        userId: userId,
        title: '🎉 Welcome to HygieneTruth Portal',
        message: 'Your account is verified and protected. Discover clean dining and track hygiene ratings in real time.',
        type: NotificationType.system,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotificationModel(
        id: 'seed_notif_002',
        userId: userId,
        title: '🛡️ Safety Patrol Alert',
        message: 'New hygiene inspection grade A awarded to restaurants in Kuala Lumpur Central.',
        type: NotificationType.hygieneAlert,
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotificationModel(
        id: 'seed_notif_003',
        userId: userId,
        title: '📋 Review Response Received',
        message: 'Owner of "testing" replied to your recent feedback: "hello"',
        type: NotificationType.review,
        actionUrl: 'outlet_testing',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
