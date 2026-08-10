class SRSCard {
  final String cardId;
  final int questionId;
  final String subjectId;
  final String chapterId;
  final double easeFactor;
  final int interval;
  final int repetitions;
  final String nextReviewDate;
  final String? lastReviewDate;

  SRSCard({
    required this.cardId,
    required this.questionId,
    required this.subjectId,
    required this.chapterId,
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    required this.nextReviewDate,
    this.lastReviewDate,
  });

  factory SRSCard.fromJson(Map<String, dynamic> json) {
    return SRSCard(
      cardId: json['cardId'] ?? '',
      questionId: json['questionId'] ?? 0,
      subjectId: json['subjectId'] ?? '',
      chapterId: json['chapterId'] ?? '',
      easeFactor: (json['easeFactor'] ?? 2.5).toDouble(),
      interval: json['interval'] ?? 0,
      repetitions: json['repetitions'] ?? 0,
      nextReviewDate: json['nextReviewDate'] ?? '',
      lastReviewDate: json['lastReviewDate'],
    );
  }

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'questionId': questionId,
    'subjectId': subjectId,
    'chapterId': chapterId,
    'easeFactor': easeFactor,
    'interval': interval,
    'repetitions': repetitions,
    'nextReviewDate': nextReviewDate,
    'lastReviewDate': lastReviewDate,
  };

  static SRSCard createCard(int questionId, String subjectId, String chapterId) {
    final now = DateTime.now();
    return SRSCard(
      cardId: '${subjectId}_${chapterId}_$questionId',
      questionId: questionId,
      subjectId: subjectId,
      chapterId: chapterId,
      nextReviewDate: now.toIso8601String().split('T')[0],
    );
  }

  static SRSCard updateCard(SRSCard card, int quality) {
    int reps = card.repetitions;
    double ease = card.easeFactor;
    int interval = card.interval;

    if (quality >= 3) {
      if (reps == 0) {
        interval = 1;
      } else if (reps == 1) {
        interval = 6;
      } else {
        interval = (interval * ease).round();
      }
      reps++;
    } else {
      reps = 0;
      interval = 1;
    }

    ease = ease + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    if (ease < 1.3) ease = 1.3;

    final nextDate = DateTime.now().add(Duration(days: interval));

    return SRSCard(
      cardId: card.cardId,
      questionId: card.questionId,
      subjectId: card.subjectId,
      chapterId: card.chapterId,
      easeFactor: ease,
      interval: interval,
      repetitions: reps,
      nextReviewDate: nextDate.toIso8601String().split('T')[0],
      lastReviewDate: DateTime.now().toIso8601String().split('T')[0],
    );
  }

  static bool isDueToday(SRSCard card) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return card.nextReviewDate.compareTo(today) <= 0;
  }
}
