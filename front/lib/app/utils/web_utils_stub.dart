import 'package:flutter/foundation.dart';

class WebUtils {
  // PWA 모드인지 확인하는 함수
  static bool isPwaMode() {
    // 네이티브 앱에서는 항상 true 반환 (PWA 설치 화면을 보여주지 않음)
    return true;
  }

  // 웹 알림 권한 요청 (네이티브에서는 사용하지 않음)
  static Future<String> requestNotificationPermission() async {
    debugPrint(
        'WebUtils.requestNotificationPermission() called on native platform');
    return 'granted'; // 네이티브에서는 FCM에서 직접 처리
  }

  // 웹 알림 표시 (네이티브에서는 사용하지 않음)
  static void showWebNotification(String title, String body, String? data) {
    debugPrint('WebUtils.showWebNotification() called on native platform');
    debugPrint('Title: $title, Body: $body, Data: $data');
    // 네이티브에서는 FCM이 직접 처리
  }

  // URL 열기 (네이티브에서는 url_launcher 사용)
  static void openUrl(String url, [String target = '_blank']) {
    debugPrint('WebUtils.openUrl() called on native platform with URL: $url');
    // 네이티브에서는 url_launcher의 launchUrl 사용
  }

  // 페이지 새로고침 (네이티브에서는 사용하지 않음)
  static void reloadPage() {
    debugPrint(
        'WebUtils.reloadPage() called on native platform - no action taken');
  }

  // 현재 origin 가져오기 (네이티브에서는 사용하지 않음)
  static String getCurrentOrigin() {
    return '';
  }

  // 현재 referrer 가져오기 (네이티브에서는 사용하지 않음)
  static String getCurrentReferrer() {
    return '';
  }
}
