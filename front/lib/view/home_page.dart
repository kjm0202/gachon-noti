import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:web/web.dart' as web;
import 'package:package_info_plus/package_info_plus.dart';

import 'subscription_view.dart';
import 'posts_view.dart';
import '../services/auth_services.dart';
import '../services/firebase_services.dart';
import '../utils/korean_wrapper.dart';

class HomePage extends StatefulWidget {
  final Client client;

  const HomePage({super.key, required this.client});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _authService = AuthService();
  final _firebaseService = FirebaseService();
  late Databases _databases;
  String? _fcmToken;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _initServices();
  }

  Future<void> _initServices() async {
    await _authService.checkCurrentSession();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    // 현재 알림 권한 상태 확인
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();

    // 아직 허용되지 않은 경우에만 다이얼로그 표시
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('알림 권한 요청'),
              content: Text('\'확인\' 버튼을 누른 뒤 나오는 팝업에서 알림 권한을 허용해주세요.'.wrapped),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                ),
              ],
            ),
      );
    }

    _fcmToken = await _firebaseService.initFCM(
      databases: _databases,
      userId: _authService.userId,
      onTokenRefresh: (token) {
        setState(() {
          _fcmToken = token;
        });
      },
      showInAppNotification: _showInAppNotification,
      handleNotificationClick: _handleNotificationClick,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('⚠️알림 권한 거부됨'),
              content: AutoSizeText('''
알림 권한이 거부되어 알림을 받을 수 없어요. 
실수로 거부를 누르셨다면,
앱 삭제 후 다시 설치하여 진행해주세요.
'''),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                ),
              ],
            ),
      );
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    if (!mounted) return;

    final notification = message.notification;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification?.title ?? '새 알림'),
        action: SnackBarAction(
          label: '보기',
          onPressed: () {
            _handleNotificationClick(message);
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final String? boardId = data['boardId'];

    // 알림을 통해 특정 게시판이나 게시글로 이동
    setState(() {
      _currentIndex = 1; // 전체 게시물 탭으로 전환
    });
  }

  Future<void> _logout() async {
    await showAdaptiveDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('로그아웃'),
            content: Text('로그아웃 하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // 다이얼로그 닫기

                  // 로그아웃 처리
                  await _authService.logout();

                  // 웹 브라우저 새로고침을 통해 앱 전체 리로드
                  // AppContentView가 다시 로드되며 isLoggedIn 상태 확인
                  web.window.location.reload();
                },
                child: Text('확인'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      SubscriptionView(client: widget.client),
      PostsView(client: widget.client, boardId: 'all'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? '구독 설정' : '전체 게시물'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () async {
              final packageInfo = await PackageInfo.fromPlatform();
              if (context.mounted) {
                showAboutDialog(
                  context: context,
                  applicationName: '가천 알림이',
                  applicationVersion: packageInfo.version,
                  applicationIcon: Image.asset(
                    'assets/icons/app_icon.png',
                    width: 48,
                    height: 48,
                  ),
                  children: [
                    AutoSizeText('Made by 무적소웨 졸업생'),
                    AutoSizeText('이 앱은 가천대학교 공식 앱이 아닙니다.'),
                  ],
                );
              }
            },
            tooltip: '앱 정보',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.notifications),
            label: '구독 설정',
          ),
          NavigationDestination(icon: Icon(Icons.article), label: '전체 게시물'),
        ],
      ),
    );
  }
}
