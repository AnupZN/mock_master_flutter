import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...
            [
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text((user.email ?? 'U')[0].toUpperCase()),
                  ),
                  title: Text(settings.userName.isNotEmpty ? settings.userName : 'User'),
                  subtitle: Text(user.email ?? ''),
                ),
              ),
              const SizedBox(height: 8),
            ],
          SwitchListTile(
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode_outlined),
            value: settings.isDarkMode,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleDarkMode();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Daily Target'),
            subtitle: Text('${settings.dailyTarget} questions per day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await showDialog<int>(
                context: context,
                builder: (ctx) => _DailyTargetDialog(current: settings.dailyTarget),
              );
              if (result != null) {
                ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(dailyTarget: result));
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out')),
                  ],
                ),
              );
              if (confirm == true) {
                await AuthService(ref.read(supabaseProvider)).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DailyTargetDialog extends StatefulWidget {
  final int current;
  const _DailyTargetDialog({required this.current});
  @override
  State<_DailyTargetDialog> createState() => _DailyTargetDialogState();
}

class _DailyTargetDialogState extends State<_DailyTargetDialog> {
  late int _value;
  @override
  void initState() { super.initState(); _value = widget.current; }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Daily Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$_value questions per day', style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _value.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: '$_value',
            onChanged: (v) => setState(() => _value = v.toInt()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _value), child: const Text('Save')),
      ],
    );
  }
}
