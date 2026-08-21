import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/bookmark.dart';
import '../../models/question.dart';
import '../../models/subject.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../services/chapter_service.dart';
import '../../widgets/markdown_text.dart';

// ─── Data class ─────────────────────────────────────────────────────────────

class _ResolvedItem {
  final Bookmark bookmark;
  final String chapterTitle;
  final Question question;

  _ResolvedItem({
    required this.bookmark,
    required this.chapterTitle,
    required this.question,
  });
}

// ─── Screen ─────────────────────────────────────────────────────────────────

class BookmarkSubjectScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;

  const BookmarkSubjectScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  ConsumerState<BookmarkSubjectScreen> createState() =>
      _BookmarkSubjectScreenState();
}

class _BookmarkSubjectScreenState
    extends ConsumerState<BookmarkSubjectScreen> {
  bool _loading = true;
  String? _error;
  List<_ResolvedItem> _items = [];
  bool _isHindi = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final bookmarks = ref.read(bookmarksProvider);
    final subjects = ref.read(subjectsProvider).value ?? [];

    final subjectBookmarks = bookmarks
        .where((b) =>
            b.subjectId.toLowerCase() == widget.subjectId.toLowerCase())
        .toList();

    if (subjectBookmarks.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final subject = subjects.firstWhere(
      (s) => s.id.toLowerCase() == widget.subjectId.toLowerCase(),
      orElse: () => Subject(
        id: widget.subjectId,
        name: widget.subjectName,
        icon: '',
        folder: '',
        chapters: [],
      ),
    );

    final supabase = ref.read(supabaseProvider);
    final service = ChapterService(supabase);

    // Group by chapter to minimize data loads
    final Map<String, List<Bookmark>> byChapter = {};
    for (final b in subjectBookmarks) {
      byChapter.putIfAbsent(b.chapterId, () => []).add(b);
    }

    final List<_ResolvedItem> resolved = [];

    for (final chapterId in byChapter.keys) {
      final chapterBookmarks = byChapter[chapterId]!;
      final chapter = subject.chapters.firstWhere(
        (c) => c.id == chapterId,
        orElse: () => Chapter(
          id: chapterId,
          title: _formatChapterId(chapterId),
        ),
      );

      try {
        final data = await service.loadChapter(
          subject.id,
          chapterId,
          folder: subject.folder,
          file: chapter.file,
        );

        for (final b in chapterBookmarks) {
          if (data != null) {
            final q = data.questions.firstWhere(
              (qItem) => qItem.id == b.questionId,
              orElse: () => _placeholderQuestion(b.questionId),
            );
            resolved.add(_ResolvedItem(
              bookmark: b,
              chapterTitle: chapter.title,
              question: q,
            ));
          } else {
            resolved.add(_ResolvedItem(
              bookmark: b,
              chapterTitle: chapter.title,
              question: _placeholderQuestion(b.questionId),
            ));
          }
        }
      } catch (e) {
        debugPrint('BookmarkSubjectScreen: error loading chapter $chapterId: $e');
        for (final b in chapterBookmarks) {
          resolved.add(_ResolvedItem(
            bookmark: b,
            chapterTitle: chapter.title,
            question: _placeholderQuestion(b.questionId),
          ));
        }
      }
    }

    if (mounted) {
      setState(() {
        _items = resolved;
        _loading = false;
      });
    }
  }

  static Question _placeholderQuestion(int id) => Question(
        id: id,
        question: 'Question #$id — data unavailable offline.',
        options: [],
        correct: 0,
        explanation: '',
        difficulty: '',
        tags: [],
      );

  static String _formatChapterId(String id) =>
      id.replaceAll('_', ' ').replaceAll('-', ' ');

  bool _anyHindi() => _items.any(
      (it) => it.question.questionHi != null && it.question.questionHi!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // Watch so bookmark toggles rebuild the list
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (!_loading && _items.isNotEmpty)
              Text(
                '${_items.length} bookmarked question${_items.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (!_loading && _anyHindi())
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
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14)),
                  ),
                )
              : _items.isEmpty
                  ? const Center(
                      child: Text(
                        'No bookmarks found for this subject.',
                        style: TextStyle(fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final q = item.question;
                        final b = item.bookmark;

                        final isBookmarked = bookmarks.any(
                          (bm) =>
                              bm.subjectId == b.subjectId &&
                              bm.chapterId == b.chapterId &&
                              bm.questionId == q.id,
                        );

                        final questionText =
                            (_isHindi && q.questionHi != null && q.questionHi!.isNotEmpty)
                                ? q.questionHi!
                                : q.question;

                        final options =
                            (_isHindi && q.optionsHi != null && q.optionsHi!.isNotEmpty)
                                ? q.optionsHi!
                                : q.options;

                        final explanationText =
                            (_isHindi && q.explanationHi != null && q.explanationHi!.isNotEmpty)
                                ? q.explanationHi!
                                : q.explanation;

                        return _QuestionCard(
                          key: ValueKey('${b.subjectId}_${b.chapterId}_${q.id}'),
                          index: index,
                          total: _items.length,
                          chapterTitle: item.chapterTitle,
                          questionText: questionText,
                          options: options,
                          correctIndex: q.correct,
                          explanationText: explanationText,
                          questionId: q.id,
                          isBookmarked: isBookmarked,
                          isDark: isDark,
                          onToggleBookmark: () {
                            ref.read(bookmarksProvider.notifier).toggle(
                                  b.subjectId,
                                  b.chapterId,
                                  q.id,
                                );
                          },
                        );
                      },
                    ),
    );
  }
}

