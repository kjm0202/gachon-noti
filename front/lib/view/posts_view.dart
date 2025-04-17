import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:gachon_noti_front/utils/alternative_text_style.dart';
import 'package:gachon_noti_front/utils/korean_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../controller/posts_controller.dart';

class PostsView extends StatefulWidget {
  final Client client;
  final String boardId;
  const PostsView({super.key, required this.client, required this.boardId});

  @override
  State<PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<PostsView> {
  late PostsController _controller;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = PostsController(
      client: widget.client,
      boardId: widget.boardId,
    );
    _initData();

    // 검색어 변경 리스너 등록
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 검색어 변경 이벤트 처리
  void _onSearchChanged() {
    setState(() {
      _controller.searchByTitle(_searchController.text);
    });
  }

  // 태그 필터 변경 이벤트 처리
  void _onTagFilterChanged(String tag) {
    setState(() {
      _controller.filterByTag(tag);
    });
  }

  Future<void> _initData() async {
    await _controller.initUserAndFetchPosts(
      onSuccess: () {
        if (mounted) {
          setState(() {
            _isLoading = _controller.loading;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('구독 정보를 불러오는데 실패했습니다.'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () => _initData(),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _refreshPosts() async {
    await _controller.fetchPosts(
      onSuccess: () {
        if (mounted) {
          setState(() {
            _isLoading = _controller.loading;
          });
        }
      },
      onError: (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('게시물을 불러오는데 실패했습니다.'),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () => _refreshPosts(),
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open link')));
    }
  }

  // 날짜 포맷팅 함수
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
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

  // 태그 선택 UI 구성
  Widget _buildTagSelector() {
    final availableTags = _controller.getAvailableTags();

    if (availableTags.length <= 1) {
      return SizedBox.shrink(); // 태그가 없거나 'all'만 있는 경우 표시하지 않음
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: availableTags.map((tag) {
          final isSelected = _controller.selectedTagFilter == tag;
          final boardName = tag == 'all' ? '전체' : _controller.getBoardName(tag);

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(boardName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onTagFilterChanged(tag);
                }
              },
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  // 검색 바 UI 구성
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: '제목으로 검색',
          prefixIcon: Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          // 키보드에서 검색 버튼을 눌렀을 때 포커스 해제
          _searchFocusNode.unfocus();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_controller.posts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              widget.boardId == 'all'
                  ? '구독 중인 게시판이 없습니다.\n구독 설정에서 게시판을 선택해주세요.'
                  : '게시물이 없습니다.',
              textAlign: TextAlign.center,
              style: AltTextStyle.titleMedium,
            ),
          ],
        ),
      );
    }

    // 검색 결과가 없는 경우
    if (_controller.filteredPosts.isEmpty) {
      return Column(
        children: [
          _buildSearchBar(),
          _buildTagSelector(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다.',
                    textAlign: TextAlign.center,
                    style: AltTextStyle.titleMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSearchBar(),
        _buildTagSelector(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshPosts,
            child: ListView.builder(
              itemCount: _controller.filteredPosts.length,
              padding: EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, idx) {
                final post = _controller.filteredPosts[idx];
                final String boardName = _controller.getBoardName(
                  post['boardId'] ?? '',
                );
                final String dateStr = _formatDate(post['pubDate']);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (post['link'] != null) {
                        _launchUrl(post['link']);
                      }
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 게시판 정보와 날짜
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      boardName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                ],
                              ),

                              SizedBox(height: 10),

                              // 게시물 제목 - 한 줄로 제한
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 24),
                                      child: AutoSizeText(
                                        (post['title'] as String?)?.wrapped ??
                                            '(제목 없음)',
                                        style: AltTextStyle.bodyLarge,
                                        maxLines: 1,
                                        minFontSize: 14,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 4),

                              // 게시물 내용 - 한 줄로 제한하고 말줄임표 처리
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: 24),
                                      child: Text(
                                        post['description']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          height: 1.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 6),
                            ],
                          ),
                        ),

                        // 오른쪽 중앙에 화살표 배치
                        Positioned(
                          right: 16,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
