import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/post_model.dart';
import '../../../data/providers/supabase_provider.dart';

class PostsController extends GetxController {
  final SupabaseProvider _supabaseProvider = Get.find<SupabaseProvider>();
  final String boardId;

  // 관찰 가능한 상태들
  final RxList<Map<String, dynamic>> posts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredPosts =
      <Map<String, dynamic>>[].obs;
  final RxBool loading = true.obs;
  final RxBool loadingMore = false.obs;
  final RxList<String> subscribedBoards = <String>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedTagFilter = 'all'.obs;
  final RxBool hasMoreData = true.obs;

  // 페이지네이션 관련 변수
  int _page = 1;
  int _limit = 20; // a

  // 캐싱 관련 변수
  static Map<String, List<Map<String, dynamic>>> _cachedPosts = {};
  static RxList<String> _cachedSubscribedBoards = <String>[].obs;
  static DateTime _lastFetchTime = DateTime(1970);
  static const Duration _cacheDuration = Duration(minutes: 5);

  PostsController({required this.boardId});

  @override
  void onInit() {
    super.onInit();
    initUserAndFetchPosts();
  }

  // 페이지를 리셋하고 처음부터 데이터를 가져오는 메소드
  void resetPagination() {
    _page = 1;
    hasMoreData.value = true;
    posts.clear();
    filteredPosts.clear();
  }

  Future<void> initUserAndFetchPosts() async {
    try {
      // 현재 시간
      final now = DateTime.now();

      // 캐시 유효 시간 확인
      final bool isCacheValid = now.difference(_lastFetchTime) < _cacheDuration;

      // 구독한 게시판 정보 로드
      if (_cachedSubscribedBoards.isEmpty || !isCacheValid) {
        final user = await _supabaseProvider.client.auth.currentUser;

        if (user != null) {
          // userId로 구독 문서 찾기
          final response = await _supabaseProvider.client
              .from('subscriptions')
              .select('boards')
              .eq('user_id', user.id)
              .maybeSingle();

          if (response != null) {
            _cachedSubscribedBoards.value =
                List<String>.from(response['boards'] ?? []);
          } else {
            _cachedSubscribedBoards.clear();
          }
        } else {
          _cachedSubscribedBoards.clear();
        }
      }

      // 캐시된 구독 보드 정보를 현재 컨트롤러에 설정
      subscribedBoards.value = _cachedSubscribedBoards;

      // 페이지네이션 리셋 후 첫 페이지 로드
      resetPagination();
      await fetchPosts(useCache: isCacheValid);
    } catch (e) {
      print('Error initializing: $e');
      loading.value = false;
      subscribedBoards.clear();
    }
  }

