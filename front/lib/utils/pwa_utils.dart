import 'package:web/web.dart' as web;

class PwaUtils {
  // PWA 모드인지 확인하는 함수
  static bool isPwaMode() {
    return web.window.matchMedia('(display-mode: standalone)').matches;
  }

  // 기타 PWA 관련 유틸리티 함수들을 여기에 추가할 수 있습니다.
}
