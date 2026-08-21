import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attempt_history.dart';
import '../services/history_service.dart';
import 'auth_provider.dart';

final historyServiceProvider = Provider((ref) => HistoryService(ref.read(supabaseProvider)));

final historyProvider = StateNotifierProvider<HistoryNotifier, List<AttemptHistoryItem>>((ref) {
  return HistoryNotifier(ref.read(historyServiceProvider), ref);
});

class HistoryNotifier extends StateNotifier<List<AttemptHistoryItem>> {
  final HistoryService _service;
  final Ref _ref;

  HistoryNotifier(this._service, this._ref) : super([]) {
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    state = await _service.loadLocalHistory();
  }

  Future<void> syncFromSupabase(String userId) async {
    final remote = await _service.fetchHistory(userId);
    state = remote;
    await _service.saveLocalHistory(state);
  }

  Future<void> add(AttemptHistoryItem item) async {
    state = [item, ...state];
    await _service.saveLocalHistory(state);
    
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      await _service.saveHistoryItem(user.id, item);
    }
  }

  Future<void> clear() async {
    try {
      state = [];
      await _service.saveLocalHistory(state);
      
      final user = _ref.read(currentUserProvider);
      if (user != null) {
        await _service.clearHistory(user.id);
      }
    } catch (e) {
      debugPrint('HistoryNotifier.clear error: $e');
    }
  }
}
