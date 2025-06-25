import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

/// 알림 관련 공통 상수와 유틸리티 함수들
class NotificationUtils {
  // 백그라운드용 로컬 알림 인스턴스
  static final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
      FlutterLocalNotificationsPlugin();

  // 알림 채널 상수
  static const String channelId = 'gachon_noti_channel';
  static const String channelName = 'Gachon Notifications';
  static const String channelDescription = '가천대학교 공지사항 알림';

  // Android 알림 채널 생성
  static AndroidNotificationChannel get androidChannel {
    return const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
    );
  }

  // Android 알림 세부 설정
  static AndroidNotificationDetails get androidNotificationDetails {
    return const AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      autoCancel: true,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.message,
      // 알림 그룹핑 방지 - 각각 개별 알림으로 표시
      groupKey: null,
      setAsGroupSummary: false,
      onlyAlertOnce: false,
    );
  }

  // iOS 알림 세부 설정
  static const DarwinNotificationDetails iosNotificationDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
    presentBanner: true,
    interruptionLevel: InterruptionLevel.active,
  );

  // 통합 알림 세부 설정
  static NotificationDetails get notificationDetails {
    return NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
    );
  }

  /// 고유한 알림 ID 생성 함수
  static int generateUniqueNotificationId(String messageId) {
    if (messageId.isNotEmpty) {
      // 메시지 ID의 해시코드를 사용하여 고유 ID 생성
      final id = messageId.hashCode.abs();
      debugPrint('알림 ID 생성: $id (기반: $messageId)');
      return id;
    } else {
      // 메시지 ID가 없으면 현재 시간의 마이크로초 사용
      final id = DateTime.now().microsecondsSinceEpoch.remainder(1000000);
      debugPrint('알림 ID 생성 (시간 기반): $id');
      return id;
    }
  }

  /// 알림 제목과 본문 생성
  static Map<String, String> createNotificationContent(
      Map<String, dynamic> data) {
    final String title = '[${data['boardName'] ?? '알림'}] 새 공지';
    final String body = data['title'] ?? '새로운 공지사항이 있습니다.';
    return {'title': title, 'body': body};
  }

  /// FCM 메시지에서 URL 추출
  static String extractUrlFromMessage(RemoteMessage message) {
    return message.data['postLink'] ?? '';
  }

  /// Firebase 백그라운드 메시지 핸들러 (main.dart에서 호출됨)
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    // Firebase 초기화 (백그라운드에서 필요시)
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    print("Handling a background message: ${message.messageId}");
    print("Message data: ${message.data}");

    // 백그라운드에서 로컬 알림 표시
    await showBackgroundNotification(message);
  }

  /// 백그라운드 알림 표시 함수
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    try {
      // 로컬 알림 초기화 (백그라운드에서)
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _backgroundLocalNotifications.initialize(initSettings);

      // Android 알림 채널 생성 (필수)
      if (!kIsWeb) {
        await _backgroundLocalNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      }

      final data = message.data;
      final content = createNotificationContent(data);
      final String payload = extractUrlFromMessage(message);

      // 고유한 알림 ID 생성 (메시지 ID 기반)
      final int notificationId =
          generateUniqueNotificationId(message.messageId ?? '');

      // 알림 표시 (고유 ID 사용)
      await _backgroundLocalNotifications.show(
        notificationId,
        content['title']!,
        content['body']!,
        notificationDetails,
        payload: payload,
      );

      print('백그라운드 알림 표시 완료: ${content['title']} (ID: $notificationId)');
    } catch (e) {
      print('백그라운드 알림 표시 오류: $e');
    }
  }
}
