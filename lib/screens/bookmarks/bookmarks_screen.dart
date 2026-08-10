import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/bookmarks_provider.dart';
import '../../widgets/empty_state.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: theme.colorScheme.primary),
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
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('Generate Bookmarked Test', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () => context.push('/generator?mode=bookmark'),
                ),
              ),
            ),
          Expanded(
            child: bookmarks.isEmpty
                ? EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No bookmarks yet',
                    subtitle: 'Tap the bookmark icon on any question during chapter practice to save it here.',
                    buttonText: 'Browse Subjects',
                    onAction: () => context.go('/subjects'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: bookmarks.length,
                    itemBuilder: (context, index) {
                      final b = bookmarks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                            child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          ),
                          title: Text(
                            'Question ID #${b.questionId}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            'Subject: ${b.subjectId.toUpperCase()} • Chapter: ${b.chapterId}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.bookmark_remove_rounded, color: Colors.redAccent),
                            tooltip: 'Remove Bookmark',
                            onPressed: () {
                              ref.read(bookmarksProvider.notifier).toggle(b.subjectId, b.chapterId, b.questionId);
                            },
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
}
