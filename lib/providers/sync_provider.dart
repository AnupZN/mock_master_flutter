import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import 'settings_provider.dart';
import 'history_provider.dart';
import 'bookmarks_provider.dart';
import 'wrong_provider.dart';

final syncProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  Future<void> syncAllData() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final userId = user.id;
    
    try {
      await Future.wait([
        _ref.read(settingsProvider.notifier).syncFromSupabase(userId),
        _ref.read(historyProvider.notifier).syncFromSupabase(userId),
        _ref.read(bookmarksProvider.notifier).syncFromSupabase(userId),
        _ref.read(wrongQuestionsProvider.notifier).syncFromSupabase(userId),
      ]);
    } catch (e) {
      // Handle sync error
    }
  }
}
