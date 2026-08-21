import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'auth_provider.dart';

final settingsServiceProvider = Provider((ref) => SettingsService(ref.read(supabaseProvider)));

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider), ref);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;
  final Ref _ref;

  SettingsNotifier(this._service, this._ref) : super(AppSettings()) {
    _loadLocal();
  }

  Future<void> _loadLocal() async {
    state = await _service.loadSettings();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    state = newSettings;
    await _service.saveSettings(state);
  }

  Future<void> toggleDarkMode() async {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
    await _service.saveSettings(state);
  }

  Future<void> syncFromSupabase(String userId) async {
    final user = _ref.read(currentUserProvider);
    final remoteSettings = await _service.fetchFromSupabase(userId, user: user);
    if (remoteSettings != null) {
      state = remoteSettings;
      await _service.saveSettings(state);
    } else if (user != null && user.userMetadata != null) {
      final meta = user.userMetadata!;
      final name = meta['full_name'] ?? meta['display_name'] ?? meta['name'];
      if (name is String && name.trim().isNotEmpty && (state.userName == 'Guest' || state.userName.isEmpty)) {
        state = state.copyWith(userName: name.trim());
        await _service.saveSettings(state);
      }
    }
  }
  
  Future<void> saveToSupabase(String userId) async {
    await _service.saveToSupabase(userId, state);
  }

  Future<void> resetToDefault() async {
    state = AppSettings();
    await _service.saveSettings(state);
    final user = _ref.read(currentUserProvider);
    if (user != null) {
      await _service.saveToSupabase(user.id, state);
    }
  }
}

