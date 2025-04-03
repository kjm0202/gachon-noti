import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front/firebase_options.dart';
import 'package:front/screens/home_screen.dart';
import 'package:front/screens/login_screen.dart';
import 'package:front/services/auth_services.dart';
import 'package:front/const.dart';
import 'package:web/web.dart' as web;

// PWA 모드인지 확인하는 함수
bool isPwaMode() {
  return web.window.matchMedia('(display-mode: standalone)').matches ||
      web.window.matchMedia('(display-mode: fullscreen)').matches ||
      web.window.matchMedia('(display-mode: minimal-ui)').matches;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // URL에서 세션 콜백 확인
  final Uri currentUrl = Uri.parse(web.window.location.href);
  final bool isRedirect = currentUrl.path.contains('auth-callback');

  if (isRedirect) {
    // 부모 창으로 메시지 전송 후 현재 창 닫기
    (web.window.opener as dynamic)?.postMessage('login-success', '*');
    web.window.close();
    return;
  }

  // PWA 모드 확인
  final bool isPwa = isPwaMode();
  Client? client;

  // PWA 모드일 때만 Firebase와 Appwrite 초기화
  if (isPwa) {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Appwrite 클라이언트 초기화
    client = Client().setEndpoint(API.apiUrl).setProject(API.projectId);
  }

  runApp(isPwa ? AppContent(client: client!) : PwaInstallScreen());
}

// PWA 모드가 아닐 때 표시되는 화면
class PwaInstallScreen extends StatelessWidget {
  const PwaInstallScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '가천대학교 공지사항',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: _PwaInstallScreenContent(),
    );
  }
}

class _PwaInstallScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('가천대학교 공지사항')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_to_home_screen, size: 80, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'PWA로 설치 필요',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                '이 앱은 홈 화면에 설치하여 사용해야 합니다. 브라우저 메뉴에서 "홈 화면에 추가" 옵션을 선택해주세요.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // 설치 방법에 대한 상세 안내 다이얼로그 표시
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('설치 방법'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chrome 브라우저:'),
                              Text('1. 오른쪽 상단 메뉴(⋮) 클릭'),
                              Text('2. "앱 설치" 또는 "홈 화면에 추가" 선택'),
                              SizedBox(height: 8),
                              Text('Safari 브라우저:'),
                              Text('1. 하단 공유 버튼 클릭'),
                              Text('2. "홈 화면에 추가" 선택'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('확인'),
                            ),
                          ],
                        ),
                  );
                },
                child: Text('설치 방법 보기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 실제 앱 컨텐츠 (PWA 모드일 때 표시)
class AppContent extends StatefulWidget {
  final Client client;

  const AppContent({Key? key, required this.client}) : super(key: key);

  @override
  State<AppContent> createState() => _AppContentState();
}

class _AppContentState extends State<AppContent> {
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gachon Notices',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home:
          !_initialized
              ? _buildLoadingScreen()
              : _authService.isLoggedIn
              ? HomeScreen(client: widget.client)
              : LoginScreen(
                onLoginSuccess: () {
                  setState(() {}); // 로그인 후 화면 갱신
                },
              ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
