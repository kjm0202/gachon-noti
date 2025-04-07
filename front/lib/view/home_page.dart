import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:web/web.dart' as web;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async'; // Timer 사용을 위한 import 추가

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
  bool _isNotificationDenied = false; // 알림 권한 거부 상태 저장
  bool _isShowingDialog = false; // 다이얼로그 표시 중 여부 플래그
  Timer? _permissionCheckTimer; // 권한 확인 타이머
  AuthorizationStatus? _lastAuthStatus; // 마지막으로 확인한 권한 상태
  DateTime? _lastDialogTime; // 마지막 다이얼로그 표시 시간

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _initServices();
  }

  @override
  void dispose() {
    // 타이머 정리
    _permissionCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initServices() async {
    await _authService.checkCurrentSession();
    await _initFirebase();

    // 권한 상태 변경 리스너 설정
    _setupAuthorizationListener();
  }

  void _setupAuthorizationListener() {
    // FirebaseMessaging의 권한 상태 변경 감지
    FirebaseMessaging.instance.onTokenRefresh.listen((_) async {
      // 토큰이 갱신될 때 권한 상태 다시 확인
      await _checkNotificationPermission();
    });

    // 앱이 포그라운드 상태로 돌아올 때마다 권한 상태 확인
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 앱이 활성화될 때 권한 상태 확인
      _checkNotificationPermission();
    });

    // 권한 요청 직후 짧은 간격으로 상태 확인
    _startPermissionPolling();
  }

  void _startPermissionPolling() {
    // 기존 타이머 취소
    _permissionCheckTimer?.cancel();

    // 짧은 간격으로 최대 5번만 체크 (과도한 체크 방지)
    int checkCount = 0;
    _permissionCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      checkCount++;
      await _checkNotificationPermission(isFromPolling: true);

      // 5번 체크 후 타이머 종료 (2.5초)
      if (checkCount >= 5) {
        timer.cancel();

        // 마지막 확인 한번 더 (3초 후)
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _checkNotificationPermission(isFromPolling: true);
          }
        });
      }
    });
  }

  // 알림 권한 상태 확인 및 처리
  Future<void> _checkNotificationPermission({
    bool isFromPolling = false,
  }) async {
    if (!mounted) return;

    // 이미 다이얼로그를 표시 중이면 중복 체크 방지
    if (_isShowingDialog) return;

    try {
      NotificationSettings settings =
          await FirebaseMessaging.instance.getNotificationSettings();

      final currentStatus = settings.authorizationStatus;
      final bool statusChanged = _lastAuthStatus != currentStatus;

      // 상태가 변경되었고, 현재 거부 상태인 경우에만 다이얼로그 표시
      if (statusChanged && currentStatus == AuthorizationStatus.denied) {
        // 마지막 다이얼로그 표시 후 10초 이내에는 다시 표시하지 않음 (중복 방지)
        final now = DateTime.now();
        if (_lastDialogTime != null &&
            now.difference(_lastDialogTime!).inSeconds < 10) {
          return;
        }

        // 권한이 새롭게 거부된 경우 팝업 표시
        if (mounted) {
          await _showNotificationDeniedDialog();
        }
      }

      // 마지막 확인 상태 업데이트
      _lastAuthStatus = currentStatus;

      // UI 상태 업데이트
      if (mounted) {
        setState(() {
          _isNotificationDenied = currentStatus == AuthorizationStatus.denied;
        });
      }

      // 폴링 중이 아닐 때만 폴링 시작 (초기 로드 또는 권한 요청 시만)
      if (statusChanged &&
          !isFromPolling &&
          currentStatus != AuthorizationStatus.notDetermined) {
        _startPermissionPolling();
      }
    } catch (e) {
      print('알림 권한 확인 중 오류 발생: $e');
    }
  }

  Future<void> _initFirebase() async {
    // 현재 알림 권한 상태 확인
    NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();

    // 마지막 확인 상태 초기화
    _lastAuthStatus = settings.authorizationStatus;

    // 알림 권한 상태에 따른 UI 업데이트
    setState(() {
      _isNotificationDenied =
          settings.authorizationStatus == AuthorizationStatus.denied;
    });

    // 아직 허용되지 않은 경우에만 다이얼로그 표시
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: Text('알림 권한 요청'),
              content: Text('\'확인\' 버튼을 누른 뒤 나오는 팝업에서 알림 권한을 허용해주세요.'.wrapped),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // 권한 요청 직후 상태 변경 감지 시작
                    _requestNotificationPermission();
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
        // 토큰이 새로 발급되면 권한 상태도 다시 확인
        _checkNotificationPermission();
      },
      showInAppNotification: _showInAppNotification,
      handleNotificationClick: _handleNotificationClick,
    );

    // 초기 실행 시 알림 권한이 거부 상태인 경우 다이얼로그 표시
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (!mounted) return;
      await _showNotificationDeniedDialog();
    }
  }

  // 알림 권한 직접 요청 및 상태 모니터링 시작
  Future<void> _requestNotificationPermission() async {
    try {
      // 권한 요청
      await FirebaseMessaging.instance.requestPermission();
      // 권한 요청 직후 상태 변화 모니터링 시작
      _startPermissionPolling();
    } catch (e) {
      print('알림 권한 요청 중 오류: $e');
    }
  }

  // 알림 권한 거부 안내 다이얼로그 표시 함수
  Future<void> _showNotificationDeniedDialog() async {
    if (!mounted || _isShowingDialog) return;

    // 다이얼로그 표시 상태 및 시간 기록
    _isShowingDialog = true;
    _lastDialogTime = DateTime.now();

    try {
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('⚠️ 알림 권한 거부됨'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoSizeText(
                    '알림 권한이 거부되어 알림을 받을 수 없어요.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  AutoSizeText(
                    '실수로 거부를 누르셨다면, ',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  AutoSizeText(
                    '앱 삭제 후 다시 설치하여 진행해주세요.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
    } finally {
      // 다이얼로그가 닫히면 상태 업데이트
      if (mounted) {
        _isShowingDialog = false;
      }
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
          // 알림 권한이 거부된 경우 경고 아이콘 표시
          if (_isNotificationDenied)
            IconButton(
              icon: Icon(Icons.notification_important, color: Colors.amber),
              onPressed: _showNotificationDeniedDialog,
              tooltip: '알림 권한 거부됨',
            ),
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
