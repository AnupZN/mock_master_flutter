import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  final SupabaseClient _supabase;

  ReportService(this._supabase);

  Future<void> submitReport(String userId, String subjectId, String chapterId, int questionId, String reason, String details) async {
    try {
      await _supabase.from('reports').insert({
        'user_id': userId,
        'subject_id': subjectId,
        'chapter_id': chapterId,
        'question_id': questionId,
        'reason': reason,
        'details': details,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('ReportService error: $e');
    }
  }
}
