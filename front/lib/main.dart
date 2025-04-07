import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:pwa_install/pwa_install.dart';

import 'firebase_options.dart';
import 'utils/const.dart';
import 'utils/pwa_utils.dart';
import 'view/app_content_view.dart';
import 'view/pwa_install_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 폰트 로드
  final fontLoader = FontLoader('PretendardVariable');
  fontLoader.addFont(rootBundle.load('assets/fonts/PretendardVariable.woff2'));
  await fontLoader.load();

  // PWA 설치 확인
  PWAInstall().setup(
    installCallback: () {
      debugPrint('APP INSTALLED!');
    },
  );

  // PWA 모드 확인
  final bool isPwa = PwaUtils.isPwaMode();
  Client? client;

  // PWA 모드일 때만 Firebase와 Appwrite 초기화
  if (isPwa) {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await FirebaseCrashlytics.instance.recordError(
          errorAndStacktrace.first,
          errorAndStacktrace.last,
          fatal: true,
        );
      }).sendPort,
    );

    // Appwrite 클라이언트 초기화
    client = Client().setEndpoint(API.apiUrl).setProject(API.projectId);
  }

  runApp(isPwa ? AppContentView(client: client!) : const PwaInstallView());
}
