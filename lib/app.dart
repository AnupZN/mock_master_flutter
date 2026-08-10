import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'providers/sync_provider.dart';
import 'widgets/app_bottom_nav.dart';

class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncData();
    });
  }

  void _syncData() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(syncProvider).syncAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      if (next.value?.session != null && prev?.value?.session == null) {
        _syncData();
      }
    });

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const AppBottomNav(),
    );
  }
}
