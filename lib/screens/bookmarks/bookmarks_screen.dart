import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../models/subject.dart';
import '../../models/bookmark.dart';
import '../../widgets/empty_state.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Subject> subjects = subjectsState.value ?? [];

    // Group bookmarks by subjectId — preserves subject order from manifest
    final Map<String, List<Bookmark>> bookmarksBySubject = {};
    for (final b in bookmarks) {
      bookmarksBySubject.putIfAbsent(b.subjectId, () => []).add(b);
    }

    // Build ordered subject list: known subjects first (in manifest order), then unknowns
    final List<MapEntry<Subject, List<Bookmark>>> orderedEntries = [];
    for (final subject in subjects) {
      if (bookmarksBySubject.containsKey(subject.id)) {
        orderedEntries.add(MapEntry(subject, bookmarksBySubject[subject.id]!));
      }
    }
    for (final subjectId in bookmarksBySubject.keys) {
      final alreadyAdded = orderedEntries.any((e) => e.key.id == subjectId);
      if (!alreadyAdded) {
        final fallback = Subject(
          id: subjectId,
          name: _formatSubjectName(subjectId),
          icon: '',
          folder: '',
          chapters: [],
        );
        orderedEntries.add(MapEntry(fallback, bookmarksBySubject[subjectId]!));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarked Questions'),
        actions: [
          if (bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${bookmarks.length} Saved',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (bookmarks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: const Text(
                    'Generate Bookmarked Test',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => context.push('/generator?mode=bookmark'),
                ),
              ),
            ),
          Expanded(
            child: bookmarks.isEmpty
                ? EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No bookmarks yet',
                    subtitle:
                        'Tap the bookmark icon on any question to save it here for later review.',
                    buttonText: 'Browse Subjects',
                    onAction: () => context.go('/subjects'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: orderedEntries.length,
                    itemBuilder: (context, index) {
                      final subject = orderedEntries[index].key;
                      final subjectBookmarks = orderedEntries[index].value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.push(
                              '/bookmarks/subject',
                              extra: {
                                'subjectId': subject.id,
                                'subjectName': subject.name,
                              },
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                // Subject icon badge
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      subject.icon.isNotEmpty
                                          ? subject.icon
                                          : '📚',
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Subject name + count
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        subject.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.bookmark_rounded,
                                            size: 13,
                                            color:
                                                theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${subjectBookmarks.length} question${subjectBookmarks.length == 1 ? '' : 's'} saved',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Chevron
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
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

  static String _formatSubjectName(String id) {
    if (id.isEmpty) return 'Subject';
    return id[0].toUpperCase() + id.substring(1).replaceAll('_', ' ');
  }
}
