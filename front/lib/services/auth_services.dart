import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  late Account _account;
  String? _userId;
  String? _userEmail;

  void init(Client client) {
    _account = Account(client);
  }

  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _userId != null;

  Future<bool> checkCurrentSession() async {
    try {
      final user = await _account.get();
      _userEmail = user.email;
      _userId = user.$id;
      return true;
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
      // 현재 URL을 기반으로 success/failure URL 설정
      final currentUrl = web.window.location.href;
      final successUrl = currentUrl;
      final failureUrl = currentUrl;

      // OAuth 세션 생성 시도
      await _account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: successUrl,
        failure: failureUrl,
      );

      // 세션 생성 후 상태 확인 (최대 3번 시도)
      int attempts = 0;
      while (attempts < 3) {
        try {
          final user = await _account.get();
          _userEmail = user.email;
          _userId = user.$id;
          onLoginSuccess();
          return true;
        } catch (e) {
          print('Session check attempt ${attempts + 1} failed: $e');
          await Future.delayed(Duration(seconds: 1));
          attempts++;
        }
      }

      // 3번 시도 후에도 실패
      onLoginFailed();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 정보를 가져오는데 실패했습니다. 페이지를 새로고침해주세요.')),
        );
      }
      return false;
    } catch (e) {
      print('Login failed: $e');
      onLoginFailed();
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
      await _account.deleteSession(sessionId: 'current');
      _userEmail = null;
      _userId = null;
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }
}
