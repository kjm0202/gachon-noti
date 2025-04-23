import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/providers/supabase_provider.dart';

class SubscriptionController extends GetxController {
  final SupabaseProvider _supabaseProvider = Get.find<SupabaseProvider>();
  final RxString userId = RxString('');
  final RxBool loading = true.obs;
  final RxString subscriptionId = RxString('');
  final RxList<String> subscribedBoards = <String>[].obs;
  final RxList<String> tempSubscribedBoards = <String>[].obs;

  final RxBool hasChanges = false.obs;

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

  @override
  void onInit() {
    super.onInit();
    initUserAndLoadSubscription();

    // hasChanges 리액티브 업데이트를 위한 리스너 설정
    ever(subscribedBoards, (_) => _checkForChanges());
    ever(tempSubscribedBoards, (_) => _checkForChanges());
  }

  void _checkForChanges() {
    hasChanges.value = !_areListsEqual(subscribedBoards, tempSubscribedBoards);
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

  Future<void> initUserAndLoadSubscription() async {
    try {
      final user = _supabaseProvider.client.auth.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인하지 않았습니다.');
      }

      userId.value = user.id;
      print('사용자 정보 로드 성공: userId=${userId.value}');

      await loadUserSubscription();
    } catch (e) {
      print('사용자 정보 로드 실패: $e');
      loading.value = false;
    }
  }

