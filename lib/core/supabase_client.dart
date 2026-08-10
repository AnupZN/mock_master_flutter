import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    // In debug, surface a clear error; in release, we cannot proceed without credentials.
    throw Exception(
      'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env. '
      'Copy .env.example to .env and fill in your Supabase project credentials.',
    );
  }

  await Supabase.initialize(
    url: url,
    publishableKey: anonKey,
    debug: kDebugMode,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
