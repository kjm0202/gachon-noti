import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../posts/controllers/posts_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../utils/version_checker.dart';

class HomeController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RxInt currentIndex = 0.obs;
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final Rx<AuthorizationStatus> notificationPermission =
      AuthorizationStatus.authorized.obs;
  // 구독 변경 성공 시 이벤트
  final RxBool subscriptionChanged = false.obs;
  // 업데이트 확인 관련 변수
  final RxBool updateAvailable = false.obs;

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
        content: const Text('\'확인\' 버튼을 누른 뒤 나오는 팝업에서 알림 권한을 허용해주세요.'),
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
    // 웹 알림 권한 요청
    final status = await web.Notification.requestPermission().toDart;

    // 권한 상태 업데이트
    if (status.toDart == 'granted') {
      notificationPermission.value = AuthorizationStatus.authorized;
    } else if (status.toDart == 'denied') {
      notificationPermission.value = AuthorizationStatus.denied;
    }

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
      final String postLink = data['postLink'];
      final String title = '[${data['boardName']}] 새 공지';
      final String body = data['title'];

      print("URL 설정: $postLink");

      web.NotificationOptions options = web.NotificationOptions(
        body: body,
        data: postLink.toJS,
      );

      web.Notification.requestPermission().toDart.then((status) {
        if (status.toDart == 'granted') {
          web.ServiceWorkerContainer container =
              web.window.navigator.serviceWorker;
          container.ready.toDart.then((registration) {
            registration.showNotification(title, options);
            print('알림 표시: $title - $body (링크: $postLink)');
          });
        }
      });
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('handleNotificationClick');
    final data = message.data;
    final String? postLink = data['postLink'];

    // 알림을 통해 특정 게시판이나 게시글로 이동
    currentIndex.value = 1; // 전체 게시물 탭으로 전환

    if (postLink != null) {
      // web.window.location.href = postLink;
      web.window.open(postLink, '_blank');
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
    // currentIndex.value = 1;

    // 구독 변경 이벤트 발생
    subscriptionChanged.value = true;
  }

  Future<bool> logout() async {
    try {
      // AuthProvider에 통합된 로그아웃 로직 호출
      final result = await _authProvider.logout();
      if (result) {
        Get.offAllNamed(Routes.LOGIN);
      }
      return result;
    } catch (e) {
      print('로그아웃 처리 오류: $e');
      return false;
    }
  }
}
