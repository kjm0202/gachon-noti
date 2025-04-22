import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'
    show PlatformDispatcher, defaultTargetPlatform, kIsWeb;
import 'package:web/web.dart' as web;
import 'dart:async';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  late final SupabaseClient _supabase;
  String? _userId;
  String? _userEmail;
  StreamSubscription<AuthState>? _authSubscription;
  Function? _pendingLoginSuccess;

  void init() {
    _supabase = Supabase.instance.client;

    // 인증 상태 변화 구독
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('인증 상태 변경: $event');

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('로그인 성공: ${session.user.email}');
        _userId = session.user.id;
        _userEmail = session.user.email;

        // 보류 중인 성공 콜백이 있으면 실행
        if (_pendingLoginSuccess != null) {
          _pendingLoginSuccess!();
          _pendingLoginSuccess = null;
        }
      } else if (event == AuthChangeEvent.signedOut) {
        print('로그아웃');
        _userId = null;
        _userEmail = null;
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userId != null;

  Future<bool> checkCurrentSession() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        _userEmail = currentUser.email;
        _userId = currentUser.id;
        return true;
      }
      return false;
    } catch (e) {
      print('No active session: $e');
      _userEmail = null;
      _userId = null;
      return false;
    }
  }

  Future<bool> loginWithGoogle({
    required BuildContext context,
    required Function onLoginSuccess,
    required Function onLoginFailed,
  }) async {
    try {
      // 로그인 성공 콜백 저장 (인증 상태 변경 시 호출)
      _pendingLoginSuccess = onLoginSuccess;

      String? redirectUrl;

      if (kIsWeb) {
        // 웹에서 리다이렉트 URL 설정 (origin만 사용)
        final origin = web.window.location.origin;
        redirectUrl = origin;
        print('리다이렉트 URL: $redirectUrl');
      } else {
        // 모바일 앱에서는 딥링크 URL 설정
        redirectUrl = 'io.supabase.flutterquickstart://login-callback';
      }

      await _supabase.auth.signInWithOAuth(
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

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')));
      }
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _supabase.auth.signOut();
      _userEmail = null;
      _userId = null;
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
