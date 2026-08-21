import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/settings_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/wrong_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final displayName = settings.getDisplayName(user);
    final history = ref.watch(historyProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final activeSession = ref.watch(sessionProvider);
    final wrongQuestions = ref.watch(wrongQuestionsProvider);
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
          // ── Hero Header ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Row ─────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                        onPressed: () => context.go('/settings'),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Stats Banner ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatColumn('$totalSubjects', 'Subjects', Icons.menu_book_rounded)),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                        Expanded(child: _buildStatColumn('$totalChapters', 'Chapters', Icons.list_alt_rounded)),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                        Expanded(child: _buildStatColumn('${accuracy.toStringAsFixed(0)}%', 'Accuracy', Icons.analytics_rounded)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Resumable Test Card ───────────────────────────────────
                  if (activeSession != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(18),
                        border: const Border.fromBorderSide(BorderSide(color: Color(0xFF818CF8), width: 1.5)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF4F46E5), size: 18),
                              const SizedBox(width: 7),
                              const Text(
                                'Unfinished Test',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(activeSession.timeRemaining / 60).floor()}m left',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            activeSession.chapterTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${activeSession.subjectName} · ${activeSession.userAnswers.length} of ${activeSession.questions.length} answered',
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
                    const SizedBox(height: 28),
                  ],

                  // ── Practice Modes ────────────────────────────────────────
                  Text(
                    'Practice Modes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose how you want to practice today',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // GridView guarantees all 4 cells are pixel-identical in
                  // width and height regardless of content length.
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      _buildPracticeCard(
                        context,
                        title: 'Browse Subjects',
                        subtitle: 'Study chapter by chapter',
                        icon: Icons.explore_rounded,
                        color: const Color(0xFF4F46E5),
                        onTap: () => context.go('/subjects'),
                        isDark: isDark,
                      ),
                      _buildPracticeCard(
                        context,
                        title: 'Custom Practice',
                        subtitle: 'Mix topics your way',
                        icon: Icons.auto_awesome_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => context.push('/generator?mode=custom'),
                        isDark: isDark,
                      ),
                      _buildPracticeCard(
                        context,
                        title: 'Random Practice',
                        subtitle: 'Surprise question set',
                        icon: Icons.shuffle_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () => context.push('/generator?mode=bookmark'),
                        isDark: isDark,
                      ),
                      _buildPracticeCard(
                        context,
                        title: 'Weak Areas',
                        subtitle: wrongQuestions.isEmpty
                            ? 'Practice more to unlock'
                            : '${wrongQuestions.length} to revisit',
                        icon: Icons.fitness_center_rounded,
                        color: const Color(0xFFEF4444),
                        onTap: () => context.go('/bookmarks'),
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // ── Recent History ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent History',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
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
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 44,
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No test history yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Complete a practice session to see your results here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.assignment_turned_in_rounded, color: badgeColor, size: 20),
                            ),
                            title: Text(
                              item.chapterTitle,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item.subjectName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${item.score.toStringAsFixed(1)} / ${item.maxScore.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: badgeColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${pct.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  // Bottom padding — clears the bottom navigation bar
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat column in header banner ─────────────────────────────────────────
  Widget _buildStatColumn(String value, String label, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 15),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.65),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Practice mode card ──────────────────────────────────────────────────
  // The card fills its GridView cell completely (width + height are fixed by
  // the grid's childAspectRatio). Icon is always top-left; title + subtitle
  // sit directly below at the same Y position in every card.
  Widget _buildPracticeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          // No padding override — fills grid cell; padding applied inside.
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          padding: const EdgeInsets.all(16),
          // Column with start alignment: icon pins to top, text follows.
          // The grid cell height is fixed so there's no per-card size drift.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Icon badge — always at the top
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              // Title — fixed position, always starts here
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Subtitle — fixed position, always starts here
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
