import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';

class ManifestService {
  final SupabaseClient _supabase;
  static const String _cacheKey = 'manifest_cache';

  ManifestService(this._supabase);

  Future<List<Subject>> loadManifest() async {
    List<Subject> localFallback = [];

    // 1. Always load bundled local asset manifest as base/fallback
    try {
      final jsonString = await rootBundle.loadString('assets/data/manifest.json');
      final decoded = jsonDecode(jsonString);
      localFallback = _parseManifestData(decoded);
    } catch (e) {
      debugPrint('Error loading local asset manifest fallback: $e');
    }

    // 2. Check SharedPreferences cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        final cachedSubjects = _parseManifestData(decoded);
        if (cachedSubjects.isNotEmpty) {
          return _mergeSubjects(cachedSubjects, localFallback);
        }
      }
    } catch (e) {
      debugPrint('Error reading manifest cache: $e');
    }

    // 3. Try Supabase admin_manifest
    try {
      final response = await _supabase
          .from('admin_manifest')
          .select('data')
          .eq('id', 'current')
          .maybeSingle();

      if (response != null && response['data'] != null) {
        final dbData = response['data'];
        await cacheManifest(dbData);
        final dbSubjects = _parseManifestData(dbData);
        if (dbSubjects.isNotEmpty) {
          return _mergeSubjects(dbSubjects, localFallback);
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin_manifest from Supabase: $e');
    }

    return localFallback;
  }

  Future<void> cacheManifest(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(data));
  }

  List<Subject> _parseManifestData(dynamic data) {
    if (data is Map && data.containsKey('subjects')) {
      return (data['subjects'] as List).map((json) => Subject.fromJson(json)).toList();
    } else if (data is List) {
      return data.map((json) => Subject.fromJson(json)).toList();
    }
    return [];
  }

  List<Subject> _mergeSubjects(List<Subject> remote, List<Subject> local) {
    final Map<String, Subject> map = {};
    for (var s in local) {
      map[s.id] = s;
    }
    for (var s in remote) {
      map[s.id] = s;
    }
    return map.values.toList();
  }
}
