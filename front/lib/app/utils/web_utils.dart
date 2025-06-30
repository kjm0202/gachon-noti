import 'package:web/web.dart' as web;
import 'package:flutter/foundation.dart';
import 'dart:js_interop';

class WebUtils {
  // PWA 모드인지 확인하는 함수
  static bool isPwaMode() {
    // 디버그 모드일 때는 항상 PWA 모드로 간주
    if (kDebugMode) {
      debugPrint('디버그 모드: PWA 설치 화면 건너뛰기');
      return true;
    }
    return (
        // Check PWA mode
        web.window.matchMedia('(display-mode: standalone)').matches ||
            // Check Android TWA mode
            web.document.referrer
                .startsWith('android-app://com.kjm.gachon_noti'));
  }

  // 웹 알림 권한 요청
  static Future<String> requestNotificationPermission() async {
    final status = await web.Notification.requestPermission().toDart;
    return status.toDart;
  }

  // 웹 알림 표시
  static void showWebNotification(String title, String body, String? data) {
    final options = web.NotificationOptions(
      body: body,
      data: data?.toJS,
    );

    web.Notification.requestPermission().toDart.then((status) {
      if (status.toDart == 'granted') {
        final container = web.window.navigator.serviceWorker;
        container.ready.toDart.then((registration) {
          registration.showNotification(title, options);
          print('알림 표시: $title - $body (링크: $data)');
        });
      }
    });
  }

  // URL 열기
  static void openUrl(String url, [String target = '_blank']) {
    web.window.open(url, target);
  }

  // 페이지 새로고침
  static void reloadPage() {
    web.window.location.reload();
  }

  // 현재 origin 가져오기
  static String getCurrentOrigin() {
    return web.window.location.origin;
  }

  // 현재 referrer 가져오기
  static String getCurrentReferrer() {
    return web.document.referrer;
  }
}
