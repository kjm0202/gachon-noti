import 'package:appwrite/appwrite.dart';
import '../utils/const.dart';

class PostsController {
  final Client client;
  final String boardId;
  late Account _account;
  late Databases _databases;
  List<Map<String, dynamic>> posts = [];
  bool loading = true;
  List<String> subscribedBoards = [];

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

      posts = result.documents.map((doc) => doc.data).toList();
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
        return '글로벌미래캠퍼스 기숙사';
      case 'dormMedical':
        return '메디컬캠퍼스 기숙사';
      case 'all':
        return '전체 게시물';
      default:
        return boardId;
    }
  }
}
