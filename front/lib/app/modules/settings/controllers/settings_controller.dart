import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/adfree_service.dart';
import '../../../data/services/qonversion_service.dart';

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
  final RxBool isLoadingQonversionDebug = false.obs;

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

  Future<void> showQonversionDebugInfo() async {
    if (isLoadingQonversionDebug.value) return;

    if (!Get.isRegistered<QonversionService>()) {
      Get.snackbar('오류', 'QonversionService가 초기화되지 않았습니다.');
      return;
    }

    final qonversionService = Get.find<QonversionService>();

    try {
      isLoadingQonversionDebug.value = true;

      await qonversionService.loadOfferings();
      final entitlements = await qonversionService.checkEntitlements();

      final productLines = _buildProductDebugLines(qonversionService);
      final entitlementLines = _buildEntitlementDebugLines(entitlements);

      Get.dialog(
        AlertDialog(
          title: const Text('Qonversion 디버그 정보'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Products',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...productLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        line,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  const Text(
                    'Entitlements',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...entitlementLines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        line,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.snackbar('오류', 'Qonversion 디버그 정보 조회 실패: $e');
    } finally {
      isLoadingQonversionDebug.value = false;
    }
  }

  List<String> _buildProductDebugLines(QonversionService qonversionService) {
    final lines = <String>[];
    final offerings = qonversionService.offerings;

    if (offerings != null) {
      lines.add('[Offerings] 총 ${offerings.availableOfferings.length}개');

      for (final offering in offerings.availableOfferings) {
        if (offering.products.isEmpty) {
          lines.add('- ${offering.id}: product 없음');
          continue;
        }

        lines.add('- ${offering.id}');
        for (final product in offering.products) {
          lines.add(
              '  • ${product.qonversionId} | ${product.storeId} | ${product.prettyPrice}');
        }
      }
    } else {
      lines.add('[Offerings] 읽은 데이터 없음');
    }

    final productsMap = qonversionService.products;
    if (productsMap != null && productsMap.isNotEmpty) {
      lines.add('');
      lines.add('[Products API] 총 ${productsMap.length}개');
      for (final entry in productsMap.entries) {
        final product = entry.value;
        lines.add(
            '- ${entry.key} | ${product.storeId} | ${product.prettyPrice}');
      }
    } else {
      lines.add('');
      lines.add('[Products API] 읽은 데이터 없음');
    }

    return lines;
  }

  List<String> _buildEntitlementDebugLines(Map<String, dynamic> entitlements) {
    if (entitlements.isEmpty) {
      return ['읽은 entitlement 없음'];
    }

    final lines = <String>[];
    for (final entry in entitlements.entries) {
      final entitlement = entry.value;
      lines.add('- ${entry.key} | active=${entitlement.isActive}');
    }
    return lines;
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
