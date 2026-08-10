import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardService {
  final SupabaseClient _supabase;

  LeaderboardService(this._supabase);

  Future<void> updateLeaderboard(String userId, String displayName, int totalCorrect, int totalAttempted, int currentStreak, int bestStreak) async {
    try {
      await _supabase.from('leaderboard').upsert({
        'user_id': userId,
        'display_name': displayName,
        'total_correct': totalCorrect,
        'total_attempted': totalAttempted,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'last_active': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('LeaderboardService error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('leaderboard')
          .select()
          .order('total_correct', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
