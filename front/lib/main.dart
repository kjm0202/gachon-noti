import 'dart:html' as html;
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:front/const.dart';
import 'package:front/boards_selection.dart';
import 'package:front/posts_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 - FCM용 최소 설정
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBVQHNNbqHXEZF6Qf3ZxOz-qxUvXrIUXQE', // FCM용 웹 API 키
      projectId: 'gachon-notice',
      messagingSenderId: '1234567890',
      appId: '1:1234567890:web:abcdef1234567890',
    ),
  );

  final client = Client().setEndpoint(API.apiUrl).setProject(API.projectId);

  // URL에서 세션 콜백 확인
  final Uri currentUrl = Uri.parse(html.window.location.href);
  final bool isRedirect = currentUrl.path.contains('auth-callback');

  if (isRedirect) {
    // 부모 창으로 메시지 전송 후 현재 창 닫기
    html.window.opener?.postMessage('login-success', '*');
    html.window.close();
    return;
  }

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final Client client;
  const MyApp({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gachon Notices',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(client: client),
    );
  }
}

class HomePage extends StatefulWidget {
  final Client client;
  const HomePage({Key? key, required this.client}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Account account;
  String? _fcmToken;
  late Databases databases;
  String? _userId;
  String? _userEmail;
  int _currentIndex = 0;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    account = Account(widget.client);
    databases = Databases(widget.client);
    _checkCurrentSession();
    _initFCM();

    // URL 파라미터 체크
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('success')) {
      _checkCurrentSession(); // 로그인 성공 후 리다이렉트된 경우 세션 체크
    }
  }

  Future<void> _checkCurrentSession() async {
    try {
      final user = await account.get();
      setState(() {
        _userEmail = user.email;
        _userId = user.$id;
      });
      if (_fcmToken != null && _userId != null) {
        await _saveFcmTokenToServer(_userId!, _fcmToken!);
      }
    } catch (e) {
      print('No active session: $e');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _isLoggingIn = true;
    });

    try {
      // 현재 URL을 기반으로 success/failure URL 설정
      final currentUrl = html.window.location.href;
      final successUrl = currentUrl;
      final failureUrl = currentUrl;

      // OAuth 세션 생성 시도
      await account.createOAuth2Session(
        provider: OAuthProvider.google,
        success: successUrl, // 현재 URL로 리다이렉트
        failure: failureUrl,
      );

      // 세션 생성 후 상태 확인 (최대 3번 시도)
      int attempts = 0;
      while (attempts < 3) {
        try {
          final user = await account.get();
          setState(() {
            _userEmail = user.email;
            _userId = user.$id;
            _isLoggingIn = false;
          });

          if (_fcmToken != null && _userId != null) {
            await _saveFcmTokenToServer(_userId!, _fcmToken!);
          }
          return; // 성공하면 종료
        } catch (e) {
          print('Session check attempt ${attempts + 1} failed: $e');
          await Future.delayed(Duration(seconds: 1)); // 1초 대기
          attempts++;
        }
      }

      // 3번 시도 후에도 실패하면 에러 표시
      setState(() {
        _isLoggingIn = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 정보를 가져오는데 실패했습니다. 페이지를 새로고침해주세요.')),
        );
      }
    } catch (e) {
      print('Login failed: $e');
      setState(() {
        _isLoggingIn = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')));
      }
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      setState(() {
        _userEmail = null;
        _userId = null;
        _currentIndex = 0;
      });
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Future<void> _initFCM() async {
    try {
      // FCM 권한 요청
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      print('FCM permission status: ${settings.authorizationStatus}');

      // 웹 환경에서는 VAPID 키가 필요
      final token = await FirebaseMessaging.instance.getToken(
        vapidKey: API.vapidKey,
      );
      print('FCM Token: $token');

      if (token != null) {
        setState(() {
          _fcmToken = token;
        });

        // 현재 세션이 있다면 토큰 저장
        try {
          final user = await account.get();
          _userId = user.$id;
          await _saveFcmTokenToServer(_userId!, token);
        } catch (e) {
          print('No user session yet: $e');
        }
      }

      // 토큰 갱신 리스너
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        setState(() {
          _fcmToken = newToken;
        });
        if (_userId != null) {
          await _saveFcmTokenToServer(_userId!, newToken);
        }
      });
    } catch (e) {
      print('FCM initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userEmail == null) {
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
                  onPressed: _loginWithGoogle,
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
            onPressed: logout,
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

  Future<void> _saveFcmTokenToServer(String userId, String fcmToken) async {
    if (fcmToken.isEmpty) return;

    print('Saving token "$fcmToken" for userId="$userId" to user_devices...');
    try {
      final existing = await databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsUserDevicesId,
        queries: [
          Query.equal('userId', userId),
          Query.equal('fcmToken', fcmToken),
        ],
      );

      if (existing.total == 0) {
        await databases.createDocument(
          databaseId: API.databaseId,
          collectionId: API.collectionsUserDevicesId,
          documentId: 'unique()',
          data: {
            'userId': userId,
            'fcmToken': fcmToken,
            'createdAt': DateTime.now().toIso8601String(),
          },
        );
        print('FCM token doc created.');
      } else {
        print('Token already exists in user_devices.');
      }
    } catch (e) {
      print('Error saving token: $e');
    }
  }
}
