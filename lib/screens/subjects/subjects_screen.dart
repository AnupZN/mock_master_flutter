import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/subjects_provider.dart';
import '../../models/subject.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getSubjectGradientColor(String subjectId, bool isDark) {
    final lower = subjectId.toLowerCase();
    if (lower.contains('history')) {
      return isDark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);
    } else if (lower.contains('polity')) {
      return isDark ? const Color(0xFF10B981) : const Color(0xFF059669);
    } else if (lower.contains('geography')) {
      return isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
    }
    return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Explore Subjects'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Index',
            onPressed: () => ref.invalidate(subjectsProvider),
          ),
        ],
      ),
      body: subjectsState.when(
        loading: () => const LoadingWidget(message: 'Loading subject catalog...'),
        error: (err, stack) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load catalog',
            subtitle: '$err',
            actionLabel: 'Try Again',
            onAction: () => ref.invalidate(subjectsProvider),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No subjects available',
              subtitle: 'Pull down to refresh or check your backend connection.',
              actionLabel: 'Refresh',
              onAction: () => ref.invalidate(subjectsProvider),
            );
          }

          final filteredSubjects = subjects.where((s) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            final nameMatch = s.name.toLowerCase().contains(query);
            final chapterMatch = s.chapters.any((c) => c.title.toLowerCase().contains(query));
            final subMatch = (s.subSubjects ?? []).any((sub) => sub.name.toLowerCase().contains(query));
            return nameMatch || chapterMatch || subMatch;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search subjects or chapters...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredSubjects.isEmpty
                    ? EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No matching subjects',
                        subtitle: 'No subjects or chapters match "$_searchQuery".',
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(subjectsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = filteredSubjects[index];
                            return _buildSubjectCard(context, subject, isDark);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, Subject subject, bool isDark) {
    final primaryColor = _getSubjectGradientColor(subject.id, isDark);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.go('/subjects/${subject.id}/chapters'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.15),
                primaryColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    subject.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

