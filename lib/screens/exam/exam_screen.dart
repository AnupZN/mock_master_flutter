import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/session_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attempt_history.dart';
import '../../models/exam_session.dart';
import '../../services/report_service.dart';
import '../../widgets/markdown_text.dart';
import '../../widgets/option_tile.dart';
import 'question_palette.dart';

class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  int _currentIndex = 0;
  Timer? _timer;
  bool _isHindi = false;
  // ARCH-2: _examStarted ensures the timer only fires after the UI is fully
  // ready — it must not auto-start during any loading delay or transition.
  bool _examStarted = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = ref.read(sessionProvider);
      if (session != null) {
        if (session.testLanguage == kLangHi) {
          setState(() {
            _isHindi = true;
          });
        } else {
          setState(() {
            _isHindi = false;
          });
        }
        if (session.questions.isNotEmpty) {
          ref.read(sessionProvider.notifier).markVisited(session.questions[0].id);
        }
      }
      // Start timer here — after the first frame has fully rendered.
      _beginExam();
    });
  }

  void _beginExam() {
    if (_examStarted) return;
    _examStarted = true;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final session = ref.read(sessionProvider);
      if (session == null) {
        timer.cancel();
        return;
      }
      if (session.timeRemaining > 0) {
        ref.read(sessionProvider.notifier).updateTimeRemaining(session.timeRemaining - 1);
      } else {
        timer.cancel();
        _submitExam();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor().toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _confirmSubmitExam() {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    int answered = 0;
    int marked = 0;
    int unanswered = 0;

    for (var q in session.questions) {
      if (session.userAnswers[q.id] != null) {
        answered++;
      } else {
        unanswered++;
      }
      if (session.markedForReview[q.id] == true) {
        marked++;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF4F46E5)),
            SizedBox(width: 10),
            Text('Submit Exam?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your test now?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Answered Questions:', '$answered', const Color(0xFF10B981)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Marked for Review:', '$marked', const Color(0xFFF59E0B)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Unanswered Questions:', '$unanswered', const Color(0xFF64748B)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue Test'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(ctx);
              _submitExam();
            },
            child: const Text('Confirm Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      ],
    );
  }

  void _submitExam() {
    final session = ref.read(sessionProvider);
    if (session == null) return;
    _timer?.cancel();

    int correct = 0;
    int wrong = 0;
    int skipped = 0;

    for (var q in session.questions) {
      final ans = session.userAnswers[q.id];
      if (ans == null) {
        skipped++;
      } else if (ans == q.correct) {
        correct++;
      } else {
        wrong++;
      }
    }

    final score = (correct * session.positiveMarks) - (wrong * session.negativeMarks);
    final maxScore = session.questions.length * session.positiveMarks;
    final accuracy = (correct + wrong) > 0 ? (correct / (correct + wrong)) * 100 : 0.0;

    final historyItem = AttemptHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      subjectId: session.subjectId,
      subjectName: session.subjectName,
      chapterId: session.chapterId,
      chapterTitle: session.chapterTitle,
      date: DateTime.now().toIso8601String(),
      score: score,
      totalQuestions: session.questions.length,
      correctCount: correct,
      wrongCount: wrong,
      skippedCount: skipped,
      maxScore: maxScore,
      accuracy: accuracy,
      timeTaken: session.totalTime - session.timeRemaining,
      isPracticeMode: session.isPracticeMode,
      userAnswers: session.userAnswers,
      questionIds: session.questions.map((q) => q.id).toList(),
    );

    ref.read(historyProvider.notifier).add(historyItem);
    context.go('/result');
  }

  void _navigateToPage(int index) {
    final session = ref.read(sessionProvider);
    if (session == null) return;

    if (index >= 0 && index < session.questions.length) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      ref.read(sessionProvider.notifier).markVisited(session.questions[index].id);
    }
  }

  void _showReportDialog(BuildContext context, dynamic question) {
    String selectedReason = 'Incorrect answer';
    final detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.amber),
              SizedBox(width: 10),
              Text('Report Question'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select reason for reporting:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Incorrect answer', child: Text('Incorrect answer')),
                  DropdownMenuItem(value: 'Question is unclear', child: Text('Question is unclear')),
                  DropdownMenuItem(value: 'Typo / Error', child: Text('Typo / Error')),
                  DropdownMenuItem(value: 'Duplicate question', child: Text('Duplicate question')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                // SEC-3: Actually submit the report via ReportService.
                final session = ref.read(sessionProvider);
                final user = ref.read(currentUserProvider);
                if (user != null && session != null) {
                  final reportService = ReportService(ref.read(supabaseProvider));
                  reportService.submitReport(
                    user.id,
                    session.subjectId,
                    session.chapterId,
                    question.id as int,
                    selectedReason,
                    detailsController.text.trim(),
                  ).catchError((e) {
                    debugPrint('Report submit failed: $e');
                  });
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you! Question report submitted.')),
                );
              },
              child: const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaletteBottomSheet(BuildContext context, ExamSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => QuestionPalette(
        session: session,
        currentIndex: _currentIndex,
        onQuestionSelected: (idx) {
          Navigator.pop(ctx);
          _navigateToPage(idx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    if (session == null) return const Scaffold(body: Center(child: Text('No active session')));

    final question = session.questions[_currentIndex];
    final isLast = _currentIndex == session.questions.length - 1;
    final isFirst = _currentIndex == 0;
    final isTimeLow = session.timeRemaining < 60;
    final isMarked = session.markedForReview[question.id] == true;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Exit Test?'),
            content: const Text('Your progress has been saved. You can resume this test later.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continue Test')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Exit Test')),
            ],
          ),
        );
        if ((exit ?? false) && context.mounted) {
          ref.read(sessionProvider.notifier).clearSession();
          context.go('/dashboard');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 12,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                session.chapterTitle,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                session.subjectName,
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            // Language Indicator Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                session.testLanguage == kLangBoth
                    ? 'English + हिन्दी'
                    : (session.testLanguage == kLangHi ? 'हिन्दी' : 'English'),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(width: 6),

            // Countdown Timer Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTimeLow ? Colors.red.withValues(alpha: 0.15) : theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isTimeLow ? Colors.red : theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: isTimeLow ? Colors.red : theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(session.timeRemaining),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isTimeLow ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // Overflow Menu Button (Secondary options)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'palette') {
                  _showPaletteBottomSheet(context, session);
                } else if (val == 'report') {
                  _showReportDialog(context, question);
                } else if (val == 'submit') {
                  _confirmSubmitExam();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'palette',
                  child: Row(
                    children: [
                      Icon(Icons.grid_view_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Question Palette'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.outlined_flag_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Report Question'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'submit',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF10B981)),
                      SizedBox(width: 10),
                      Text('Submit Test', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Sub-Header: Question Progress Pill & Palette Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Q ${_currentIndex + 1} / ${session.questions.length}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                        ),
                      ),
                      if (isMarked) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD97706)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.flag_rounded, size: 12, color: Color(0xFFD97706)),
                              SizedBox(width: 4),
                              Text('Marked', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.grid_view_rounded, size: 16),
                    label: const Text('Palette', style: TextStyle(fontSize: 12)),
                    onPressed: () => _showPaletteBottomSheet(context, session),
                  ),
                ],
              ),
            ),

            // Question Content (Scrollable PageView)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: session.questions.length,
                itemBuilder: (context, index) {
                  final q = session.questions[index];
                  String questionText;
                  List<String> options;

                  if (session.testLanguage == kLangBoth) {
                    final hasHiQuestion = q.questionHi != null && q.questionHi!.isNotEmpty;
                    questionText = hasHiQuestion ? '${q.question}\n\n---\n\n${q.questionHi!}' : q.question;
                    options = List.generate(q.options.length, (optIdx) {
                      final hasHiOpt = q.optionsHi != null && optIdx < q.optionsHi!.length && q.optionsHi![optIdx].isNotEmpty;
                      return hasHiOpt ? '${q.options[optIdx]}\n${q.optionsHi![optIdx]}' : q.options[optIdx];
                    });
                  } else {
                    questionText = _isHindi && q.questionHi != null && q.questionHi!.isNotEmpty ? q.questionHi! : q.question;
                    options = _isHindi && q.optionsHi != null ? q.optionsHi! : q.options;
                  }

                  final currentAnswer = session.userAnswers[q.id];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        MarkdownText(text: questionText),
                        const SizedBox(height: 24),
                        ...List.generate(options.length, (optIdx) {
                          final isSelected = currentAnswer == optIdx;
                          return OptionTile(
                            prefix: String.fromCharCode(65 + optIdx),
                            text: options[optIdx],
                            isSelected: isSelected,
                            onTap: () {
                              final newAnswer = isSelected ? null : optIdx;
                              ref.read(sessionProvider.notifier).updateAnswer(q.id, newAnswer);
                            },
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Sticky Bottom Comprehensive Navigation Action Area
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Compact Secondary Actions (Mark for Review & Clear Response)
                    Row(
                      children: [
                        // Mark for Review (Subtle Amber Outline)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFD97706),
                              side: const BorderSide(color: Color(0xFFD97706), width: 1.2),
                              backgroundColor: isMarked ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : null,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: Icon(isMarked ? Icons.flag_rounded : Icons.flag_outlined, size: 16),
                            label: Text(
                              isMarked ? 'Unmark Review' : 'Mark for Review',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              ref.read(sessionProvider.notifier).toggleMarkForReview(question.id);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Clear Response (Neutral / Secondary Style instead of Red)
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.onSurfaceVariant,
                              side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text(
                              'Clear Response',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: session.userAnswers[question.id] == null
                                ? null
                                : () {
                                    ref.read(sessionProvider.notifier).updateAnswer(question.id, null);
                                  },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 2: Dedicated Navigation Row (Previous 38% flex | Save & Next / Submit 62% flex)
                    Row(
                      children: [
                        // Previous (38% flex) - Single line, never wraps
                        Expanded(
                          flex: 38,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded, size: 16),
                            label: const Text(
                              'Previous',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            onPressed: isFirst ? null : () => _navigateToPage(_currentIndex - 1),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Save & Next / Submit Test (62% flex) - Primary Dominant Action
                        Expanded(
                          flex: 62,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: isLast ? const Color(0xFF10B981) : theme.colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              minimumSize: const Size(0, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                              isLast ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isLast ? 'Submit Test' : 'Save & Next',
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              if (isLast) {
                                _confirmSubmitExam();
                              } else {
                                _navigateToPage(_currentIndex + 1);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

