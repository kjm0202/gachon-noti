import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/auth_service.dart';
import '../../../utils/web_utils.dart';

class SettingsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  // 로그아웃 상태
  final RxBool isLoggingOut = false.obs;

  // 앱 버전 정보
  final RxString appVersion = '1.0.0'.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppVersion();
  }

  // 실제 앱 버전 정보 가져오기
  Future<void> _loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion.value = packageInfo.version;
    } catch (e) {
      print('앱 버전을 가져오는 중 오류 발생: $e');
      // 오류 발생 시 기본값 유지
      appVersion.value = '1.0.0';
    }
  }

  // 로그아웃 기능
  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      await _authService.logout();
      Get.back(); // 다이얼로그 닫기
      Get.offAllNamed('/login'); // 로그인 화면으로 이동
    } catch (e) {
      Get.snackbar('오류', '로그아웃 중 오류가 발생했습니다.');
    } finally {
      isLoggingOut.value = false;
    }
  }

  // 개인정보처리방침 열기
  void openPrivacyPolicy() {
    if (kIsWeb) {
      WebUtils.openUrl('https://gachon-noti-privacy.ven0m.kr/');
    } else {
      // 네이티브에서는 url_launcher 사용
      launchUrl(
        Uri.parse('https://gachon-noti-privacy.ven0m.kr/'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // 회원탈퇴 기능 (아직 미구현)
  void deleteAccount() {
    Get.snackbar('알림', '회원탈퇴 기능은 아직 준비 중입니다.');
  }
}
