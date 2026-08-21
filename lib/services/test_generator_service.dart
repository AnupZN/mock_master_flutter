import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';
import '../models/question.dart';
import '../models/subject.dart';
import 'chapter_service.dart';

class GeneratedTestResult {
  final String testType; // "Bookmarked Test", "Custom Test", or "Mixed Test"
  final List<String> selectedSubjectNames;
  final int requestedQuestionCount;
  final int actualQuestionCount;
  final int durationMinutes;
  final List<Question> questions;
  final String? capWarningMessage;
  final bool isEmpty;

  GeneratedTestResult({
    required this.testType,
    required this.selectedSubjectNames,
    required this.requestedQuestionCount,
    required this.actualQuestionCount,
    required this.durationMinutes,
    required this.questions,
    this.capWarningMessage,
    required this.isEmpty,
  });
}

class TestGeneratorService {
  final ChapterService _chapterService;

  TestGeneratorService(this._chapterService);

  /// Loads all questions across all chapters for the given subjects.
  /// Used only for custom/mixed tests — NOT for bookmarked tests.
  Future<List<Question>> _loadAllQuestionsForSubjects(
      List<Subject> subjects) async {
    final List<Question> allQuestions = [];

    for (var subject in subjects) {
      for (var chapter in subject.chapters) {
        try {
          final chapterData = await _chapterService.loadChapter(
            subject.id,
            chapter.id,
            folder: subject.folder,
            file: chapter.file,
          );
          if (chapterData != null) {
            for (var q in chapterData.questions) {
              allQuestions.add(q.copyWith(
                subjectId: subject.id,
                chapterId: chapter.id,
              ));
            }
          }
        } catch (e) {
          debugPrint(
              'Error loading chapter ${chapter.id} for subject ${subject.id}: $e');
        }
      }
    }

    return allQuestions;
  }

