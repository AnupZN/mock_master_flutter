import 'question.dart';

class ExamSession {
  final String subjectId;
  final String chapterId;
  final String subjectName;
  final String chapterTitle;
  final List<Question> questions;
  final Map<int, int?> userAnswers;
  final Map<int, bool> markedForReview;
  final Map<int, bool> visitedQuestions;
  final int timeRemaining;
  final int totalTime;
  final bool isPracticeMode;
  final String? practiceType;
  final double positiveMarks;
  final double negativeMarks;

  ExamSession({
    required this.subjectId,
    required this.chapterId,
    required this.subjectName,
    required this.chapterTitle,
    required this.questions,
    required this.userAnswers,
    required this.markedForReview,
    required this.visitedQuestions,
    required this.timeRemaining,
    required this.totalTime,
    required this.isPracticeMode,
    this.practiceType,
    required this.positiveMarks,
    required this.negativeMarks,
  });

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    Map<int, int?> parsedAnswers = {};
    if (json['userAnswers'] != null) {
      (json['userAnswers'] as Map<String, dynamic>).forEach((key, value) {
        parsedAnswers[int.parse(key)] = value as int?;
      });
    }

    Map<int, bool> parsedReview = {};
    if (json['markedForReview'] != null) {
      (json['markedForReview'] as Map<String, dynamic>).forEach((key, value) {
        parsedReview[int.parse(key)] = value as bool;
      });
    }

    Map<int, bool> parsedVisited = {};
    if (json['visitedQuestions'] != null) {
      (json['visitedQuestions'] as Map<String, dynamic>).forEach((key, value) {
        parsedVisited[int.parse(key)] = value as bool;
      });
    }

    return ExamSession(
      subjectId: json['subjectId'] ?? '',
      chapterId: json['chapterId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      chapterTitle: json['chapterTitle'] ?? '',
      questions: (json['questions'] as List?)?.map((q) => Question.fromJson(q)).toList() ?? [],
      userAnswers: parsedAnswers,
      markedForReview: parsedReview,
      visitedQuestions: parsedVisited,
      timeRemaining: json['timeRemaining'] ?? 0,
      totalTime: json['totalTime'] ?? 0,
      isPracticeMode: json['isPracticeMode'] ?? false,
      practiceType: json['practiceType'],
      positiveMarks: (json['positiveMarks'] ?? 1.0).toDouble(),
      negativeMarks: (json['negativeMarks'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'chapterId': chapterId,
      'subjectName': subjectName,
      'chapterTitle': chapterTitle,
      'questions': questions.map((q) => q.toJson()).toList(),
      'userAnswers': userAnswers.map((key, value) => MapEntry(key.toString(), value)),
      'markedForReview': markedForReview.map((key, value) => MapEntry(key.toString(), value)),
      'visitedQuestions': visitedQuestions.map((key, value) => MapEntry(key.toString(), value)),
      'timeRemaining': timeRemaining,
      'totalTime': totalTime,
      'isPracticeMode': isPracticeMode,
      'practiceType': practiceType,
      'positiveMarks': positiveMarks,
      'negativeMarks': negativeMarks,
    };
  }

  ExamSession copyWith({
    String? subjectId,
    String? chapterId,
    String? subjectName,
    String? chapterTitle,
    List<Question>? questions,
    Map<int, int?>? userAnswers,
    Map<int, bool>? markedForReview,
    Map<int, bool>? visitedQuestions,
    int? timeRemaining,
    int? totalTime,
    bool? isPracticeMode,
    String? practiceType,
    double? positiveMarks,
    double? negativeMarks,
  }) {
    return ExamSession(
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
      subjectName: subjectName ?? this.subjectName,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      questions: questions ?? this.questions,
      userAnswers: userAnswers ?? this.userAnswers,
      markedForReview: markedForReview ?? this.markedForReview,
      visitedQuestions: visitedQuestions ?? this.visitedQuestions,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      totalTime: totalTime ?? this.totalTime,
      isPracticeMode: isPracticeMode ?? this.isPracticeMode,
      practiceType: practiceType ?? this.practiceType,
      positiveMarks: positiveMarks ?? this.positiveMarks,
      negativeMarks: negativeMarks ?? this.negativeMarks,
    );
  }
}
