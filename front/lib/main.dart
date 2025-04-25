import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pwa_install/pwa_install.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app/utils/const.dart';
import 'app/utils/pwa_utils.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/bindings/initial_binding.dart';
import 'app/data/providers/auth_provider.dart';
import 'app/data/providers/supabase_provider.dart';
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

  // PWA 모드이거나 디버그 모드일 때 Firebase와 Supabase 초기화
  if (isPwa || kDebugMode) {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Supabase 초기화
    await Supabase.initialize(
      url: API.supabaseUrl,
      anonKey: API.supabaseAnonKey,
    );

    // GetX 앱 실행
    runApp(const MyApp());
  } else {
    // PWA 설치 화면
    runApp(const PwaInstallView());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(Theme.of(context).textTheme);

    return FutureBuilder(
      // 서비스 제공자들이 초기화되길 기다립니다
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
    final supabaseProvider = SupabaseProvider();
    await supabaseProvider.init();
    Get.put(supabaseProvider);

    final authProvider = AuthProvider();
    await authProvider.init();
    Get.put(authProvider);
  }
}
