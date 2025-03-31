import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:firebase_messaging/firebase_messaging.dart'; // [ADDED]
import 'package:front/const.dart'; // [ADDED] const.dart에서 API 관련 상수 가져오기

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 초기화
  final client = Client()
    .setEndpoint(API.apiUrl)
    .setProject(API.projectId);

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final Client client;
  const MyApp({Key? key, required this.client}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gachon Notices',
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

  // [ADDED] 아래 두 줄 추가 (Databases를 통해 user_devices에 접근)
  late Databases databases;
  String? _userId;

  @override
  void initState() {
    super.initState();
    account = Account(widget.client);

    // [ADDED] Databases 초기화
    databases = Databases(widget.client);

    _initFCM(); 
  }

  Future<void> _loginWithGoogle() async {
    try {
      // 1) createOAuth2Session 호출
      final result = await account.createOAuth2Session(
        provider: OAuthProvider.google,
      );

      // 만약 Flutter 웹이라면, 브라우저로 이동 후 리디렉션이 처리됩니다.
      // 모바일에서는 inAppBrowser: true 옵션 등 추가 가능 (SDK 버전에 따라 상이)

      // 2) 세션이 성공적으로 생성되면, 이후 account.get() 해서 유저 정보 확인
      final user = await account.get();
      print('User logged in: ${user.name}, ${user.email}');

      setState(() {
        _userEmail = user.email;
        _userId = user.$id; // [ADDED] userId 저장
      });

      // [ADDED] 로그인 후 FCM 토큰이 있다면 user_devices에 저장(또는 업데이트)
      if (_fcmToken != null && _userId != null) {
        await _saveFcmTokenToServer(_userId!, _fcmToken!);
      }

    } catch (e) {
      print('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      // 이제 세션 삭제 → account.get() 하면 401 에러
    } catch (e) {
      print('Logout error: $e');
    }
  }


  String? _userEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gachon Notice - Home'),
      ),
      body: Center(
        child: _userEmail == null
            ? ElevatedButton(
                onPressed: _loginWithGoogle,
                child: Text('Login with Google'),
              )
            : Text('Logged in as $_userEmail'),
      ),
    );
  }

  // [ADDED] FCM 초기설정 (권한 요청, 토큰 획득)
  Future<void> _initFCM() async {
    // iOS라면 알림 권한 요청
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
    print('FCM permission status: ${settings.authorizationStatus}');

    // FCM 토큰 가져오기
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    setState(() {
      _fcmToken = token;
    });

    // 만약 이미 로그인된 상태라면 즉시 서버에 저장
    try {
      final user = await account.get(); // 세션 있으면 유저 정보 성공
      _userId = user.$id;
      if (_fcmToken != null && _userId != null) {
        await _saveFcmTokenToServer(_userId!, _fcmToken!);
      }
    } catch (e) {
      // 아직 로그인 안됐거나 에러
      print('No user session yet: $e');
    }

    // 토큰 변경(만료, 재생성) 이벤트 캐치
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      setState(() {
        _fcmToken = newToken;
      });
      if (_userId != null) {
        await _saveFcmTokenToServer(_userId!, newToken);
      }
    });
  }

  // [ADDED] user_devices 컬렉션에 토큰 저장 로직
  Future<void> _saveFcmTokenToServer(String userId, String fcmToken) async {
    if (fcmToken.isEmpty) return;

    print('Saving token "$fcmToken" for userId="$userId" to user_devices...');
    try {
      // 1) 기존 문서가 있는지 검색
      final existing = await databases.listDocuments(
        databaseId: API.databaseId,     // [ADDED] 바꿔주세요
        collectionId: API.collectionsUserDevicesId,         // [ADDED] 실제 collectionId
        queries: [
          Query.equal('userId', userId),
          Query.equal('fcmToken', fcmToken),
        ],
      );

      // 2) 없으면 생성
      if (existing.total == 0) {
        await databases.createDocument(
          databaseId: API.databaseId, // [ADDED] 바꿔주세요
          collectionId: API.collectionsUserDevicesId,
          documentId: 'unique()', // 자동문서ID
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
