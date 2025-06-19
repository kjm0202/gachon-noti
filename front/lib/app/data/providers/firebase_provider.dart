import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../utils/const.dart';
import './supabase_provider.dart';

// 콜백 핸들러 타입 정의
typedef NotificationCallback = void Function(RemoteMessage message);

class FirebaseProvider {
  static final FirebaseProvider _instance = FirebaseProvider._internal();

  factory FirebaseProvider() => _instance;

  FirebaseProvider._internal();

  Future<String?> initFCM({
    required String? userId,
    required Function(String token) onTokenRefresh,
    required Function(RemoteMessage message) showInAppNotification,
    required Function(RemoteMessage message) handleNotificationClick,
  }) async {
    try {
      // FCM 권한 요청
      NotificationSettings settings =
          await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );
      print('FCM permission status: ${settings.authorizationStatus}');

      // 플랫폼별 토큰 가져오기
      String? token;
      if (kIsWeb) {
        // 웹 환경에서는 VAPID 키가 필요
        token = await FirebaseMessaging.instance.getToken(
          vapidKey: API.vapidKey,
        );
      } else {
        // 네이티브 환경에서는 기본 토큰 가져오기
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        // 현재 세션이 있다면 토큰 저장
        if (userId != null) {
          await saveFcmTokenToServer(userId, token);
        }

        // 토큰 갱신 리스너
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          print('FCM Token refreshed: $newToken');
          onTokenRefresh(newToken);
          if (userId != null) {
            await saveFcmTokenToServer(userId, newToken);
          }
        });

        // 플랫폼별 알림 설정
        if (kIsWeb) {
          // 웹에서는 서비스 워커가 백그라운드 메시지를 처리
          FirebaseMessaging.instance
              .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );
        } else {
          // 네이티브에서는 백그라운드 메시지 핸들러 설정
          FirebaseMessaging.onBackgroundMessage(
              _firebaseMessagingBackgroundHandler);
        }

        // 앱이 열려 있을 때 수신된 메시지 처리 (모든 플랫폼 공통)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');

          if (message.notification != null) {
            print(
              'Message also contained a notification: ${message.notification}',
            );
          }
          showInAppNotification(message);
        });

        // 앱이 백그라운드에 있는 상태에서 알림 클릭으로 열렸을 때
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print('A new onMessageOpenedApp event was published!');
          print('Message data: ${message.data}');
          handleNotificationClick(message);
        });

        // 앱이 종료된 상태에서 알림 클릭으로 열렸을 때의 초기 메시지 확인
        FirebaseMessaging.instance.getInitialMessage().then((
          RemoteMessage? message,
        ) {
          if (message != null) {
            print('App opened from terminated state via notification!');
            print('Initial message: ${message.data}');
            handleNotificationClick(message);
          }
        });
      }

      return token;
    } catch (e) {
      print('FCM initialization error: $e');
      return null;
    }
  }

  Future<void> saveFcmTokenToServer(
    String userId,
    String fcmToken,
  ) async {
    if (fcmToken.isEmpty) return;

    print('Saving token "$fcmToken" for userId="$userId" to user_devices...');
    try {
      final supabase = Get.find<SupabaseProvider>().client;

      // user_devices 테이블에서 같은 userId와 fcmToken을 가진 레코드 확인
      final existing = await supabase
          .from('user_devices')
          .select('id')
          .eq('user_id', userId)
          .eq('fcm_token', fcmToken)
          .maybeSingle();

      if (existing == null) {
        // 없으면 새로 추가
        await supabase.from('user_devices').insert({
          'user_id': userId,
          'fcm_token': fcmToken,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('FCM token saved to user_devices.');
      } else {
        print('Token already exists in user_devices.');
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  // 로그아웃 시 FCM 토큰 삭제 메서드
  Future<void> removeFcmToken(String userId) async {
    try {
      print('Removing FCM tokens for userId "$userId"...');

      // 현재 FCM 토큰 가져오기
      final token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        final supabase = Get.find<SupabaseProvider>().client;

        // 현재 디바이스의 토큰만 삭제
        await supabase
            .from('user_devices')
            .delete()
            .eq('user_id', userId)
            .eq('fcm_token', token);

        print('FCM token removed from user_devices.');

        // 토큰 삭제
        await FirebaseMessaging.instance.deleteToken();
        print('FCM token deleted from device.');
      }
    } catch (e) {
      print('Error removing FCM token: $e');
    }
  }

  Future<bool> checkNotificationPermission() async {
    final permission =
        await FirebaseMessaging.instance.getNotificationSettings();
    if (permission.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }
    return true;
  }
}

// 네이티브 앱에서 백그라운드 메시지 처리를 위한 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");

  // 네이티브에서는 여기서 백그라운드 알림을 처리
  // 필요시 로컬 알림이나 기타 백그라운드 작업 수행
}
