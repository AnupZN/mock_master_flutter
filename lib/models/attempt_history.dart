class AttemptHistoryItem {
  final String id;
  final String subjectId;
  final String subjectName;
  final String chapterId;
  final String chapterTitle;
  final String date;
  final double score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final double maxScore;
  final double accuracy;
  final int timeTaken;
  final bool? isPracticeMode;
  final String? practiceType;
  final Map<int, int?>? userAnswers;
  final List<int>? questionIds;

  AttemptHistoryItem({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.chapterId,
    required this.chapterTitle,
    required this.date,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.maxScore,
    required this.accuracy,
    required this.timeTaken,
    this.isPracticeMode,
    this.practiceType,
    this.userAnswers,
    this.questionIds,
  });

  factory AttemptHistoryItem.fromJson(Map<String, dynamic> json) {
    Map<int, int?>? parsedAnswers;
    if (json['userAnswers'] != null) {
      final answers = json['userAnswers'] as Map<String, dynamic>;
      parsedAnswers = {};
      answers.forEach((key, value) {
        // Safe cast: JSON numbers may deserialize as int or double.
        parsedAnswers![int.parse(key)] = value == null
            ? null
            : value is int
                ? value
                : (value as num).toInt();
      });
    }

    return AttemptHistoryItem(
      id: json['id'] ?? '',
      subjectId: json['subjectId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      chapterId: json['chapterId'] ?? '',
      chapterTitle: json['chapterTitle'] ?? '',
      date: json['date'] ?? '',
      score: (json['score'] ?? 0).toDouble(),
      totalQuestions: json['totalQuestions'] ?? 0,
      correctCount: json['correctCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      skippedCount: json['skippedCount'] ?? 0,
      maxScore: (json['maxScore'] ?? 0).toDouble(),
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      timeTaken: json['timeTaken'] ?? 0,
      isPracticeMode: json['isPracticeMode'],
      practiceType: json['practiceType'],
      userAnswers: parsedAnswers,
      questionIds: (json['questionIds'] as List?)?.map((e) => e as int).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic>? answers = userAnswers?.map((key, value) => MapEntry(key.toString(), value));
    
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'date': date,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'skippedCount': skippedCount,
      'maxScore': maxScore,
      'accuracy': accuracy,
      'timeTaken': timeTaken,
      if (isPracticeMode != null) 'isPracticeMode': isPracticeMode,
      if (practiceType != null) 'practiceType': practiceType,
      if (answers != null) 'userAnswers': answers,
      if (questionIds != null) 'questionIds': questionIds,
    };
  }
}
