import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/wrong_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(
      text: currentName == 'Guest' || currentName == 'Aspirant' ? '' : currentName,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final settingsNotifier = ref.read(settingsProvider.notifier);
                final settings = ref.read(settingsProvider);
                await settingsNotifier.updateSettings(settings.copyWith(userName: newName));
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  await settingsNotifier.saveToSupabase(user.id);
                }
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, WidgetRef ref, {required bool isFullReset}) {
    final passwordController = TextEditingController();
    bool isObscured = true;
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isFullReset ? Icons.delete_forever_rounded : Icons.restart_alt_rounded,
                  color: isFullReset ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFullReset ? 'Clear All Data' : 'Reset Progress & Attempts',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFullReset
                      ? 'This will permanently delete ALL attempt history, wrong questions, bookmarks, and reset settings in local storage and Supabase.\n\nPlease enter your password to confirm.'
                      : 'This will permanently delete all test attempt history and wrong questions in local storage and Supabase. Bookmarks will NOT be affected.\n\nPlease enter your password to confirm.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMsg!,
                            style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextField(
                  controller: passwordController,
                  obscureText: isObscured,
                  decoration: InputDecoration(
                    labelText: 'Account Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setDialogState(() => isObscured = !isObscured),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isFullReset ? Colors.red : Colors.orange.shade800,
                ),
                onPressed: isLoading
                    ? null
                    : () async {
                        final password = passwordController.text;
                        if (password.isEmpty) {
                          setDialogState(() => errorMsg = 'Please enter your password.');
                          return;
                        }

                        setDialogState(() {
                          isLoading = true;
                          errorMsg = null;
                        });

                        try {
                          final supabase = ref.read(supabaseProvider);
                          final user = ref.read(currentUserProvider);

                          if (user != null && user.email != null) {
                            // Verify password by attempting signInWithPassword
                            await supabase.auth.signInWithPassword(
                              email: user.email!,
                              password: password,
                            );
                          }

                          // Password verified! Perform requested reset actions.
                          if (isFullReset) {
                            await ref.read(historyProvider.notifier).clear();
                            await ref.read(wrongQuestionsProvider.notifier).clear();
                            await ref.read(bookmarksProvider.notifier).clear();
                            await ref.read(sessionProvider.notifier).clearSession();
                            await ref.read(settingsProvider.notifier).resetToDefault();
                          } else {
                            await ref.read(historyProvider.notifier).clear();
                            await ref.read(wrongQuestionsProvider.notifier).clear();
                            await ref.read(sessionProvider.notifier).clearSession();
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isFullReset
                                      ? 'All data cleared. Settings restored to defaults.'
                                      : 'Progress reset complete. History & wrong questions cleared.',
                                ),
                              ),
                            );
                          }
                        } on AuthException catch (e) {
                          setDialogState(() {
                            isLoading = false;
                            errorMsg = 'Incorrect password. ${e.message}';
                          });
                        } catch (e) {
                          setDialogState(() {
                            isLoading = false;
                            errorMsg = 'Incorrect password or authentication error.';
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isFullReset ? 'Confirm Clear All Data' : 'Confirm Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final displayName = settings.getDisplayName(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U'),
                ),
                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(user.email ?? ''),
                trailing: const Icon(Icons.edit_outlined, size: 20),
                onTap: () => _showEditNameDialog(context, ref, displayName),
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
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 12, 4, 4),
            child: Text(
              'DATA & RESET OPTIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
            title: const Text('Reset Progress & Attempts'),
            subtitle: const Text('Clears test history & wrong questions. Bookmarks are kept.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showResetPasswordDialog(context, ref, isFullReset: false),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red),
            ),
            title: const Text('Clear All Data'),
            subtitle: const Text('Clears all history, wrong questions, bookmarks & settings.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _showResetPasswordDialog(context, ref, isFullReset: true),
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
