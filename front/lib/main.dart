import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'app/utils/const.dart';
import 'app/utils/pwa_utils.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/supabase_service.dart';
import 'app/data/services/qonversion_service.dart';
import 'app/utils/notification_utils.dart';
import 'theme.dart';
import 'app/modules/pwa_install_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /* // 폰트 로드
  final fontLoader = FontLoader('PretendardVariable');
  fontLoader.addFont(rootBundle.load('assets/fonts/PretendardVariable.woff2'));
  await fontLoader.load(); */

  // PWA 설치 확인
  PWAInstall().setup(
    installCallback: () {
      debugPrint('APP INSTALLED!');
    },
  );

  // PWA 모드 확인
  final bool isPwa = PwaUtils.isPwaMode();

  // Firebase 초기화 (웹이 아니거나 PWA 모드일 때)
  if (!kIsWeb || isPwa || kDebugMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 네이티브 플랫폼에서 백그라운드 메시지 핸들러 등록
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          NotificationUtils.firebaseMessagingBackgroundHandler);
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // Supabase 초기화
    await Supabase.initialize(
      url: API.supabaseUrl,
      anonKey: API.supabaseAnonKey,
    );

    // 🚀 네이티브 앱에서 알림으로 시작되었는지 즉시 확인하고 URL 열기
    if (!kIsWeb) {
      await _checkAndHandleInitialNotification();
    }
  }

  // PWA 모드가 아닌 웹에서는 PWA 설치 화면 표시
  if (kIsWeb && !isPwa && !kDebugMode) {
    runApp(const PwaInstallView());
  } else {
    // 메인 앱 실행
    runApp(const MyApp());
  }
}

/// 🚀 앱 시작 시 알림으로 열렸는지 즉시 확인하고 URL 열기
Future<void> _checkAndHandleInitialNotification() async {
  try {
    print('🚀 알림으로 앱 시작 확인 중...');

    // 1. FCM 초기 메시지 확인 (앱이 종료된 상태에서 알림 클릭)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🎯 FCM 초기 메시지 발견: ${initialMessage.data}');
      final url = initialMessage.data['postLink'];
      if (url != null && url.isNotEmpty) {
        print('🌐 즉시 URL 열기: $url');
        await _launchUrlImmediately(url);
        return;
      }
    }

    // 2. 로컬 알림으로 앱 시작 확인 (백그라운드 알림 클릭)
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await localNotifications.initialize(initSettings);

    final notificationAppLaunchDetails =
        await localNotifications.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp == true) {
      final payload =
          notificationAppLaunchDetails?.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        print('🎯 로컬 알림으로 앱 시작 발견: $payload');
        print('🌐 즉시 URL 열기: $payload');
        await _launchUrlImmediately(payload);
        return;
      }
    }

    print('✅ 일반적인 앱 시작 (알림 없음)');
  } catch (e) {
    print('❌ 초기 알림 확인 오류: $e');
  }
}

/// 🌐 즉시 URL 열기 (Flutter 앱 초기화 대기 없이)
Future<void> _launchUrlImmediately(String url) async {
  try {
    final uri = Uri.parse(url);

    if (!uri.hasScheme) {
      print('❌ 잘못된 URL: $url (스키마 없음)');
      return;
    }

    print('🔍 URL 실행 가능 여부 확인: $uri');
    final canLaunch = await url_launcher.canLaunchUrl(uri);

    if (canLaunch) {
      print('🚀 Chrome Custom Tab으로 URL 열기 시도...');

      // Chrome Custom Tab으로 열기 시도
      final launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.inAppBrowserView,
        browserConfiguration: const url_launcher.BrowserConfiguration(
          showTitle: true,
        ),
      );

      if (launched) {
        print('✅ Chrome Custom Tab으로 URL 열기 성공');
      } else {
        print('⚠️ Chrome Custom Tab 실패, 외부 브라우저로 재시도...');
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
        print('✅ 외부 브라우저로 URL 열기 완료');
      }
    } else {
      print('❌ URL을 열 수 없음: $url');
    }
  } catch (e) {
    print('❌ URL 열기 오류: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return FutureBuilder<String>(
      // 서비스 제공자들이 초기화 완료되길 기다림
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
            initialRoute: snapshot.data!, // 동적으로 결정된 초기 경로 사용
            getPages: AppPages.routes,
            defaultTransition: Transition.fade,
          );
        } else {
          // 로딩 중 화면 표시
          return MaterialApp(
            title: '가천 알림이',
            theme: materialTheme.light(),
            darkTheme: materialTheme.dark(),
            themeMode: ThemeMode.system,
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
      },
    );
  }

  // 서비스 초기화를 위한 메소드
  Future<String> _initializeServices() async {
    final supabaseProvider = SupabaseService();
    await supabaseProvider.init();
    Get.put(supabaseProvider);

    final authProvider = AuthService();
    await authProvider.init();
    Get.put(authProvider);

    // Qonversion 서비스 초기화 (모바일 전용)
    if (!kIsWeb) {
      final qonversionService = QonversionService();
      Get.put(qonversionService, permanent: true);
    }

    // 로그인 상태를 확인하고 적절한 초기 경로 반환
    final isLoggedIn = await authProvider.checkCurrentSession();
    return isLoggedIn ? Routes.HOME : Routes.LOGIN;
  }
}
