/// Represents a question the user has answered incorrectly.
/// Kept separate from [Bookmark] to allow independent evolution of each domain.
class WrongQuestion {
  final String subjectId;
  final String chapterId;
  final String questionId;
  final DateTime? addedAt;

  const WrongQuestion({
    required this.subjectId,
    required this.chapterId,
    required this.questionId,
    this.addedAt,
  });

  factory WrongQuestion.fromJson(Map<String, dynamic> json) {
    return WrongQuestion(
      subjectId: json['subject_id'] ?? json['subjectId'] ?? '',
      chapterId: json['chapter_id'] ?? json['chapterId'] ?? '',
      questionId: json['question_id'] ?? json['questionId'] ?? '',
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'subjectId': subjectId,
        'chapterId': chapterId,
        'questionId': questionId,
        if (addedAt != null) 'added_at': addedAt!.toIso8601String(),
      };

  WrongQuestion copyWith({
    String? subjectId,
    String? chapterId,
    String? questionId,
    DateTime? addedAt,
  }) {
    return WrongQuestion(
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      questionId: questionId ?? this.questionId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WrongQuestion &&
          subjectId == other.subjectId &&
          chapterId == other.chapterId &&
          questionId == other.questionId;

  @override
  int get hashCode => Object.hash(subjectId, chapterId, questionId);
}
