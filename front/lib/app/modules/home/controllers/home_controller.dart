import 'package:get/get.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../posts/controllers/posts_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../utils/version_checker.dart';
import '../../../utils/platform_utils.dart';

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
        content: Text(kIsWeb
            ? '\'확인\' 버튼을 누른 뒤 나오는 팝업에서 알림 권한을 허용해주세요.'
            : '새로운 공지사항 알림을 받으려면 알림 권한을 허용해주세요.'),
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
    if (kIsWeb) {
      // 웹에서는 WebUtils를 통해 알림 권한 요청
      final status = await WebUtils.requestNotificationPermission();

      // 권한 상태 업데이트
      if (status == 'granted') {
        notificationPermission.value = AuthorizationStatus.authorized;
      } else if (status == 'denied') {
        notificationPermission.value = AuthorizationStatus.denied;
      }
    } else {
      // 네이티브에서는 FCM이 직접 권한 처리
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      notificationPermission.value = settings.authorizationStatus;
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
      final String postLink = data['postLink'] ?? '';
      final String title = '[${data['boardName'] ?? '알림'}] 새 공지';
      final String body = data['title'] ?? '새로운 공지사항이 있습니다.';

      print("URL 설정: $postLink");

      if (kIsWeb) {
        // 웹에서는 WebUtils를 통해 알림 표시
        WebUtils.showWebNotification(title, body, postLink);
      } else {
        // 네이티브에서는 Get.snackbar나 로컬 알림으로 표시
        Get.snackbar(
          title,
          body,
          duration: const Duration(seconds: 5),
          onTap: postLink.isNotEmpty ? (_) => _launchUrl(postLink) : null,
          mainButton: postLink.isNotEmpty
              ? TextButton(
                  onPressed: () => _launchUrl(postLink),
                  child: const Text('보기'),
                )
              : null,
        );
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('handleNotificationClick');
    final data = message.data;
    final String? postLink = data['postLink'];

    // 알림을 통해 특정 게시판이나 게시글로 이동
    currentIndex.value = 1; // 전체 게시물 탭으로 전환

    if (postLink != null && postLink.isNotEmpty) {
      _launchUrl(postLink);
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      if (kIsWeb) {
        // 웹에서는 WebUtils를 통해 URL 열기
        WebUtils.openUrl(url, '_blank');
      } else {
        // 네이티브에서는 url_launcher 사용
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      }
    } catch (e) {
      print('URL 열기 실패: $e');
      Get.snackbar(
        '오류',
        'URL을 열 수 없습니다.',
        snackPosition: SnackPosition.BOTTOM,
      );
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
