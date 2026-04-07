import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';

import '../../posts/views/posts_view.dart';
import '../../subscription/views/subscription_view.dart';
import '../controllers/home_controller.dart';
import '../../../utils/admob_banner_widget.dart';


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
        controller.showUpdateSnackbar(context);
      }
    });

    return PopScope(
      canPop: false, // 시스템의 뒤로가기 동작을 막습니다.
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
                  const AdMobMediumRectangleBannerWidget(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Get.back(result: false), // 종료 취소
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () => SystemNavigator.pop(), // 종료 확인
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
        bottomNavigationBar: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 배너 광고 위젯 (네비게이션 바 위쪽)
              const AdMobBannerWidget(
                bannerType: AdMobBannerType.home,
              ),
              // 네비게이션 바 (가로형 레이아웃으로 두께 감소)
              Obx(() => Container(
                    height: 60, // 높이를 명시적으로 설정하여 두께 조절
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                              .bottomNavigationBarTheme
                              .backgroundColor ??
                          Theme.of(context).colorScheme.surface,
                      border: Border(
                        top: BorderSide(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => controller.changeTab(0),
                              child: Container(
                                height: 60,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications,
                                      color: controller.currentIndex.value == 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '구독 설정',
                                      style: TextStyle(
                                        color:
                                            controller.currentIndex.value == 0
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        fontSize: 14,
                                        fontWeight:
                                            controller.currentIndex.value == 0
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 구분선
                        Container(
                          width: 0.5,
                          height: 32,
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.3),
                        ),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => controller.changeTab(1),
                              child: Container(
                                height: 60,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.article,
                                      color: controller.currentIndex.value == 1
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '전체 게시물',
                                      style: TextStyle(
                                        color:
                                            controller.currentIndex.value == 1
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        fontSize: 14,
                                        fontWeight:
                                            controller.currentIndex.value == 1
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
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
}
