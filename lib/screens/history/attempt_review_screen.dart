import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/attempt_history.dart';
import '../../models/question.dart';
import '../../providers/auth_provider.dart';
import '../../services/chapter_service.dart';
import '../../widgets/markdown_text.dart';

enum _ReviewFilter { all, correct, wrong, skipped }

class AttemptReviewScreen extends ConsumerStatefulWidget {
  final AttemptHistoryItem attempt;
  final int attemptNumber;

  const AttemptReviewScreen({
    super.key,
    required this.attempt,
    required this.attemptNumber,
  });

  @override
  ConsumerState<AttemptReviewScreen> createState() => _AttemptReviewScreenState();
}

class _AttemptReviewScreenState extends ConsumerState<AttemptReviewScreen> {
  _ReviewFilter _filter = _ReviewFilter.all;
  int _currentIndex = 0;
  bool _isHindi = false;
  List<Question> _allQuestions = [];
  bool _loading = true;
  String? _error;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final attempt = widget.attempt;
    try {
      final supabase = ref.read(supabaseProvider);
      final service = ChapterService(supabase);
      final data = await service.loadChapter(attempt.subjectId, attempt.chapterId);
      if (data != null && mounted) {
        List<Question> questions = data.questions;
        // If questionIds were recorded, preserve the original attempt order.
        if (attempt.questionIds != null && attempt.questionIds!.isNotEmpty) {
          final idSet = attempt.questionIds!.toSet();
          final ordered = attempt.questionIds!
              .where((id) => questions.any((q) => q.id == id))
              .map((id) => questions.firstWhere((q) => q.id == id))
              .toList();
          if (ordered.isNotEmpty) {
            questions = ordered;
          } else {
            // Fallback: filter by idSet.
            questions = questions.where((q) => idSet.contains(q.id)).toList();
          }
        }
        setState(() {
          _allQuestions = questions;
          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _error = 'Could not load questions for this attempt.\nThe chapter data may have changed.';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load questions: $e';
          _loading = false;
        });
      }
    }
  }

  List<Question> get _filteredQuestions {
    final answers = widget.attempt.userAnswers;
    if (answers == null) return _allQuestions;
    switch (_filter) {
      case _ReviewFilter.all:
        return _allQuestions;
      case _ReviewFilter.correct:
        return _allQuestions.where((q) => answers[q.id] == q.correct).toList();
      case _ReviewFilter.wrong:
        return _allQuestions
            .where((q) => answers[q.id] != null && answers[q.id] != q.correct)
            .toList();
      case _ReviewFilter.skipped:
        return _allQuestions.where((q) => answers[q.id] == null).toList();
    }
  }

  void _setFilter(_ReviewFilter f) {
    setState(() {
      _filter = f;
      _currentIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  void _goTo(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return DateFormat('d MMM yyyy, h:mm a').format(dt);
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final attempt = widget.attempt;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attempt ${widget.attemptNumber} Review'),
            Text(
              _formatDate(attempt.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          // Hindi/English toggle (only if questions loaded)
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilterChip(
                label: Text(_isHindi ? 'हि' : 'EN',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                selected: _isHindi,
                onSelected: (_) => setState(() => _isHindi = !_isHindi),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDark)
              : _buildBody(theme, isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _loadQuestions();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark) {
    final filtered = _filteredQuestions;
    final answers = widget.attempt.userAnswers;
    final hasAnswers = answers != null && answers.isNotEmpty;

    return Column(
      children: [
        // ── Summary strip ────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryChip(
                label: '✓',
                value: '${widget.attempt.correctCount}',
                color: const Color(0xFF10B981),
              ),
              _SummaryChip(
                label: '✕',
                value: '${widget.attempt.wrongCount}',
                color: const Color(0xFFEF4444),
              ),
              _SummaryChip(
                label: '—',
                value: '${widget.attempt.skippedCount}',
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
              _SummaryChip(
                label: 'Score',
                value: '${widget.attempt.score.toStringAsFixed(1)}/${widget.attempt.maxScore.toStringAsFixed(1)}',
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),

        // ── Filter chips ─────────────────────────────────────────────────
        if (hasAnswers)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('All (${_allQuestions.length})', _ReviewFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Correct (${widget.attempt.correctCount})', _ReviewFilter.correct,
                    color: const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildFilterChip('Wrong (${widget.attempt.wrongCount})', _ReviewFilter.wrong,
                    color: const Color(0xFFEF4444)),
                const SizedBox(width: 8),
                _buildFilterChip('Skipped (${widget.attempt.skippedCount})', _ReviewFilter.skipped,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ],
            ),
          ),

        // ── Position counter ─────────────────────────────────────────────
        if (filtered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Q ${_currentIndex + 1} of ${filtered.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                // Jump to incorrect button
                if (hasAnswers)
                  TextButton.icon(
                    icon: const Icon(Icons.flag_rounded, size: 14),
                    label: const Text('Incorrect', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => _setFilter(_ReviewFilter.wrong),
                  ),
              ],
            ),
          ),

        // ── Question PageView ────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyFilter(isDark)
              : PageView.builder(
                  controller: _pageController,
                  itemCount: filtered.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    final q = filtered[index];
                    final userAnswer = answers?[q.id];
                    final isCorrect = userAnswer == q.correct;
                    final isSkipped = userAnswer == null;

                    return _QuestionCard(
                      question: q,
                      questionNumber: index + 1,
                      totalQuestions: filtered.length,
                      userAnswer: userAnswer,
                      isCorrect: isCorrect,
                      isSkipped: isSkipped,
                      isHindi: _isHindi,
                      isDark: isDark,
                      hasAnswerData: hasAnswers,
                    );
                  },
                ),
        ),

        // ── Navigation bar ───────────────────────────────────────────────
        if (filtered.isNotEmpty)
          _buildNavBar(filtered.length, isDark),
      ],
    );
  }

  Widget _buildFilterChip(String label, _ReviewFilter filter, {Color? color}) {
    final selected = _filter == filter;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _setFilter(filter),
      selectedColor: (color ?? const Color(0xFF4F46E5)).withValues(alpha: 0.15),
      checkmarkColor: color ?? const Color(0xFF4F46E5),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? (color ?? const Color(0xFF4F46E5)) : null,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyFilter(bool isDark) {
    return Center(
      child: Text(
        'No questions in this category',
        style: TextStyle(
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  Widget _buildNavBar(int total, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Prev
          Expanded(
            flex: 2,
            child: OutlinedButton(
              onPressed: _currentIndex > 0 ? () => _goTo(_currentIndex - 1) : null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('← Prev'),
            ),
          ),
          const SizedBox(width: 10),

          // Palette
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () => _showPalette(total),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.grid_view_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 10),

          // Next / Done
          Expanded(
            flex: 2,
            child: _currentIndex < total - 1
                ? FilledButton(
                    onPressed: () => _goTo(_currentIndex + 1),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Next →'),
                  )
                : FilledButton(
                    onPressed: () => context.pop(),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Done'),
                  ),
          ),
        ],
      ),
    );
  }

  void _showPalette(int total) {
    final filtered = _filteredQuestions;
    final answers = widget.attempt.userAnswers;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Question Palette',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final q = filtered[i];
                      final ua = answers?[q.id];
                      Color bg;
                      if (ua == null) {
                        bg = const Color(0xFF94A3B8);
                      } else if (ua == q.correct) {
                        bg = const Color(0xFF10B981);
                      } else {
                        bg = const Color(0xFFEF4444);
                      }
                      final isSelected = i == _currentIndex;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _goTo(i);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: isSelected ? 1.0 : 0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Legend(color: const Color(0xFF10B981), label: 'Correct'),
                    _Legend(color: const Color(0xFFEF4444), label: 'Wrong'),
                    _Legend(color: const Color(0xFF94A3B8), label: 'Skipped'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final Question question;
  final int questionNumber;
  final int totalQuestions;
  final int? userAnswer;
  final bool isCorrect;
  final bool isSkipped;
  final bool isHindi;
  final bool isDark;
  final bool hasAnswerData;

  const _QuestionCard({
    required this.question,
    required this.questionNumber,
    required this.totalQuestions,
    required this.userAnswer,
    required this.isCorrect,
    required this.isSkipped,
    required this.isHindi,
    required this.isDark,
    required this.hasAnswerData,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showExplanation = true;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isDark = widget.isDark;

    // Status colors and labels
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (!widget.hasAnswerData || widget.isSkipped) {
      statusColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
      statusLabel = '— Skipped';
      statusIcon = Icons.remove_circle_outline_rounded;
    } else if (widget.isCorrect) {
      statusColor = const Color(0xFF10B981);
      statusLabel = '✓ Correct';
      statusIcon = Icons.check_circle_rounded;
    } else {
      statusColor = const Color(0xFFEF4444);
      statusLabel = '✕ Wrong';
      statusIcon = Icons.cancel_rounded;
    }

    final questionText = (widget.isHindi && q.questionHi != null && q.questionHi!.isNotEmpty)
        ? q.questionHi!
        : q.question;
    final options = (widget.isHindi && q.optionsHi != null && q.optionsHi!.isNotEmpty)
        ? q.optionsHi!
        : q.options;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status badge ───────────────────────────────────────────────
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Q${widget.questionNumber} of ${widget.totalQuestions}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Question text ──────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: MarkdownText(text: questionText),
          ),
          const SizedBox(height: 12),

          // ── Options ────────────────────────────────────────────────────
          ...List.generate(options.length, (idx) {
            final isUserChoice = widget.hasAnswerData && widget.userAnswer == idx;
            final isCorrectOption = idx == q.correct;

            Color? tileColor;
            Color? borderColor;
            Widget? trailingIcon;

            if (isCorrectOption) {
              tileColor = const Color(0xFF10B981).withValues(alpha: 0.1);
              borderColor = const Color(0xFF10B981);
              trailingIcon = const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 18);
            } else if (isUserChoice && !isCorrectOption) {
              tileColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
              borderColor = const Color(0xFFEF4444);
              trailingIcon = const Icon(Icons.cancel_rounded,
                  color: Color(0xFFEF4444), size: 18);
            } else {
              tileColor = isDark ? const Color(0xFF1E293B) : Colors.white;
              borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
            }

            final optionLabels = ['A', 'B', 'C', 'D', 'E'];
            final label = idx < optionLabels.length ? optionLabels[idx] : '${idx + 1}';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: isCorrectOption || isUserChoice ? 1.5 : 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: isCorrectOption
                              ? const Color(0xFF10B981)
                              : (isUserChoice
                                  ? const Color(0xFFEF4444)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: (isCorrectOption || isUserChoice)
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: MarkdownText(text: options[idx]),
                      ),
                      if (trailingIcon != null) ...[
                        const SizedBox(width: 8),
                        trailingIcon,
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── Your answer annotation (if wrong) ─────────────────────────
          if (widget.hasAnswerData && !widget.isSkipped && !widget.isCorrect) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text(
                    'Your answer: Option ${['A', 'B', 'C', 'D', 'E'][widget.userAnswer!]}  ·  '
                    'Correct: Option ${['A', 'B', 'C', 'D', 'E'][q.correct]}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ── Explanation ────────────────────────────────────────────────
          if (q.explanation.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _showExplanation = !_showExplanation),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 16,
                          color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _showExplanation
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    if (_showExplanation) ...[
                      const SizedBox(height: 8),
                      MarkdownText(text: q.explanation),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 80), // space above nav bar
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
