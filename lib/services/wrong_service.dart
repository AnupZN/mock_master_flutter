import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bookmark.dart';

class WrongService {
  final SupabaseClient _supabase;

  WrongService(this._supabase);

  Future<List<Bookmark>> fetchWrongQuestions(String userId) async {
    try {
      final response = await _supabase
          .from('wrong_questions')
          .select('subject_id, chapter_id, question_id')
          .eq('user_id', userId);
          
      return (response as List).map((item) => Bookmark(
        subjectId: item['subject_id'],
        chapterId: item['chapter_id'],
        questionId: item['question_id'],
      )).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addWrongQuestion(String userId, Bookmark item) async {
    try {
      final wrongId = '${userId}_${item.subjectId}_${item.chapterId}_${item.questionId}';
      await _supabase.from('wrong_questions').upsert({
        'wrong_id': wrongId,
        'user_id': userId,
        'subject_id': item.subjectId,
        'chapter_id': item.chapterId,
        'question_id': item.questionId,
      });
    } catch (e) {
      debugPrint('WrongService error: $e');
    }
  }

  Future<void> removeWrongQuestion(String userId, Bookmark item) async {
    try {
      final wrongId = '${userId}_${item.subjectId}_${item.chapterId}_${item.questionId}';
      await _supabase.from('wrong_questions').delete().eq('wrong_id', wrongId);
    } catch (e) {
      debugPrint('WrongService error: $e');
    }
  }
}
