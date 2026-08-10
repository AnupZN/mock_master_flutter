import 'package:flutter/material.dart';
import '../../models/exam_session.dart';

class QuestionPalette extends StatelessWidget {
  final ExamSession session;
  final int currentIndex;
  final Function(int) onQuestionSelected;

  const QuestionPalette({
    super.key,
    required this.session,
    required this.currentIndex,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    int answered = 0;
    int marked = 0;
    int visitedUnanswered = 0;
    int notVisited = 0;

    for (var q in session.questions) {
      final isAns = session.userAnswers[q.id] != null;
      final isMrk = session.markedForReview[q.id] == true;
      final isVis = session.visitedQuestions[q.id] == true;

      if (isMrk) {
        marked++;
      } else if (isAns) {
        answered++;
      } else if (isVis) {
        visitedUnanswered++;
      } else {
        notVisited++;
      }
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Question Palette',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),

          // Stat Chips Summary Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildStatBadge('Answered: $answered', const Color(0xFF10B981), Colors.white, Icons.check_circle_rounded),
              _buildStatBadge('Marked: $marked', const Color(0xFFF59E0B), Colors.white, Icons.flag_rounded),
              _buildStatBadge('Unanswered: $visitedUnanswered', isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), isDark ? Colors.white : Colors.black87, Icons.remove_circle_outline),
              _buildStatBadge('Not Visited: $notVisited', isDark ? Colors.white10 : Colors.black12, isDark ? Colors.white70 : Colors.black54, Icons.circle_outlined),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Question Tiles Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: session.questions.length,
              itemBuilder: (context, index) {
                final q = session.questions[index];
                final isAnswered = session.userAnswers[q.id] != null;
                final isMarked = session.markedForReview[q.id] == true;
                final isVisited = session.visitedQuestions[q.id] == true;
                final isCurrent = index == currentIndex;

                Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
                Color textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
                IconData? icon;
                BoxBorder? border;

                if (isCurrent) {
                  border = Border.all(color: const Color(0xFF4F46E5), width: 2.5);
                }

                if (isMarked) {
                  bgColor = const Color(0xFFF59E0B);
                  textColor = Colors.white;
                  icon = Icons.flag_rounded;
                } else if (isAnswered) {
                  bgColor = const Color(0xFF10B981);
                  textColor = Colors.white;
                  icon = Icons.check_rounded;
                } else if (isVisited) {
                  bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
                  textColor = isDark ? Colors.white : Colors.black87;
                  border = border ?? Border.all(color: Colors.grey.shade400, width: 1.5);
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onQuestionSelected(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      border: border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor,
                          ),
                        ),
                        if (icon != null)
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Icon(icon, size: 10, color: textColor),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, Color bg, Color text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text)),
        ],
      ),
    );
  }
}