  /// Loads ONLY the specific chapters that contain bookmarked questions.
  /// This is an order-of-magnitude faster than loading all chapters.
  Future<List<Question>> _loadBookmarkedQuestions({
    required List<Subject> allSubjects,
    required List<Bookmark> bookmarks,
    required List<String> targetSubjectIds,
  }) async {
    // Filter bookmarks to the target subjects
    final relevantBookmarks = bookmarks
        .where((b) => targetSubjectIds.contains(b.subjectId))
        .toList();

    if (relevantBookmarks.isEmpty) return [];

    // Build a de-duplicated map of (subjectId, chapterId) pairs to load
    final Set<String> chapterKeys = {};
    for (final b in relevantBookmarks) {
      chapterKeys.add('${b.subjectId}::${b.chapterId}');
    }

    final List<Question> result = [];

    for (final key in chapterKeys) {
      final parts = key.split('::');
      final subjectId = parts[0];
      final chapterId = parts[1];

      final subject = allSubjects.firstWhere(
        (s) => s.id == subjectId,
        orElse: () => Subject(
          id: subjectId,
          name: subjectId,
          icon: '',
          folder: '',
          chapters: [],
        ),
      );

      final chapter = subject.chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => Chapter(id: chapterId, title: chapterId),
      );

      try {
        final chapterData = await _chapterService.loadChapter(
          subjectId,
          chapterId,
          folder: subject.folder,
          file: chapter.file,
        );

        if (chapterData != null) {
          // Only keep questions that are actually bookmarked in this chapter
          final chapterBookmarkIds = relevantBookmarks
              .where((b) => b.subjectId == subjectId && b.chapterId == chapterId)
              .map((b) => b.questionId)
              .toSet();

          for (final q in chapterData.questions) {
            if (chapterBookmarkIds.contains(q.id)) {
              result.add(q.copyWith(
                subjectId: subjectId,
                chapterId: chapterId,
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading bookmarked chapter $chapterId: $e');
      }
    }

    return result;
  }

  /// Count available bookmarked questions for selected subjects.
  /// Fast: only loads chapters that actually have bookmarks.
  Future<int> countAvailableBookmarkedQuestions({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required List<Bookmark> bookmarks,
  }) async {
    if (bookmarks.isEmpty) return 0;

    final targetSubjectIds =
        selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
            ? allSubjects.map((s) => s.id).toList()
            : selectedSubjectIds;

    final questions = await _loadBookmarkedQuestions(
      allSubjects: allSubjects,
      bookmarks: bookmarks,
      targetSubjectIds: targetSubjectIds,
    );

    return questions.length;
  }

  /// Count available total questions for selected subjects.
  Future<int> countAvailableCustomQuestions({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
  }) async {
    final targetSubjectIds =
        selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
            ? allSubjects.map((s) => s.id).toList()
            : selectedSubjectIds;

    final targetSubjects =
        allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);
    return allQuestions.length;
  }

  /// Generate a Bookmarked Test.
  /// Fast: only loads chapters with bookmarks, matches on subjectId+chapterId+questionId.
  Future<GeneratedTestResult> generateBookmarkedTest({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required List<Bookmark> bookmarks,
    required int requestedCount,
    required int durationMinutes,
  }) async {
    final targetSubjectIds =
        selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
            ? allSubjects.map((s) => s.id).toList()
            : selectedSubjectIds;

    final targetSubjects =
        allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final subjectNames = targetSubjects.map((s) => s.name).toList();

    final bookmarkedQuestions = await _loadBookmarkedQuestions(
      allSubjects: allSubjects,
      bookmarks: bookmarks,
      targetSubjectIds: targetSubjectIds,
    );

    if (bookmarkedQuestions.isEmpty) {
      return GeneratedTestResult(
        testType: 'Bookmarked Test',
        selectedSubjectNames:
            subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
        requestedQuestionCount: requestedCount,
        actualQuestionCount: 0,
        durationMinutes: durationMinutes,
        questions: [],
        capWarningMessage: null,
        isEmpty: true,
      );
    }

    // Shuffle and take the requested count
    final shuffled = List<Question>.from(bookmarkedQuestions)..shuffle(Random());
    final actualCount = min(requestedCount, shuffled.length);
    final selectedQuestions = shuffled.take(actualCount).toList();

    String? warning;
    if (actualCount < requestedCount) {
      warning =
          '$actualCount bookmarked question${actualCount == 1 ? '' : 's'} available — the test will contain $actualCount question${actualCount == 1 ? '' : 's'}.';
    }

    return GeneratedTestResult(
      testType: 'Bookmarked Test',
      selectedSubjectNames:
          subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
      requestedQuestionCount: requestedCount,
      actualQuestionCount: actualCount,
      durationMinutes: durationMinutes,
      questions: selectedQuestions,
      capWarningMessage: warning,
      isEmpty: false,
    );
  }

  /// Generate a Custom / Mixed Test.
  Future<GeneratedTestResult> generateCustomTest({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required int requestedCount,
    required int durationMinutes,
  }) async {
    final isAllSubjects =
        selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all');
    final targetSubjectIds = isAllSubjects
        ? allSubjects.map((s) => s.id).toList()
        : selectedSubjectIds;

    final targetSubjects =
        allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final subjectNames = targetSubjects.map((s) => s.name).toList();

    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);

    if (allQuestions.isEmpty) {
      return GeneratedTestResult(
        testType: isAllSubjects || targetSubjects.length > 1
            ? 'Mixed Test'
            : 'Custom Test',
        selectedSubjectNames:
            subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
        requestedQuestionCount: requestedCount,
        actualQuestionCount: 0,
        durationMinutes: durationMinutes,
        questions: [],
        capWarningMessage: null,
        isEmpty: true,
      );
    }

    // Shuffle questions without duplicates
    final shuffled = List<Question>.from(allQuestions)..shuffle(Random());
    final actualCount = min(requestedCount, shuffled.length);
    final selectedQuestions = shuffled.take(actualCount).toList();

    String? warning;
    if (actualCount < requestedCount) {
      warning =
          '$actualCount total question${actualCount == 1 ? '' : 's'} available — the test will contain $actualCount question${actualCount == 1 ? '' : 's'}.';
    }

    final testTypeLabel =
        (isAllSubjects || targetSubjects.length > 1) ? 'Mixed Test' : 'Custom Test';

    return GeneratedTestResult(
      testType: testTypeLabel,
      selectedSubjectNames:
          subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
      requestedQuestionCount: requestedCount,
      actualQuestionCount: actualCount,
      durationMinutes: durationMinutes,
      questions: selectedQuestions,
      capWarningMessage: warning,
      isEmpty: false,
    );
  }
}
