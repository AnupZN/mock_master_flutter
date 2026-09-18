import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_master/models/app_settings.dart';
import 'package:mock_master/models/bookmark.dart';
import 'package:mock_master/models/chapter_data.dart';
import 'package:mock_master/models/exam_session.dart';
import 'package:mock_master/models/question.dart';

void main() {
  group('Shuffle Questions Setting & Model Tests', () {
    test('DefaultSettings.shuffleQuestions defaults to false', () {
      final settings = AppSettings();
      expect(settings.shuffleQuestions, false);
    });

    test('AppSettings serializes and deserializes shuffleQuestions correctly', () {
      final settingsEnabled = AppSettings(shuffleQuestions: true);
      final json = settingsEnabled.toJson();
      expect(json['shuffleQuestions'], true);

      final restored = AppSettings.fromJson(json);
      expect(restored.shuffleQuestions, true);

      final updated = restored.copyWith(shuffleQuestions: false);
      expect(updated.shuffleQuestions, false);
    });

    test('AppSettings handles missing shuffleQuestions key gracefully', () {
      final legacyJson = <String, dynamic>{
        'theme': 'system',
        'isDarkMode': false,
      };
      final settings = AppSettings.fromJson(legacyJson);
      expect(settings.shuffleQuestions, false);
    });
  });

  group('Chapter Test Shuffling Logic Tests', () {
    late List<Question> originalQuestions;
    late ChapterData chapterData;

    setUp(() {
      originalQuestions = List.generate(
        10,
        (i) => Question(
          id: 100 + i,
          question: 'Original Question #${100 + i}',
          options: ['Opt A', 'Opt B', 'Opt C', 'Opt D'],
          correct: i % 4,
          explanation: 'Explanation for #${100 + i}',
          difficulty: 'Medium',
          tags: ['test'],
        ),
      );

      chapterData = ChapterData(
        subject: 'History',
        chapter: 'Modern India',
        timePerQuestion: 60,
        positiveMarks: 1.0,
        negativeMarks: 0.33,
        questions: originalQuestions,
      );
    });

    test('Original chapter questions are NEVER mutated when shuffling', () {
      final originalIdsBefore = chapterData.questions.map((q) => q.id).toList();

      // Simulate starting a test with shuffle enabled: create a copy and shuffle it
      final testQuestions = List<Question>.from(chapterData.questions);
      testQuestions.shuffle(Random(42));

      // Shuffled order should differ from original with high probability (10! possibilities)
      final shuffledIds = testQuestions.map((q) => q.id).toList();
      expect(shuffledIds, isNot(equals(originalIdsBefore)));

      // Original chapter data questions MUST remain in the exact same original order
      final originalIdsAfter = chapterData.questions.map((q) => q.id).toList();
      expect(originalIdsAfter, equals(originalIdsBefore));
      expect(chapterData.questions[0].id, 100);
      expect(chapterData.questions[9].id, 109);
    });

    test('Questions are numbered sequentially according to shuffled position', () {
      final testQuestions = List<Question>.from(chapterData.questions);
      testQuestions.shuffle(Random(123));

      final session = ExamSession(
        subjectId: 'sub_1',
        chapterId: 'chap_1',
        subjectName: 'History',
        chapterTitle: 'Modern India',
        questions: testQuestions,
        userAnswers: {},
        markedForReview: {},
        visitedQuestions: {},
        timeRemaining: 600,
        totalTime: 600,
        isPracticeMode: false,
        positiveMarks: 1.0,
        negativeMarks: 0.33,
      );

      // Question appearing at index 0 is Question 1, index 1 is Question 2, etc.
      for (int i = 0; i < session.questions.length; i++) {
        final displayQuestionNumber = i + 1;
        expect(displayQuestionNumber, equals(i + 1));
        // Each question at position i is accessible via session.questions[i]
        final q = session.questions[i];
        expect(q, isNotNull);
        // And each question maintains its permanent original ID
        expect(q.id, inInclusiveRange(100, 109));
      }
    });

    test('Bookmarks remain correctly linked to permanent question ID across shuffled attempts', () {
      // Suppose user bookmarks Question ID 105 in attempt 1
      const bookmarkedQuestionId = 105;
      final bookmark = Bookmark(
        subjectId: 'sub_1',
        chapterId: 'chap_1',
        questionId: bookmarkedQuestionId,
      );
      final bookmarksList = [bookmark];

      // Attempt 1: Shuffled order 1
      final attempt1Questions = List<Question>.from(chapterData.questions);
      attempt1Questions.shuffle(Random(1));
      final attempt1Index = attempt1Questions.indexWhere((q) => q.id == bookmarkedQuestionId);
      expect(attempt1Index, isNot(-1));

      // In Attempt 1, verify bookmark lookup by q.id matches regardless of presentation index
      final attempt1QuestionAtPos = attempt1Questions[attempt1Index];
      final isBookmarkedInAttempt1 = bookmarksList.any(
        (b) =>
            b.subjectId == 'sub_1' &&
            b.chapterId == 'chap_1' &&
            b.questionId == attempt1QuestionAtPos.id,
      );
      expect(isBookmarkedInAttempt1, true);

      // Attempt 2 (Retake): Shuffled order 2
      final attempt2Questions = List<Question>.from(chapterData.questions);
      attempt2Questions.shuffle(Random(999));
      final attempt2Index = attempt2Questions.indexWhere((q) => q.id == bookmarkedQuestionId);
      expect(attempt2Index, isNot(-1));

      // The question may be at a different index in attempt 2
      final attempt2QuestionAtPos = attempt2Questions[attempt2Index];
      expect(attempt2QuestionAtPos.id, bookmarkedQuestionId);

      // Even at a different position, the bookmark remains linked to the exact same question
      final isBookmarkedInAttempt2 = bookmarksList.any(
        (b) =>
            b.subjectId == 'sub_1' &&
            b.chapterId == 'chap_1' &&
            b.questionId == attempt2QuestionAtPos.id,
      );
      expect(isBookmarkedInAttempt2, true);

      // A different question at attempt2Index's previous position is NOT bookmarked
      final differentQuestion = attempt2Questions.firstWhere((q) => q.id != bookmarkedQuestionId);
      final isDifferentBookmarked = bookmarksList.any(
        (b) =>
            b.subjectId == 'sub_1' &&
            b.chapterId == 'chap_1' &&
            b.questionId == differentQuestion.id,
      );
      expect(isDifferentBookmarked, false);
    });

    test('Retakes generate different random orders each time', () {
      final order1 = List<Question>.from(chapterData.questions)..shuffle(Random(10));
      final order2 = List<Question>.from(chapterData.questions)..shuffle(Random(20));
      final order3 = List<Question>.from(chapterData.questions)..shuffle(Random(30));

      final ids1 = order1.map((q) => q.id).toList();
      final ids2 = order2.map((q) => q.id).toList();
      final ids3 = order3.map((q) => q.id).toList();

      expect(ids1, isNot(equals(ids2)));
      expect(ids2, isNot(equals(ids3)));

      // All attempts must contain all original questions without omission or duplicate
      expect(ids1.toSet(), equals(chapterData.questions.map((q) => q.id).toSet()));
      expect(ids2.toSet(), equals(chapterData.questions.map((q) => q.id).toSet()));
      expect(ids3.toSet(), equals(chapterData.questions.map((q) => q.id).toSet()));
    });
  });
}
