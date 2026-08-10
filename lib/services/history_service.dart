import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attempt_history.dart';
import '../core/constants.dart';

class HistoryService {
  final SupabaseClient _supabase;

  HistoryService(this._supabase);

  Future<List<AttemptHistoryItem>> fetchHistory(String userId) async {
    try {
      final response = await _supabase
          .from('history')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);
          
      return (response as List).map((item) {
        return AttemptHistoryItem(
          id: item['id'] ?? '',
          subjectId: item['subject_id'] ?? '',
          subjectName: item['subject_name'] ?? '',
          chapterId: item['chapter_id'] ?? '',
          chapterTitle: item['chapter_title'] ?? '',
          date: item['date'] ?? '',
          score: (item['score'] ?? 0).toDouble(),
          totalQuestions: item['total_questions'] ?? 0,
          correctCount: item['correct_count'] ?? 0,
          wrongCount: item['wrong_count'] ?? 0,
          skippedCount: item['skipped_count'] ?? 0,
          maxScore: (item['max_score'] ?? 0).toDouble(),
          accuracy: (item['accuracy'] ?? 0).toDouble(),
          timeTaken: item['time_taken'] ?? 0,
          isPracticeMode: item['is_practice_mode'],
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveHistoryItem(String userId, AttemptHistoryItem item) async {
    try {
      await _supabase.from('history').insert({
        'id': item.id,
        'user_id': userId,
        'subject_id': item.subjectId,
        'subject_name': item.subjectName,
        'chapter_id': item.chapterId,
        'chapter_title': item.chapterTitle,
        'date': item.date,
        'score': item.score,
        'total_questions': item.totalQuestions,
        'correct_count': item.correctCount,
        'wrong_count': item.wrongCount,
        'skipped_count': item.skippedCount,
        'max_score': item.maxScore,
        'accuracy': item.accuracy,
        'time_taken': item.timeTaken,
        'is_practice_mode': item.isPracticeMode,
      });
    } catch (e) {
      // print(e);
    }
  }

  Future<void> clearHistory(String userId) async {
    try {
      await _supabase.from('history').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('HistoryService error: $e');
    }
  }

  Future<List<AttemptHistoryItem>> loadLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(StorageKeys.history);
    if (data != null) {
      final List decoded = jsonDecode(data);
      return decoded.map((e) => AttemptHistoryItem.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> saveLocalHistory(List<AttemptHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.history, jsonEncode(history.map((e) => e.toJson()).toList()));
  }
}
