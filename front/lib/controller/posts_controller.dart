import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/const.dart';

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
  List<String> subscribedBoards = [];
  String searchQuery = ''; // 검색어
  String selectedTagFilter = 'all'; // 선택된 태그 필터, 기본값은 'all'

  // 캐싱 관련 변수
  static Map<String, List<Map<String, dynamic>>> _cachedPosts = {};
  static List<String> _cachedSubscribedBoards = [];
  static DateTime _lastFetchTime = DateTime(1970);
  // 캐시 유효 시간 (5분)
  static const Duration _cacheDuration = Duration(minutes: 5);

  PostsController({required this.client, required this.boardId});

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
    loading = true;
    if (onSuccess != null) onSuccess();

    try {
      List<String> targetBoards =
          boardId == 'all' ? subscribedBoards : [boardId];

      if (targetBoards.isEmpty) {
        posts = [];
        filteredPosts = [];
        loading = false;
        if (onSuccess != null) onSuccess();
        return;
      }

      // 캐시 키 생성 (boardId 또는 'all'+'구독 게시판 목록' 조합)
      final String cacheKey =
          boardId == 'all' ? 'all_${subscribedBoards.join('_')}' : boardId;

      // 캐시 사용 가능하고 강제 새로고침이 아닌 경우, 캐시된 데이터 사용
      if (useCache && !forceRefresh && _cachedPosts.containsKey(cacheKey)) {
        posts = List.from(_cachedPosts[cacheKey]!);
        filteredPosts = List.from(posts);
        loading = false;
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

      final data =
          await queryBuilder.order('created_at', ascending: false).limit(50);

      posts = (data as List<dynamic>).map((doc) {
        // Map 형태로 변환하여 'description'이 없으면 빈 문자열로 설정
        final Map<String, dynamic> data = Map<String, dynamic>.from(doc);
        if (data['description'] == null) {
          data['description'] = '';
        }
        return data;
      }).toList();

      // 캐시 업데이트
      _cachedPosts[cacheKey] = List.from(posts);
      _lastFetchTime = DateTime.now();

      // 초기에는 필터링된 게시물 목록과 전체 게시물 목록이 동일
      filteredPosts = List.from(posts);

      loading = false;
      if (onSuccess != null) onSuccess();
    } catch (err) {
      print('Error fetching posts: $err');
      loading = false;
      if (onError != null) {
        onError(err);
      }
    }
  }

  // 강제 새로고침 수행
  Future<void> forceRefresh({Function? onSuccess, Function? onError}) async {
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
  void filterByTag(String tag) {
    selectedTagFilter = tag;
    _applyFilters();
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
