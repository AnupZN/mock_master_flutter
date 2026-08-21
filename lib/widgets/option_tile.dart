import 'package:flutter/material.dart';
import 'markdown_text.dart';

class OptionTile extends StatelessWidget {
  final String prefix;
  final String text;
  final bool isSelected;
  final bool? isCorrect; // null: normal, true: correct (green), false: wrong (red)
  final VoidCallback onTap;

  const OptionTile({
    super.key,
    required this.prefix,
    required this.text,
    required this.isSelected,
    this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor = theme.colorScheme.surface;
    Color borderColor = theme.colorScheme.outlineVariant;
    Color prefixBg = theme.colorScheme.surfaceContainerHighest;
    Color prefixFg = theme.colorScheme.onSurface;
    double borderWidth = 1;

    if (isCorrect == true) {
      backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.08);
      borderColor = const Color(0xFF10B981);
      prefixBg = const Color(0xFF10B981);
      prefixFg = Colors.white;
      borderWidth = 1.5;
    } else if (isCorrect == false) {
      backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.08);
      borderColor = const Color(0xFFEF4444);
      prefixBg = const Color(0xFFEF4444);
      prefixFg = Colors.white;
      borderWidth = 1.5;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.08);
      borderColor = theme.colorScheme.primary;
      prefixBg = theme.colorScheme.primary;
      prefixFg = theme.colorScheme.onPrimary;
      borderWidth = 1.5;
    }

    Widget trailingIcon;
    if (isCorrect == true) {
      trailingIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18);
    } else if (isCorrect == false) {
      trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18);
    } else if (isSelected) {
      trailingIcon = Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 18);
    } else {
      trailingIcon = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: borderWidth),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Prefix badge
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: prefixBg,
              ),
              child: Text(
                prefix,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: prefixFg,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MarkdownText(text: text),
            ),
            const SizedBox(width: 8),
            trailingIcon,
          ],
        ),
      ),
    );
  }
}
