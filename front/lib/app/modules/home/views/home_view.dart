import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../posts/views/posts_view.dart';
import '../../subscription/views/subscription_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.currentIndex.value == 0 ? '구독 설정' : '전체 게시물',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.logout,
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

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('가천 알림이'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icons/app_icon_transparent.png',
              width: 48,
              height: 48,
            ),
            const SizedBox(height: 16),
            const Text('Made by 무적소웨 졸업생'),
            const Text('이 앱은 가천대학교 공식 앱이 아닙니다.'),
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
}
