import 'package:supabase_flutter/supabase_flutter.dart';

class Post {
  final String id;
  final String boardId;
  final String title;
  final String? description;
  final String link;
  final String? author;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.boardId,
    required this.title,
    this.description,
    required this.link,
    this.author,
    required this.createdAt,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['id'],
      boardId: map['board_id'],
      title: map['title'],
      description: map['description'],
      link: map['link'],
      author: map['author'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  String getBoardName() {
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
}

class PostsController {
  final SupabaseClient client;
  final String boardId;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> filteredPosts = []; // 필터링된 게시물 목록
  bool loading = true;
  bool loadingMore = false; // 추가 데이터 로딩 중 상태
  List<String> subscribedBoards = [];
  String searchQuery = ''; // 검색어
  String selectedTagFilter = 'all'; // 선택된 태그 필터, 기본값은 'all'

  // 페이지네이션 관련 변수
  int _page = 1;
  int _limit = 20; // 한 번에 가져올 게시물 수
  bool hasMoreData = true; // 더 가져올 데이터가 있는지 여부

  // 캐싱 관련 변수
  static Map<String, List<Map<String, dynamic>>> _cachedPosts = {};
  static List<String> _cachedSubscribedBoards = [];
  static DateTime _lastFetchTime = DateTime(1970);
  // 캐시 유효 시간 (5분)
  static const Duration _cacheDuration = Duration(minutes: 5);

  PostsController({required this.client, required this.boardId});

  // 페이지를 리셋하고 처음부터 데이터를 가져오는 메소드
  void resetPagination() {
    _page = 1;
    hasMoreData = true;
    posts = [];
    filteredPosts = [];
  }

  Future<void> initUserAndFetchPosts({
    Function? onSuccess,
    Function? onError,
  }) async {
    try {
      // 현재 시간
      final now = DateTime.now();

      // 캐시 유효 시간 확인
      final bool isCacheValid = now.difference(_lastFetchTime) < _cacheDuration;

      // 구독한 게시판 정보 로드
      if (_cachedSubscribedBoards.isEmpty || !isCacheValid) {
        final user = await client.auth.currentUser;

        if (user != null) {
          // userId로 구독 문서 찾기
          final response = await client
              .from('subscriptions')
              .select('boards')
              .eq('user_id', user.id)
              .maybeSingle();

          if (response != null) {
            _cachedSubscribedBoards =
                List<String>.from(response['boards'] ?? []);
          } else {
            _cachedSubscribedBoards = [];
          }
        } else {
          _cachedSubscribedBoards = [];
        }
      }

      // 캐시된 구독 보드 정보를 현재 컨트롤러에 설정
      subscribedBoards = _cachedSubscribedBoards;

      // 페이지네이션 리셋 후 첫 페이지 로드
      resetPagination();
      await fetchPosts(onSuccess: onSuccess, useCache: isCacheValid);
    } catch (e) {
      print('Error initializing: $e');
      loading = false;
      subscribedBoards = [];

      if (onError != null) {
        onError(e);
      }
    }
  }

  Future<void> fetchPosts(
      {Function? onSuccess,
      Function? onError,
      bool useCache = true,
      bool forceRefresh = false}) async {
    // 첫 페이지를 로드하는 경우에만 loading을 true로 설정
    if (_page == 1) {
      loading = true;
      if (onSuccess != null) onSuccess();
    } else {
      loadingMore = true;
    }

    try {
      List<String> targetBoards =
          boardId == 'all' ? subscribedBoards : [boardId];

      if (targetBoards.isEmpty) {
        posts = [];
        filteredPosts = [];
        loading = false;
        loadingMore = false;
        hasMoreData = false;
        if (onSuccess != null) onSuccess();
        return;
      }

      // 캐시 키 생성 (boardId + 페이지 또는 'all'+구독 게시판 목록 + 페이지 조합)
      final String cacheKey = boardId == 'all'
          ? 'all_${subscribedBoards.join('_')}_page$_page'
          : '${boardId}_page$_page';

      // 캐시 사용 가능하고 강제 새로고침이 아닌 경우, 캐시된 데이터 사용
      if (_page == 1 &&
          useCache &&
          !forceRefresh &&
          _cachedPosts.containsKey(cacheKey)) {
        // 첫 페이지만 캐시 사용
        posts = List.from(_cachedPosts[cacheKey]!);
        filteredPosts = List.from(posts);
        loading = false;
        loadingMore = false;
        if (onSuccess != null) onSuccess();
        return;
      }

      var queryBuilder = client.from('posts').select();

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
      hasMoreData = newPosts.length == _limit;

      // 페이지가 1이면 posts를 새로 설정, 아니면 기존 posts에 추가
      if (_page == 1) {
        posts = newPosts;
      } else {
        posts.addAll(newPosts);
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

      loading = false;
      loadingMore = false;
      if (onSuccess != null) onSuccess();
    } catch (err) {
      print('Error fetching posts: $err');
      loading = false;
      loadingMore = false;
      if (onError != null) {
        onError(err);
      }
    }
  }

  // 다음 페이지 로드
  Future<void> loadMorePosts({Function? onSuccess, Function? onError}) async {
    if (loadingMore || !hasMoreData) return; // 이미 로딩 중이거나 더 이상 데이터가 없으면 리턴

    await fetchPosts(
      onSuccess: onSuccess,
      onError: onError,
      useCache: false,
    );
  }

  // 강제 새로고침 수행
  Future<void> forceRefresh({Function? onSuccess, Function? onError}) async {
    resetPagination(); // 페이지네이션 리셋
    await fetchPosts(
        onSuccess: onSuccess,
        onError: onError,
        useCache: false,
        forceRefresh: true);
  }

  // 검색어로 게시물 필터링
  void searchByTitle(String query) {
    searchQuery = query;
    _applyFilters();
  }

  // 태그로 게시물 필터링
  Future<void> filterByTag(String tag,
      {Function? onSuccess, Function? onError}) async {
    selectedTagFilter = tag;

    try {
      loading = true;
      // 페이지네이션 리셋
      resetPagination();

      if (tag == 'all') {
        // 'all'인 경우 모든 구독 게시판의 게시물 새로 가져오기
        if (subscribedBoards.isEmpty) {
          // 구독 게시판이 없는 경우
          posts = [];
          filteredPosts = [];
          loading = false;
          if (onSuccess != null) onSuccess();
          return;
        }

        // 캐시 키 생성
        final String cacheKey = 'all_${subscribedBoards.join('_')}_page1';

        // 모든 구독 게시판의 게시물 로드
        final data = await client
            .from('posts')
            .select()
            .inFilter('board_id', subscribedBoards)
            .order('pub_date', ascending: false)
            .limit(_limit); // 페이지당 크기만큼만 가져옴

        // 결과 처리
        posts = (data as List<dynamic>).map((doc) {
          final Map<String, dynamic> postData = Map<String, dynamic>.from(doc);
          if (postData['description'] == null) {
            postData['description'] = '';
          }
          return postData;
        }).toList();

        // 더 가져올 데이터가 있는지 확인
        hasMoreData = posts.length == _limit;

        // 페이지 증가
        _page = 2;

        // 캐시 업데이트
        _cachedPosts[cacheKey] = List.from(posts);
        _lastFetchTime = DateTime.now();

        // 필터링된 결과와 전체 결과 동일하게 설정
        filteredPosts = List.from(posts);
      } else {
        // 특정 게시판의 게시물만 가져오는 쿼리 직접 실행
        final data = await client
            .from('posts')
            .select()
            .eq('board_id', tag) // 선택한 태그로 필터링
            .order('pub_date', ascending: false)
            .limit(_limit); // 페이지당 크기만큼만 가져옴

        // 결과 처리
        posts = (data as List<dynamic>).map((doc) {
          final Map<String, dynamic> postData = Map<String, dynamic>.from(doc);
          if (postData['description'] == null) {
            postData['description'] = '';
          }
          return postData;
        }).toList();

        // 더 가져올 데이터가 있는지 확인
        hasMoreData = posts.length == _limit;

        // 페이지 증가
        _page = 2;

        // 캐시 업데이트
        _cachedPosts[tag + '_page1'] = List.from(posts);
        _lastFetchTime = DateTime.now();

        // 필터링된 결과와 전체 결과 동일하게 설정
        filteredPosts = List.from(posts);
      }

      loading = false;
      if (onSuccess != null) onSuccess();
    } catch (err) {
      print('Error fetching posts for tag $tag: $err');
      loading = false;
      if (onError != null) {
        onError(err);
      }
    }
  }

  // 검색어와 태그 필터 모두 적용
  void _applyFilters() {
    // 먼저 태그 필터 적용
    var tempFiltered = List<Map<String, dynamic>>.from(posts);

    // 'all'이 아닌 경우에만 태그 필터링 적용
    if (selectedTagFilter != 'all') {
      tempFiltered = tempFiltered.where((post) {
        return post['board_id'] == selectedTagFilter;
      }).toList();
    }

    // 검색어가 있는 경우 제목 또는 내용으로 필터링
    if (searchQuery.isNotEmpty) {
      tempFiltered = tempFiltered.where((post) {
        final title = post['title']?.toString().toLowerCase() ?? '';
        final description = post['description']?.toString().toLowerCase() ?? '';
        final query = searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    filteredPosts = tempFiltered;
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
      final response = await client
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
