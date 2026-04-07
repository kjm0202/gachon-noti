import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';


import '../../posts/controllers/posts_controller.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_routes.dart';
import '../../../data/services/firebase_service.dart';
import '../../../utils/version_checker.dart';

class HomeController extends GetxController {
  final AuthService _authProvider = Get.find<AuthService>();
  final RxInt currentIndex = 0.obs;
  final FirebaseService _firebaseProvider = FirebaseService();
  final Rx<AuthorizationStatus> notificationPermission =
      AuthorizationStatus.authorized.obs;
  // 구독 변경 성공 시 이벤트
  final RxBool subscriptionChanged = false.obs;
  // 업데이트 확인 관련 변수
  final RxBool updateAvailable = false.obs;
  // 로그아웃 진행 중 상태
  final RxBool isLoggingOut = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _checkNotificationPermission();

    // 알림 권한이 아직 결정되지 않은 경우 권한 요청 다이얼로그 표시
    if (notificationPermission.value == AuthorizationStatus.notDetermined) {
      _showNotificationPermissionDialog();
    }

    if (_authProvider.isLoggedIn.value) {
      await _initFCM();
    } else {
      // 로그인 상태가 변경될 때 FCM 초기화 수행
      ever(_authProvider.isLoggedIn, (isLoggedIn) {
        if (isLoggedIn) {
          _initFCM();
        }
      });
    }
  }

  @override
  void onReady() {
    super.onReady();
    _checkForUpdates();
  }

  // 업데이트 확인 메서드
  Future<void> _checkForUpdates() async {
    // 모바일 환경이므로 VersionChecker.needsUpdate()를 바로 호출하거나, 일단 유지합니다.
    // kIsWeb 조건이 있었으나 이제 항상 실행합니다.
    try {
      final needsUpdate = await VersionChecker.needsUpdate();
      updateAvailable.value = needsUpdate;
    } catch (e) {
      print('업데이트 확인 중 오류 발생: $e');
    }
  }

  Future<void> _checkNotificationPermission() async {
    final permission =
        await FirebaseMessaging.instance.getNotificationSettings();
    notificationPermission.value = permission.authorizationStatus;
  }

  void _showNotificationPermissionDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('알림 권한 요청'),
        content: const Text('새로운 공지사항 알림을 받으려면 알림 권한을 허용해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _requestNotificationPermission();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    // 네이티브에서는 FCM이 직접 권한 처리
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    notificationPermission.value = settings.authorizationStatus;

    // 권한을 얻었다면 FCM 초기화
    if (notificationPermission.value == AuthorizationStatus.authorized) {
      await _initFCM();
    }
  }

  Future<void> _initFCM() async {
    await _firebaseProvider.initFCM(
      userId: _authProvider.userId.value,
      onTokenRefresh: (token) {
        print('FCM 토큰 갱신: $token');
      },
      showInAppNotification: _showInAppNotification,
      handleNotificationClick: _handleNotificationClick,
    );
  }

  void _showInAppNotification(RemoteMessage message) {
    final data = message.data;
    print("_showInAppNotification: $data");

    if (data.isNotEmpty) {
      final String postLink = data['postLink'] ?? '';
      final String title = '[${data['boardName'] ?? '알림'}] 새 공지';

      print("URL 설정: $postLink");

      // 네이티브에서는 FirebaseProvider에서 로컬 알림으로 처리
      // 여기서는 추가 처리가 필요한 경우에만 snackbar 표시
      print('네이티브 앱에서 포그라운드 알림 수신: $title');
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('handleNotificationClick');
    final data = message.data;
    final String? postLink = data['postLink'];

    if (postLink != null && postLink.isNotEmpty) {
      Get.toNamed(Routes.WEBVIEW, arguments: postLink);
    }
  }

  void changeTab(int index) {
    currentIndex.value = index;
  }

  Future<void> handleSubscriptionChange() async {
    // 구독 설정 변경 시 게시물 새로고침 처리
    if (Get.isRegistered<PostsController>()) {
      final postsController = Get.find<PostsController>();
      await postsController.refreshAfterSubscriptionChange();
    }

    // 게시물 탭으로 변경
    // currentIndex.value = 1;

    // 구독 변경 이벤트 발생
    subscriptionChanged.value = true;
  }

  // 업데이트 스낵바 표시
  void showUpdateSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('새로운 버전이 출시되었습니다.'),
        action: SnackBarAction(
          label: '업데이트',
          onPressed: () {
            // 네이티브에서는 앱스토어로 이동하거나 다른 업데이트 로직 구현
            Get.snackbar(
              '업데이트',
              '앱스토어에서 업데이트를 확인해주세요.',
              duration: const Duration(seconds: 3),
            );
          },
        ),
        duration: const Duration(days: 365),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> logout() async {
    try {
      // 로그아웃 시작
      isLoggingOut.value = true;

      // AuthProvider에 통합된 로그아웃 로직 호출
      final result = await _authProvider.logout();
      if (result) {
        Get.offAllNamed(Routes.LOGIN);
      }

      return result;
    } catch (e) {
      print('로그아웃 처리 오류: $e');
      return false;
    } finally {
      // 로그아웃 완료 (성공 또는 실패)
      isLoggingOut.value = false;
    }
  }
}
