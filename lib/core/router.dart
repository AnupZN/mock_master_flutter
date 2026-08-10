import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/subjects/subjects_screen.dart';
import '../screens/chapters/chapters_screen.dart';
import '../screens/exam/exam_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/review/review_screen.dart';
import '../screens/bookmarks/bookmarks_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/exam/test_generator_screen.dart';
import '../screens/history/attempt_history_screen.dart';
import '../screens/history/attempt_review_screen.dart';
import '../models/attempt_history.dart';
import '../app.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = authState.value?.session != null;
      final isLoggingIn = state.uri.toString() == '/login';

      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/subjects',
            builder: (context, state) => const SubjectsScreen(),
            routes: [
              GoRoute(
                path: ':id/chapters',
                builder: (context, state) => ChaptersScreen(subjectId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/bookmarks',
            builder: (context, state) => const BookmarksScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/exam',
        builder: (context, state) => const ExamScreen(),
      ),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '/generator',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'];
          return TestGeneratorScreen(initialMode: mode);
        },
      ),
      // ── Chapter attempt history ──────────────────────────────────────────
      GoRoute(
        path: '/history/attempts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AttemptHistoryScreen(
            subjectId: extra['subjectId'] as String,
            chapterId: extra['chapterId'] as String,
            chapterTitle: extra['chapterTitle'] as String,
            subjectName: extra['subjectName'] as String,
          );
        },
      ),
      // ── Individual attempt review ────────────────────────────────────────
      GoRoute(
        path: '/history/review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AttemptReviewScreen(
            attempt: extra['attempt'] as AttemptHistoryItem,
            attemptNumber: extra['attemptNumber'] as int,
          );
        },
      ),
    ],
  );
});
