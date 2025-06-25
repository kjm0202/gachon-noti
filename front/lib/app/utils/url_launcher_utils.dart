import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'platform_utils.dart';

/// URL 실행 관련 공통 유틸리티 함수들
class UrlLauncherUtils {
  /// 플랫폼에 맞는 방식으로 URL을 엽니다
  static Future<void> launchUrl(String url) async {
    try {
      debugPrint('URL 열기 시도: $url');

      if (kIsWeb) {
        // 웹에서는 WebUtils를 통해 URL 열기
        WebUtils.openUrl(url, '_blank');
        debugPrint('웹에서 URL 열기 완료');
      } else {
        // 네이티브에서는 url_launcher 사용 (Chrome Custom Tab 우선)
        await _launchUrlNative(url);
      }
    } catch (e) {
      print('URL 열기 실패: $e');
      _showErrorDialog(url);
    }
  }

  /// 네이티브 플랫폼에서 URL 열기
  static Future<void> _launchUrlNative(String url) async {
    final uri = Uri.parse(url);

    // URL 유효성 검사
    if (!uri.hasScheme) {
      throw 'Invalid URL: $url (no scheme)';
    }

    debugPrint('URI 파싱 완료: $uri');

    // canLaunchUrl 검사
    final canLaunch = await url_launcher.canLaunchUrl(uri);
    debugPrint('canLaunchUrl 결과: $canLaunch');

    if (canLaunch) {
      // Chrome Custom Tab으로 열기 시도
      final launched = await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.inAppBrowserView, // Chrome Custom Tab 사용
        browserConfiguration: const url_launcher.BrowserConfiguration(
          showTitle: true,
        ),
      );

      debugPrint('launchUrl 결과: $launched');

      if (!launched) {
        // Chrome Custom Tab 실패 시 외부 브라우저로 재시도
        debugPrint('Chrome Custom Tab 실패, 외부 브라우저로 재시도');
        await url_launcher.launchUrl(
          uri,
          mode: url_launcher.LaunchMode.externalApplication,
        );
      }
    } else {
      throw 'Cannot launch URL: $url';
    }
  }

  /// URL 열기 실패 시 오류 다이얼로그 표시
  static void _showErrorDialog(String url) {
    Get.dialog(
      AlertDialog(
        title: const Text('링크 열기 실패'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('링크를 열 수 없습니다.'),
            const SizedBox(height: 8),
            Text(
              'URL: $url',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('확인'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('알림', 'URL을 다시 확인해주세요.',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
