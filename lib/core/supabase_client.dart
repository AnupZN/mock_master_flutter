import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Credentials can be injected at build time via --dart-define:
//   flutter build apk \
//     --dart-define=SUPABASE_URL=https://xxx.supabase.co \
//     --dart-define=SUPABASE_ANON_KEY=sb_publishable_...
// When not provided via --dart-define, they fall back to the .env asset file.
const _dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
const _dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> initSupabase() async {
  // Priority 1: compile-time --dart-define values (production builds).
  // Priority 2: .env file loaded by flutter_dotenv (local/debug builds).
  final url = _dartDefineUrl.isNotEmpty
      ? _dartDefineUrl
      : dotenv.env['SUPABASE_URL'];

  final anonKey = _dartDefineKey.isNotEmpty
      ? _dartDefineKey
      : dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw Exception(
      'Supabase credentials not found.\n'
      'For local development: ensure .env contains SUPABASE_URL and SUPABASE_ANON_KEY.\n'
      'For production builds: pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
    );
  }

  await Supabase.initialize(
    url: url,
    publishableKey: anonKey,
    debug: kDebugMode,
  );
}

SupabaseClient get supabase => Supabase.instance.client;

