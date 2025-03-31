import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:front/const.dart'; // const.dart에서 API 관련 상수 가져오기

class BoardSelectionPage extends StatefulWidget {
  final Client client;
  const BoardSelectionPage({Key? key, required this.client}) : super(key: key);

  @override
  State<BoardSelectionPage> createState() => _BoardSelectionPageState();
}

class _BoardSelectionPageState extends State<BoardSelectionPage> {
  late Account _account;
  late Databases _databases;
  late String _userId;

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

      // `subscriptions` 컬렉션에서 userId와 동일한 문서를 가져옴
      final doc = await _databases.getDocument(
        databaseId: API.databaseId, 
        collectionId: API.collectionsSubscriptionsId, 
        documentId: _userId, 
      );
      // boards 필드를 배열로 받음
      final boardsField = doc.data['boards'] ?? [];
      setState(() {
        _subscribedBoards = List<String>.from(boardsField);
      });
    } catch (e) {
      // 만약 문서가 없으면 404 에러 -> 새로 만들 수도 있음
      print('Subscription not found, creating new...');
      _createEmptySubscription();
    }
  }

  Future<void> _createEmptySubscription() async {
    try {
      final result = await _databases.createDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: _userId,  // userId와 동일하게
        data: {
          'boards': [],
        },
      );
      setState(() {
        _subscribedBoards = [];
      });
      print('Created new subscription doc');
    } catch (err) {
      print('Error creating subscription doc: $err');
    }
  }

  bool _isBoardSubscribed(String boardId) {
    return _subscribedBoards.contains(boardId);
  }

  Future<void> _toggleBoard(String boardId) async {
    final newList = List<String>.from(_subscribedBoards);
    if (newList.contains(boardId)) {
      newList.remove(boardId);
    } else {
      newList.add(boardId);
    }

    // 서버에 업데이트
    try {
      await _databases.updateDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: _userId,
        data: {
          'boards': newList,
        },
      );
      setState(() {
        _subscribedBoards = newList;
      });
    } catch (err) {
      print('Error updating boards: $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Boards to Subscribe'),
      ),
      body: ListView(
        children: _allBoards.map((boardId) {
          final subscribed = _isBoardSubscribed(boardId);
          return CheckboxListTile(
            title: Text(boardId),
            value: subscribed,
            onChanged: (val) {
              if (val != null) {
                _toggleBoard(boardId);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
