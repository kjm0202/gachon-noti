import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'supabase_service.dart';
import 'firebase_service.dart';
import 'qonversion_service.dart';
import 'adfree_service.dart';

class AuthService extends GetxService {
  final SupabaseService _supabaseProvider = Get.find<SupabaseService>();
  late final FirebaseService _firebaseProvider;

  final RxString userId = RxString('');
  final RxString userEmail = RxString('');
  final RxBool isLoggedIn = false.obs;

  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _googleAuthSubscription;
  Function? _pendingLoginSuccess;

  Future<AuthService> init() async {
    _firebaseProvider = FirebaseService();

    // 7.x: GoogleSignIn is now a singleton accessed via GoogleSignIn.instance
    // initialize() must be called exactly once before any other methods
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '1006219923383-jmos7nbuisvh963o7uful7rsentp9i3e.apps.googleusercontent.com',
    );

    // 7.x: Subscribe to authentication events stream to track sign-in state
    _googleAuthSubscription = GoogleSignIn.instance.authenticationEvents
        .listen(_handleGoogleAuthEvent)
      ..onError(_handleGoogleAuthError);

    // NOTE:
    // Do not trigger lightweight auth automatically on app startup.
    // On some Android devices this can surface an account selection/sign-in UI,
    // which looks like an unwanted login popup on every launch.
    // We treat Supabase session as the source of truth for auto-login,
    // and only run interactive Google auth when the user explicitly taps login.

    // 인증 상태 변화 구독 (Supabase)
    _authSubscription =
        _supabaseProvider.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        userId.value = session.user.id;
        userEmail.value = session.user.email ?? '';
        isLoggedIn.value = true;

