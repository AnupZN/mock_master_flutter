import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import '../services/wrong_service.dart';
import 'auth_provider.dart';

final wrongServiceProvider = Provider((ref) => WrongService(ref.read(supabaseProvider)));

final wrongQuestionsProvider = StateNotifierProvider<WrongQuestionsNotifier, List<Bookmark>>((ref) {
  return WrongQuestionsNotifier(ref.read(wrongServiceProvider), ref);
});

class WrongQuestionsNotifier extends StateNotifier<List<Bookmark>> {
  final WrongService _service;
  final Ref _ref;

  WrongQuestionsNotifier(this._service, this._ref) : super([]);

  Future<void> syncFromSupabase(String userId) async {
    state = await _service.fetchWrongQuestions(userId);
  }

  Future<void> add(String subjectId, String chapterId, int questionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final exists = state.any((b) => b.subjectId == subjectId && b.chapterId == chapterId && b.questionId == questionId);
    if (!exists) {
      final item = Bookmark(subjectId: subjectId, chapterId: chapterId, questionId: questionId);
      state = [...state, item];
      await _service.addWrongQuestion(user.id, item);
    }
  }

  Future<void> remove(String subjectId, String chapterId, int questionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final item = Bookmark(subjectId: subjectId, chapterId: chapterId, questionId: questionId);
    state = state.where((b) => !(b.subjectId == subjectId && b.chapterId == chapterId && b.questionId == questionId)).toList();
    await _service.removeWrongQuestion(user.id, item);
  }
}
