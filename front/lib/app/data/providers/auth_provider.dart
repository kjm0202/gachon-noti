import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import 'dart:async';

import 'supabase_provider.dart';
import 'firebase_provider.dart';

class AuthProvider extends GetxService {
  final SupabaseProvider _supabaseProvider = Get.find<SupabaseProvider>();
  late final FirebaseProvider _firebaseProvider;

  final RxString userId = RxString('');
  final RxString userEmail = RxString('');
  final RxBool isLoggedIn = false.obs;

  StreamSubscription<AuthState>? _authSubscription;
  Function? _pendingLoginSuccess;

  Future<AuthProvider> init() async {
    _firebaseProvider = FirebaseProvider();

    // 인증 상태 변화 구독
    _authSubscription =
        _supabaseProvider.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('인증 상태 변경: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('로그인 성공: ${session.user.email}');
        userId.value = session.user.id;
        userEmail.value = session.user.email ?? '';
        isLoggedIn.value = true;

        // 보류 중인 성공 콜백이 있으면 실행
        if (_pendingLoginSuccess != null) {
          _pendingLoginSuccess!();
          _pendingLoginSuccess = null;
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('로그아웃');
        userId.value = '';
        userEmail.value = '';
        isLoggedIn.value = false;
      }
    });

    await checkCurrentSession();

    return this;
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    super.onClose();
  }

  Future<bool> checkCurrentSession() async {
    try {
      final currentUser = _supabaseProvider.client.auth.currentUser;
      if (currentUser != null) {
        userEmail.value = currentUser.email ?? '';
        userId.value = currentUser.id;
        isLoggedIn.value = true;
        return true;
      }
      isLoggedIn.value = false;
      return false;
    } catch (e) {
      print('No active session: $e');
      userEmail.value = '';
      userId.value = '';
      isLoggedIn.value = false;
      return false;
    }
  }

  Future<bool> loginWithGoogle({
    required Function onLoginSuccess,
    required Function onLoginFailed,
  }) async {
    try {
      // 로그인 성공 콜백 저장 (인증 상태 변경 시 호출)
      _pendingLoginSuccess = onLoginSuccess;

      String? redirectUrl;

      if (kIsWeb) {
        // 웹에서 리다이렉트 URL 설정 (origin만 사용)
        redirectUrl = web.window.location.origin;
      } else {
        // 모바일 앱에서는 딥링크 URL 설정
        redirectUrl = 'io.supabase.flutterquickstart://login-callback';
      }

      await _supabaseProvider.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode:
            (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS)
                ? LaunchMode.inAppBrowserView
                : LaunchMode.externalApplication,
      );

      // 웹에서는 리다이렉션이 발생하므로 여기에 도달하지 않을 수 있음
      // 대신 onAuthStateChange 이벤트에서 처리
      return true;
    } catch (e) {
      print('Login failed: $e');
      onLoginFailed();
      _pendingLoginSuccess = null;

      Get.snackbar(
        '로그인 실패',
        '로그인에 실패했습니다. 다시 시도해주세요.',
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    }
  }

  // 사용자 로그아웃 처리
  Future<bool> logout() async {
    try {
      // 현재 유저 ID 저장 (로그아웃 후에는 사라지므로)
      final currentUserId = userId.value;

      // Supabase 로그아웃 처리
      await _supabaseProvider.client.auth.signOut();

      // FCM 토큰 삭제 처리
      if (currentUserId.isNotEmpty) {
        await _firebaseProvider.removeFcmToken(currentUserId);
      }

      // 상태 초기화
      userEmail.value = '';
      userId.value = '';
      isLoggedIn.value = false;

      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
