import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../providers/session_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final activeSession = ref.watch(sessionProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    int totalSubjects = 0;
    int totalChapters = 0;
    if (subjectsState.hasValue) {
      totalSubjects = subjectsState.value!.length;
      for (var s in subjectsState.value!) {
        totalChapters += s.chapters.length;
      }
    }

    double accuracy = 0.0;
    if (history.isNotEmpty) {
      accuracy = history.map((e) => e.accuracy).fold<double>(0.0, (a, b) => a + b) / history.length;
    }


    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom App Bar / Hero Header
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              (settings.userName.isNotEmpty ? settings.userName : 'U')[0].toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                settings.userName.isNotEmpty ? settings.userName : 'Aspirant',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => context.go('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hero Stat Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeroStat('Subjects', '$totalSubjects', Icons.menu_book_rounded),
                        Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _buildHeroStat('Chapters', '$totalChapters', Icons.list_alt_rounded),
                        Container(height: 30, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                        _buildHeroStat('Accuracy', '${accuracy.toStringAsFixed(0)}%', Icons.analytics_rounded),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Resumable Unfinished Test Card
                  if (activeSession != null) ...[
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF4F46E5), size: 20),
                                const SizedBox(width: 8),
                                const Text('Unfinished Test in Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5))),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${(activeSession.timeRemaining / 60).floor()}m remaining',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              activeSession.chapterTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              '${activeSession.subjectName} • ${activeSession.userAnswers.length} of ${activeSession.questions.length} answered',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                    label: const Text('Resume Test'),
                                    onPressed: () => context.go('/exam'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
                                  onPressed: () => ref.read(sessionProvider.notifier).clearSession(),
                                  child: const Text('Discard'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Practice Modes Section
                  Text(
                    'Practice Modes',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 2.2,
                    children: [
                      _buildQuickActionCard(
                        context,
                        title: 'Browse Subjects',
                        subtitle: 'Study by chapter',
                        icon: Icons.explore_rounded,
                        color: const Color(0xFF4F46E5),
                        onTap: () => context.go('/subjects'),
                      ),
                      _buildQuickActionCard(
                        context,
                        title: 'Bookmarked Test',
                        subtitle: 'Test saved Qs',
                        icon: Icons.bookmark_added_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/generator?mode=bookmark'),
                      ),
                      _buildQuickActionCard(
                        context,
                        title: 'Custom/Mixed Test',
                        subtitle: 'Random test mix',
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => context.push('/generator?mode=custom'),
                      ),
                      _buildQuickActionCard(
                        context,
                        title: 'Leaderboard',
                        subtitle: 'Global rankings',
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFF59E0B),
                        onTap: () => context.go('/leaderboard'),
                      ),
                      _buildQuickActionCard(
                        context,
                        title: 'Settings',
                        subtitle: 'App preferences',
                        icon: Icons.tune_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => context.go('/settings'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Recent Activity Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent History',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (history.isNotEmpty)
                        TextButton(
                          onPressed: () => context.go('/subjects'),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (history.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 48,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No recent test activity yet.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select a subject from the catalog to start practicing!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.take(5).length,
                      itemBuilder: (context, index) {
                        final item = history[index];
                        final pct = item.maxScore > 0 ? (item.score / item.maxScore) * 100 : 0.0;
                        Color badgeColor = const Color(0xFF10B981);
                        if (pct < 50) {
                          badgeColor = const Color(0xFFEF4444);
                        } else if (pct < 75) {
                          badgeColor = const Color(0xFFF59E0B);
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.assignment_turned_in_rounded, color: badgeColor, size: 20),
                            ),
                            title: Text(item.chapterTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item.subjectName, style: const TextStyle(fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.score.toStringAsFixed(1)} / ${item.maxScore.toStringAsFixed(1)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor),
                                ),
                                Text(
                                  '${pct.toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

