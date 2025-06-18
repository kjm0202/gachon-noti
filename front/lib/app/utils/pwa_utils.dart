import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';

class PwaUtils {
  // PWA 모드인지 확인하는 함수
  static bool isPwaMode() {
    // 디버그 모드일 때는 항상 PWA 모드로 간주
    if (kDebugMode) {
      print('디버그 모드: PWA 설치 화면 건너뛰기');
      return true;
    }
    return (
        // Check PWA mode
        web.window.matchMedia('(display-mode: standalone)').matches ||
            // Check Android TWA mode
            web.document.referrer
                .startsWith('android-app://com.kjm.gachon_noti'));
  }
}