// ─── Question Card ───────────────────────────────────────────────────────────

class _QuestionCard extends StatefulWidget {
  final int index;
  final int total;
  final String chapterTitle;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String explanationText;
  final int questionId;
  final bool isBookmarked;
  final bool isDark;
  final VoidCallback onToggleBookmark;

  const _QuestionCard({
    super.key,
    required this.index,
    required this.total,
    required this.chapterTitle,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanationText,
    required this.questionId,
    required this.isBookmarked,
    required this.isDark,
    required this.onToggleBookmark,
  });

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: chapter badge + Q# + bookmark ────────────────
            Row(
              children: [
                // Chapter badge
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.chapterTitle,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Q# badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q#${widget.questionId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
                const Spacer(),
                // Bookmark toggle
                GestureDetector(
                  onTap: widget.onToggleBookmark,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      widget.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      size: 22,
                      color: widget.isBookmarked
                          ? const Color(0xFFEAB308)
                          : (isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Question text ─────────────────────────────────────────────
            MarkdownText(text: widget.questionText),

            const SizedBox(height: 12),

            // ── Options ───────────────────────────────────────────────────
            if (widget.options.isNotEmpty) ...[
              ...List.generate(widget.options.length, (idx) {
                final isCorrect = idx == widget.correctIndex;
                final optLabels = ['A', 'B', 'C', 'D', 'E'];
                final label =
                    idx < optLabels.length ? optLabels[idx] : '${idx + 1}';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCorrect
                            ? const Color(0xFF10B981)
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                        width: isCorrect ? 1.5 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Option letter circle
                          Container(
                            width: 22,
                            height: 22,
                            margin: const EdgeInsets.only(right: 10, top: 1),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: MarkdownText(text: widget.options[idx]),
                          ),
                          if (isCorrect) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF10B981), size: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],

            // ── Explanation toggle ────────────────────────────────────────
            if (widget.explanationText.isNotEmpty) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showExplanation = !_showExplanation),
                child: Row(
                  children: [
                    Icon(
                      _showExplanation
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showExplanation ? 'Hide Explanation' : 'Show Explanation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showExplanation) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lightbulb_rounded,
                              size: 15, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Explanation',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      MarkdownText(text: widget.explanationText),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
