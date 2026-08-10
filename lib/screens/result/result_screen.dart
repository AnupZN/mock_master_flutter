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

    final scoreRatio = result.maxScore > 0 ? (result.score / result.maxScore).clamp(0.0, 1.0) : 0.0;
    
    String performanceText = 'Keep Practicing! 💪';
    Color performanceColor = Colors.orange;
    if (result.accuracy >= 90) {
      performanceText = 'Masterful Performance! 🏆';
      performanceColor = const Color(0xFF10B981);
    } else if (result.accuracy >= 75) {
      performanceText = 'Great Job! ⭐';
      performanceColor = const Color(0xFF4F46E5);
    } else if (result.accuracy >= 50) {
      performanceText = 'Good Effort! 👍';
      performanceColor = const Color(0xFFF59E0B);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Result'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 8),
            Text(
              '${result.subjectName} — ${result.chapterTitle}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Score Circular Progress
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: scoreRatio,
                    strokeWidth: 14,
                    backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                    color: performanceColor,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      result.score % 1 == 0 ? result.score.toInt().toString() : result.score.toStringAsFixed(1),
                      style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Out of ${result.maxScore.toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: performanceColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${result.accuracy.toStringAsFixed(1)}% Accuracy',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: performanceColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Stat Cards Row: Correct, Wrong, Skipped
            Row(
              children: [
                Expanded(child: _buildStatCard('Correct', '${result.correctCount}', const Color(0xFF10B981), Icons.check_circle_rounded, theme)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Wrong', '${result.wrongCount}', const Color(0xFFEF4444), Icons.cancel_rounded, theme)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Skipped', '${result.skippedCount}', const Color(0xFF64748B), Icons.remove_circle_outline, theme)),
              ],
            ),
            const SizedBox(height: 20),

            // Time Taken & Metrics Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFF4F46E5), size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Time Taken', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(_formatTime(result.timeTaken), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    Container(height: 30, width: 1, color: theme.colorScheme.outlineVariant),
                    Row(
                      children: [
                        const Icon(Icons.help_outline_rounded, color: Color(0xFF7C3AED), size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Questions', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text('${result.totalQuestions}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text('Review Answers', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => context.go('/review'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
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

  Widget _buildStatCard(String label, String val, Color color, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
