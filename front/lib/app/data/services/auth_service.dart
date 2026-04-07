import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

import 'supabase_service.dart';
import 'firebase_service.dart';

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

    // 7.x: attemptLightweightAuthentication replaces signInSilently.
    // It may or may not return a Future depending on the platform.
    // We use the stream-based approach, so we don't await the result here.
    GoogleSignIn.instance.attemptLightweightAuthentication();

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
      // User signed in via Google (e.g., via lightweight auth).
      // For Supabase token exchange, this is handled in loginWithGoogle().
    } else if (event is GoogleSignInAuthenticationEventSignOut) {
      // Google sign-out event received
    }
  }

  void _handleGoogleAuthError(Object error) {
    if (error is GoogleSignInException) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        // Ignore cancellation, log other errors
        // ignore: avoid_print
        print('Google Sign-In error: ${error.code} - ${error.description}');
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
      // ignore: avoid_print
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
        // ignore: avoid_print
        print('Google ID 토큰을 가져올 수 없습니다');
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
        // ignore: avoid_print
        print('Google 로그인이 취소되었습니다');
      } else {
        // ignore: avoid_print
        print('Google Sign-In 실패: ${e.code} - ${e.description}');
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
      // ignore: avoid_print
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

      // 7.x: Sign out from Google Sign-In.
      // There is no isSignedIn() check in 7.x — just call signOut() directly.
      await GoogleSignIn.instance.signOut();

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
      // ignore: avoid_print
      print('Logout error: $e');
      return false;
    }
  }
}
