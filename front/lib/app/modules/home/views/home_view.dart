import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import '../../posts/views/posts_view.dart';
import '../../subscription/views/subscription_view.dart';
import '../controllers/home_controller.dart';

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
        _showUpdateDialog(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.currentIndex.value == 0 ? '구독 설정' : '전체 게시물',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
            tooltip: '로그아웃',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: _showAboutDialog,
            tooltip: '앱 정보',
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
      bottomNavigationBar: Obx(() => NavigationBar(
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.changeTab,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.notifications),
                label: '구독 설정',
              ),
              NavigationDestination(icon: Icon(Icons.article), label: '전체 게시물'),
            ],
          )),
    );
  }

  void _showSubscriptionChangedSnackBar() {
    Get.snackbar(
      '성공',
      '구독 설정이 저장되었습니다. 게시물이 업데이트되었습니다.',
      duration: const Duration(seconds: 2),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await controller.logout();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /* Image.asset(
              'assets/icons/app_icon_transparent.webp',
              width: 48,
              height: 48,
            ), */
            const SizedBox(height: 16),
            const Text('Made by 무적소웨 졸업생'),
            const Text('이 앱은 가천대학교 공식 앱이 아닙니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              web.window.open('https://gachon-noti.notion.site/');
            },
            child: const Text('홈페이지'),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('새로운 버전이 출시되었습니다. 업데이트하시겠습니까?'),
        action: SnackBarAction(
          label: '업데이트',
          onPressed: () {
            web.window.location.reload();
          },
        ),
        duration: const Duration(days: 365),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
