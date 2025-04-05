import 'package:flutter/material.dart';
import '../services/auth_services.dart';

class LoginScreen extends StatefulWidget {
  final Function onLoginSuccess;

  const LoginScreen({Key? key, required this.onLoginSuccess}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가천대학교 공지사항')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '가천대학교 공지사항 알림 서비스',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            if (_isLoggingIn)
              CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _login,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login),
                      SizedBox(width: 8),
                      Text('Google 계정으로 로그인'),
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
    setState(() {
      _isLoggingIn = true;
    });

    await _authService.loginWithGoogle(
      context: context,
      onLoginSuccess: () {
        setState(() {
          _isLoggingIn = false;
        });
        widget.onLoginSuccess();
      },
      onLoginFailed: () {
        setState(() {
          _isLoggingIn = false;
        });
      },
    );
  }
}
