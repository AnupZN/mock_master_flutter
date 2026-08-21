import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wrong_question.dart';
import '../services/wrong_service.dart';
import 'auth_provider.dart';

final wrongServiceProvider = Provider((ref) => WrongService(ref.read(supabaseProvider)));

final wrongQuestionsProvider = StateNotifierProvider<WrongQuestionsNotifier, List<WrongQuestion>>((ref) {
  return WrongQuestionsNotifier(ref.read(wrongServiceProvider), ref);
});

class WrongQuestionsNotifier extends StateNotifier<List<WrongQuestion>> {
  final WrongService _service;
  final Ref _ref;

  WrongQuestionsNotifier(this._service, this._ref) : super([]);

  Future<void> syncFromSupabase(String userId) async {
    state = await _service.fetchWrongQuestions(userId);
  }

  Future<void> add(String subjectId, String chapterId, int questionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final qId = questionId.toString();
    final exists = state.any((w) =>
        w.subjectId == subjectId && w.chapterId == chapterId && w.questionId == qId);
    if (!exists) {
      final item = WrongQuestion(
        subjectId: subjectId,
        chapterId: chapterId,
        questionId: qId,
        addedAt: DateTime.now(),
      );
      state = [...state, item];
      await _service.addWrongQuestion(user.id, item);
    }
  }

  Future<void> remove(String subjectId, String chapterId, int questionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final qId = questionId.toString();
    final item = WrongQuestion(subjectId: subjectId, chapterId: chapterId, questionId: qId);
    state = state
        .where((w) => !(w.subjectId == subjectId && w.chapterId == chapterId && w.questionId == qId))
        .toList();
    await _service.removeWrongQuestion(user.id, item);
  }

  Future<void> clear() async {
    try {
      state = [];
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        await _service.clearWrongQuestions(user.id);
      }
    } catch (e) {
      debugPrint('WrongQuestionsNotifier.clear error: $e');
    }
  }
}


