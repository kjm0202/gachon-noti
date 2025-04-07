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
  List<String> tempSubscribedBoards = [];
  bool get hasChanges =>
      !_areListsEqual(subscribedBoards, tempSubscribedBoards);

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

  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;

    final sortedList1 = List<String>.from(list1)..sort();
    final sortedList2 = List<String>.from(list2)..sort();

    for (int i = 0; i < sortedList1.length; i++) {
      if (sortedList1[i] != sortedList2[i]) return false;
    }

    return true;
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
        tempSubscribedBoards = List<String>.from(subscribedBoards);
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
      tempSubscribedBoards = [];
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
    return tempSubscribedBoards.contains(boardId);
  }

  void toggleBoardTemp(String boardId) {
    final newList = List<String>.from(tempSubscribedBoards);
    if (newList.contains(boardId)) {
      newList.remove(boardId);
    } else {
      newList.add(boardId);
    }

    tempSubscribedBoards = newList;
  }

  Future<bool> saveAllSubscriptions({
    Function? onUpdate,
    Function? onError,
  }) async {
    if (userId == null) return false;
    if (!hasChanges) return true;

    try {
      if (subscriptionId == null) {
        await createEmptySubscription(onError: onError);
        if (subscriptionId == null) return false;
      }

      final now = DateTime.now().toIso8601String();
      print(
        'Updating subscription $subscriptionId with boards: $tempSubscribedBoards',
      );

      await _databases.updateDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: subscriptionId!,
        data: {'boards': tempSubscribedBoards, 'lastUpdate': now},
      );

      subscribedBoards = List<String>.from(tempSubscribedBoards);
      print('Successfully updated subscription');

      if (onUpdate != null) {
        onUpdate(subscribedBoards);
      }

      return true;
    } catch (err) {
      print('Error updating boards: $err');
      if (onError != null) {
        onError(err);
      }
      return false;
    }
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

    if (onUpdate != null) {
      onUpdate(newList);
    }

    try {
      if (subscriptionId == null) {
        await createEmptySubscription(onError: onError);
        await toggleBoard(boardId, onUpdate: onUpdate, onError: onError);
        return;
      }

      final now = DateTime.now().toIso8601String();

      print('Updating subscription $subscriptionId with boards: $newList');

      await _databases.updateDocument(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        documentId: subscriptionId!,
        data: {'boards': newList, 'lastUpdate': now},
      );

      subscribedBoards = newList;
      tempSubscribedBoards = List<String>.from(newList);
      print('Successfully updated subscription');
    } catch (err) {
      print('Error updating boards: $err');
      if (onError != null) {
        onError(err);
      }
    }
  }

  void cancelChanges() {
    tempSubscribedBoards = List<String>.from(subscribedBoards);
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
