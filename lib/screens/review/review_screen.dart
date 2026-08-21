import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/exam_session.dart';
import '../../models/question.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/option_tile.dart';

enum ReviewFilter { all, correct, wrong, skipped }

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  ReviewFilter _activeFilter = ReviewFilter.all;
  int _currentIndex = 0;
  bool _isHindi = false;
  final bool _showExplanation = true;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<Question> _getFilteredQuestions(ExamSession session) {
    switch (_activeFilter) {
      case ReviewFilter.correct:
        return session.questions.where((q) => session.userAnswers[q.id] == q.correct).toList();
      case ReviewFilter.wrong:
        return session.questions
            .where((q) => session.userAnswers[q.id] != null && session.userAnswers[q.id] != q.correct)
            .toList();
      case ReviewFilter.skipped:
        return session.questions.where((q) => session.userAnswers[q.id] == null).toList();
      case ReviewFilter.all:
        return session.questions;
    }
  }

  void _onFilterChanged(ReviewFilter newFilter) {
    setState(() {
      _activeFilter = newFilter;
      _currentIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _navigateToPage(int index, int totalCount) {
    if (index >= 0 && index < totalCount) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showReviewPaletteSheet(BuildContext context, ExamSession session, List<Question> filteredList) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Review Question Palette',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final q = filteredList[index];
                      final userAns = session.userAnswers[q.id];
                      final isCorrect = userAns == q.correct;
                      final isWrong = userAns != null && userAns != q.correct;
                      final isCurrent = index == _currentIndex;

                      Color tileBg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                      Color tileColor = isDark ? Colors.white : Colors.black87;
                      late final IconData iconData;

                      if (isCorrect) {
                        tileBg = const Color(0xFF10B981);
                        tileColor = Colors.white;
                        iconData = Icons.check_rounded;
                      } else if (isWrong) {
                        tileBg = const Color(0xFFEF4444);
                        tileColor = Colors.white;
                        iconData = Icons.close_rounded;
                      } else {
                        tileBg = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
                        iconData = Icons.horizontal_rule_rounded;
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToPage(index, filteredList.length);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: tileBg,
                            borderRadius: BorderRadius.circular(12),
                            border: isCurrent
                                ? Border.all(color: theme.colorScheme.primary, width: 3)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${session.questions.indexOf(q) + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tileColor,
                                  fontSize: 14,
                                ),
                              ),
                              Icon(iconData, size: 12, color: tileColor),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Answers')),
        body: const Center(child: Text('No active session review data.')),
      );
    }

    final allQuestions = session.questions;
    final int correctCount = allQuestions.where((q) => session.userAnswers[q.id] == q.correct).length;
    final int wrongCount = allQuestions.where((q) => session.userAnswers[q.id] != null && session.userAnswers[q.id] != q.correct).length;
    final int skippedCount = allQuestions.where((q) => session.userAnswers[q.id] == null).length;

    final filteredQuestions = _getFilteredQuestions(session);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Review Answers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              session.chapterTitle,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to Results',
          onPressed: () => context.go('/result'),
        ),
        actions: [
          // Language Switcher Chip
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isHindi = !_isHindi),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                _isHindi ? 'हिन्दी' : 'English',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Palette Trigger Button
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Question Palette',
            onPressed: () => _showReviewPaletteSheet(context, session, filteredQuestions),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Filter Bar (All, Correct, Wrong, Skipped)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All ${allQuestions.length}', ReviewFilter.all, theme),
                  const SizedBox(width: 8),
                  _buildFilterChip('Correct $correctCount', ReviewFilter.correct, theme, color: const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Wrong $wrongCount', ReviewFilter.wrong, theme, color: const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterChip('Skipped $skippedCount', ReviewFilter.skipped, theme, color: Colors.orange),
                ],
              ),
            ),
          ),

          // 2. Question View Area
          Expanded(
            child: filteredQuestions.isEmpty
                ? EmptyState(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No questions in this filter',
                    subtitle: 'Select another filter above to review questions.',
                  )
                : PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final q = filteredQuestions[index];
                      final originalIndex = session.questions.indexOf(q);
                      final userAns = session.userAnswers[q.id];
                      final isCorrect = userAns == q.correct;
                      final isWrong = userAns != null && userAns != q.correct;
                      final isSkipped = userAns == null;

                      final isBookmarked = bookmarks.any(
                        (b) => b.subjectId == session.subjectId && b.chapterId == session.chapterId && b.questionId == q.id,
                      );

                      final questionText = _isHindi && q.questionHi != null ? q.questionHi! : q.question;
                      final options = _isHindi && q.optionsHi != null ? q.optionsHi! : q.options;
                      final explanationText = _isHindi && q.explanationHi != null ? q.explanationHi! : q.explanation;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Question Metadata & Status Banner
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Q ${index + 1} / ${filteredQuestions.length} (Overall #${originalIndex + 1})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Status Badge (Correct / Wrong / Skipped)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCorrect
                                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                        : isWrong
                                            ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                            : Colors.orange.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCorrect
                                          ? const Color(0xFF10B981)
                                          : isWrong
                                              ? const Color(0xFFEF4444)
                                              : Colors.orange,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCorrect
                                            ? Icons.check_circle_rounded
                                            : isWrong
                                                ? Icons.cancel_rounded
                                                : Icons.remove_circle_outline_rounded,
                                        size: 14,
                                        color: isCorrect
                                            ? const Color(0xFF10B981)
                                            : isWrong
                                                ? const Color(0xFFEF4444)
                                                : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isCorrect
                                            ? '✓ Correct'
                                            : isWrong
                                                ? '✕ Wrong Choice'
                                                : '— Skipped',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: isCorrect
                                              ? const Color(0xFF10B981)
                                              : isWrong
                                                  ? const Color(0xFFEF4444)
                                                  : Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Spacer(),

                                // Bookmark Toggle Button
                                IconButton(
                                  icon: Icon(
                                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                    color: isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  tooltip: isBookmarked ? 'Bookmarked' : 'Bookmark Question',
                                  onPressed: () {
                                    ref.read(bookmarksProvider.notifier).toggle(session.subjectId, session.chapterId, q.id);
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Question Markdown Body
                            MarkdownText(text: questionText),

                            const SizedBox(height: 20),

                            // Options List with Clear Correct/Wrong Visuals
                            ...List.generate(options.length, (optIdx) {
                              final isUserChoice = userAns == optIdx;
                              final isCorrectChoice = optIdx == q.correct;

                              bool? optionStatus;
                              if (isCorrectChoice) {
                                optionStatus = true; // Always Green
                              } else if (isUserChoice) {
                                optionStatus = false; // User's wrong choice in Red
                              }

                              return OptionTile(
                                prefix: String.fromCharCode(65 + optIdx),
                                text: options[optIdx],
                                isSelected: isUserChoice,
                                isCorrect: optionStatus,
                                onTap: () {},
                              );
                            }),

                            if (isSkipped) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 15, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Not attempted — correct answer is highlighted in green.',
                                        style: TextStyle(fontSize: 12, color: Colors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Collapsible Explanation Section
                            if (explanationText.isNotEmpty) ...[
                              Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: _showExplanation,
                                  leading: const Icon(Icons.lightbulb_outline_rounded, color: Colors.amber),
                                  title: const Text('Explanation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                      child: MarkdownText(text: explanationText),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Sticky Navigation Action Bar (Previous & Next / Done)
          if (filteredQuestions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // Previous Button
                    Expanded(
                      flex: 38,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text(
                          'Previous',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _currentIndex == 0 ? null : () => _navigateToPage(_currentIndex - 1, filteredQuestions.length),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Next / Done Button
                    Expanded(
                      flex: 62,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _currentIndex == filteredQuestions.length - 1
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(
                          _currentIndex == filteredQuestions.length - 1
                              ? Icons.check_circle_outline_rounded
                              : Icons.arrow_forward_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _currentIndex == filteredQuestions.length - 1 ? 'Finish Review' : 'Next Question',
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (_currentIndex == filteredQuestions.length - 1) {
                            context.go('/result');
                          } else {
                            _navigateToPage(_currentIndex + 1, filteredQuestions.length);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ReviewFilter filter, ThemeData theme, {Color? color}) {
    final isSelected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (color ?? theme.colorScheme.onSurface),
        ),
      ),
      selected: isSelected,
      selectedColor: color ?? theme.colorScheme.primary,
      onSelected: (_) => _onFilterChanged(filter),
    );
  }
}
