import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'app/utils/const.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/services/qonversion_service.dart';
import 'app/utils/notification_utils.dart';
import 'theme.dart';

/// 앱이 알림으로 열렸을 때 이동할 URL을 전역으로 저장
String? _pendingNotificationUrl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(
      NotificationUtils.firebaseMessagingBackgroundHandler);

  // Crashlytics 설정
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Supabase 초기화
  await Supabase.initialize(
    url: API.supabaseUrl,
    anonKey: API.supabaseAnonKey,
  );

  // 앱이 종료된 상태에서 알림 탭으로 열렸는지 확인
  await _checkInitialNotification();

  runApp(const MyApp());
}

/// 앱 시작 시 알림으로 열렸는지 확인 후 URL 저장 (앱 내 웹뷰로 처리)
Future<void> _checkInitialNotification() async {
  try {
    // 1. FCM 초기 메시지 확인 (앱 종료 상태에서 알림 탭)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      final url = initialMessage.data['postLink'];
      if (url != null && url.isNotEmpty) {
        print('🎯 FCM 초기 알림 URL 저장: $url');
        _pendingNotificationUrl = url;
        return;
      }
    }

    // 2. 로컬 알림으로 앱 시작 확인 (백그라운드 알림 탭)
    final localNotifications = FlutterLocalNotificationsPlugin();
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await localNotifications.initialize(initSettings);

    final launchDetails = await localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        print('🎯 로컬 알림 URL 저장: $payload');
        _pendingNotificationUrl = payload;
      }
    }
  } catch (e) {
    print('❌ 초기 알림 확인 오류: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return FutureBuilder<String>(
      future: _initializeServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return GetMaterialApp(
            title: '가천 알림이',
            debugShowCheckedModeBanner: false,
            theme: materialTheme.light(),
            darkTheme: materialTheme.dark(),
            themeMode: ThemeMode.system,
            initialBinding: InitialBinding(),
            initialRoute: snapshot.data!,
            getPages: AppPages.routes,
            defaultTransition: Transition.fade,
          );
        } else {
          return MaterialApp(
            title: '가천 알림이',
            theme: materialTheme.light(),
            darkTheme: materialTheme.dark(),
            themeMode: ThemeMode.system,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
      },
    );
  }

  Future<String> _initializeServices() async {
    final supabaseProvider = SupabaseService();
    await supabaseProvider.init();
    Get.put(supabaseProvider);

    final authProvider = AuthService();
    await authProvider.init();
    Get.put(authProvider);

    // Qonversion 서비스 초기화
    final qonversionService = QonversionService();
    Get.put(qonversionService, permanent: true);

    // 로그인 상태 확인
    final isLoggedIn = await authProvider.checkCurrentSession();

    // 알림으로 앱이 시작된 경우 WebView로 바로 이동
    if (_pendingNotificationUrl != null) {
      final url = _pendingNotificationUrl!;
      _pendingNotificationUrl = null;
      // 다음 프레임에서 WebView로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.toNamed(Routes.WEBVIEW, arguments: url);
      });
    }

    return isLoggedIn ? Routes.HOME : Routes.LOGIN;
  }
}
