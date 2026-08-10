import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chapter_data.dart';

class ChapterService {
  final SupabaseClient _supabase;

  ChapterService(this._supabase);

  Future<ChapterData?> loadChapter(String subjectId, String chapterId, {String? folder, String? file}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chapter_${subjectId}_$chapterId';
    
    // 1. Try SharedPreferences cache
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        return ChapterData.fromJson(jsonDecode(cached));
      } catch (e) {
        debugPrint('ChapterService cache decode error: $e');
      }
    }

    // 2. Try Supabase admin_chapters_data
    try {
      final response = await _supabase
          .from('admin_chapters_data')
          .select('data')
          .eq('id', '${subjectId}_$chapterId')
          .maybeSingle();

      if (response != null && response['data'] != null) {
        final data = ChapterData.fromJson(response['data']);
        await cacheChapter(subjectId, chapterId, data);
        return data;
      }
    } catch (e) {
      debugPrint('ChapterService Supabase error: $e');
    }

    // 3. Fallback to bundled local asset file if available
    try {
      final folderName = folder ?? _defaultFolder(subjectId);
      final fileName = file ?? '$chapterId.json';
      final assetPath = 'assets/data/$folderName/$fileName';
      
      final jsonString = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(jsonString);
      final data = ChapterData.fromJson(decoded);
      await cacheChapter(subjectId, chapterId, data);
      return data;
    } catch (e) {
      debugPrint('ChapterService asset fallback error: $e');
    }

    return null;
  }

  String _defaultFolder(String subjectId) {
    if (subjectId.toLowerCase().contains('history')) return 'History';
    if (subjectId.toLowerCase().contains('polity')) return 'Polity';
    if (subjectId.toLowerCase().contains('geography')) return 'Geography';
    return subjectId.isNotEmpty ? subjectId[0].toUpperCase() + subjectId.substring(1) : 'History';
  }

  Future<void> cacheChapter(String subjectId, String chapterId, ChapterData data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'chapter_${subjectId}_$chapterId';
    await prefs.setString(cacheKey, jsonEncode(data.toJson()));
  }
}
