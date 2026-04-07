
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/adfree_service.dart';


class SettingsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final AdFreeService _adFreeService = Get.find<AdFreeService>();

  // 로그아웃 상태
  final RxBool isLoggingOut = false.obs;

  // 앱 버전 정보
  final RxString appVersion = '1.0.0'.obs;

  // 구매 관련 상태
  final RxBool isPurchasing = false.obs;
  final RxBool isRestoring = false.obs;

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
    launchUrl(
      Uri.parse('https://gachon-noti-privacy.ven0m.kr/'),
      mode: LaunchMode.externalApplication,
    );
  }

  // 광고 제거 상태 확인
  bool get isAdFree => _adFreeService.isAdFree;

  // 광고 제거 구매
  Future<void> purchaseRemoveAds() async {
    if (isPurchasing.value) return;

    try {
      isPurchasing.value = true;
      await _adFreeService.purchaseRemoveAds();
    } finally {
      isPurchasing.value = false;
    }
  }

  // 구매 복원
  Future<void> restorePurchases() async {
    if (isRestoring.value) return;

    try {
      isRestoring.value = true;
      await _adFreeService.restorePurchases();
    } finally {
      isRestoring.value = false;
    }
  }

  // 로그아웃 다이얼로그 표시
  void showLogoutDialog() {
    Get.dialog(
      PopScope(
        canPop: !isLoggingOut.value,
        child: Obx(() => AlertDialog(
              title: const Text('로그아웃'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoggingOut.value)
                    const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('로그아웃 중...'),
                      ],
                    )
                  else
                    const Text('로그아웃 하시겠습니까?'),
                ],
              ),
              actions: [
                if (!isLoggingOut.value) ...[
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: logout,
                    child: const Text('확인'),
                  ),
                ],
              ],
            )),
      ),
      barrierDismissible: false,
    );
  }

  // 회원탈퇴 다이얼로그 표시
  void showDeleteAccountDialog() {
    Get.dialog(
      AlertDialog(
        title: Text(
          '회원탈퇴',
          style: TextStyle(color: Colors.red[700]),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.orange,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              '회원탈퇴 기능은 현재 준비 중입니다.\n추후 업데이트에서 제공될 예정입니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 회원탈퇴 기능 (아직 미구현)
  void deleteAccount() {
    Get.snackbar('알림', '회원탈퇴 기능은 아직 준비 중입니다.');
  }
}
