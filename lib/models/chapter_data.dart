import 'question.dart';

class ChapterData {
  final String subject;
  final String chapter;
  final int timePerQuestion;
  final double positiveMarks;
  final double negativeMarks;
  final List<Question> questions;
  final int? maxAttempts;

  ChapterData({
    required this.subject,
    required this.chapter,
    required this.timePerQuestion,
    required this.positiveMarks,
    required this.negativeMarks,
    required this.questions,
    this.maxAttempts,
  });

  factory ChapterData.fromJson(Map<String, dynamic> json) {
    return ChapterData(
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      timePerQuestion: json['timePerQuestion'] ?? 60,
      positiveMarks: (json['positiveMarks'] ?? 1.0).toDouble(),
      negativeMarks: (json['negativeMarks'] ?? 0.0).toDouble(),
      questions: (json['questions'] as List?)?.map((q) => Question.fromJson(q)).toList() ?? [],
      maxAttempts: json['maxAttempts'],
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'chapter': chapter,
    'timePerQuestion': timePerQuestion,
    'positiveMarks': positiveMarks,
    'negativeMarks': negativeMarks,
    'questions': questions.map((q) => q.toJson()).toList(),
    'maxAttempts': maxAttempts,
  };
}
