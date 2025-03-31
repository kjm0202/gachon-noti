import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:front/const.dart';

class PostsPage extends StatefulWidget {
  final Client client;
  final String boardId; // 이 예시는 단일 게시판만 보여주는 경우
  const PostsPage({Key? key, required this.client, required this.boardId}) : super(key: key);

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  late Databases _databases;
  List<Map<String, dynamic>> _posts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _databases = Databases(widget.client);
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _loading = true;
    });
    try {
      final result = await _databases.listDocuments(
        databaseId: API.databaseId,
        collectionId: API.collectionsPostsId,
        queries: [
          Query.equal('boardId', widget.boardId),
          Query.orderDesc('pubDate'), // 내림차순 정렬 가능
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.boardId} Posts')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('${widget.boardId} Posts')),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, idx) {
          final post = _posts[idx];
          return ListTile(
            title: Text(post['title'] ?? 'No Title'),
            subtitle: Text(post['pubDate']?.toString() ?? ''),
            onTap: () {
              // 링크를 웹뷰나 브라우저로 열기, etc.
            },
          );
        },
      ),
    );
  }
}
