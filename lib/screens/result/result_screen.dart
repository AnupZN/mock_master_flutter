import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/history_provider.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    if (history.isEmpty) return const Scaffold(body: Center(child: Text('No result found')));

    final result = history.first;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scoreRatio =
        result.maxScore > 0 ? (result.score / result.maxScore).clamp(0.0, 1.0) : 0.0;

    // Completion ratio: how many questions were actually attempted vs total
    final attempted = result.correctCount + result.wrongCount;
    final completionRatio = result.totalQuestions > 0
        ? attempted / result.totalQuestions
        : 0.0;

    // Performance depends on BOTH accuracy (of answered Qs) AND completion.
    // A user who answered 1/106 questions correctly is not "Masterful".
    String performanceText;
    Color performanceColor;
    if (completionRatio >= 0.5 && result.accuracy >= 90) {
      performanceText = 'Masterful Performance! 🏆';
      performanceColor = const Color(0xFF10B981);
    } else if (completionRatio >= 0.5 && result.accuracy >= 75) {
      performanceText = 'Great Job! ⭐';
      performanceColor = const Color(0xFF4F46E5);
    } else if (completionRatio >= 0.3 && result.accuracy >= 50) {
      performanceText = 'Good Effort! 👍';
      performanceColor = const Color(0xFFF59E0B);
    } else if (attempted == 0) {
      performanceText = 'No Attempts Made';
      performanceColor = const Color(0xFF64748B);
    } else {
      performanceText = 'Keep Practicing! 💪';
      performanceColor = Colors.orange;
    }

    // Safe accuracy: never show −0%
    final displayAccuracy = result.accuracy.abs();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          children: [
            // Performance Header
            Text(
              performanceText,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: performanceColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${result.subjectName} · ${result.chapterTitle}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Score Circular Progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 148,
                  height: 148,
                  child: CircularProgressIndicator(
                    value: scoreRatio,
                    strokeWidth: 12,
                    backgroundColor:
                        isDark ? Colors.white10 : Colors.grey.shade200,
                    color: performanceColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.score % 1 == 0
                          ? result.score.toInt().toString()
                          : result.score.toStringAsFixed(1),
                      style: theme.textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.bold, height: 1.1),
                    ),
                    Text(
                      'out of ${result.maxScore.toInt()}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: performanceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${displayAccuracy.toStringAsFixed(1)}% accuracy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: performanceColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Four stat cards: Attempted, Correct, Wrong, Skipped
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Attempted',
                    '$attempted',
                    const Color(0xFF4F46E5),
                    Icons.edit_note_rounded,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Correct',
                    '${result.correctCount}',
                    const Color(0xFF10B981),
                    Icons.check_circle_rounded,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Wrong',
                    '${result.wrongCount}',
                    const Color(0xFFEF4444),
                    Icons.cancel_rounded,
                    theme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    'Skipped',
                    '${result.skippedCount}',
                    const Color(0xFF64748B),
                    Icons.remove_circle_outline,
                    theme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time Taken & Total Questions row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetaItem(
                    Icons.timer_outlined,
                    _formatTime(result.timeTaken),
                    'Time Taken',
                    const Color(0xFF4F46E5),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildMetaItem(
                    Icons.quiz_outlined,
                    '${result.totalQuestions}',
                    'Total Questions',
                    const Color(0xFF7C3AED),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildMetaItem(
                    Icons.bar_chart_rounded,
                    '$attempted/${result.totalQuestions}',
                    'Attempted',
                    const Color(0xFF0891B2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review Answers',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/review'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Dashboard'),
                onPressed: () => context.go('/dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String val, Color color, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 3),
          Text(
            val,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.2,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
