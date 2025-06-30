import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import '../../../utils/alternative_text_style.dart';
import '../../../utils/korean_wrapper.dart';
import '../../../utils/url_launcher_utils.dart';
import 'package:intl/intl.dart';
import '../controllers/posts_controller.dart';

class PostsView extends GetView<PostsController> {
  const PostsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 검색바와 태그 선택기
        _buildSearchBar(),
        _buildTagSelector(),

        // 게시물 목록 부분만 조건부 렌더링
        Expanded(
          child: _buildPostsContent(context),
        ),
      ],
    );
  }

  // 태그 선택 UI 구성
  Widget _buildTagSelector() {
    return Obx(() {
      final availableTags = controller.getAvailableTags();

      if (availableTags.length <= 1) {
        return const SizedBox.shrink(); // 태그가 없거나 'all'만 있는 경우 표시하지 않음
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: availableTags.map((tag) {
            final isSelected = controller.selectedTagFilter.value == tag;
            final boardName =
                tag == 'all' ? '전체' : controller.getBoardName(tag);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(boardName),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    controller.filterByTag(tag);
                  }
                },
                backgroundColor:
                    Theme.of(Get.context!).colorScheme.surfaceContainerHighest,
                selectedColor:
                    Theme.of(Get.context!).colorScheme.primaryContainer,
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // 검색 바 UI 구성
  Widget _buildSearchBar() {
    final TextEditingController searchController = TextEditingController();
    final FocusNode searchFocusNode = FocusNode();

    searchController.text = controller.searchQuery.value;

    // 검색어 변경 리스너 등록
    searchController.addListener(() {
      controller.searchByTitle(searchController.text);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Obx(() {
        return TextField(
          controller: searchController,
          focusNode: searchFocusNode,
          decoration: InputDecoration(
            hintText: '제목으로 검색',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(Get.context!)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            // 키보드에서 검색 버튼을 눌렀을 때 포커스 해제
            searchFocusNode.unfocus();
          },
        );
      }),
    );
  }

  // 게시물 목록 콘텐츠를 조건에 따라 표시
  Widget _buildPostsContent(BuildContext context) {
    return Obx(() {
      // 로딩 중인 경우
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // 게시물이 없는 경우
      if (controller.posts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                controller.boardId == 'all'
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
      if (controller.filteredPosts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                '검색 결과가 없습니다.',
                textAlign: TextAlign.center,
                style: AltTextStyle.titleMedium,
              ),
            ],
          ),
        );
      }

      // 게시물 목록 표시
      return RefreshIndicator(
        onRefresh: controller.forceRefresh,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: ListView.builder(
            itemCount: controller.filteredPosts.length +
                (controller.hasMoreData.value ? 1 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, idx) {
              // 마지막 항목이고 더 로드할 데이터가 있는 경우 로딩 인디케이터 표시
              if (idx == controller.filteredPosts.length) {
                return _buildLoadingIndicator();
              }

              final post = controller.filteredPosts[idx];
              final String boardName = controller.getBoardName(
                post['board_id'] ?? '',
              );
              final String dateStr = _formatDate(post['pub_date']);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 게시판 정보와 날짜
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
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
                                const SizedBox(width: 24),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 게시물 제목 - 한 줄로 제한
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
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

                            const SizedBox(height: 4),

                            // 게시물 내용 - 한 줄로 제한하고 말줄임표 처리
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
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

                            const SizedBox(height: 6),
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
      );
    });
  }

  // 스크롤 이벤트 처리
  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      if (notification.metrics.pixels >=
          notification.metrics.maxScrollExtent * 0.9) {
        _loadMoreData();
      }
    }
    return false;
  }

  // 추가 데이터 로드
  Future<void> _loadMoreData() async {
    if (!controller.loadingMore.value && controller.hasMoreData.value) {
      await controller.loadMorePosts();
    }
  }

  // 로딩 인디케이터 위젯
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  // URL 실행
  Future<void> _launchUrl(String url) async {
    await UrlLauncherUtils.launchUrl(url);
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
}
