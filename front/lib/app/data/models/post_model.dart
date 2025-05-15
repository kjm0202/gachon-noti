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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'board_id': boardId,
      'title': title,
      'description': description,
      'link': link,
      'author': author,
      'created_at': createdAt.toIso8601String(),
    };
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
