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
    Color borderColor = theme.dividerColor;
    
    if (isCorrect == true) {
      backgroundColor = Colors.green.withValues(alpha: 0.1);
      borderColor = Colors.green;
    } else if (isCorrect == false) {
      backgroundColor = Colors.red.withValues(alpha: 0.1);
      borderColor = Colors.red;
    } else if (isSelected) {
      backgroundColor = theme.colorScheme.primaryContainer;
      borderColor = theme.colorScheme.primary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: isSelected || isCorrect != null ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                prefix,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: MarkdownText(text: text),
              ),
            ),
            if (isCorrect == true)
              const Icon(Icons.check_circle_rounded, color: Colors.green)
            else if (isCorrect == false)
              const Icon(Icons.cancel_rounded, color: Colors.red)
            else if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
