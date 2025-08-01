import 'package:flutter/material.dart';
import 'package:gachon_noti_front/app/utils/unified_banner_widget.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../../posts/views/posts_view.dart';
import '../../subscription/views/subscription_view.dart';
import '../controllers/home_controller.dart';
import '../../../utils/admob_banner_widget.dart';
import '../../../utils/web_utils.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    // 구독 변경 알림을 위한 리스너 설정
    ever(controller.subscriptionChanged, (changed) {
      if (changed) {
        _showSubscriptionChangedSnackBar();
        // 상태 초기화
        controller.subscriptionChanged.value = false;
      }
    });

    // 업데이트 확인 리스너 설정
    ever(controller.updateAvailable, (available) {
      if (available) {
        _showUpdateSnackbar(context);
      }
    });

    return PopScope(
      canPop: kIsWeb ? true : false, // 시스템의 뒤로가기 동작을 막습니다.
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }

        final bool? shouldExit = await Get.dialog<bool>(
          Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: Get.width * 0.05),
            child: Container(
              width: Get.width * 0.9,
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '앱을 종료하시겠습니까?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 300x250 중간 직사각형 배너 광고 추가
                  if (!kIsWeb) ...[
                    const AdMobMediumRectangleBannerWidget(),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(result: false), // 종료 취소
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => Get.back(result: true), // 종료 확인
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (shouldExit == true) {
          // Get.back()을 호출하여 앱을 종료합니다.
          // iOS에서는 앱이 완전히 종료되지 않고 백그라운드로 갈 수 있습니다.
          Get.back();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                controller.currentIndex.value == 0 ? '구독 설정' : '전체 게시물',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Get.toNamed('/settings'),
              tooltip: '설정',
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() => IndexedStack(
                index: controller.currentIndex.value,
                children: const [
                  SubscriptionView(),
                  PostsView(),
                ],
              )),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 배너 광고 위젯 (네비게이션 바 위쪽)
            const UnifiedBannerWidget(
              adfitAdUnit: 'DAN-U8bbT9CwMuyswC2r',
            ),
            // 네비게이션 바
            Obx(() => NavigationBar(
                  selectedIndex: controller.currentIndex.value,
                  onDestinationSelected: controller.changeTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.notifications),
                      label: '구독 설정',
                    ),
                    NavigationDestination(
                        icon: Icon(Icons.article), label: '전체 게시물'),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void _showSubscriptionChangedSnackBar() {
    Get.snackbar(
      '성공',
      '구독 설정이 저장되었습니다. 게시물이 업데이트되었습니다.',
      duration: const Duration(seconds: 2),
    );
  }

  void _showUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('새로운 버전이 출시되었습니다.'),
        action: SnackBarAction(
          label: '업데이트',
          onPressed: () {
            if (kIsWeb) {
              WebUtils.reloadPage();
            } else {
              // 네이티브에서는 앱스토어로 이동하거나 다른 업데이트 로직 구현
              Get.snackbar(
                '업데이트',
                '앱스토어에서 업데이트를 확인해주세요.',
                duration: const Duration(seconds: 3),
              );
            }
          },
        ),
        duration: const Duration(days: 365),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
