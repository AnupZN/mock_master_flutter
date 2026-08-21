import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/subjects')) return 1;
    if (location.startsWith('/bookmarks')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/subjects');
        break;
      case 2:
        context.go('/bookmarks');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _calculateSelectedIndex(context);

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_stories_outlined),
        selectedIcon: Icon(Icons.auto_stories_rounded),
        label: 'Subjects',
      ),
      const NavigationDestination(
        icon: Icon(Icons.bookmark_outline_rounded),
        selectedIcon: Icon(Icons.bookmark_rounded),
        label: 'Bookmarks',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Settings',
      ),
    ];

    return NavigationBar(
      selectedIndex: currentIndex >= destinations.length ? 0 : currentIndex,
      onDestinationSelected: (idx) => _onItemTapped(idx, context),
      destinations: destinations,
    );
  }
}
