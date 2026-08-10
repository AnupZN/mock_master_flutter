class Bookmark {
  final String subjectId;
  final String chapterId;
  final int questionId;

  Bookmark({
    required this.subjectId,
    required this.chapterId,
    required this.questionId,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    subjectId: json['subjectId'] ?? '',
    chapterId: json['chapterId'] ?? '',
    questionId: json['questionId'] is int ? json['questionId'] : int.parse(json['questionId'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'chapterId': chapterId,
    'questionId': questionId,
  };
}
