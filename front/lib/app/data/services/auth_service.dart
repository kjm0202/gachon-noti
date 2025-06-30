import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'supabase_service.dart';
import 'firebase_service.dart';
import '../../utils/platform_utils.dart';

class AuthService extends GetxService {
  final SupabaseProvider _supabaseProvider = Get.find<SupabaseProvider>();
  late final FirebaseService _firebaseProvider;
  late final GoogleSignIn _googleSignIn;

  final RxString userId = RxString('');
  final RxString userEmail = RxString('');
  final RxBool isLoggedIn = false.obs;

  StreamSubscription<AuthState>? _authSubscription;
  Function? _pendingLoginSuccess;

  Future<AuthService> init() async {
    _firebaseProvider = FirebaseService();

    // Google Sign In 초기화 (모바일용)
    if (!kIsWeb) {
      _googleSignIn = GoogleSignIn(
        serverClientId:
            '1006219923383-jmos7nbuisvh963o7uful7rsentp9i3e.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
    }

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

      if (kIsWeb) {
        // 웹에서는 Supabase OAuth 방식 사용
        String? redirectUrl = WebUtils.getCurrentOrigin();

        await _supabaseProvider.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: redirectUrl,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      } else {
        // iOS/Android에서는 google_sign_in 패키지 사용
        print('모바일에서 Google 로그인 시작');

        // 기존 로그인 상태 확인 및 로그아웃
        if (await _googleSignIn.isSignedIn()) {
          await _googleSignIn.signOut();
        }

        // Google 로그인 시도
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // 사용자가 로그인을 취소함
          print('Google 로그인이 취소되었습니다');
          onLoginFailed();
          _pendingLoginSuccess = null;
          return false;
        }

        // Google 인증 정보 획득
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          print('Google ID 토큰을 가져올 수 없습니다');
          onLoginFailed();
          _pendingLoginSuccess = null;
          return false;
        }

        print('Google 로그인 성공, Supabase 인증 진행 중...');

        // Supabase에 Google ID 토큰으로 로그인
        final AuthResponse response =
            await _supabaseProvider.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: googleAuth.idToken!,
          accessToken: googleAuth.accessToken,
        );

        if (response.user != null) {
          print('Supabase 인증 성공: ${response.user!.email}');
          // onAuthStateChange에서 처리됨
          return true;
        } else {
          print('Supabase 인증 실패');
          onLoginFailed();
          _pendingLoginSuccess = null;
          return false;
        }
      }

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

      // Google Sign In 로그아웃 (모바일에서만)
      if (!kIsWeb && await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

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
