import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../utils/unified_banner_widget.dart';
import '../../../utils/admob_banner_widget.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 앱 정보 섹션
              const Text(
                '앱 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 16),
                          const Text('앱 버전'),
                          const Spacer(),
                          Obx(() => Text(
                                controller.appVersion.value,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              )),
                        ],
                      ),
                      const Divider(),
                      const Row(
                        children: [
                          Icon(Icons.code),
                          SizedBox(width: 16),
                          Text('Made by 베놈 (ven0m)'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.warning_amber_outlined),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              '이 앱은 가천대학교 공식 앱이 아닙니다.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 개인정보 및 약관 섹션
              const Text(
                '개인정보 및 약관',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('개인정보처리방침'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: controller.openPrivacyPolicy,
                ),
              ),

              const SizedBox(height: 24),

              // 광고 설정 섹션
              const Text(
                '광고 설정',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Obx(() => Card(
                    child: Column(
                      children: [
                        // 광고 제거 상태 표시
                        ListTile(
                          leading: Icon(
                            controller.isAdFree
                                ? Icons.check_circle
                                : Icons.ads_click,
                            color: controller.isAdFree ? Colors.green : null,
                          ),
                          title:
                              Text(controller.isAdFree ? '광고 제거됨' : '광고 표시 중'),
                          subtitle: Text(
                            controller.isAdFree
                                ? '광고 없이 깔끔한 앱을 즐기고 있습니다.'
                                : '광고를 제거하여 더 나은 사용 경험을 누려보세요.',
                          ),
                        ),
                        if (!controller.isAdFree) ...[
                          const Divider(height: 1),
                          // 광고 제거 구매 버튼
                          ListTile(
                            leading: const Icon(Icons.shopping_cart),
                            title: const Text('광고 제거 구매'),
                            subtitle: const Text('₩2,900 - 1회 결제로 평생 광고 없음'),
                            trailing: controller.isPurchasing.value
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.arrow_forward_ios),
                            onTap: controller.isPurchasing.value
                                ? null
                                : controller.purchaseRemoveAds,
                          ),
                        ],
                        const Divider(height: 1),
                        // 구매 복원 버튼
                        ListTile(
                          leading: const Icon(Icons.restore),
                          title: const Text('구매 복원'),
                          subtitle: const Text('이전에 구매한 광고 제거를 복원합니다.'),
                          trailing: controller.isRestoring.value
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward_ios),
                          onTap: controller.isRestoring.value
                              ? null
                              : controller.restorePurchases,
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 24),

              // 계정 관리 섹션
              const Text(
                '계정 관리',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text('로그아웃'),
                      onTap: controller.showLogoutDialog,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading:
                          Icon(Icons.person_remove, color: Colors.red[700]),
                      title: Text(
                        '회원탈퇴',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                      onTap: controller.showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: const UnifiedBannerWidget(
          adfitAdUnit: 'DAN-U8bbT9CwMuyswC2r',
          bannerType: AdMobBannerType.settings,
        ),
      ),
    );
  }
}
