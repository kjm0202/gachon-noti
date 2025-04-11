import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:appwrite/appwrite.dart';
import '../utils/const.dart';
import 'package:web/web.dart' as web;

// 콜백 핸들러 타입 정의
typedef NotificationCallback = void Function(RemoteMessage message);

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() => _instance;

  FirebaseService._internal();

  // 콜백 핸들러
  NotificationCallback? _onMessageClickHandler;

  Future<String?> initFCM({
    required Databases databases,
    String? userId,
    required Function(String token) onTokenRefresh,
    required Function(RemoteMessage message) showInAppNotification,
    required Function(RemoteMessage message) handleNotificationClick,
  }) async {
    try {
      // FCM 권한 요청
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: true,
          );
      print('FCM permission status: ${settings.authorizationStatus}');

      // 웹 환경에서는 VAPID 키가 필요
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: API.vapidKey,
      );

      _onMessageClickHandler = handleNotificationClick;

      if (token != null) {
        // 현재 세션이 있다면 토큰 저장
        if (userId != null) {
          await saveFcmTokenToServer(databases, userId, token);
        }

        // 토큰 갱신 리스너
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          print('FCM Token refreshed: $newToken');
          onTokenRefresh(newToken);
          if (userId != null) {
            await saveFcmTokenToServer(databases, userId, newToken);
          }
        });

        FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // 앱이 열려 있을 때 수신된 메시지 처리
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');

          if (message.notification != null) {
            print(
              'Message also contained a notification: ${message.notification}',
            );
            showInAppNotification(message);
          }
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
    Databases databases,
    String userId,
    String fcmToken,
  ) async {
    if (fcmToken.isEmpty) return;

    print('Saving token "$fcmToken" for userId="$userId" to user_devices...');
    try {
      final existing = await databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsUserDevicesId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('fcmToken', fcmToken),
        ],
      );

      if (existing.total == 0) {
        await databases.createDocument(
          databaseId: API.databaseId,
          collectionId: API.collectionsUserDevicesId,
          documentId: 'unique()',
          data: {
            'userId': userId,
            'fcmToken': fcmToken,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        print('FCM token doc created.');
      } else {
        print('Token already exists in user_devices.');
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  void handleNotificationClick(RemoteMessage message) {
    final data = message.data;

    // 메시지 데이터에 'boardId'와 'link' 필드가 있는지 확인
    final String? boardId = data['boardId'];
    final String? link = data['link'];

    if (link != null && link.isNotEmpty) {
      // 링크가 있으면 외부 브라우저로 열기
      web.window.open(link, '_blank');
    } else if (_onMessageClickHandler != null) {
      _onMessageClickHandler!(message);
    }
  }
}
