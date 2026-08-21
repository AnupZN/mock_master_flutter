import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/bookmark.dart';
import '../../models/question.dart';
import '../../models/subject.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../services/chapter_service.dart';
import '../../widgets/markdown_text.dart';

class BookmarkedQuestionViewerScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final int initialIndex;

  const BookmarkedQuestionViewerScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<BookmarkedQuestionViewerScreen> createState() =>
      _BookmarkedQuestionViewerScreenState();
}

class _BookmarkedQuestionViewerScreenState
    extends ConsumerState<BookmarkedQuestionViewerScreen> {
  int _currentIndex = 0;
  bool _isHindi = false;
  bool _loading = true;
  String? _error;

  // Holds resolved details: Bookmark entry, Chapter title, and Question data
  List<_ResolvedBookmarkQuestion> _resolvedQuestions = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    final bookmarks = ref.read(bookmarksProvider);
    final subjects = ref.read(subjectsProvider).value ?? [];

    final subjectBookmarks = bookmarks
        .where((b) => b.subjectId.toLowerCase() == widget.subjectId.toLowerCase())
        .toList();

    if (subjectBookmarks.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No bookmarked questions found for this subject.';
        });
      }
      return;
    }

    final subject = subjects.firstWhere(
      (s) => s.id.toLowerCase() == widget.subjectId.toLowerCase(),
      orElse: () => Subject(
        id: widget.subjectId,
        name: widget.subjectName,
        icon: '📚',
        folder: '',
        chapters: [],
      ),
    );

    final supabase = ref.read(supabaseProvider);
    final service = ChapterService(supabase);
    final List<_ResolvedBookmarkQuestion> resolvedList = [];

    // Group bookmarks by chapter to minimize network/asset loads
    final Map<String, List<Bookmark>> bookmarksByChapter = {};
    for (final b in subjectBookmarks) {
      bookmarksByChapter.putIfAbsent(b.chapterId, () => []).add(b);
    }

    for (final chapterId in bookmarksByChapter.keys) {
      final chapterBookmarks = bookmarksByChapter[chapterId]!;
      final chapter = subject.chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => Chapter(id: chapterId, title: _formatChapterTitle(chapterId)),
      );

      try {
        final chapterData = await service.loadChapter(
          subject.id,
          chapterId,
          folder: subject.folder,
          file: chapter.file,
        );

        if (chapterData != null) {
          for (final b in chapterBookmarks) {
            final q = chapterData.questions.firstWhere(
              (qItem) => qItem.id == b.questionId,
              orElse: () => Question(
                id: b.questionId,
                question: 'Question #${b.questionId}',
                options: ['Option A', 'Option B', 'Option C', 'Option D'],
                correct: 0,
                explanation: 'No detailed explanation available for this question.',
                difficulty: 'Medium',
                tags: [],
              ),
            );

            resolvedList.add(_ResolvedBookmarkQuestion(
              bookmark: b,
              chapterTitle: chapter.title,
              question: q,
            ));
          }
        }
      } catch (e) {
        debugPrint('Error loading chapter $chapterId: $e');
      }
    }

    if (mounted) {
      if (resolvedList.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Could not load question data for the bookmarked questions.';
        });
      } else {
        // Ensure index is within bounds
        final safeIndex = _currentIndex.clamp(0, resolvedList.length - 1);
        setState(() {
          _resolvedQuestions = resolvedList;
          _currentIndex = safeIndex;
          _loading = false;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(safeIndex);
        }
      }
    }
  }

  void _goTo(int index) {
    if (index >= 0 && index < _resolvedQuestions.length) {
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  static String _formatChapterTitle(String id) {
    if (id.isEmpty) return 'Chapter';
    return id.replaceAll('_', ' ').replaceAll('-', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (!_loading && _resolvedQuestions.isNotEmpty)
              Text(
                'Bookmark ${_currentIndex + 1} of ${_resolvedQuestions.length}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          // Language toggle if available
          if (!_loading && _resolvedQuestions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.translate_rounded, size: 16),
                label: Text(
                  _isHindi ? 'हिन्दी' : 'English',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () => setState(() => _isHindi = !_isHindi),
              ),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back to Bookmarks'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _resolvedQuestions.length,
                        onPageChanged: (idx) {
                          setState(() => _currentIndex = idx);
                        },
                        itemBuilder: (context, index) {
                          final resolved = _resolvedQuestions[index];
                          return _BookmarkedQuestionCard(
                            resolved: resolved,
                            subjectId: widget.subjectId,
                            index: index,
                            totalCount: _resolvedQuestions.length,
                            isHindi: _isHindi,
                            isDark: isDark,
                          );
                        },
                      ),
                    ),

                    // ── Compact Bottom Navigation Control Bar ─────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            // Previous Button
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: _currentIndex > 0
                                      ? () => _goTo(_currentIndex - 1)
                                      : null,
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: const Text('Previous',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 13)),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Question Palette Grid Button
                            SizedBox(
                              height: 40,
                              width: 44,
                              child: OutlinedButton(
                                onPressed: () => _showPaletteModal(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Icon(Icons.grid_view_rounded, size: 18),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Next / Done Button
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 40,
                                child: _currentIndex < _resolvedQuestions.length - 1
                                    ? FilledButton.icon(
                                        onPressed: () => _goTo(_currentIndex + 1),
                                        icon: const Icon(Icons.arrow_forward_rounded,
                                            size: 16),
                                        label: const Text('Next',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      )
                                    : FilledButton.icon(
                                        onPressed: () => context.pop(),
                                        icon: const Icon(Icons.check_circle_rounded,
                                            size: 16),
                                        label: const Text('Done',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13)),
                                        style: FilledButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          backgroundColor: const Color(0xFF10B981),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showPaletteModal(BuildContext context) {
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.subjectName} Bookmarks',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_resolvedQuestions.length} Questions',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _resolvedQuestions.length,
                    itemBuilder: (_, i) {
                      final isSelected = i == _currentIndex;
                      final theme = Theme.of(context);

                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _goTo(i);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.primary, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResolvedBookmarkQuestion {
  final Bookmark bookmark;
  final String chapterTitle;
  final Question question;

  _ResolvedBookmarkQuestion({
    required this.bookmark,
    required this.chapterTitle,
    required this.question,
  });
}

class _BookmarkedQuestionCard extends ConsumerWidget {
  final _ResolvedBookmarkQuestion resolved;
  final String subjectId;
  final int index;
  final int totalCount;
  final bool isHindi;
  final bool isDark;

  const _BookmarkedQuestionCard({
    required this.resolved,
    required this.subjectId,
    required this.index,
    required this.totalCount,
    required this.isHindi,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = resolved.question;
    final b = resolved.bookmark;
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any(
      (bm) =>
          bm.subjectId == b.subjectId &&
          bm.chapterId == b.chapterId &&
          bm.questionId == q.id,
    );

    final questionText = (isHindi && q.questionHi != null && q.questionHi!.isNotEmpty)
        ? q.questionHi!
        : q.question;
    final options = (isHindi && q.optionsHi != null && q.optionsHi!.isNotEmpty)
        ? q.optionsHi!
        : q.options;
    final explanationText =
        (isHindi && q.explanationHi != null && q.explanationHi!.isNotEmpty)
            ? q.explanationHi!
            : q.explanation;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subsubject / Chapter Badge & Bookmark Action ────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_outlined,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        resolved.chapterTitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q#${q.id}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isBookmarked
                      ? const Color(0xFFEAB308)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  size: 24,
                ),
                tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Question',
                onPressed: () {
                  ref.read(bookmarksProvider.notifier).toggle(
                        b.subjectId,
                        b.chapterId,
                        q.id,
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Question Card Container ────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownText(text: questionText),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Options List with Highlighted Correct Answer ───────────────
          const Text(
            'Options & Correct Answer',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          ...List.generate(options.length, (idx) {
            final isCorrectOption = idx == q.correct;
            final optionLabels = ['A', 'B', 'C', 'D', 'E'];
            final label = idx < optionLabels.length ? optionLabels[idx] : '${idx + 1}';

            final Color tileColor = isCorrectOption
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1E293B) : Colors.white);

            final Color borderColor = isCorrectOption
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: tileColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: isCorrectOption ? 1.5 : 1,
                  ),
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
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCorrectOption
                                  ? Colors.white
                                  : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: MarkdownText(text: options[idx]),
                      ),
                      if (isCorrectOption) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10B981), size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Correct',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // ── Detailed Explanation / Solution Box ────────────────────────
          if (explanationText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Explanation & Solution',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  MarkdownText(text: explanationText),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
