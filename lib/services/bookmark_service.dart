import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bookmark.dart';

class BookmarkService {
  final SupabaseClient _supabase;

  BookmarkService(this._supabase);

  Future<List<Bookmark>> fetchBookmarks(String userId) async {
    try {
      final response = await _supabase
          .from('bookmarks')
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

  Future<void> addBookmark(String userId, Bookmark bookmark) async {
    try {
      final bookmarkId = '${userId}_${bookmark.subjectId}_${bookmark.chapterId}_${bookmark.questionId}';
      await _supabase.from('bookmarks').upsert({
        'bookmark_id': bookmarkId,
        'user_id': userId,
        'subject_id': bookmark.subjectId,
        'chapter_id': bookmark.chapterId,
        'question_id': bookmark.questionId,
      });
    } catch (e) {
      debugPrint('BookmarkService error: $e');
    }
  }

  Future<void> removeBookmark(String userId, Bookmark bookmark) async {
    try {
      final bookmarkId = '${userId}_${bookmark.subjectId}_${bookmark.chapterId}_${bookmark.questionId}';
      await _supabase.from('bookmarks').delete().eq('bookmark_id', bookmarkId);
    } catch (e) {
      debugPrint('BookmarkService error: $e');
    }
  }
}
