import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bookmark.dart';
import '../core/constants.dart';

class BookmarkService {
  final SupabaseClient _supabase;

  BookmarkService(this._supabase);

  // ── Local persistence (SharedPreferences) ─────────────────────────────────

  Future<List<Bookmark>> loadLocalBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(StorageKeys.bookmarks);
      if (data != null && data.isNotEmpty) {
        final List decoded = jsonDecode(data);
        return decoded.map((e) => Bookmark.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('BookmarkService.loadLocalBookmarks error: $e');
    }
    return [];
  }

  Future<void> saveLocalBookmarks(List<Bookmark> bookmarks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        StorageKeys.bookmarks,
        jsonEncode(bookmarks.map((b) => b.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('BookmarkService.saveLocalBookmarks error: $e');
    }
  }

  // ── Supabase persistence ───────────────────────────────────────────────────

  Future<List<Bookmark>> fetchBookmarks(String userId) async {
    try {
      final response = await _supabase
          .from('bookmarks')
          .select('subject_id, chapter_id, question_id')
          .eq('user_id', userId);

      return (response as List).map((item) => Bookmark(
            subjectId: item['subject_id'] ?? '',
            chapterId: item['chapter_id'] ?? '',
            questionId: item['question_id'] is int
                ? item['question_id']
                : int.tryParse(item['question_id'].toString()) ?? 0,
          )).toList();
    } catch (e) {
      debugPrint('BookmarkService.fetchBookmarks error: $e');
      return [];
    }
  }

  Future<void> addBookmark(String userId, Bookmark bookmark) async {
    try {
      final bookmarkId =
          '${userId}_${bookmark.subjectId}_${bookmark.chapterId}_${bookmark.questionId}';
      await _supabase.from('bookmarks').upsert({
        'bookmark_id': bookmarkId,
        'user_id': userId,
        'subject_id': bookmark.subjectId,
        'chapter_id': bookmark.chapterId,
        'question_id': bookmark.questionId,
      });
    } catch (e) {
      debugPrint('BookmarkService.addBookmark error: $e');
    }
  }

  Future<void> removeBookmark(String userId, Bookmark bookmark) async {
    try {
      final bookmarkId =
          '${userId}_${bookmark.subjectId}_${bookmark.chapterId}_${bookmark.questionId}';
      await _supabase.from('bookmarks').delete().eq('bookmark_id', bookmarkId);
    } catch (e) {
      debugPrint('BookmarkService.removeBookmark error: $e');
    }
  }

  Future<void> clearBookmarks(String userId) async {
    try {
      await _supabase.from('bookmarks').delete().eq('user_id', userId);
    } catch (e) {
      debugPrint('BookmarkService.clearBookmarks error: $e');
    }
  }
}
