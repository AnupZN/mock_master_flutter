import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'] ?? 'https://ttbtburllrmcdnorbqrl.supabase.co';
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 'sb_publishable_QqW37wq4Q5vTgwCRdpyolg_2eEgG_Aj';
  await Supabase.initialize(
    url: url,
    publishableKey: anonKey,
  );
}

SupabaseClient get supabase => Supabase.instance.client;
