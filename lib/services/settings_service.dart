import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  Future<AppSettings?> fetchFromSupabase(String userId, {User? user}) async {
    try {
      final data = await _supabase
          .from('users')
          .select('is_dark_mode, font_size, daily_target, user_name, user_title, is_admin')
          .eq('id', userId)
          .maybeSingle();

      String? metaName;
      if (user != null && user.userMetadata != null) {
        final meta = user.userMetadata!;
        final name = meta['full_name'] ?? meta['display_name'] ?? meta['name'];
        if (name is String && name.trim().isNotEmpty) {
          metaName = name.trim();
        }
      }

      if (data != null) {
        String dbName = data['user_name'] ?? '';
        if ((dbName.isEmpty || dbName == 'Guest') && metaName != null && metaName.isNotEmpty) {
          dbName = metaName;
          _supabase.from('users').update({'user_name': dbName}).eq('id', userId).then((_) {}).catchError((_) {});
        }
        return AppSettings(
          isDarkMode: data['is_dark_mode'] ?? false,
          fontSize: (data['font_size'] ?? 16.0).toDouble(),
          dailyTarget: data['daily_target'] ?? 15,
          userName: dbName.isNotEmpty ? dbName : 'Guest',
          userTitle: data['user_title'] ?? 'Level 1 Aspirant',
          isAdmin: data['is_admin'] ?? false,
        );
      } else if (metaName != null && metaName.isNotEmpty) {
        return AppSettings(
          userName: metaName,
        );
      }
    } catch (e) {
      debugPrint('SettingsService.fetchFromSupabase error: $e');
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
      debugPrint('SettingsService.saveToSupabase error: $e');
    }
  }
}
