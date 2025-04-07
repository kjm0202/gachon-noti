import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = PostsController(
      client: widget.client,
      boardId: widget.boardId,
    );
    _initData();
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        itemCount: _controller.posts.length,
        itemBuilder: (context, idx) {
          final post = _controller.posts[idx];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                post['title'] ?? '(제목 없음)',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_controller.getBoardName(post['boardId'] ?? '')),
                  Text(post['pubDate']?.toString() ?? ''),
                ],
              ),
              onTap: () {
                if (post['link'] != null) {
                  _launchUrl(post['link']);
                }
              },
            ),
          );
        },
      ),
    );
  }
}
