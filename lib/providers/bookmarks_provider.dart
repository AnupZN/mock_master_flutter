import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import '../services/bookmark_service.dart';
import 'auth_provider.dart';

final bookmarkServiceProvider =
    Provider((ref) => BookmarkService(ref.read(supabaseProvider)));

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<Bookmark>>((ref) {
  return BookmarksNotifier(ref.read(bookmarkServiceProvider), ref);
});

class BookmarksNotifier extends StateNotifier<List<Bookmark>> {
  final BookmarkService _service;
  final Ref _ref;

  BookmarksNotifier(this._service, this._ref) : super([]) {
    // Load from local storage immediately on startup so bookmarks are
    // available even before Supabase sync completes.
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    final local = await _service.loadLocalBookmarks();
    if (local.isNotEmpty) {
      state = local;
    }
  }

  /// Sync from Supabase. Merges remote + local so neither overwrites the
  /// other — whichever has more data wins on a per-entry union basis.
  Future<void> syncFromSupabase(String userId) async {
    final remote = await _service.fetchBookmarks(userId);

    if (remote.isNotEmpty) {
      // Build a merged set (remote is authoritative, but add any local-only
      // entries that haven't made it to the server yet).
      final merged = [...remote];
      for (final local in state) {
        final alreadyInRemote = remote.any(
          (r) =>
              r.subjectId == local.subjectId &&
              r.chapterId == local.chapterId &&
              r.questionId == local.questionId,
        );
        if (!alreadyInRemote) {
          merged.add(local);
          // Push missing local bookmark to Supabase.
          await _service.addBookmark(userId, local);
        }
      }
      state = merged;
    }
    // If remote is empty, keep whatever is in local state (don't wipe it).

    // Always persist current state locally.
    await _service.saveLocalBookmarks(state);
  }

  bool isBookmarked(String subjectId, String chapterId, int questionId) {
    return state.any(
      (b) =>
          b.subjectId == subjectId &&
          b.chapterId == chapterId &&
          b.questionId == questionId,
    );
  }

  Future<void> toggle(
      String subjectId, String chapterId, int questionId) async {
    final existingIndex = state.indexWhere(
      (b) =>
          b.subjectId == subjectId &&
          b.chapterId == chapterId &&
          b.questionId == questionId,
    );
    final bookmark =
        Bookmark(subjectId: subjectId, chapterId: chapterId, questionId: questionId);

    if (existingIndex >= 0) {
      // Remove
      state = [...state]..removeAt(existingIndex);
      await _service.saveLocalBookmarks(state);
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        await _service.removeBookmark(user.id, bookmark);
      }
    } else {
      // Add
      state = [...state, bookmark];
      await _service.saveLocalBookmarks(state);
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        await _service.addBookmark(user.id, bookmark);
      }
    }
  }

  /// Clears all bookmarks (used only by full reset — NOT by progress reset).
  Future<void> clear() async {
    try {
      final currentBookmarks = List<Bookmark>.from(state);
      state = [];
      await _service.saveLocalBookmarks([]);
      
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        // Delete one by one to ensure they are removed, in case bulk delete fails due to RLS
        for (final b in currentBookmarks) {
          await _service.removeBookmark(user.id, b);
        }
        // Fallback bulk delete
        await _service.clearBookmarks(user.id);
      }
    } catch (e) {
      debugPrint('BookmarksNotifier.clear error: $e');
    }
  }
}