  Future<void> fetchPosts(
      {bool useCache = true, bool forceRefresh = false}) async {
    // 첫 페이지를 로드하는 경우에만 loading을 true로 설정
    if (_page == 1) {
      loading.value = true;
    } else {
      loadingMore.value = true;
    }

    try {
      List<String> targetBoards =
          boardId == 'all' ? subscribedBoards.toList() : [boardId];

      if (targetBoards.isEmpty) {
        posts.clear();
        filteredPosts.clear();
        loading.value = false;
        loadingMore.value = false;
        hasMoreData.value = false;
        return;
      }

      // 캐시 키 생성
      final String cacheKey = boardId == 'all'
          ? 'all_${subscribedBoards.join('_')}_page$_page'
          : '${boardId}_page$_page';

      // 캐시 사용 가능하고 강제 새로고침이 아닌 경우, 캐시된 데이터 사용
      if (_page == 1 &&
          useCache &&
          !forceRefresh &&
          _cachedPosts.containsKey(cacheKey)) {
        // 첫 페이지만 캐시 사용
        posts.value = List.from(_cachedPosts[cacheKey]!);
        filteredPosts.value = List.from(posts);
        loading.value = false;
        loadingMore.value = false;
        return;
      }

      var queryBuilder = _supabaseProvider.client.from('posts').select();

      // 게시판 필터링
      if (boardId != 'all') {
        queryBuilder = queryBuilder.eq('board_id', boardId);
      } else if (subscribedBoards.isNotEmpty) {
        queryBuilder = queryBuilder.inFilter('board_id', subscribedBoards);
      }

      // 페이지네이션 적용 - 최신순으로 정렬하고 페이지 크기만큼 가져옴
      final int start = (_page - 1) * _limit;
      final data = await queryBuilder
          .order('pub_date', ascending: false)
          .range(start, start + _limit - 1);

      final newPosts = (data as List<dynamic>).map((doc) {
        // Map 형태로 변환하여 'description'이 없으면 빈 문자열로 설정
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc);
        if (data['description'] == null) {
          data['description'] = '';
        }
        return data;
      }).toList();

      // 더 가져올 데이터가 있는지 확인
      hasMoreData.value = newPosts.length == _limit;

      // 페이지가 1이면 posts를 새로 설정, 아니면 기존 posts에 추가
      if (_page == 1) {
        posts.value = newPosts;
      } else {
        List<Map<String, dynamic>> updatedPosts = [...posts, ...newPosts];
        posts.value = updatedPosts;
      }

      // 캐시 업데이트 (첫 페이지만)
      if (_page == 1) {
        _cachedPosts[cacheKey] = List.from(posts);
        _lastFetchTime = DateTime.now();
      }

      // 필터링된 게시물 목록 업데이트
      _applyFilters();

      // 페이지 증가
      _page++;

      loading.value = false;
      loadingMore.value = false;
    } catch (err) {
      print('Error fetching posts: $err');
      loading.value = false;
      loadingMore.value = false;
    }
  }

  // 다음 페이지 로드
  Future<void> loadMorePosts() async {
    if (loadingMore.value || !hasMoreData.value)
      return; // 이미 로딩 중이거나 더 이상 데이터가 없으면 리턴
    await fetchPosts(useCache: false);
  }

  // 강제 새로고침 수행
  Future<void> forceRefresh() async {
    resetPagination(); // 페이지네이션 리셋
    await fetchPosts(useCache: false, forceRefresh: true);
  }

  // 검색어로 게시물 필터링
  void searchByTitle(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  // 태그로 게시물 필터링
  Future<void> filterByTag(String tag) async {
    selectedTagFilter.value = tag;

    try {
      loading.value = true;
      // 페이지네이션 리셋
      resetPagination();

      if (tag == 'all') {
        // 'all'인 경우 모든 구독 게시판의 게시물 새로 가져오기
        if (subscribedBoards.isEmpty) {
          // 구독 게시판이 없는 경우
          posts.clear();
          filteredPosts.clear();
          loading.value = false;
          return;
        }

        // 캐시 키 생성
        final String cacheKey = 'all_${subscribedBoards.join('_')}_page1';

        // 모든 구독 게시판의 게시물 로드
        final data = await _supabaseProvider.client
            .from('posts')
            .select()
            .inFilter('board_id', subscribedBoards)
            .order('pub_date', ascending: false)
            .limit(_limit); // 페이지당 크기만큼만 가져옴

        // 결과 처리
        final postsList = (data as List<dynamic>).map((doc) {
          final Map<String, dynamic> postData = Map<String, dynamic>.from(doc);
          if (postData['description'] == null) {
            postData['description'] = '';
          }
          return postData;
        }).toList();

        // 더 가져올 데이터가 있는지 확인
        hasMoreData.value = postsList.length == _limit;

        // posts에 값 설정
        posts.value = postsList;

        // 페이지 증가
        _page = 2;

        // 캐시 업데이트
        _cachedPosts[cacheKey] = List.from(posts);
        _lastFetchTime = DateTime.now();

        // 필터링된 결과와 전체 결과 동일하게 설정
        filteredPosts.value = List.from(posts);
      } else {
        // 특정 게시판의 게시물만 가져오는 쿼리 직접 실행
        final data = await _supabaseProvider.client
            .from('posts')
            .select()
            .eq('board_id', tag) // 선택한 태그로 필터링
            .order('pub_date', ascending: false)
            .limit(_limit); // 페이지당 크기만큼만 가져옴

        // 결과 처리
        final postsList = (data as List<dynamic>).map((doc) {
          final Map<String, dynamic> postData = Map<String, dynamic>.from(doc);
          if (postData['description'] == null) {
            postData['description'] = '';
          }
          return postData;
        }).toList();

        // 더 가져올 데이터가 있는지 확인
        hasMoreData.value = postsList.length == _limit;

        // posts에 값 설정
        posts.value = postsList;

        // 페이지 증가
        _page = 2;

        // 캐시 업데이트
        _cachedPosts[tag + '_page1'] = List.from(posts);
        _lastFetchTime = DateTime.now();

        // 필터링된 결과와 전체 결과 동일하게 설정
        filteredPosts.value = List.from(posts);
      }

      loading.value = false;
    } catch (err) {
      print('Error fetching posts for tag $tag: $err');
      loading.value = false;
    }
  }

  // 검색어와 태그 필터 모두 적용
  void _applyFilters() {
    // 먼저 태그 필터 적용
    var tempFiltered = List<Map<String, dynamic>>.from(posts);

    // 'all'이 아닌 경우에만 태그 필터링 적용
    if (selectedTagFilter.value != 'all') {
      tempFiltered = tempFiltered.where((post) {
        return post['board_id'] == selectedTagFilter.value;
      }).toList();
    }

    // 검색어가 있는 경우 제목 또는 내용으로 필터링
    if (searchQuery.value.isNotEmpty) {
      tempFiltered = tempFiltered.where((post) {
        final title = post['title']?.toString().toLowerCase() ?? '';
        final description = post['description']?.toString().toLowerCase() ?? '';
        final query = searchQuery.value.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    filteredPosts.value = tempFiltered;
  }

  // 현재 선택 가능한 태그 목록 반환 (구독 중인 태그들)
  List<String> getAvailableTags() {
    // 'all' 옵션을 기본으로 추가하고, 구독 중인 태그들을 추가
    return ['all', ...subscribedBoards];
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
      case 'all':
        return '전체 게시물';
      default:
        return boardId;
    }
  }

  Future<List<String>> getUserSubscribedBoards(String userId) async {
    try {
      final response = await _supabaseProvider.client
          .from('subscriptions')
          .select('boards')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return [];
      }

      final boardsField = response['boards'];
      return boardsField != null ? List<String>.from(boardsField) : [];
    } catch (e) {
      print('Error fetching user subscriptions: $e');
      return [];
    }
  }
}
