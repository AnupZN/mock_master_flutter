import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => supabase);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(supabaseProvider).auth.onAuthStateChange;
});

/// Derives the current user reactively from [authStateProvider].
/// Using ref.watch (not ref.read) ensures this re-evaluates on login/logout.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user;
});

