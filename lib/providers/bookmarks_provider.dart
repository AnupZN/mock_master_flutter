import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import 'auth_provider.dart';

final bookmarkServiceProvider = Provider((ref) => BookmarkService(ref.read(supabaseProvider)));

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<Bookmark>>((ref) {
  return BookmarksNotifier(ref.read(bookmarkServiceProvider), ref);
});

class BookmarksNotifier extends StateNotifier<List<Bookmark>> {
  final BookmarkService _service;
  final Ref _ref;

  BookmarksNotifier(this._service, this._ref) : super([]);

  Future<void> syncFromSupabase(String userId) async {
    state = await _service.fetchBookmarks(userId);
  }

  bool isBookmarked(String subjectId, String chapterId, int questionId) {
    return state.any((b) => b.subjectId == subjectId && b.chapterId == chapterId && b.questionId == questionId);
  }

  Future<void> toggle(String subjectId, String chapterId, int questionId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final existingIndex = state.indexWhere((b) => b.subjectId == subjectId && b.chapterId == chapterId && b.questionId == questionId);
    final bookmark = Bookmark(subjectId: subjectId, chapterId: chapterId, questionId: questionId);

    if (existingIndex >= 0) {
      state = [...state]..removeAt(existingIndex);
      await _service.removeBookmark(user.id, bookmark);
    } else {
      state = [...state, bookmark];
      await _service.addBookmark(user.id, bookmark);
    }
  }
}