  Future<void> loadUserSubscription() async {
    if (userId.isEmpty) return;

    try {
      print('사용자 구독 정보 조회 시도: userId=${userId.value}');

      final response = await _supabaseProvider.client
          .from('subscriptions')
          .select('id, boards')
          .eq('user_id', userId.value)
          .maybeSingle();

      if (response != null) {
        // id 값이 int인 경우 String으로 변환
        subscriptionId.value =
            response['id'] != null ? response['id'].toString() : '';

        final boardsField = response['boards'];
        subscribedBoards.value =
            boardsField != null ? List<String>.from(boardsField) : [];
        tempSubscribedBoards.value = List<String>.from(subscribedBoards);

        print(
            '구독 정보 로드 성공: ID=${subscriptionId.value}, boards=${subscribedBoards.value}');
      } else {
        print('구독 정보가 없음, 새 구독 생성 시도');
        await createEmptySubscription();
      }
    } catch (e) {
      print('구독 정보 로드 실패: $e');
      // 여기서 중복 키 오류가 발생했다면, 이미 구독이 있다는 의미이므로 다시 로드
      try {
        print('오류 발생, 구독 정보 재시도');
        // 이미 구독이 있을 수 있으므로, 다시 한번 조회
        final retryResponse = await _supabaseProvider.client
            .from('subscriptions')
            .select('id, boards')
            .eq('user_id', userId.value)
            .maybeSingle();

        if (retryResponse != null) {
          // id 값이 int인 경우 String으로 변환
          subscriptionId.value =
              retryResponse['id'] != null ? retryResponse['id'].toString() : '';
          final boardsField = retryResponse['boards'];
          subscribedBoards.value =
              boardsField != null ? List<String>.from(boardsField) : [];
          tempSubscribedBoards.value = List<String>.from(subscribedBoards);
          print(
              '구독 정보 재시도 성공: ID=${subscriptionId.value}, boards=${subscribedBoards.value}');
        } else {
          // 여전히 없으면 생성 시도
          print('구독 정보가 여전히 없음, 새 구독 생성 시도');
          await createEmptySubscription();
        }
      } catch (retryError) {
        print('구독 정보 재시도 실패: $retryError');
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> createEmptySubscription() async {
    if (userId.isEmpty) return;

    try {
      // 생성 전에 먼저 기존 subscription이 있는지 확인
      print('기존 구독 검색 시도: userId=${userId.value}');
      final existingSubscription = await _supabaseProvider.client
          .from('subscriptions')
          .select('id')
          .eq('user_id', userId.value)
          .maybeSingle();

      if (existingSubscription != null) {
        // id 값이 int인 경우 String으로 변환
        subscriptionId.value = existingSubscription['id'] != null
            ? existingSubscription['id'].toString()
            : '';
        print('기존 구독 발견: ID=${subscriptionId.value}');

        // 기존 구독의 boards 정보를 가져옴
        print('기존 구독의 게시판 정보 조회 시도');
        final boardsResponse = await _supabaseProvider.client
            .from('subscriptions')
            .select('boards')
            .eq('id', subscriptionId.value)
            .single();

        final boardsField = boardsResponse['boards'];
        subscribedBoards.value =
            boardsField != null ? List<String>.from(boardsField) : [];
        tempSubscribedBoards.value = List<String>.from(subscribedBoards);
        print('기존 구독의 게시판 정보 로드 완료: ${subscribedBoards.value}');
        loading.value = false;
        return;
      }

      // 기존 구독이 없으면 새로 생성
      final now = DateTime.now().toIso8601String();

      final data = {
        'boards': <String>[],
        'user_id': userId.value,
        'created_at': now,
        'updated_at': now
      };

      print('새 구독 생성 시도: $data');

      final response = await _supabaseProvider.client
          .from('subscriptions')
          .insert(data)
          .select('id')
          .single();

      // id 값이 int인 경우 String으로 변환
      subscriptionId.value =
          response['id'] != null ? response['id'].toString() : '';
      print('새 구독 생성 성공: ID=${subscriptionId.value}');

      subscribedBoards.clear();
      tempSubscribedBoards.clear();
      loading.value = false;
    } catch (err) {
      print('구독 생성/검색 실패: $err');
      // 중복 키 오류인 경우 다시 로드 시도
      if (err.toString().contains('duplicate key') ||
          err.toString().contains('unique constraint')) {
        try {
          print('중복 키 오류 발생, 기존 구독 재시도');
          final existingResponse = await _supabaseProvider.client
              .from('subscriptions')
              .select('id, boards')
              .eq('user_id', userId.value)
              .single();

          // id 값이 int인 경우 String으로 변환
          subscriptionId.value = existingResponse['id'] != null
              ? existingResponse['id'].toString()
              : '';
          final boardsField = existingResponse['boards'];
          subscribedBoards.value =
              boardsField != null ? List<String>.from(boardsField) : [];
          tempSubscribedBoards.value = List<String>.from(subscribedBoards);
          print(
              '중복 키 복구 성공: ID=${subscriptionId.value}, boards=${subscribedBoards.value}');
        } catch (retryError) {
          print('중복 키 복구 실패: $retryError');
        }
      } else {
        loading.value = false;
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

    tempSubscribedBoards.value = newList;
  }

  Future<bool> saveAllSubscriptions() async {
    if (userId.isEmpty) return false;
    if (!hasChanges.value) return true;

    try {
      if (subscriptionId.isEmpty) {
        await createEmptySubscription();
        if (subscriptionId.isEmpty) return false;
      }

      final now = DateTime.now().toIso8601String();
      print(
          '구독 업데이트 시도: ID=${subscriptionId.value}, boards=${tempSubscribedBoards.value}');

      final response = await _supabaseProvider.client
          .from('subscriptions')
          .update({'boards': tempSubscribedBoards.toList(), 'updated_at': now})
          .eq('id', subscriptionId.value)
          .select();

      print('구독 업데이트 성공: 응답 데이터=$response');
      subscribedBoards.value = List<String>.from(tempSubscribedBoards);
      print('구독된 게시판 목록 업데이트 완료: ${subscribedBoards.value}');

      return true;
    } catch (err) {
      print('구독 업데이트 실패: $err');
      return false;
    }
  }

  Future<void> toggleBoard(String boardId) async {
    if (userId.isEmpty) return;

    final newList = List<String>.from(subscribedBoards);
    if (newList.contains(boardId)) {
      newList.remove(boardId);
    } else {
      newList.add(boardId);
    }

    try {
      if (subscriptionId.isEmpty) {
        await createEmptySubscription();
        await toggleBoard(boardId);
        return;
      }

      final now = DateTime.now().toIso8601String();
      print(
          '개별 게시판 토글 시도: ID=${subscriptionId.value}, boardId=$boardId, 새 목록=$newList');

      final response = await _supabaseProvider.client
          .from('subscriptions')
          .update({'boards': newList, 'updated_at': now})
          .eq('id', subscriptionId.value)
          .select();

      print('게시판 토글 성공: 응답 데이터=$response');
      subscribedBoards.value = newList;
      tempSubscribedBoards.value = List<String>.from(newList);
      print('구독된 게시판 목록 업데이트 완료: ${subscribedBoards.value}');
    } catch (err) {
      print('게시판 토글 실패: $err');
    }
  }

  void cancelChanges() {
    tempSubscribedBoards.value = List<String>.from(subscribedBoards);
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
