import 'package:appwrite/appwrite.dart';
import '../utils/const.dart';

class PostsController {
  final Client client;
  final String boardId;
  late Account _account;
  late Databases _databases;
  List<Map<String, dynamic>> posts = [];
  List<Map<String, dynamic>> filteredPosts = []; // 필터링된 게시물 목록
  bool loading = true;
  List<String> subscribedBoards = [];
  String searchQuery = ''; // 검색어
  String selectedTagFilter = 'all'; // 선택된 태그 필터, 기본값은 'all'

  PostsController({required this.client, required this.boardId}) {
    _account = Account(client);
    _databases = Databases(client);
  }

  Future<void> initUserAndFetchPosts({
    Function? onSuccess,
    Function? onError,
  }) async {
    try {
      final user = await _account.get();

      // userId로 구독 문서 찾기
      final subscriptions = await _databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsSubscriptionsId,
        queries: [Query.equal('userId', user.$id)],
      );

      if (subscriptions.documents.isNotEmpty) {
        final doc = subscriptions.documents.first;
        subscribedBoards = List<String>.from(doc.data['boards'] ?? []);
      } else {
        subscribedBoards = [];
      }

      await fetchPosts(onSuccess: onSuccess);
    } catch (e) {
      print('Error initializing: $e');
      loading = false;
      subscribedBoards = [];

      if (onError != null) {
        onError(e);
      }
    }
  }

  Future<void> fetchPosts({Function? onSuccess, Function? onError}) async {
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

      final result = await _databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsPostsId,
        queries: [
          Query.equal('boardId', targetBoards),
          Query.orderDesc('pubDate'),
          Query.limit(50),
        ],
      );

      posts =
          result.documents.map((doc) {
            // description이 없는 경우 빈 문자열로 설정
            final data = doc.data;
            if (data['description'] == null) {
              data['description'] = '';
            }
            return data;
          }).toList();

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
      tempFiltered =
          tempFiltered.where((post) {
            return post['boardId'] == selectedTagFilter;
          }).toList();
    }

    // 검색어가 있는 경우 제목 또는 내용으로 필터링
    if (searchQuery.isNotEmpty) {
      tempFiltered =
          tempFiltered.where((post) {
            final title = post['title']?.toString().toLowerCase() ?? '';
            final description =
                post['description']?.toString().toLowerCase() ?? '';
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
        return '글캠 기숙사';
      case 'dormMedical':
        return '메캠 기숙사';
      case 'all':
        return '전체 게시물';
      default:
        return boardId;
    }
  }
}
