import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class LoginController {
  final AuthService _authService = AuthService();
  bool isLoggingIn = false;

  Future<void> loginWithGoogle({
    required BuildContext context,
    required Function onLoginSuccess,
    required Function onLoginFailed,
    required Function onStateChange,
  }) async {
    // 로그인 상태 변경
    isLoggingIn = true;
    onStateChange();

    // Google 로그인 실행
    await _authService.loginWithGoogle(
      context: context,
      onLoginSuccess: () {
        isLoggingIn = false;
        onStateChange();
        onLoginSuccess();
      },
      onLoginFailed: () {
        isLoggingIn = false;
        onStateChange();
        onLoginFailed();
      },
    );
  }
}
