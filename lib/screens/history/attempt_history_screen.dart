import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/attempt_history.dart';
import '../../providers/history_provider.dart';

class AttemptHistoryScreen extends ConsumerWidget {
  final String subjectId;
  final String chapterId;
  final String chapterTitle;
  final String subjectName;

  const AttemptHistoryScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.chapterTitle,
    required this.subjectName,
  });

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '—';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    if (m == 0) return '${s}s';
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  Color _scoreColor(double accuracy) {
    if (accuracy >= 75) return const Color(0xFF10B981);
    if (accuracy >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allHistory = ref.watch(historyProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter to this chapter only, newest first
    final attempts = allHistory
        .where((h) => h.chapterId == chapterId && h.subjectId == subjectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Attempts'),
            Text(
              chapterTitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: attempts.isEmpty
          ? _buildEmptyState(context, isDark)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: attempts.length,
              itemBuilder: (context, index) {
                final attempt = attempts[index];
                return _AttemptCard(
                  attempt: attempt,
                  attemptNumber: attempts.length - index,
                  isLatest: index == 0,
                  isDark: isDark,
                  onTap: () {
                    context.push(
                      '/history/review',
                      extra: {
                        'attempt': attempt,
                        'attemptNumber': attempts.length - index,
                      },
                    );
                  },
                  scoreColor: _scoreColor(attempt.accuracy),
                  formattedDate: _formatDate(attempt.date),
                  formattedDuration: _formatDuration(attempt.timeTaken),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 48,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No attempts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t attempted "$chapterTitle" yet.\nStart your first exam to see your history here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Start Exam'),
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AttemptCard extends StatelessWidget {
  final AttemptHistoryItem attempt;
  final int attemptNumber;
  final bool isLatest;
  final bool isDark;
  final VoidCallback onTap;
  final Color scoreColor;
  final String formattedDate;
  final String formattedDuration;

  const _AttemptCard({
    required this.attempt,
    required this.attemptNumber,
    required this.isLatest,
    required this.isDark,
    required this.onTap,
    required this.scoreColor,
    required this.formattedDate,
    required this.formattedDuration,
  });

  @override
  Widget build(BuildContext context) {
    final pct = attempt.maxScore > 0
        ? (attempt.score / attempt.maxScore * 100)
        : attempt.accuracy;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────
                Row(
                  children: [
                    // Attempt badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Attempt $attemptNumber',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ),
                    if (isLatest) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Latest',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Score
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Stats row ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatPill(
                        label: 'Score',
                        value: '${attempt.score.toStringAsFixed(1)} / ${attempt.maxScore.toStringAsFixed(1)}',
                        color: scoreColor,
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _StatPill(
                        label: 'Correct',
                        value: '${attempt.correctCount}',
                        color: const Color(0xFF10B981),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _StatPill(
                        label: 'Wrong',
                        value: '${attempt.wrongCount}',
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _StatPill(
                        label: 'Skipped',
                        value: '${attempt.skippedCount}',
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        isDark: isDark,
                      ),
                      _Divider(isDark: isDark),
                      _StatPill(
                        label: 'Time',
                        value: formattedDuration,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Footer row ───────────────────────────────────────────
                Row(
                  children: [
                    if (attempt.isPracticeMode == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Practice Mode',
                          style: TextStyle(fontSize: 10, color: Color(0xFF7C3AED), fontWeight: FontWeight.w500),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      'Tap to review →',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
    );
  }
}
