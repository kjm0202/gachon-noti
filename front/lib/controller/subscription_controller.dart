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
        // id 값이 int인 경우 String으로 변환
        subscriptionId =
            response['id'] != null ? response['id'].toString() : null;
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
      // 여기서 중복 키 오류가 발생했다면, 이미 구독이 있다는 의미이므로 다시 로드
      try {
        // 이미 구독이 있을 수 있으므로, 다시 한번 조회
        final retryResponse = await client
            .from('subscriptions')
            .select('id, boards')
            .eq('user_id', userId!)
            .maybeSingle();

        if (retryResponse != null) {
          // id 값이 int인 경우 String으로 변환
          subscriptionId = retryResponse['id'] != null
              ? retryResponse['id'].toString()
              : null;
          final boardsField = retryResponse['boards'];
          subscribedBoards =
              boardsField != null ? List<String>.from(boardsField) : [];
          tempSubscribedBoards = List<String>.from(subscribedBoards);
          print('Successfully loaded existing subscription: $subscriptionId');
        } else {
          // 여전히 없으면 생성 시도
          await createEmptySubscription(onError: onError);
        }
      } catch (retryError) {
        print('Error retrying subscription load: $retryError');
        if (onError != null) {
          onError(retryError);
        }
      }
    } finally {
      loading = false;
    }
  }

  Future<void> createEmptySubscription({Function? onError}) async {
    if (userId == null) return;

    try {
      // 생성 전에 먼저 기존 subscription이 있는지 확인
      final existingSubscription = await client
          .from('subscriptions')
          .select('id')
          .eq('user_id', userId!)
          .maybeSingle();

      if (existingSubscription != null) {
        // id 값이 int인 경우 String으로 변환
        subscriptionId = existingSubscription['id'] != null
            ? existingSubscription['id'].toString()
            : null;
        print('Using existing subscription ID: $subscriptionId');

        // 기존 구독의 boards 정보를 가져옴
        final boardsResponse = await client
            .from('subscriptions')
            .select('boards')
            .eq('id', subscriptionId!)
            .single();

        final boardsField = boardsResponse['boards'];
        subscribedBoards =
            boardsField != null ? List<String>.from(boardsField) : [];
        tempSubscribedBoards = List<String>.from(subscribedBoards);
        loading = false;
        return;
      }

      // 기존 구독이 없으면 새로 생성
      final now = DateTime.now().toIso8601String();

      final data = {
        'boards': <String>[],
        'user_id': userId,
        'created_at': now,
        'updated_at': now
      };

      print('Creating subscription with data: $data'); // 디버깅용 로그 추가

      final response =
          await client.from('subscriptions').insert(data).select('id').single();

      // id 값이 int인 경우 String으로 변환
      subscriptionId =
          response['id'] != null ? response['id'].toString() : null;
      print('Created subscription with ID: $subscriptionId'); // 디버깅용 로그 추가

      subscribedBoards = [];
      tempSubscribedBoards = [];
      loading = false;
    } catch (err) {
      print('Error creating subscription: $err');
      // 중복 키 오류인 경우 다시 로드 시도
      if (err.toString().contains('duplicate key') ||
          err.toString().contains('unique constraint')) {
        try {
          final existingResponse = await client
              .from('subscriptions')
              .select('id, boards')
              .eq('user_id', userId!)
              .single();

          // id 값이 int인 경우 String으로 변환
          subscriptionId = existingResponse['id'] != null
              ? existingResponse['id'].toString()
              : null;
          final boardsField = existingResponse['boards'];
          subscribedBoards =
              boardsField != null ? List<String>.from(boardsField) : [];
          tempSubscribedBoards = List<String>.from(subscribedBoards);
          print('Recovered with existing subscription ID: $subscriptionId');
        } catch (retryError) {
          print('Error recovering from duplicate key: $retryError');
          if (onError != null) {
            onError(retryError);
          }
        }
      } else {
        loading = false;
        if (onError != null) {
          onError(err);
        }
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
