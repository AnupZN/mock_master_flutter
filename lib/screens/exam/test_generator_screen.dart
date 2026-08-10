import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/supabase_client.dart';
import '../../models/exam_session.dart';
import '../../providers/bookmarks_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/subjects_provider.dart';
import '../../services/chapter_service.dart';
import '../../services/test_generator_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_widget.dart';

class TestGeneratorScreen extends ConsumerStatefulWidget {
  final String? initialMode; // 'bookmark' or 'custom'
  const TestGeneratorScreen({super.key, this.initialMode});

  @override
  ConsumerState<TestGeneratorScreen> createState() => _TestGeneratorScreenState();
}

class _TestGeneratorScreenState extends ConsumerState<TestGeneratorScreen> {
  late bool _isBookmarkMode;
  final Set<String> _selectedSubjectIds = {'all'};
  int _requestedQuestionCount = 25;
  int _durationMinutes = 20;
  bool _isCustomDuration = false;
  final TextEditingController _customDurationController = TextEditingController();

  int? _availableCount;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _isBookmarkMode = widget.initialMode == 'bookmark';
    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateAvailableQuestions());
  }

  @override
  void dispose() {
    _customDurationController.dispose();
    super.dispose();
  }

  Future<void> _calculateAvailableQuestions() async {
    final subjectsState = ref.read(subjectsProvider);
    if (!subjectsState.hasValue) return;

    setState(() => _isCalculating = true);

    final generatorService = TestGeneratorService(ChapterService(supabase));
    final subjects = subjectsState.value!;
    final bookmarks = ref.read(bookmarksProvider);

    int count = 0;
    if (_isBookmarkMode) {
      count = await generatorService.countAvailableBookmarkedQuestions(
        allSubjects: subjects,
        selectedSubjectIds: _selectedSubjectIds.toList(),
        bookmarks: bookmarks,
      );
    } else {
      count = await generatorService.countAvailableCustomQuestions(
        allSubjects: subjects,
        selectedSubjectIds: _selectedSubjectIds.toList(),
      );
    }

    if (mounted) {
      setState(() {
        _availableCount = count;
        _isCalculating = false;
      });
    }
  }

  void _onSubjectTapped(String subjectId) {
    setState(() {
      if (subjectId == 'all') {
        _selectedSubjectIds.clear();
        _selectedSubjectIds.add('all');
      } else {
        _selectedSubjectIds.remove('all');
        if (_selectedSubjectIds.contains(subjectId)) {
          _selectedSubjectIds.remove(subjectId);
          if (_selectedSubjectIds.isEmpty) {
            _selectedSubjectIds.add('all');
          }
        } else {
          _selectedSubjectIds.add(subjectId);
        }
      }
    });
    _calculateAvailableQuestions();
  }

  void _showTestPreviewModal(GeneratedTestResult testResult) {
    final theme = Theme.of(context);
    final subjectNamesText = testResult.selectedSubjectNames.join(', ');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
                _isBookmarkMode ? Icons.bookmark_rounded : Icons.quiz_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(testResult.testType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subjectNamesText, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
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
            if (testResult.capWarningMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        testResult.capWarningMessage!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModalStat(Icons.help_outline_rounded, '${testResult.actualQuestionCount}', 'Questions'),
                _buildModalStat(Icons.timer_outlined, '${testResult.durationMinutes} Mins', 'Duration'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildModalDetailRow('Requested Questions:', '${testResult.requestedQuestionCount}'),
                  const SizedBox(height: 6),
                  _buildModalDetailRow('Actual Questions:', '${testResult.actualQuestionCount}'),
                  const SizedBox(height: 6),
                  _buildModalDetailRow('Marking Scheme:', '+1.0 Correct / -0.33 Wrong'),
                  const SizedBox(height: 6),
                  _buildModalDetailRow('Languages Available:', 'English + हिन्दी'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start Test', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              _launchExamSession(testResult);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModalStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildModalDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _generateAndPreviewTest() async {
    final subjectsState = ref.read(subjectsProvider);
    if (!subjectsState.hasValue) return;

    final generatorService = TestGeneratorService(ChapterService(supabase));
    final subjects = subjectsState.value!;
    final bookmarks = ref.read(bookmarksProvider);

    int duration = _durationMinutes;
    if (_isCustomDuration) {
      final parsed = int.tryParse(_customDurationController.text);
      if (parsed != null && parsed > 0) {
        duration = parsed;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid custom duration in minutes.')),
        );
        return;
      }
    }

    GeneratedTestResult result;
    if (_isBookmarkMode) {
      result = await generatorService.generateBookmarkedTest(
        allSubjects: subjects,
        selectedSubjectIds: _selectedSubjectIds.toList(),
        bookmarks: bookmarks,
        requestedCount: _requestedQuestionCount,
        durationMinutes: duration,
      );
    } else {
      result = await generatorService.generateCustomTest(
        allSubjects: subjects,
        selectedSubjectIds: _selectedSubjectIds.toList(),
        requestedCount: _requestedQuestionCount,
        durationMinutes: duration,
      );
    }

    if (result.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isBookmarkMode ? 'No bookmarked questions found for selected subjects.' : 'No questions available.')),
      );
      return;
    }

    if (mounted) {
      _showTestPreviewModal(result);
    }
  }

  void _launchExamSession(GeneratedTestResult result) {
    final session = ExamSession(
      subjectId: 'generated_test',
      chapterId: result.testType.toLowerCase().replaceAll(' ', '_'),
      subjectName: result.selectedSubjectNames.join(', '),
      chapterTitle: result.testType,
      questions: result.questions,
      userAnswers: {},
      markedForReview: {},
      visitedQuestions: {},
      timeRemaining: result.durationMinutes * 60,
      totalTime: result.durationMinutes * 60,
      isPracticeMode: true,
      practiceType: result.testType,
      positiveMarks: 1.0,
      negativeMarks: 0.33,
    );

    ref.read(sessionProvider.notifier).startSession(session);
    context.go('/exam');
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Generator'),
        centerTitle: true,
      ),
      body: subjectsState.when(
        loading: () => const LoadingWidget(message: 'Loading catalog metadata...'),
        error: (err, stack) => Center(
          child: EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load test setup',
            subtitle: '$err',
          ),
        ),
        data: (subjects) {
          final actualCount = _availableCount ?? 0;
          final isCapApplied = actualCount < _requestedQuestionCount && actualCount > 0;
          final isZeroAvailable = actualCount == 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Toggle Segmented Control
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isBookmarkMode = true);
                            _calculateAvailableQuestions();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isBookmarkMode ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 18,
                                  color: _isBookmarkMode ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bookmarked Test',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: _isBookmarkMode ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isBookmarkMode = false);
                            _calculateAvailableQuestions();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isBookmarkMode ? theme.colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shuffle_rounded,
                                  size: 18,
                                  color: !_isBookmarkMode ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Custom/Mixed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: !_isBookmarkMode ? Colors.white : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 1. Select Subject(s)
                Text(
                  '1. Select Subject(s)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('All Subjects'),
                      selected: _selectedSubjectIds.contains('all'),
                      onSelected: (_) => _onSubjectTapped('all'),
                    ),
                    ...subjects.map((sub) {
                      final isSelected = _selectedSubjectIds.contains(sub.id);
                      return FilterChip(
                        label: Text(sub.name),
                        selected: isSelected,
                        onSelected: (_) => _onSubjectTapped(sub.id),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. Select Question Count (25 or 50)
                Text(
                  '2. Number of Questions (Max Requested)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [25, 50].map((count) {
                    final isSelected = _requestedQuestionCount == count;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ChoiceChip(
                        label: Text('$count Questions', style: const TextStyle(fontWeight: FontWeight.bold)),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _requestedQuestionCount = count);
                          _calculateAvailableQuestions();
                        },
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // 3. Select Duration
                Text(
                  '3. Test Duration (Minutes)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...[10, 15, 20, 25, 30].map((mins) {
                      final isSelected = !_isCustomDuration && _durationMinutes == mins;
                      return ChoiceChip(
                        label: Text('$mins Mins'),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _isCustomDuration = false;
                            _durationMinutes = mins;
                          });
                        },
                      );
                    }),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _isCustomDuration,
                      onSelected: (_) {
                        setState(() => _isCustomDuration = true);
                      },
                    ),
                  ],
                ),

                if (_isCustomDuration) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _customDurationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Duration in minutes',
                        hintText: 'e.g. 45',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Live Availability & Capping Notice Banner
                Card(
                  elevation: 0,
                  color: isZeroAvailable
                      ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2))
                      : isCapApplied
                          ? (isDark ? const Color(0xFF3F2D1C) : const Color(0xFFFFFBEB))
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isZeroAvailable
                          ? Colors.red
                          : isCapApplied
                              ? Colors.amber
                              : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _isCalculating
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(
                                isZeroAvailable
                                    ? Icons.error_outline_rounded
                                    : isCapApplied
                                        ? Icons.info_outline_rounded
                                        : Icons.check_circle_outline_rounded,
                                color: isZeroAvailable
                                    ? Colors.red
                                    : isCapApplied
                                        ? Colors.amber
                                        : const Color(0xFF10B981),
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isCalculating
                                    ? 'Calculating available questions...'
                                    : isZeroAvailable
                                        ? (_isBookmarkMode ? 'No bookmarked questions available' : 'No questions found')
                                        : isCapApplied
                                            ? '$actualCount questions available'
                                            : '$actualCount questions ready',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isZeroAvailable ? Colors.red : (isCapApplied ? Colors.amber.shade900 : null),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isZeroAvailable
                                    ? (_isBookmarkMode
                                        ? 'Bookmark questions during chapter practice to generate a bookmarked test.'
                                        : 'Select a different subject combination.')
                                    : isCapApplied
                                        ? '${_isBookmarkMode ? "Bookmarked" : "Total"} questions available ($actualCount) is less than requested ($_requestedQuestionCount). This test will automatically contain $actualCount questions.'
                                        : 'Test will contain $_requestedQuestionCount questions.',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Main CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.preview_rounded),
                    label: const Text('Configure & Preview Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: isZeroAvailable || _isCalculating ? null : () => _generateAndPreviewTest(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
