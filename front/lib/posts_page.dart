import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:front/const.dart';
import 'package:url_launcher/url_launcher.dart';

class PostsPage extends StatefulWidget {
  final Client client;
  final String boardId;
  const PostsPage({Key? key, required this.client, required this.boardId})
    : super(key: key);

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  late Account _account;
  late Databases _databases;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  List<String> _subscribedBoards = [];

  @override
  void initState() {
    super.initState();
    _account = Account(widget.client);
    _databases = Databases(widget.client);
    _initUserAndFetchPosts();
  }

  Future<void> _initUserAndFetchPosts() async {
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
        setState(() {
          _subscribedBoards = List<String>.from(doc.data['boards'] ?? []);
        });
      } else {
        setState(() {
          _subscribedBoards = [];
        });
      }

      await _fetchPosts();
    } catch (e) {
      print('Error initializing: $e');
      setState(() {
        _loading = false;
        _subscribedBoards = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('구독 정보를 불러오는데 실패했습니다.'),
            action: SnackBarAction(
              label: '다시 시도',
              onPressed: () => _initUserAndFetchPosts(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
    });

    try {
      List<String> targetBoards =
          widget.boardId == 'all' ? _subscribedBoards : [widget.boardId];

      if (targetBoards.isEmpty) {
        setState(() {
          _posts = [];
          _loading = false;
        });
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

      setState(() {
        _posts = result.documents.map((doc) => doc.data).toList();
        _loading = false;
      });
    } catch (err) {
      print('Error fetching posts: $err');
      setState(() {
        _loading = false;
      });
    }
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
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
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
      onRefresh: _fetchPosts,
      child: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, idx) {
          final post = _posts[idx];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                post['title'] ?? 'No Title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['boardId'] ?? ''),
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
