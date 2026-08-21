import 'package:flutter/material.dart';

/// A fixed-size, visually consistent pair of action buttons for chapter cards.
///
/// - "Attempts" is always the label, never changes to "History" or other text.
/// - The attempt count is shown as a small rounded badge next to the label.
/// - Both buttons have identical height, border radius, and padding so they
///   always align perfectly regardless of count value (0, 1, 12, etc.).
class ChapterActionButtons extends StatelessWidget {
  final int attemptCount;
  final VoidCallback onAttemptsPressed;
  final VoidCallback onStartExamPressed;

  const ChapterActionButtons({
    super.key,
    required this.attemptCount,
    required this.onAttemptsPressed,
    required this.onStartExamPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Shared geometry — both buttons use exactly these values.
    const double buttonHeight = 40;
    const borderRadius = BorderRadius.all(Radius.circular(10));
    const shape = RoundedRectangleBorder(borderRadius: borderRadius);

    return Row(
      children: [
        // ── Secondary: Attempts ─────────────────────────────────────────────
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              onPressed: onAttemptsPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 15,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Attempts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Count badge — always rendered, never omitted.
                  _CountBadge(count: attemptCount, theme: theme),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // ── Primary: Start Exam ─────────────────────────────────────────────
        Expanded(
          child: SizedBox(
            height: buttonHeight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 17),
              label: const Text(
                'Start Exam',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              onPressed: onStartExamPressed,
            ),
          ),
        ),
      ],
    );
  }
}

/// Small rounded badge that shows the numeric count.
/// Has a fixed minimum width so single-digit and multi-digit counts
/// never shift the surrounding layout.
class _CountBadge extends StatelessWidget {
  final int count;
  final ThemeData theme;

  const _CountBadge({required this.count, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
