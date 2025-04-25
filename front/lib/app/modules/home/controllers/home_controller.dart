import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import '../../posts/controllers/posts_controller.dart';
import '../../subscription/controllers/subscription_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/supabase_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/firebase_services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final SupabaseProvider _supabaseProvider = Get.find<SupabaseProvider>();
  final RxInt currentIndex = 0.obs;
  final RxBool isNotificationDenied = false.obs;
  final RxBool isShowingDialog = false.obs;
  final FirebaseProvider _firebaseService = FirebaseProvider();

  @override
  void onInit() {
    super.onInit();
    _initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_authProvider.isLoggedIn.value) {
      await _firebaseService.initFCM(
        userId: _authProvider.userId.value,
        onTokenRefresh: (token) {
          print('FCM 토큰 갱신: $token');
        },
        showInAppNotification: _showInAppNotification,
        handleNotificationClick: _handleNotificationClick,
      );
    } else {
      // 로그인 상태가 변경될 때 FCM 초기화 수행
      ever(_authProvider.isLoggedIn, (isLoggedIn) {
        if (isLoggedIn) {
          _firebaseService.initFCM(
            userId: _authProvider.userId.value,
            onTokenRefresh: (token) {
              print('FCM 토큰 갱신: $token');
            },
            showInAppNotification: _showInAppNotification,
            handleNotificationClick: _handleNotificationClick,
          );
        }
      });
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification != null) {
      Get.snackbar(
        notification.title ?? '알림',
        notification.body ?? '',
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final String? boardId = data['boardId'];

    if (boardId != null) {
      // 게시물 탭으로 이동
      currentIndex.value = 1;
    }
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
