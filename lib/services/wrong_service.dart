import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wrong_question.dart';

class WrongService {
  final SupabaseClient _supabase;

  WrongService(this._supabase);

  Future<List<WrongQuestion>> fetchWrongQuestions(String userId) async {
    try {
      final response = await _supabase
          .from('wrong_questions')
          .select('subject_id, chapter_id, question_id, added_at')
          .eq('user_id', userId);

      return (response as List).map((item) => WrongQuestion.fromJson(item)).toList();
    } catch (e) {
      debugPrint('WrongService.fetchWrongQuestions error: $e');
      return [];
    }
  }

  Future<void> addWrongQuestion(String userId, WrongQuestion item) async {
    try {
      final wrongId = '${userId}_${item.subjectId}_${item.chapterId}_${item.questionId}';
      await _supabase.from('wrong_questions').upsert({
        'wrong_id': wrongId,
        'user_id': userId,
        'subject_id': item.subjectId,
        'chapter_id': item.chapterId,
        'question_id': item.questionId,
        'added_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('WrongService.addWrongQuestion error: $e');
    }
  }

  Future<void> removeWrongQuestion(String userId, WrongQuestion item) async {
    try {
      final wrongId = '${userId}_${item.subjectId}_${item.chapterId}_${item.questionId}';
      await _supabase.from('wrong_questions').delete().eq('wrong_id', wrongId);
    } catch (e) {
      debugPrint('WrongService.removeWrongQuestion error: $e');
    }
  }
}

