import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import '../const.dart'; // const.dart에서 API 관련 상수 가져오기

class BoardSelectionPage extends StatefulWidget {
  final Client client;
  const BoardSelectionPage({super.key, required this.client});

  @override
  State<BoardSelectionPage> createState() => _BoardSelectionPageState();
}

class _BoardSelectionPageState extends State<BoardSelectionPage> {
  late Account _account;
  late Databases _databases;
  String? _userId; // nullable로 변경
  bool _loading = true; // 로딩 상태 추가
  String? _subscriptionId;

  final List<String> _allBoards = [
    'bachelor',
    'scholarship',
    'student',
    'job',
    'extracurricular',
    'other',
    'dormGlobal',
    'dormMedical',
  ];
  List<String> _subscribedBoards = [];

  @override
  void initState() {
    super.initState();
    _account = Account(widget.client);
    _databases = Databases(widget.client);
    _initUserAndLoadSubscription();
  }

  Future<void> _initUserAndLoadSubscription() async {
    try {
      final user = await _account.get();
      _userId = user.$id;
      print('Current user ID: $_userId'); // 디버깅용 로그 추가

      await _loadUserSubscription();
    } catch (e) {
      print('Error getting user: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는데 실패했습니다.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _initUserAndLoadSubscription(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadUserSubscription() async {
    if (_userId == null) return;

    try {
      print('Fetching subscriptions for user: $_userId'); // 디버깅용 로그 추가
      final subscriptions = await _databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        queries: [Query.equal('userId', _userId!)],
      );

      print(
        'Found ${subscriptions.documents.length} subscriptions',
      ); // 디버깅용 로그 추가

      if (subscriptions.documents.isNotEmpty) {
        final doc = subscriptions.documents.first;
        _subscriptionId = doc.$id;
        print('Subscription document ID: ${doc.$id}'); // 디버깅용 로그 추가
        final boardsField = doc.data['boards'];
        print('Boards field: $boardsField'); // 디버깅용 로그 추가

        if (mounted) {
          setState(() {
            _subscribedBoards =
                boardsField != null ? List<String>.from(boardsField) : [];
            _loading = false;
          });
        }
      } else {
        print('No subscription found, creating new...'); // 디버깅용 로그 추가
        await _createEmptySubscription();
      }
    } catch (e) {
      print('Error loading subscription: $e');
      if (e.toString().contains('document not found')) {
        await _createEmptySubscription();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('구독 정보를 불러오는데 실패했습니다.'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () => _loadUserSubscription(),
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createEmptySubscription() async {
    if (_userId == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      final data = {'boards': [], 'userId': _userId, 'lastUpdate': now};

      print('Creating subscription with data: $data'); // 디버깅용 로그 추가

      final result = await _databases.createDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: 'unique()',
        data: data,
      );

      _subscriptionId = result.$id;
      print('Created subscription document: ${result.$id}'); // 디버깅용 로그 추가

      if (mounted) {
        setState(() {
          _subscribedBoards = [];
          _loading = false;
        });
      }
    } catch (err) {
      print('Error creating subscription doc: $err');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 설정 초기화 중 오류가 발생했습니다.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _createEmptySubscription(),
            ),
          ),
        );
      }
    }
  }

  bool _isBoardSubscribed(String boardId) {
    return _subscribedBoards.contains(boardId);
  }

  Future<void> _toggleBoard(String boardId) async {
    if (_userId == null) return;

    final newList = List<String>.from(_subscribedBoards);
    if (newList.contains(boardId)) {
      newList.remove(boardId);
    } else {
      newList.add(boardId);
    }

    // UI 먼저 업데이트
    setState(() {
      _subscribedBoards = newList;
    });

    try {
      if (_subscriptionId == null) {
        // 구독 문서가 없으면 생성 후 다시 시도
        await _createEmptySubscription();
        await _toggleBoard(boardId);
        return;
      }

      final now = DateTime.now().toIso8601String();

      print('Updating subscription $_subscriptionId with boards: $newList');

      // 문서 업데이트
      await _databases.updateDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: _subscriptionId!,
        data: {'boards': newList, 'lastUpdate': now},
      );

      print('Successfully updated subscription');
    } catch (err) {
      print('Error updating boards: $err');
      // 서버 업데이트 실패 시 원래 상태로 복구
      if (mounted) {
        setState(() {
          _subscribedBoards = List<String>.from(_subscribedBoards);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 설정 업데이트에 실패했습니다. 다시 시도해주세요.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _toggleBoard(boardId),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView(
      children:
          _allBoards.map((boardId) {
            final subscribed = _isBoardSubscribed(boardId);
            return CheckboxListTile(
              title: Text(_getBoardName(boardId)),
              subtitle: Text(_getBoardDescription(boardId)),
              value: subscribed,
              onChanged: (val) {
                if (val != null) {
                  _toggleBoard(boardId);
                }
              },
            );
          }).toList(),
    );
  }

  String _getBoardName(String boardId) {
    switch (boardId) {
      case 'bachelor':
        return '학사';
      case 'scholarship':
        return '장학';
      case 'student':
        return '학생';
      case 'job':
        return '취업';
      case 'extracurricular':
        return '비교과';
      case 'other':
        return '기타';
      case 'dormGlobal':
        return '글로벌미래캠퍼스 기숙사';
      case 'dormMedical':
        return '메디컬캠퍼스 기숙사';
      default:
        return boardId;
    }
  }

  String _getBoardDescription(String boardId) {
    switch (boardId) {
      case 'bachelor':
        return '수강신청, 학적, 성적 등 학사 관련 공지';
      case 'scholarship':
        return '교내/외 장학금 관련 공지';
      case 'student':
        return '학생회, 동아리, 행사 등 학생 활동 관련 공지';
      case 'job':
        return '채용설명회, 인턴십, 취업 특강 등 취업 관련 공지';
      case 'extracurricular':
        return '비교과 프로그램, 특강, 워크샵 등';
      case 'other':
        return '기타 공지사항';
      case 'dormGlobal':
        return '글로벌미래캠퍼스(성남) 기숙사 공지';
      case 'dormMedical':
        return '메디컬캠퍼스(인천) 기숙사 공지';
      default:
        return '';
    }
  }
}
