import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../data/services/supabase_service.dart';
import '../../../routes/app_routes.dart';

class PostsController extends GetxController {
  final SupabaseService _supabaseProvider = Get.find<SupabaseService>();
  final String boardId;
  final posts = <Map<String, dynamic>>[].obs;
  final filteredPosts = <Map<String, dynamic>>[].obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final subscribedBoards = <String>[].obs;
  final searchQuery = ''.obs;
  final selectedTagFilter = 'all'.obs;
  final hasMoreData = true.obs;
  late final TextEditingController searchController;
  late final FocusNode searchFocusNode;
  int _page = 1;
  int _requestVersion = 0;
  int _subscriptionVersion = 0;
  Timer? _searchDebounce;
  static const _limit = 20;
  // Controller-owned cache cannot survive logout/navigation to another account.
  final _cache = <String, List<Map<String, dynamic>>>{};
  final _cacheTimes = <String, DateTime>{};
  PostsController({required this.boardId});

  @override
  void onInit() {
    super.onInit();
    searchController = TextEditingController();
    searchFocusNode = FocusNode();
    searchController.addListener(() => searchByTitle(searchController.text));
    initUserAndFetchPosts();
  }

  @override
  void onClose() {
    _requestVersion++;
    _subscriptionVersion++;
    _searchDebounce?.cancel();
    searchController.dispose();
    searchFocusNode.dispose();
    _cache.clear();
    _cacheTimes.clear();
    super.onClose();
  }

  void resetPagination() {
    _requestVersion++;
    _page = 1;
    loadingMore.value = false;
    hasMoreData.value = true;
    posts.clear();
    filteredPosts.clear();
  }

  Future<void> initUserAndFetchPosts() async {
    await refreshSubscriptions();
    if (isClosed) return;
    resetPagination();
    await fetchPosts();
  }

  Future<void> refreshSubscriptions() async {
    final user = _supabaseProvider.client.auth.currentUser;
    final version = ++_subscriptionVersion;
    try {
      final row = user == null
          ? null
          : await _supabaseProvider.client
              .from('subscriptions')
              .select('boards')
              .eq('user_id', user.id)
              .maybeSingle();
      if (isClosed ||
          version != _subscriptionVersion ||
          _supabaseProvider.client.auth.currentUser?.id != user?.id) return;
      subscribedBoards.assignAll(List<String>.from(row?['boards'] ?? []));
    } catch (error) {
      if (!isClosed && version == _subscriptionVersion) {
        subscribedBoards.clear();
      }
      debugPrint('Subscription load failed: $error');
    }
  }

  Future<void> fetchPosts(
      {bool useCache = true, bool forceRefresh = false}) async {
    final version = ++_requestVersion;
    final userId = _supabaseProvider.client.auth.currentUser?.id;
    final page = _page;
    final search = searchQuery.value.trim();
    final tag = selectedTagFilter.value;
    final boards = (boardId == 'all' ? subscribedBoards.toList() : [boardId])
      ..sort();
    bool current() =>
        !isClosed &&
        version == _requestVersion &&
        userId == _supabaseProvider.client.auth.currentUser?.id;
    if (page == 1) {
      loading.value = true;
    } else {
      loadingMore.value = true;
    }
    try {
      if (userId == null || boards.isEmpty) {
        posts.clear();
        filteredPosts.clear();
        hasMoreData.value = false;
        return;
      }
      final key = jsonEncode([userId, boards, tag, search]);
      final cachedAt = _cacheTimes[key];
      if (page == 1 &&
          useCache &&
          !forceRefresh &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < const Duration(minutes: 5)) {
        posts.assignAll(_cache[key]!);
        filteredPosts.assignAll(posts);
        hasMoreData.value = posts.length == _limit;
        _page = 2;
        return;
      }
      var query = _supabaseProvider.client
          .from('posts')
          .select()
          .inFilter('board_id', boards);
      if (tag != 'all') query = query.eq('board_id', tag);
      if (search.isNotEmpty) {
        // Quote the PostgREST value, preserving punctuation as literal search text.
        final literal = search
            .replaceAll('\\', '\\\\')
            .replaceAll('%', '\\%')
            .replaceAll('_', '\\_');
        final pattern = jsonEncode('%$literal%');
        query = query.or('title.ilike.$pattern,description.ilike.$pattern');
      }
      final start = (page - 1) * _limit;
      final data = await query
          .order('pub_date', ascending: false)
          .order('id', ascending: false)
          .range(start, start + _limit - 1);
      if (!current()) return;
      final rows = data
          .map((row) => <String, dynamic>{
                ...row,
                'description': row['description'] ?? ''
              })
          .toList();
      if (page == 1) {
        posts.assignAll(rows);
      } else {
        posts.addAll(rows);
      }
      filteredPosts.assignAll(posts);
      hasMoreData.value = rows.length == _limit;
      _page = page + 1;
      if (page == 1) {
        _cache[key] = List.from(rows);
        _cacheTimes[key] = DateTime.now();
      }
    } catch (error) {
      debugPrint('Post load failed: $error');
    } finally {
      if (current()) {
        loading.value = false;
        loadingMore.value = false;
      }
    }
  }

  Future<void> loadMorePosts() async {
    if (loading.value || loadingMore.value || !hasMoreData.value) return;
    await fetchPosts(useCache: false);
  }

  Future<void> forceRefresh() async {
    _searchDebounce?.cancel();
    _requestVersion++;
    await refreshSubscriptions();
    if (isClosed) return;
    _cache.clear();
    _cacheTimes.clear();
    if (!subscribedBoards.contains(selectedTagFilter.value))
      selectedTagFilter.value = 'all';
    resetPagination();
    await fetchPosts(useCache: false, forceRefresh: true);
  }

  Future<void> refreshAfterSubscriptionChange() => forceRefresh();

  void searchByTitle(String query) {
    _searchDebounce?.cancel();
    searchQuery.value = query;
    resetPagination();
    loading.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      fetchPosts(useCache: false);
    });
  }

  Future<void> filterByTag(String tag) async {
    _searchDebounce?.cancel();
    selectedTagFilter.value = tag;
    resetPagination();
    await fetchPosts();
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

  // 검색 바 관련 메서드들
  void clearSearch() {
    searchController.clear();
  }

  void unfocusSearch() {
    searchFocusNode.unfocus();
  }

  // URL 실행
  Future<void> launchUrl(String url) async {
    if (url.trim().isEmpty) {
      return;
    }

    await Get.toNamed(Routes.WEBVIEW, arguments: url);
  }

  // 날짜 포맷팅 함수
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      // 오늘 날짜인 경우 시간만 표시
      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(date);
      }
      // 올해인 경우 월-일만 표시
      else if (date.year == now.year) {
        return DateFormat('MM-dd').format(date);
      }
      // 다른 연도인 경우 연-월-일 표시
      else {
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      return dateStr;
    }
  }

  // 스크롤 이벤트 처리
  bool handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels >=
          notification.metrics.maxScrollExtent * 0.9) {
        loadMorePosts();
      }
    }
    return false;
  }
}
