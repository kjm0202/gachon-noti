import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/adfree_service.dart';
import '../../../data/services/qonversion_service.dart';

class SettingsController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final AdFreeService _adFreeService = Get.find<AdFreeService>();

  // 로그아웃 및 회원탈퇴 상태
  final RxBool isLoggingOut = false.obs;
  final RxBool isDeletingAccount = false.obs;
  final RxBool hasConfirmedDeletion = false.obs;

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
      debugPrint('앱 버전을 가져오는 중 오류 발생: $e');
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
    hasConfirmedDeletion.value = false;

    Get.dialog(
      PopScope(
        canPop: !isDeletingAccount.value,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Obx(
              () => AlertDialog(
                title: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '회원탈퇴',
                      style: TextStyle(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                content: isDeletingAccount.value
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              '회원탈퇴 및 데이터 정리 중...',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '정말로 탈퇴하시겠습니까?\n탈퇴 시 다음 정보가 즉시 영구 삭제되며 복구할 수 없습니다.',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 삭제 항목 안내 카드
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildBulletPoint('알림 키워드 및 공지사항 구독 설정'),
                                    const SizedBox(height: 4),
                                    _buildBulletPoint('등록 기기 및 푸시 알림 수신 토큰'),
                                    const SizedBox(height: 4),
                                    _buildBulletPoint('Google 계정 연동 및 로그인 정보'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 💡 광고 제거(1회성 구매) 구매자 안내 카드
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '광고 제거 1회성 구매 내역은 스토어(Google Play / App Store) 계정에 안전하게 유지됩니다. 탈퇴 후 동일한 스토어 계정으로 다시 이용 시 [구매 복원]을 통해 언제든 광고 없이 이용하실 수 있습니다.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.35,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 확인 체크박스
                              CheckboxListTile(
                                value: hasConfirmedDeletion.value,
                                onChanged: (val) {
                                  hasConfirmedDeletion.value = val ?? false;
                                },
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                dense: true,
                                activeColor: colorScheme.error,
                                title: const Text(
                                  '위 유의사항을 모두 확인하였으며, 회원탈퇴에 동의합니다.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                actions: [
                  if (!isDeletingAccount.value) ...[
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('취소'),
                    ),
                    FilledButton(
                      onPressed:
                          hasConfirmedDeletion.value ? deleteAccount : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        disabledBackgroundColor:
                            colorScheme.error.withValues(alpha: 0.3),
                      ),
                      child: const Text(
                        '탈퇴하기',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  // 회원탈퇴 기능 실행
  Future<void> deleteAccount() async {
    try {
      isDeletingAccount.value = true;
      await _authService.deleteAccount();
      Get.back(); // 다이얼로그 닫기
      Get.offAllNamed(Routes.login); // 로그인 화면으로 이동
      Get.snackbar(
        '탈퇴 완료',
        '회원탈퇴 및 데이터 정리가 정상적으로 완료되었습니다.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey[850],
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        '회원탈퇴 실패',
        e
            .toString()
            .replaceFirst('Exception: ', '')
            .replaceFirst('StateError: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isDeletingAccount.value = false;
    }
  }

}
