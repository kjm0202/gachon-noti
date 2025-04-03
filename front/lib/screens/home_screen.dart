import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:front/boards_selection.dart';
import 'package:front/posts_page.dart';
import '../services/auth_services.dart';
import '../services/firebase_services.dart';

class HomeScreen extends StatefulWidget {
  final Client client;

  const HomeScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    await _authService.logout();
    // 로그아웃 처리 및 화면 전환 등의 로직
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BoardSelectionPage(client: widget.client),
      PostsPage(client: widget.client, boardId: 'all'),
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
