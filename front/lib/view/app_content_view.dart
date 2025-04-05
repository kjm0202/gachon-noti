import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:pwa_update_listener/pwa_update_listener.dart';
import 'package:web/web.dart' as web;

import 'home_page.dart';
import 'login_page.dart';
import '../services/auth_services.dart';

// 실제 앱 컨텐츠 (PWA 모드일 때 표시)
class AppContentView extends StatefulWidget {
  final Client client;

  const AppContentView({super.key, required this.client});

  @override
  State<AppContentView> createState() => _AppContentViewState();
}

class _AppContentViewState extends State<AppContentView> {
  final _authService = AuthService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    _authService.init(widget.client);
    await _authService.checkCurrentSession();
    setState(() {
      _initialized = true;
    });
  }

  // PWA 새로고침 함수
  void reloadPwa() {
    web.window.location.reload();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가천 알림이',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home:
          !_initialized
              ? _buildLoadingScreen()
              : PwaUpdateListener(
                onReady: () {
                  /// 새 버전이 준비되면 SnackBar 표시
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Expanded(child: Text('새로운 업데이트가 준비되었습니다.')),
                          TextButton(
                            onPressed: () {
                              reloadPwa(); // 앱 새로고침
                            },
                            child: const Text('업데이트'),
                          ),
                        ],
                      ),
                      duration: const Duration(
                        days: 365,
                      ), // 매우 길게 설정하여 사용자가 닫기 전까지 유지
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child:
                    _authService.isLoggedIn
                        ? HomePage(client: widget.client)
                        : LoginPage(
                          onLoginSuccess: () {
                            setState(() {}); // 로그인 후 화면 갱신
                          },
                        ),
              ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
