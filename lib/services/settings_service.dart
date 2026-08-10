import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_settings.dart';
import '../core/constants.dart';

class SettingsService {
  final SupabaseClient _supabase;

  SettingsService(this._supabase);

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(StorageKeys.settings);
    if (jsonString != null) {
      return AppSettings.fromJson(jsonDecode(jsonString));
    }
    return AppSettings();
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.settings, jsonEncode(settings.toJson()));
  }

  Future<AppSettings?> fetchFromSupabase(String userId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('is_dark_mode, font_size, daily_target, user_name, user_title, is_admin')
          .eq('id', userId)
          .maybeSingle();

      if (data != null) {
        return AppSettings(
          isDarkMode: data['is_dark_mode'] ?? false,
          fontSize: (data['font_size'] ?? 16.0).toDouble(),
          dailyTarget: data['daily_target'] ?? 15,
          userName: data['user_name'] ?? 'Guest',
          userTitle: data['user_title'] ?? 'Level 1 Aspirant',
          isAdmin: data['is_admin'] ?? false,
        );
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  Future<void> saveToSupabase(String userId, AppSettings settings) async {
    try {
      await _supabase.from('users').update({
        'is_dark_mode': settings.isDarkMode,
        'font_size': settings.fontSize,
        'daily_target': settings.dailyTarget,
        'user_name': settings.userName,
        'user_title': settings.userTitle,
      }).eq('id', userId);
    } catch (e) {
      // ignore
    }
  }
}
