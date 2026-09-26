import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../utils/notification_utils.dart';
import 'supabase_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static Function(RemoteMessage)? _notificationClickCallback;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void> _tokenWork = Future.value();
  String? _userId;
  String? _lastToken;
  int _generation = 0;

  Future<void> _cancelListeners() async {
    await _tokenSubscription?.cancel();
    await _messageSubscription?.cancel();
    await _openedSubscription?.cancel();
    _tokenSubscription = null;
    _messageSubscription = null;
    _openedSubscription = null;
  }

  Future<String?> initFCM({
    required String? userId,
    required Function(String token) onTokenRefresh,
    required Function(RemoteMessage message) showInAppNotification,
    required Function(RemoteMessage message) handleNotificationClick,
  }) async {
    final generation = ++_generation;
    _userId = userId;
    await _cancelListeners();
    try {
      if (userId == null || userId.isEmpty) return null;
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (response) {
          final link = response.payload;
          if (link != null && link.isNotEmpty) {
            _notificationClickCallback
                ?.call(RemoteMessage(data: {'postLink': link}));
          }
        },
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(NotificationUtils.androidChannel);
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      if (generation != _generation) return null;
      _notificationClickCallback = handleNotificationClick;
      // Subscribe even if the first getToken call returns null or fails.
      _tokenSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        if (generation != _generation) return;
        onTokenRefresh(token);
        _queueToken(userId, token, generation);
      });
      _messageSubscription = FirebaseMessaging.onMessage.listen((message) {
        if (generation == _generation) _showLocalNotification(message);
      });
      _openedSubscription =
          FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (generation == _generation) {
          _notificationClickCallback?.call(message);
        }
      });
      // Local notifications render foreground messages; avoid duplicate OS banners.
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      final token = await FirebaseMessaging.instance.getToken();
      if (generation != _generation) return null;
      if (token != null) await _queueToken(userId, token, generation);
      return token;
    } catch (error) {
      debugPrint('FCM initialization failed: $error');
      return null;
    }
  }

  Future<void> _queueToken(String userId, String token, int generation) {
    _tokenWork = _tokenWork.then((_) async {
      if (generation != _generation || _userId != userId) return;
      await saveFcmTokenToServer(userId, token);
    }).catchError((Object error) {
      debugPrint('Device registration failed: $error');
    });
    return _tokenWork;
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final content = NotificationUtils.createNotificationContent(message.data);
      await _localNotifications.show(
        id: NotificationUtils.generateUniqueNotificationId(
          message.data['postId'] ?? message.messageId ?? '',
        ),
        title: content['title'],
        body: content['body'],
        notificationDetails: NotificationUtils.notificationDetails,
        payload: NotificationUtils.extractUrlFromMessage(message),
      );
    } catch (error) {
      debugPrint('Notification display failed: $error');
    }
  }

  Future<void> saveFcmTokenToServer(String userId, String token) async {
    final db = Get.find<SupabaseService>().client;
    if (token.isEmpty || db.auth.currentUser?.id != userId) return;
    await db.from('user_devices').upsert({
      'user_id': userId,
      'fcm_token': token,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'fcm_token');
    final previous = _lastToken;
    _lastToken = token;
    if (previous != null && previous != token) {
      await db
          .from('user_devices')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', previous);
    }
  }

  // Must run while the Supabase session still permits deleting this user's row.
  Future<void> removeFcmToken(String userId) async {
    ++_generation;
    _userId = null;
    _notificationClickCallback = null;
    await _cancelListeners();
    await _tokenWork;
    final db = Get.find<SupabaseService>().client;
    final token = await FirebaseMessaging.instance.getToken();
    final tokens = <String>{
      if (token != null) token,
      if (_lastToken != null) _lastToken!
    };
    await FirebaseMessaging.instance.deleteToken();
    for (final value in tokens) {
      await db
          .from('user_devices')
          .delete()
          .eq('user_id', userId)
          .eq('fcm_token', value);
    }
    _lastToken = null;
    // Server snapshot retains removed tokens until topic unsubscription completes.
  }

  Future<bool> checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus != AuthorizationStatus.denied;
  }
}
