import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gachon_noti_front/utils/alternative_text_style.dart';
import '../controller/login_controller.dart';

class LoginPage extends StatefulWidget {
  final Function onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController _controller = LoginController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가천 알림이')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_controller.isLoggingIn)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: 24,
                        height: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Google 계정으로 로그인',
                        style: AltTextStyle.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    await _controller.loginWithGoogle(
      context: context,
      onLoginSuccess: widget.onLoginSuccess,
      onLoginFailed: () {
        // 로그인 실패 시 처리 (예: 에러 메시지 표시)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')));
      },
      onStateChange: () {
        // 상태 변경 시 UI 업데이트
        setState(() {});
      },
    );
  }
}
