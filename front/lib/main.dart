import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:pwa_install/pwa_install.dart';

import 'firebase_options.dart';
import 'utils/const.dart';
import 'utils/pwa_utils.dart';
import 'view/app_content_view.dart';
import 'view/pwa_install_view.dart';

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
  Client? client;

  // PWA 모드이거나 디버그 모드일 때 Firebase와 Appwrite 초기화
  if (isPwa || kDebugMode) {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Appwrite 클라이언트 초기화
    client = Client().setEndpoint(API.apiUrl).setProject(API.projectId);
  }

  // 디버그 모드이거나 PWA 모드일 때 앱 콘텐츠 뷰 표시, 그 외에는 PWA 설치 화면 표시
  runApp(
    (isPwa || kDebugMode)
        ? AppContentView(client: client!)
        : const PwaInstallView(),
  );
}
