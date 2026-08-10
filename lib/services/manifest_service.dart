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

    // Step 1: Always load the bundled asset manifest as a base/fallback.
    try {
      final jsonString = await rootBundle.loadString('assets/data/manifest.json');
      final decoded = jsonDecode(jsonString);
      localFallback = _parseManifestData(decoded);
    } catch (e) {
      debugPrint('ManifestService: error loading bundled asset manifest: $e');
    }

    // Step 2: Check SharedPreferences cache for immediate display.
    List<Subject>? cachedSubjects;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final decoded = jsonDecode(cachedData);
        final parsed = _parseManifestData(decoded);
        if (parsed.isNotEmpty) {
          cachedSubjects = parsed;
        }
      }
    } catch (e) {
      debugPrint('ManifestService: error reading manifest cache: $e');
    }

    // Step 3: Fetch from Supabase in the background (stale-while-revalidate).
    // We do NOT short-circuit on cache — always keep the remote copy fresh.
    _refreshFromSupabase(localFallback);

    // Return best available data immediately:
    // cached (if available) → local fallback.
    if (cachedSubjects != null) {
      return _mergeSubjects(cachedSubjects, localFallback);
    }
    return localFallback;
  }

  /// Fetches fresh data from Supabase and writes it to cache.
  /// Called in the background — callers do not await this.
  Future<void> _refreshFromSupabase(List<Subject> localFallback) async {
    try {
      final response = await _supabase
          .from('admin_manifest')
          .select('data')
          .eq('id', 'current')
          .maybeSingle();

      if (response != null && response['data'] != null) {
        final dbData = response['data'];
        await cacheManifest(dbData);
        debugPrint('ManifestService: remote manifest refreshed and cached.');
      }
    } catch (e) {
      debugPrint('ManifestService: error fetching admin_manifest from Supabase: $e');
    }
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

  /// Remote subjects override local bundled ones (by id); local provides extras.
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

