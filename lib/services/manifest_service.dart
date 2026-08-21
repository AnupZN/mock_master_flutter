import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subject.dart';

class ManifestService {
  final SupabaseClient _supabase;
  static const String _cacheKey = 'manifest_cache';

  // In-memory cache so the manifest is never parsed/read more than once per session
  static List<Subject>? _memoryCache;

  ManifestService(this._supabase);

  Future<List<Subject>> loadManifest() async {
    // 0. Return in-memory cache immediately if available (fastest path)
    if (_memoryCache != null && _memoryCache!.isNotEmpty) {
      // Still refresh from Supabase in the background, but don't block
      _refreshFromSupabase();
      return _memoryCache!;
    }

    // 1. Load bundled asset manifest and SharedPreferences cache in parallel
    final results = await Future.wait([
      _loadBundledAsset(),
      _loadPrefsCache(),
    ]);

    final List<Subject> localFallback = results[0] as List<Subject>;
    final dynamic cachedRaw = results[1];
    final List<Subject>? cachedSubjects = cachedRaw != null ? cachedRaw as List<Subject> : null;

    // 2. Decide what to return immediately
    final List<Subject> best = cachedSubjects != null && cachedSubjects.isNotEmpty
        ? _mergeSubjects(cachedSubjects, localFallback)
        : localFallback;

    // Store in memory so subsequent calls are instant
    _memoryCache = best;

    // 3. Refresh from Supabase in the background (stale-while-revalidate).
    _refreshFromSupabase();

    return best;
  }

  Future<List<Subject>> _loadBundledAsset() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/manifest.json');
      return _parseManifestData(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('ManifestService: error loading bundled asset manifest: $e');
      return [];
    }
  }

  Future<List<Subject>?> _loadPrefsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      if (cachedData != null) {
        final parsed = _parseManifestData(jsonDecode(cachedData));
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (e) {
      debugPrint('ManifestService: error reading manifest cache: $e');
    }
    return null;
  }

  /// Fetches fresh data from Supabase and updates the cache + memory store.
  /// Never awaited by callers — runs entirely in the background.
  Future<void> _refreshFromSupabase() async {
    try {
      final response = await _supabase
          .from('admin_manifest')
          .select('data')
          .eq('id', 'current')
          .maybeSingle();

      if (response != null && response['data'] != null) {
        final dbData = response['data'];
        // Update prefs cache
        await cacheManifest(dbData);
        // Update in-memory cache
        final fresh = _parseManifestData(dbData);
        if (fresh.isNotEmpty) {
          _memoryCache = fresh;
        }
        debugPrint('ManifestService: remote manifest refreshed.');
      }
    } catch (e) {
      debugPrint('ManifestService: error fetching admin_manifest: $e');
    }
  }

  Future<void> cacheManifest(dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('ManifestService.cacheManifest error: $e');
    }
  }

  List<Subject> _parseManifestData(dynamic data) {
    try {
      if (data is Map && data.containsKey('subjects')) {
        return (data['subjects'] as List)
            .map((json) => Subject.fromJson(json))
            .toList();
      } else if (data is List) {
        return data.map((json) => Subject.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('ManifestService._parseManifestData error: $e');
    }
    return [];
  }

  /// Remote subjects override local bundled ones (by id); local provides extras.
  List<Subject> _mergeSubjects(List<Subject> remote, List<Subject> local) {
    final Map<String, Subject> map = {};
    for (final s in local) {
      map[s.id] = s;
    }
    for (final s in remote) {
      map[s.id] = s; // remote wins on conflict
    }
    return map.values.toList();
  }
}
