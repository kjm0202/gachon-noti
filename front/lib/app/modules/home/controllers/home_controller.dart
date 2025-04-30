import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../../posts/controllers/posts_controller.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../data/providers/firebase_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomeController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RxInt currentIndex = 0.obs;
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final Rx<AuthorizationStatus> notificationPermission =
      AuthorizationStatus.authorized.obs;
  // 구독 변경 성공 시 이벤트
  final RxBool subscriptionChanged = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkNotificationPermission();
    _initializeFirebaseMessaging();
  }

  Future<void> _checkNotificationPermission() async {
    final permission =
        await FirebaseMessaging.instance.getNotificationSettings();
    notificationPermission.value = permission.authorizationStatus;
  }

  Future<void> _initializeFirebaseMessaging() async {
    if (_authProvider.isLoggedIn.value) {
      await _firebaseProvider.initFCM(
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
          _firebaseProvider.initFCM(
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
