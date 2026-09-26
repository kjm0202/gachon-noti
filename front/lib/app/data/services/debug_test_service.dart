import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// 디버그 모드에서만 사용되는 테스트 알림 서비스.
///
/// Supabase Edge Function `send-test-notification`을 호출하여
/// 테스트 게시물을 DB에 삽입하고, 이 기기의 FCM 토큰으로만
/// 알림을 전송한다.
class DebugTestService {
  DebugTestService._();
  static final DebugTestService instance = DebugTestService._();

  /// 게시판 ID 목록 (앱에 정의된 것과 동일)
  static const boardIds = [
    'bachelor',
    'scholarship',
    'student',
    'job',
    'extracurricular',
    'other',
    'dormGlobal',
    'dormMedical',
  ];

  static const boardNames = {
    'bachelor': '학사',
    'scholarship': '장학',
    'student': '학생',
    'job': '취업',
    'extracurricular': '비교과',
    'other': '기타',
    'dormGlobal': '글로벌 기숙사',
    'dormMedical': '메디컬 기숙사',
  };

  /// 테스트 알림을 전송한다.
  ///
  /// [boardId]가 null이면 'bachelor'로 기본 설정된다.
  /// 성공 시 서버 응답 Map을, 실패 시 예외를 던진다.
  Future<Map<String, dynamic>> sendTestNotification({
    String? boardId,
  }) async {
    if (!kDebugMode) {
      throw StateError('디버그 모드에서만 사용할 수 있습니다.');
    }

    // 이 기기의 FCM 토큰 가져오기
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      throw StateError('FCM 토큰을 가져올 수 없습니다. 알림 권한을 확인해주세요.');
    }

    debugPrint('🧪 테스트 알림 전송 시작 (boardId: ${boardId ?? "bachelor"})');
    debugPrint('🧪 FCM 토큰: ${fcmToken.substring(0, 20)}...');

    final db = Get.find<SupabaseService>().client;

    try {
      // Supabase Edge Function 호출
      final response = await db.functions.invoke(
        'send-test-notification',
        body: {
          'fcmToken': fcmToken,
          'boardId': boardId ?? 'bachelor',
        },
      );

      final data = response.data as Map<String, dynamic>?;

      if (data == null) {
        throw StateError(
            'Edge Function 응답이 비어있습니다. (status: ${response.status})');
      }

      if (data['success'] != true) {
        final error = data['error'] ?? '알 수 없는 오류';
        throw StateError('테스트 알림 전송 실패: $error');
      }

      debugPrint('🧪 테스트 알림 전송 성공: ${data['title']}');
      return data;
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] != null) {
        throw StateError('${details['error']}');
      }
      throw StateError(
          'Edge Function 오류 (${e.status}): ${e.reasonPhrase ?? e.toString()}');
    }
  }
}