        // 보류 중인 성공 콜백이 있으면 실행
        if (_pendingLoginSuccess != null) {
          _pendingLoginSuccess!();
          _pendingLoginSuccess = null;
        }
      } else if (event == AuthChangeEvent.signedOut) {
        userId.value = '';
        userEmail.value = '';
        isLoggedIn.value = false;
      }
    });

    await checkCurrentSession();

    return this;
  }

  // 7.x: Handle authentication events from Google Sign-In stream
  Future<void> _handleGoogleAuthEvent(
      GoogleSignInAuthenticationEvent event) async {
    if (event is GoogleSignInAuthenticationEventSignIn) {
      // User signed in via Google.
      // For Supabase token exchange, this is handled in loginWithGoogle().
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      // Google sign-out event received
    }
  }

  void _handleGoogleAuthError(Object error) {
    if (error is GoogleSignInException) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        // Ignore cancellation, log other errors
        debugPrint(
            'Google Sign-In error: ${error.code} - ${error.description}');
      }
    }
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _googleAuthSubscription?.cancel();
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
      debugPrint('No active session: $e');
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

      // 7.x: Use authenticate() instead of signIn().
      // On platforms that don't support authenticate() (e.g., web),
      // supportsAuthenticate() returns false — but this is mobile-only.
      // authenticate() throws GoogleSignInException with code.canceled if user cancels.
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      // 7.x: authentication is now a SYNCHRONOUS property (no await).
      // idToken is available from authentication; accessToken requires
      // separate authorization via authorizationClient.
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        debugPrint('Google ID 토큰을 가져올 수 없습니다');
        onLoginFailed();
        _pendingLoginSuccess = null;
        return false;
      }

      // 7.x: Get accessToken for Supabase via authorizationClient.
      // Try silently first; the openid/email/profile scopes are required.
      const List<String> scopes = <String>['email', 'openid', 'profile'];
      final GoogleSignInClientAuthorization? authorization =
          await googleUser.authorizationClient.authorizationForScopes(scopes);

      // Supabase에 Google ID 토큰으로 로그인
      final AuthResponse response =
          await _supabaseProvider.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: authorization?.accessToken,
      );

      if (response.user != null) {
        // onAuthStateChange에서 처리됨
        return true;
      } else {
        onLoginFailed();
        _pendingLoginSuccess = null;
        return false;
      }
    } on GoogleSignInException catch (e) {
      // 7.x: Exceptions are thrown for cancellation and other failures
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // 사용자가 로그인을 취소함
        debugPrint('Google 로그인이 취소되었습니다');
      } else {
        debugPrint('Google Sign-In 실패: ${e.code} - ${e.description}');
        Get.snackbar(
          '로그인 실패',
          '로그인에 실패했습니다. 다시 시도해주세요.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      onLoginFailed();
      _pendingLoginSuccess = null;
      return false;
    } catch (e) {
      debugPrint('Login failed: $e');
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

  /// SHA256 해시를 생성하기 위한 32자 무작위 raw nonce 생성
  String _generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// 문자열을 SHA256으로 해시
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Apple 로그인
  Future<bool> loginWithApple({
    required Function onLoginSuccess,
    required Function onLoginFailed,
  }) async {
    try {
      _pendingLoginSuccess = onLoginSuccess;

      final rawNonce = _generateRawNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        debugPrint('Apple ID 토큰을 가져올 수 없습니다');
        onLoginFailed();
        _pendingLoginSuccess = null;
        return false;
      }

      // Supabase에 Apple ID 토큰으로 로그인
      final response = await _supabaseProvider.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      if (response.user != null) {
        // onAuthStateChange에서 처리됨
        return true;
      } else {
        onLoginFailed();
        _pendingLoginSuccess = null;
        return false;
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('Apple 로그인이 취소되었습니다');
      } else {
        debugPrint('Apple Sign-In 실패: ${e.code} - ${e.message}');
        Get.snackbar(
          '로그인 실패',
          '로그인에 실패했습니다. 다시 시도해주세요.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      onLoginFailed();
      _pendingLoginSuccess = null;
      return false;
    } catch (e) {
      debugPrint('Apple login failed: $e');
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

      // RLS requires the current session to remove this device.
      if (currentUserId.isNotEmpty) {
        await _firebaseProvider.removeFcmToken(currentUserId);
      }

      // 현재 로그인 provider 확인 후 Google인 경우에만 Google Sign-Out
      final currentProvider =
          _supabaseProvider.client.auth.currentUser?.appMetadata['provider'];
      if (currentProvider == 'google') {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (googleError) {
          debugPrint('Google Sign-In signOut error: $googleError');
        }
      }

      // Supabase 로그아웃 처리
      await _supabaseProvider.client.auth.signOut();

      // 상태 초기화
      userEmail.value = '';
      userId.value = '';
      isLoggedIn.value = false;

      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }

  // 사용자 회원탈퇴 처리
  Future<bool> deleteAccount() async {
    try {
      final currentUserId = userId.value;
      if (currentUserId.isEmpty) {
        throw StateError('로그인된 계정 정보를 찾을 수 없습니다.');
      }

      // 1. FCM 토큰 삭제 (DB 및 로컬)
      try {
        await _firebaseProvider.removeFcmToken(currentUserId);
      } catch (e) {
        debugPrint('FCM 토큰 정리 중 오류 (계속 진행): $e');
      }

      // 2. Supabase Edge Function 'delete-account' 호출
      try {
        final response = await _supabaseProvider.client.functions.invoke(
          'delete-account',
        );

        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['success'] != true) {
          final error = data['error'] ?? '알 수 없는 오류가 발생했습니다.';
          throw StateError(error.toString());
        }
      } on FunctionException catch (e) {
        final details = e.details;
        if (details is Map && details['error'] != null) {
          throw StateError(details['error'].toString());
        }
        throw StateError(
            '회원탈퇴 처리 실패 (${e.status}): ${e.reasonPhrase ?? e.toString()}');
      }

      // 3. Google Sign-In 연동 해제 (Google 계정으로 로그인한 경우에만 disconnect 호출)
      final currentProvider =
          _supabaseProvider.client.auth.currentUser?.appMetadata['provider'];
      if (currentProvider == 'google') {
        try {
          await GoogleSignIn.instance.disconnect();
          debugPrint('Google Sign-In 연동 해제(disconnect) 완료');
        } catch (e) {
          debugPrint(
              'Google Sign-In disconnect error (falling back to signOut): $e');
          try {
            await GoogleSignIn.instance.signOut();
          } catch (signOutError) {
            debugPrint('Google Sign-In signOut error: $signOutError');
          }
        }
      }

      // 4. Supabase 로컬 세션 종료
      try {
        await _supabaseProvider.client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signOut error: $e');
      }

      // 5. Qonversion 및 광고 제거 상태 초기화
      try {
        if (Get.isRegistered<QonversionService>()) {
          await Get.find<QonversionService>().resetUser();
        }
        if (Get.isRegistered<AdFreeService>()) {
          Get.find<AdFreeService>().reset();
        }
      } catch (e) {
        debugPrint('Qonversion/AdFreeService reset error: $e');
      }

      // 6. Crashlytics 사용자 식별자 초기화
      try {
        await FirebaseCrashlytics.instance.setUserIdentifier('');
      } catch (e) {
        debugPrint('Crashlytics identifier reset error: $e');
      }

      // 7. 상태 초기화
      userEmail.value = '';
      userId.value = '';
      isLoggedIn.value = false;

      return true;
    } catch (e) {
      debugPrint('Delete account error: $e');
      rethrow;
    }
  }
}
