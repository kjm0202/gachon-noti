import 'package:appwrite/appwrite.dart';
import '../utils/const.dart';

class BoardSelectionController {
  final Client client;
  late Account _account;
  late Databases _databases;
  String? userId;
  bool loading = true;
  String? subscriptionId;
  List<String> subscribedBoards = [];

  final List<String> allBoards = [
    'bachelor',
    'scholarship',
    'student',
    'job',
    'extracurricular',
    'other',
    'dormGlobal',
    'dormMedical',
  ];

  BoardSelectionController({required this.client}) {
    _account = Account(client);
    _databases = Databases(client);
  }

  Future<void> initUserAndLoadSubscription({
    Function? onError,
    Function? onFinally,
  }) async {
    try {
      final user = await _account.get();
      userId = user.$id;
      print('Current user ID: $userId'); // 디버깅용 로그 추가

      await loadUserSubscription(onError: onError);
    } catch (e) {
      print('Error getting user: $e');
      loading = false;
      if (onError != null) {
        onError(e);
      }
    } finally {
      if (onFinally != null) {
        onFinally();
      }
    }
  }

  Future<void> loadUserSubscription({Function? onError}) async {
    if (userId == null) return;

    try {
      print('Fetching subscriptions for user: $userId'); // 디버깅용 로그 추가
      final subscriptions = await _databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        queries: [Query.equal('userId', userId!)],
      );

      print(
        'Found ${subscriptions.documents.length} subscriptions',
      ); // 디버깅용 로그 추가

      if (subscriptions.documents.isNotEmpty) {
        final doc = subscriptions.documents.first;
        subscriptionId = doc.$id;
        print('Subscription document ID: ${doc.$id}'); // 디버깅용 로그 추가
        final boardsField = doc.data['boards'];
        print('Boards field: $boardsField'); // 디버깅용 로그 추가

        subscribedBoards =
            boardsField != null ? List<String>.from(boardsField) : [];
        loading = false;
      } else {
        print('No subscription found, creating new...'); // 디버깅용 로그 추가
        await createEmptySubscription(onError: onError);
      }
    } catch (e) {
      print('Error loading subscription: $e');
      if (e.toString().contains('document not found')) {
        await createEmptySubscription(onError: onError);
      } else if (onError != null) {
        onError(e);
      }
    } finally {
      loading = false;
    }
  }

  Future<void> createEmptySubscription({Function? onError}) async {
    if (userId == null) return;

    try {
      final now = DateTime.now().toIso8601String();
      final data = {'boards': [], 'userId': userId, 'lastUpdate': now};

      print('Creating subscription with data: $data'); // 디버깅용 로그 추가

      final result = await _databases.createDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: 'unique()',
        data: data,
      );

      subscriptionId = result.$id;
      print('Created subscription document: ${result.$id}'); // 디버깅용 로그 추가

      subscribedBoards = [];
      loading = false;
    } catch (err) {
      print('Error creating subscription doc: $err');
      loading = false;
      if (onError != null) {
        onError(err);
      }
    }
  }

  bool isBoardSubscribed(String boardId) {
    return subscribedBoards.contains(boardId);
  }

  Future<void> toggleBoard(
    String boardId, {
    Function? onUpdate,
    Function? onError,
  }) async {
    if (userId == null) return;

    final newList = List<String>.from(subscribedBoards);
    if (newList.contains(boardId)) {
      newList.remove(boardId);
    } else {
      newList.add(boardId);
    }

    // UI 업데이트 콜백 호출
    if (onUpdate != null) {
      onUpdate(newList);
    }

    try {
      if (subscriptionId == null) {
        // 구독 문서가 없으면 생성 후 다시 시도
        await createEmptySubscription(onError: onError);
        await toggleBoard(boardId, onUpdate: onUpdate, onError: onError);
        return;
      }

      final now = DateTime.now().toIso8601String();

      print('Updating subscription $subscriptionId with boards: $newList');

      // 문서 업데이트
      await _databases.updateDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: subscriptionId!,
        data: {'boards': newList, 'lastUpdate': now},
      );

      subscribedBoards = newList;
      print('Successfully updated subscription');
    } catch (err) {
      print('Error updating boards: $err');
      if (onError != null) {
        onError(err);
      }
    }
  }

  String getBoardName(String boardId) {
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

  String getBoardDescription(String boardId) {
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
