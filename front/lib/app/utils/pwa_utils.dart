import 'platform_utils.dart';

class PwaUtils {
  // PWA 모드인지 확인하는 함수 - 이제 WebUtils를 통해 처리
  static bool isPwaMode() {
    return WebUtils.isPwaMode();
  }
}
