import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:web/web.dart' as web;
import 'package:pwa_install/pwa_install.dart';
import 'package:pwa_update_listener/pwa_update_listener.dart';

import './firebase_options.dart';
import 'view/home_screen.dart';
import 'view/login_screen.dart';
import './services/auth_services.dart';
import 'utils/const.dart';

// PWA 모드인지 확인하는 함수
bool isPwaMode() {
  return web.window.matchMedia('(display-mode: standalone)').matches;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // PWA 설치 확인
  PWAInstall().setup(
    installCallback: () {
      debugPrint('APP INSTALLED!');
    },
  );

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
  const PwaInstallScreen({super.key});

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
                '이 앱은 기기의 홈 화면에 설치하여 사용해야 합니다. 아래 설치 버튼을 누르시거나, 브라우저 메뉴에서 "홈 화면에 추가" 옵션을 선택해주세요.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (defaultTargetPlatform == TargetPlatform.iOS) {
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => Container(
                            child: Column(
                              children: [
                                Text(
                                  'iOS 설치 방법 (Safari 권장)',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Row(
                                  children: [
                                    Text('1. 메뉴 바의 공유('),
                                    Icon(
                                      CupertinoIcons.share,
                                      size: 14,
                                      color: Color(0xFF007AFF),
                                    ),
                                    Text(') 버튼 클릭'),
                                  ],
                                ),
                                Text('2. 공유 메뉴에서 "홈 화면에 추가" 선택'),
                                Text('3. 홈 화면에 앱이 설치되면 눌러서 실행'),
                              ],
                            ),
                          ),
                    );
                  } else {
                    PWAInstall().promptInstall_();
                    if (defaultTargetPlatform == TargetPlatform.windows) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Windows에서는 설치 후 F5를 눌러 새로고침 해주세요.'),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
                child: Text('설치'),
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

  const AppContent({super.key, required this.client});

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

  // PWA 새로고침 함수
  /* void reloadPwa() {
    web.window.location.reload();
  } */

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
                          Expanded(child: Text('새로운 업데이트가 준비되었습니다.')),
                          TextButton(
                            onPressed: () {
                              reloadPwa(); // 앱 새로고침
                            },
                            child: Text('업데이트'),
                          ),
                        ],
                      ),
                      duration: Duration(
                        days: 365,
                      ), // 매우 길게 설정하여 사용자가 닫기 전까지 유지
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child:
                    _authService.isLoggedIn
                        ? HomeScreen(client: widget.client)
                        : LoginScreen(
                          onLoginSuccess: () {
                            setState(() {}); // 로그인 후 화면 갱신
                          },
                        ),
              ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
