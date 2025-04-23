import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../posts/controllers/posts_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';

class HomeController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RxInt currentIndex = 0.obs;
  final RxBool isNotificationDenied = false.obs;
  final RxBool isShowingDialog = false.obs;

  @override
  void onInit() {
    super.onInit();
    // 필요한 초기화 작업
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  Future<void> handleSubscriptionChange() async {
    // 구독 설정 변경 시 게시물 새로고침 처리
    final postsController = Get.find<PostsController>();
    await postsController.forceRefresh();

    // 게시물 탭으로 변경
    currentIndex.value = 1;

    // 성공 메시지 표시
    Get.snackbar(
      '성공',
      '구독 설정이 저장되었습니다. 게시물이 업데이트되었습니다.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authProvider.logout();
      // 앱 재시작 또는 로그인 화면으로 이동
      Get.offAllNamed(Routes.LOGIN);
    }
  }
}
