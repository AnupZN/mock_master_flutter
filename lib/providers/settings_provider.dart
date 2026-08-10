import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';
import 'auth_provider.dart';

final settingsServiceProvider = Provider((ref) => SettingsService(ref.read(supabaseProvider)));

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.read(settingsServiceProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsService _service;

  SettingsNotifier(this._service) : super(AppSettings()) {
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
    final remoteSettings = await _service.fetchFromSupabase(userId);
    if (remoteSettings != null) {
      state = remoteSettings;
      await _service.saveSettings(state);
    }
  }
  
  Future<void> saveToSupabase(String userId) async {
    await _service.saveToSupabase(userId, state);
  }
}
