import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/subjects_provider.dart';
import '../../services/chapter_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/history_provider.dart';
import '../../models/exam_session.dart';
import '../../models/chapter_data.dart';
import '../../models/subject.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/chapter_action_buttons.dart';

class ChaptersScreen extends ConsumerStatefulWidget {
  final String subjectId;
  const ChaptersScreen({super.key, required this.subjectId});

  @override
  ConsumerState<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends ConsumerState<ChaptersScreen> {
  String? _selectedSubSubjectId;

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return subjectsState.when(
      loading: () => const Scaffold(body: LoadingWidget(message: 'Loading chapters...')),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: const Text('Chapters')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (subjects) {
        final subject = subjects.firstWhere(
          (s) => s.id == widget.subjectId,
          orElse: () => Subject(id: widget.subjectId, name: 'Subject', icon: '📚', folder: 'History', chapters: [], subSubjects: []),
        );

        final filteredChapters = _selectedSubSubjectId == null
            ? subject.chapters
            : subject.chapters.where((c) => c.subSubjectId == _selectedSubSubjectId).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subject.name),
                Text(
                  '${subject.chapters.length} Chapters total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Sub-subject filter tabs if available
              if (subject.subSubjects?.isNotEmpty == true) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Topics'),
                        selected: _selectedSubSubjectId == null,
                        onSelected: (_) => setState(() => _selectedSubSubjectId = null),
                      ),
                      const SizedBox(width: 8),
                      ...(subject.subSubjects ?? []).map((sub) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(sub.name),
                            selected: _selectedSubSubjectId == sub.id,
                            onSelected: (_) => setState(() => _selectedSubSubjectId = sub.id),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

              // Chapter list
              Expanded(
                child: filteredChapters.isEmpty
                    ? const EmptyState(
                        icon: Icons.menu_book_rounded,
                        title: 'No chapters found',
                        subtitle: 'No chapters match the selected topic filter.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = filteredChapters[index];
                          final subSubjectName = (subject.subSubjects ?? [])
                              .firstWhere((s) => s.id == chapter.subSubjectId, orElse: () => SubSubject(id: '', name: 'General'))
                              .name;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              chapter.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              subSubjectName,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Builder(builder: (context) {
                                    final history = ref.watch(historyProvider);
                                    final chapterAttempts = history
                                        .where((h) =>
                                            h.chapterId == chapter.id &&
                                            h.subjectId == subject.id)
                                        .length;
                                    return ChapterActionButtons(
                                      attemptCount: chapterAttempts,
                                      onAttemptsPressed: () => context.push(
                                        '/history/attempts',
                                        extra: {
                                          'subjectId': subject.id,
                                          'chapterId': chapter.id,
                                          'chapterTitle': chapter.title,
                                          'subjectName': subject.name,
                                        },
                                      ),
                                      onStartExamPressed: () => _startExam(
                                          subject, chapter,
                                          isPractice: false),
                                    );
                                  }),
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
      },
    );
  }

  Future<void> _startExam(Subject subject, Chapter chapter, {required bool isPractice}) async {
    final chapterService = ChapterService(ref.read(supabaseProvider));
    final data = await chapterService.loadChapter(
      subject.id,
      chapter.id,
      folder: subject.folder,
      file: chapter.file,
    );

    if (data != null && mounted) {
      await _showExamOverviewModal(subject, chapter, data, isPractice);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load chapter questions. Please check connection.')),
      );
    }
  }

  Future<void> _showExamOverviewModal(
    Subject subject,
    Chapter chapter,
    ChapterData data,
    bool isPractice,
  ) async {
    final totalTimeMins = ((data.questions.length * data.timePerQuestion) / 60).round();
    final theme = Theme.of(context);

    // ── Bilingual detection — content-based, not name-based ──────────────
    // A chapter is bilingual only if at least one question actually has
    // Hindi text populated. This correctly handles future subjects too.
    final isBilingual = data.questions.any(
      (q) => q.questionHi != null && q.questionHi!.isNotEmpty,
    );

    // ── Load last-used language for bilingual subjects ────────────────────
    const prefKey = 'lastTestLanguage';
    String selectedLang = kLangEn;
    if (isBilingual) {
      final prefs = await SharedPreferences.getInstance();
      selectedLang = prefs.getString(prefKey) ?? kLangEn;
    }

    if (!mounted) return;

    // ── Show dialog with StatefulBuilder so the picker re-renders ─────────
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPractice ? Icons.menu_book_rounded : Icons.timer_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        subject.name,
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),

                // ── Question count + duration row ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildOverviewStat(
                      Icons.quiz_outlined,
                      '${data.questions.length}',
                      'Questions',
                    ),
                    _buildOverviewStat(
                      Icons.hourglass_bottom_rounded,
                      isPractice ? 'Untimed' : '$totalTimeMins Mins',
                      'Duration',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Marking scheme + language info ───────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Marking Scheme:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            '+${data.positiveMarks} / -${data.negativeMarks}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Content:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text(
                            isBilingual ? 'English + हिन्दी' : 'English only',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isBilingual ? Colors.indigo : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Language selector ────────────────────────────────────
                const SizedBox(height: 16),
                if (isBilingual) ...[
                  Row(
                    children: [
                      Icon(Icons.translate_rounded,
                          size: 15, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Test Language',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Radio-style language tiles
                  ...[
                    (kLangEn, 'English', 'Questions in English'),
                    (kLangHi, 'हिन्दी', 'Questions in Hindi'),
                    (kLangBoth, 'English + हिन्दी',
                        'Both languages shown together'),
                  ].map((opt) {
                    final (val, label, desc) = opt;
                    final isChosen = selectedLang == val;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedLang = val),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isChosen
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isChosen ? 1.5 : 1,
                          ),
                          color: isChosen
                              ? theme.colorScheme.primary
                                  .withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isChosen
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 18,
                              color: isChosen
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isChosen
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isChosen
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  desc,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  // English-only notice
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'English only — no Hindi content available',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(isPractice ? 'Start Practice' : 'Start Test'),
                onPressed: () => Navigator.pop(ctx, selectedLang),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !mounted) return;

    // Persist the language choice for next time (only for bilingual subjects)
    if (isBilingual) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastTestLanguage', result);
    }

    final session = ExamSession(
      subjectId: subject.id,
      chapterId: chapter.id,
      subjectName: subject.name,
      chapterTitle: chapter.title,
      questions: data.questions,
      userAnswers: {},
      markedForReview: {},
      visitedQuestions: {},
      timeRemaining: data.questions.length * data.timePerQuestion,
      totalTime: data.questions.length * data.timePerQuestion,
      isPracticeMode: isPractice,
      positiveMarks: data.positiveMarks,
      negativeMarks: data.negativeMarks,
      testLanguage: result,
    );
    ref.read(sessionProvider.notifier).startSession(session);
    if (!mounted) return;
    context.go('/exam');
  }

  Widget _buildOverviewStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

