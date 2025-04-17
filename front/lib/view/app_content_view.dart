import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:gachon_noti_front/theme.dart';
import 'package:web/web.dart' as web;

import 'home_page.dart';
import 'login_page.dart';
import '../services/auth_services.dart';
import '../utils/version_checker.dart';

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
  bool _checkingForUpdates = false;

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

    // 앱 초기화 후 버전 확인
    _checkForUpdates();
  }

  // 버전 체크 함수
  Future<void> _checkForUpdates() async {
    if (_checkingForUpdates) return;

    setState(() {
      _checkingForUpdates = true;
    });

    try {
      final needsUpdate = await VersionChecker.needsUpdate();

      if (needsUpdate && mounted) {
        // 업데이트가 필요하면 스낵바 표시
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
            duration: const Duration(days: 365), // 매우 길게 설정하여 사용자가 닫기 전까지 유지
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('업데이트 확인 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _checkingForUpdates = false;
        });
      }
    }
  }

  // PWA 새로고침 함수
  void reloadPwa() {
    web.window.location.reload();
  }

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme();

    return MaterialApp(
      title: '가천 알림이',
      theme: materialTheme.light(),
      darkTheme: materialTheme.dark(),
      themeMode: ThemeMode.system,
      home: !_initialized ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Scaffold(
      body: _authService.isLoggedIn
          ? HomePage(client: widget.client)
          : LoginPage(
              onLoginSuccess: () {
                setState(() {}); // 로그인 후 화면 갱신
                // 로그인 성공 후 업데이트 확인
                _checkForUpdates();
              },
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
