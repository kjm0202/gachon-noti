import 'package:supabase_flutter/supabase_flutter.dart';

class BoardSelectionController {
  final SupabaseClient client;
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

  BoardSelectionController({required this.client});

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
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인하지 않았습니다.');
      }

      userId = user.id;
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

      final response = await client
          .from('subscriptions')
          .select('id, boards')
          .eq('user_id', userId!)
          .maybeSingle();

      if (response != null) {
        subscriptionId = response['id'];
        print('Subscription ID: $subscriptionId'); // 디버깅용 로그 추가

        final boardsField = response['boards'];
        print('Boards field: $boardsField'); // 디버깅용 로그 추가

        subscribedBoards =
            boardsField != null ? List<String>.from(boardsField) : [];
        tempSubscribedBoards = List<String>.from(subscribedBoards);
      } else {
        print('No subscription found, creating new...'); // 디버깅용 로그 추가
        await createEmptySubscription(onError: onError);
      }
    } catch (e) {
      print('Error loading subscription: $e');
      await createEmptySubscription(onError: onError);
    } finally {
      loading = false;
    }
  }

  Future<void> createEmptySubscription({Function? onError}) async {
    if (userId == null) return;

    try {
      final now = DateTime.now().toIso8601String();

      final data = {
        'boards': [],
        'user_id': userId,
        'created_at': now,
        'updated_at': now
      };

      print('Creating subscription with data: $data'); // 디버깅용 로그 추가

      final response =
          await client.from('subscriptions').insert(data).select('id').single();

      subscriptionId = response['id'];
      print('Created subscription with ID: $subscriptionId'); // 디버깅용 로그 추가

      subscribedBoards = [];
      tempSubscribedBoards = [];
      loading = false;
    } catch (err) {
      print('Error creating subscription: $err');
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

      await client
          .from('subscriptions')
          .update({'boards': tempSubscribedBoards, 'updated_at': now}).eq(
              'id', subscriptionId!);

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

      await client.from('subscriptions').update(
          {'boards': newList, 'updated_at': now}).eq('id', subscriptionId!);

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
        return '글로벌 기숙사';
      case 'dormMedical':
        return '메디컬 기숙사';
      default:
        return boardId;
    }
  }

  String getBoardDescription(String boardId) {
    switch (boardId) {
      case 'bachelor':
        return '수업 및 학사 일정';
      case 'scholarship':
        return '교내외 각종 장학금';
      case 'student':
        return '학생 생활 및 각종 행사';
      case 'job':
        return '채용 및 취업 관련 정보';
      case 'extracurricular':
        return '비교과 프로그램';
      case 'other':
        return '기타 정보';
      case 'dormGlobal':
        return '글로벌 캠퍼스 기숙사';
      case 'dormMedical':
        return '메디컬 캠퍼스 기숙사';
      default:
        return '게시판 설명 없음';
    }
  }
}
