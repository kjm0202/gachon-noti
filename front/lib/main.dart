import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app/utils/const.dart';
import 'app/utils/pwa_utils.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/services/auth_service.dart';
import 'app/data/services/supabase_service.dart';
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
  }

  // PWA 모드가 아닌 웹에서는 PWA 설치 화면 표시
  if (kIsWeb && !isPwa && !kDebugMode) {
    runApp(const PwaInstallView());
  } else {
    // 메인 앱 실행
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return FutureBuilder(
      // 서비스 제공자들이 초기화 완료되길 기다림
      future: _initializeServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GetMaterialApp(
            title: '가천 알림이',
            debugShowCheckedModeBanner: false,
            theme: materialTheme.light(),
            darkTheme: materialTheme.dark(),
            themeMode: ThemeMode.system,
            initialBinding: InitialBinding(),
            initialRoute: AppPages.INITIAL,
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
  Future<void> _initializeServices() async {
    final supabaseProvider = SupabaseService();
    await supabaseProvider.init();
    Get.put(supabaseProvider);

    final authProvider = AuthService();
    await authProvider.init();
    Get.put(authProvider);
  }
}
