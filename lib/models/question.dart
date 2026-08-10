class QuestionTable {
  final List<String> headers;
  final List<List<String>> rows;

  QuestionTable({required this.headers, required this.rows});

  factory QuestionTable.fromJson(Map<String, dynamic> json) {
    return QuestionTable(
      headers: List<String>.from(json['headers'] ?? []),
      rows: (json['rows'] as List?)?.map((row) => List<String>.from(row)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'headers': headers,
    'rows': rows,
  };
}

class Question {
  final int id;
  final String question;
  final List<String> options;
  final int correct;
  final String explanation;
  final String difficulty;
  final List<String> tags;
  final String? questionHi;
  final List<String>? optionsHi;
  final String? explanationHi;
  final QuestionTable? table;
  final QuestionTable? tableHi;
  final String? subjectId;
  final String? chapterId;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    required this.difficulty,
    required this.tags,
    this.questionHi,
    this.optionsHi,
    this.explanationHi,
    this.table,
    this.tableHi,
    this.subjectId,
    this.chapterId,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correct: json['correct'] ?? 0,
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'Medium',
      tags: List<String>.from(json['tags'] ?? []),
      questionHi: json['question_hi'] ?? json['questionHi'],
      optionsHi: json['options_hi'] != null ? List<String>.from(json['options_hi']) : (json['optionsHi'] != null ? List<String>.from(json['optionsHi']) : null),
      explanationHi: json['explanation_hi'] ?? json['explanationHi'],
      table: json['table'] != null ? QuestionTable.fromJson(json['table']) : null,
      tableHi: json['table_hi'] != null ? QuestionTable.fromJson(json['table_hi']) : (json['tableHi'] != null ? QuestionTable.fromJson(json['tableHi']) : null),
      subjectId: json['subjectId'],
      chapterId: json['chapterId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correct': correct,
      'explanation': explanation,
      'difficulty': difficulty,
      'tags': tags,
      'question_hi': questionHi,
      'options_hi': optionsHi,
      'explanation_hi': explanationHi,
      'table': table?.toJson(),
      'table_hi': tableHi?.toJson(),
      'subjectId': subjectId,
      'chapterId': chapterId,
    };
  }

  Question copyWith({
    int? id,
    String? question,
    List<String>? options,
    int? correct,
    String? explanation,
    String? difficulty,
    List<String>? tags,
    String? questionHi,
    List<String>? optionsHi,
    String? explanationHi,
    QuestionTable? table,
    QuestionTable? tableHi,
    String? subjectId,
    String? chapterId,
  }) {
    return Question(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correct: correct ?? this.correct,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      tags: tags ?? this.tags,
      questionHi: questionHi ?? this.questionHi,
      optionsHi: optionsHi ?? this.optionsHi,
      explanationHi: explanationHi ?? this.explanationHi,
      table: table ?? this.table,
      tableHi: tableHi ?? this.tableHi,
      subjectId: subjectId ?? this.subjectId,
      chapterId: chapterId ?? this.chapterId,
    );
  }
}
