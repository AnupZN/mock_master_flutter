import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/supabase_client.dart';
import 'core/app_theme.dart';
import 'core/router.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env from the filesystem (not bundled in assets for security).
  // mergeWith allows environment variables set at build time via --dart-define
  // to override .env values, so production builds can skip the file entirely.
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env may not exist in production builds — that's expected.
    // Credentials must then be provided via --dart-define or another secure mechanism.
    debugPrint('dotenv: .env file not found or could not be loaded: $e');
  }

  try {
    await initSupabase();
  } catch (e) {
    // Surface initialization failure with a clear error widget.
    runApp(_InitErrorApp(message: e.toString()));
    return;
  }

  runApp(
    const ProviderScope(
      child: MockMasterApp(),
    ),
  );
}

class MockMasterApp extends ConsumerWidget {
  const MockMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Mock Master',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Shown when Supabase cannot be initialized (e.g., missing .env credentials).
class _InitErrorApp extends StatelessWidget {
  final String message;
  const _InitErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Failed',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ensure your .env file contains valid SUPABASE_URL and SUPABASE_ANON_KEY values.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

