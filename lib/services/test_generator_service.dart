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

  /// Loads all questions across all chapters for the given subjects
  Future<List<Question>> _loadAllQuestionsForSubjects(List<Subject> subjects) async {
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
          debugPrint('Error loading chapter ${chapter.id} for subject ${subject.id}: $e');
        }
      }
    }

    return allQuestions;
  }

  /// Count available bookmarked questions for selected subjects
  Future<int> countAvailableBookmarkedQuestions({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required List<Bookmark> bookmarks,
  }) async {
    if (bookmarks.isEmpty) return 0;

    final targetSubjectIds = selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
        ? allSubjects.map((s) => s.id).toList()
        : selectedSubjectIds;

    final targetSubjects = allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);

    int count = 0;
    for (var q in allQuestions) {
      if (bookmarks.any((b) => (b.subjectId == q.subjectId || targetSubjectIds.contains(b.subjectId)) && b.questionId == q.id)) {
        count++;
      }
    }
    return count;
  }

  /// Count available total questions for selected subjects
  Future<int> countAvailableCustomQuestions({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
  }) async {
    final targetSubjectIds = selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
        ? allSubjects.map((s) => s.id).toList()
        : selectedSubjectIds;

    final targetSubjects = allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);
    return allQuestions.length;
  }

  /// Generate a Bookmarked Test
  Future<GeneratedTestResult> generateBookmarkedTest({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required List<Bookmark> bookmarks,
    required int requestedCount,
    required int durationMinutes,
  }) async {
    final targetSubjectIds = selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all')
        ? allSubjects.map((s) => s.id).toList()
        : selectedSubjectIds;

    final targetSubjects = allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final subjectNames = targetSubjects.map((s) => s.name).toList();

    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);

    // Filter by bookmarks
    final bookmarkedQuestions = allQuestions.where((q) {
      return bookmarks.any((b) => (b.subjectId == q.subjectId || targetSubjectIds.contains(b.subjectId)) && b.questionId == q.id);
    }).toList();

    if (bookmarkedQuestions.isEmpty) {
      return GeneratedTestResult(
        testType: 'Bookmarked Test',
        selectedSubjectNames: subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
        requestedQuestionCount: requestedCount,
        actualQuestionCount: 0,
        durationMinutes: durationMinutes,
        questions: [],
        capWarningMessage: null,
        isEmpty: true,
      );
    }

    // Shuffle bookmarked questions
    final shuffled = List<Question>.from(bookmarkedQuestions)..shuffle(Random());
    final actualCount = min(requestedCount, shuffled.length);
    final selectedQuestions = shuffled.take(actualCount).toList();

    String? warning;
    if (actualCount < requestedCount) {
      warning = '$actualCount bookmarked questions are available, so this test will contain $actualCount questions.';
    }

    return GeneratedTestResult(
      testType: 'Bookmarked Test',
      selectedSubjectNames: subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
      requestedQuestionCount: requestedCount,
      actualQuestionCount: actualCount,
      durationMinutes: durationMinutes,
      questions: selectedQuestions,
      capWarningMessage: warning,
      isEmpty: false,
    );
  }

  /// Generate a Custom / Mixed Test
  Future<GeneratedTestResult> generateCustomTest({
    required List<Subject> allSubjects,
    required List<String> selectedSubjectIds,
    required int requestedCount,
    required int durationMinutes,
  }) async {
    final isAllSubjects = selectedSubjectIds.isEmpty || selectedSubjectIds.contains('all');
    final targetSubjectIds = isAllSubjects ? allSubjects.map((s) => s.id).toList() : selectedSubjectIds;

    final targetSubjects = allSubjects.where((s) => targetSubjectIds.contains(s.id)).toList();
    final subjectNames = targetSubjects.map((s) => s.name).toList();

    final allQuestions = await _loadAllQuestionsForSubjects(targetSubjects);

    if (allQuestions.isEmpty) {
      return GeneratedTestResult(
        testType: isAllSubjects || targetSubjects.length > 1 ? 'Mixed Test' : 'Custom Test',
        selectedSubjectNames: subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
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
      warning = '$actualCount total questions are available across the selected subjects, so this test will contain $actualCount questions.';
    }

    final testTypeLabel = (isAllSubjects || targetSubjects.length > 1) ? 'Mixed Test' : 'Custom Test';

    return GeneratedTestResult(
      testType: testTypeLabel,
      selectedSubjectNames: subjectNames.isEmpty ? ['All Subjects'] : subjectNames,
      requestedQuestionCount: requestedCount,
      actualQuestionCount: actualCount,
      durationMinutes: durationMinutes,
      questions: selectedQuestions,
      capWarningMessage: warning,
      isEmpty: false,
    );
  }
}
