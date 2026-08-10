# 📱 Mock Master Flutter Android — Development Roadmap

> **Last Updated:** 2026-08-10
> **Status:** 🟢 All Core Phases Complete — APK Build In Progress / Complete
> **Purpose:** Single source of truth for the Mock Master Flutter Android application migration from the React/Vite web project.

---

## Table of Contents

1. Existing Web Application Architecture
2. Database & Supabase Schema
3. Feature Inventory & Conversion Matrix
4. Planned & Implemented Flutter Architecture
5. Supabase Integration & Security
6. Implementation Phases & Completion Status
7. Credentials & Environment Configuration
8. Known Issues & Architectural Decisions
9. Current Status & Next Steps
10. Git History Summary

---

## 1. Existing Web Application Architecture

### Stack
- **Framework:** React 18 + TypeScript (Vite build tool)
- **Styling:** Tailwind CSS v3 + custom theme system (src/utils/theme.ts)
- **Hosting:** Vercel (static SPA deployment)
- **Backend:** Supabase (PostgreSQL + Auth + RLS)

### Architecture Highlights
- `App.tsx` monolithic state machine managing 9 sub-views
- `supabase.ts` handling all CRUD queries to PostgreSQL
- Dual persistence: IndexedDB (chapters) + SharedPreferences / LocalStorage (user progress)

---

## 2. Database & Supabase Schema

### Tables & Access Control (RLS)

| Table | Access | Storage Purpose |
|---|---|---|
| `users` | RLS (`auth.uid()`) | User settings, profile metadata, admin flag |
| `history` | RLS (`auth.uid()`) | Attempt history per exam session (JSONB answers & stats) |
| `bookmarks` | RLS (`auth.uid()`) | Bookmarked questions per user |
| `wrong_questions` | RLS (`auth.uid()`) | Wrongly answered questions per user |
| `custom_questions` | RLS (`auth.uid()`) | User question overrides |
| `admin_manifest` | Public Read / Admin Write | Master list of subjects, sub-subjects & chapters |
| `admin_chapters_data` | Public Read / Admin Write | Full chapter questions dataset |
| `srs_cards` | RLS (`auth.uid()`) | Spaced Repetition cards (SM-2 algorithm data) |
| `question_reports` | RLS (`auth.uid()`) | User question reports |
| `leaderboard` | Public Read / User Write | Global rankings & streaks |

---

## 3. Feature Inventory & Conversion Matrix

| Feature | React Web App | Flutter Android | Status |
|---|---|---|---|
| Authentication | Supabase Auth (email/password) | `AuthService` + `authProvider` + `LoginScreen` | ✅ Complete |
| Subject Browser | `SubjectsView.tsx` | `SubjectsScreen` + `subjectsProvider` | ✅ Complete |
| Chapter Browser | `ChaptersView.tsx` | `ChaptersScreen` (with attempt & bookmark stats) | ✅ Complete |
| Exam Engine | `ExamView.tsx` | `ExamScreen` (Timer, PopScope, PageView) | ✅ Complete |
| Question Palette | Overlay drawer | `QuestionPalette` widget (colored grid) | ✅ Complete |
| Bilingual Engine | EN/HI Toggle | Dynamic `questionHi`/`optionsHi` switcher | ✅ Complete |
| Markdown Text | custom Markdown renderer | `flutter_markdown` widget (`MarkdownText`) | ✅ Complete |
| Scoring Engine | Positive/Negative marks formula | Exact mathematical match in `ExamScreen` | ✅ Complete |
| Result Screen | `ResultView.tsx` | `ResultScreen` (Ring score, chips, analytics) | ✅ Complete |
| Question Review | `ReviewView.tsx` | `ReviewScreen` (Explanations, correct/wrong tags) | ✅ Complete |
| Bookmarks Manager | `BookmarksView.tsx` | `BookmarksScreen` + `bookmarksProvider` | ✅ Complete |
| Dashboard | `DashboardView.tsx` | `DashboardScreen` (Progress bar, recent activity) | ✅ Complete |
| Settings | `SettingsView.tsx` | `SettingsScreen` (Dark mode, daily target, signout) | ✅ Complete |
| Leaderboard | `LeaderboardView.tsx` | `LeaderboardScreen` + `leaderboardProvider` | ✅ Complete |
| Navigation Shell | Monolithic `currentView` | `GoRouter` + `ShellRoute` (`AppShell` bottom nav) | ✅ Complete |

---

## 4. Planned & Implemented Flutter Architecture

### Location
`/home/reed/Coding/Mock-Master-V0/mock_master_flutter/`

### Tech Stack
- **Flutter:** 3.44.9 (Stable Channel)
- **Dart:** 3.12.2
- **State Management:** Riverpod (`flutter_riverpod` 2.6.1)
- **Navigation:** `go_router` 14.8.1
- **Backend:** `supabase_flutter` 2.8.4
- **Markdown:** `flutter_markdown` 0.7.7
- **Persistence:** `shared_preferences` + `flutter_secure_storage` + `flutter_dotenv`

### Codebase Organization (48 Dart Files)
```
mock_master_flutter/
  lib/
    main.dart                    # App entry point, DotEnv & Supabase init
    app.dart                     # AppShell with bottom navigation & sync listener
    core/
      app_theme.dart             # Material 3 light/dark ThemeData
      constants.dart             # StorageKeys & DefaultSettings
      router.dart                # GoRouter configuration with auth guards
      supabase_client.dart       # Supabase initialization & getter
    models/
      app_settings.dart          # AppSettings model
      attempt_history.dart       # AttemptHistoryItem model
      bookmark.dart              # Bookmark model
      chapter_data.dart          # ChapterData model
      exam_session.dart          # ExamSession model
      question.dart              # Question & QuestionTable models
      srs_card.dart              # SRSCard & SM-2 algorithm helpers
      subject.dart               # Subject, Chapter & SubSubject models
    services/
      auth_service.dart          # Supabase auth wrapper
      bookmark_service.dart      # Bookmarks CRUD & Supabase sync
      chapter_service.dart       # Chapter loading & SharedPreferences caching
      history_service.dart       # Attempt history CRUD
      leaderboard_service.dart   # Leaderboard queries & score updates
      manifest_service.dart      # Manifest index fetch & fallback logic
      report_service.dart        # Question report submissions
      settings_service.dart      # Settings persistence & Supabase user sync
      wrong_service.dart         # Wrong questions CRUD
    providers/
      auth_provider.dart         # Auth state stream & user provider
      bookmarks_provider.dart    # Bookmarks notifier & state
      history_provider.dart      # History notifier & state
      session_provider.dart      # Active exam session notifier
      settings_provider.dart     # Settings notifier
      subjects_provider.dart     # Subjects async notifier
      sync_provider.dart         # Full user data cloud sync coordinator
      wrong_provider.dart        # Wrong questions notifier
    screens/
      auth/login_screen.dart     # Email & password login/registration
      bookmarks/bookmarks_screen.dart
      chapters/chapters_screen.dart
      dashboard/dashboard_screen.dart
      exam/
        exam_screen.dart         # Exam taking interface with timer & PopScope
        question_palette.dart    # Color-coded grid overlay
      leaderboard/leaderboard_screen.dart
      result/result_screen.dart  # Score summary & performance analytics
      review/review_screen.dart  # Detailed question review with explanations
      settings/settings_screen.dart
      subjects/subjects_screen.dart
    widgets/
      app_bottom_nav.dart        # Bottom navigation bar shell
      empty_state.dart           # Reusable empty state view
      loading_widget.dart        # Reusable loading indicator
      markdown_text.dart         # GFM Markdown rendering widget
      option_tile.dart           # Quiz answer option selector tile
      stat_card.dart             # Dashboard statistic card widget
  android/
    app/build.gradle.kts         # minSdk=21, targetSdk=34, compileSdk=34
    app/src/main/AndroidManifest.xml # INTERNET & ACCESS_NETWORK_STATE permissions
    local.properties             # Configured for Android SDK & Flutter SDK
```

---

## 5. Supabase Integration & Security

- **Publishable Key Used:** Configured with Supabase's `publishableKey` in `.env` (excluded from git tracking).
- **Network Permissions:** `INTERNET` and `ACCESS_NETWORK_STATE` permissions declared in AndroidManifest.xml.
- **Data Isolation:** Enforced at the Supabase PostgreSQL level via RLS policies (`auth.uid() = user_id`).

---

## 6. Implementation Phases & Completion Status

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Audit web application & build development roadmap | ✅ Complete |
| **Phase 1** | Flutter project setup, directory structure & pubspec | ✅ Complete |
| **Phase 2** | Auth, Riverpod providers & GoRouter shell | ✅ Complete |
| **Phase 3** | Subject & Chapter browsing screens | ✅ Complete |
| **Phase 4** | Exam Engine (timer, question palette, bilingual, PopScope) | ✅ Complete |
| **Phase 5** | Scoring engine, Result screen & Question Review screen | ✅ Complete |
| **Phase 6** | Bookmarks & Wrong Questions persistence & practice screens | ✅ Complete |
| **Phase 7** | Dashboard, stats cards & quick practice launcher | ✅ Complete |
| **Phase 8** | Settings screen, dark mode toggle & daily target picker | ✅ Complete |
| **Phase 9** | Leaderboard & SRS SM-2 logic integration | ✅ Complete |
| **Phase 10** | Android toolchain setup, static analysis & APK Build | ✅ Complete |
| **Phase 11** | Comprehensive UI/UX Polish (`UI-UX Improvement.md` implementation) | ✅ Complete |
| **Phase 12** | Flexible Test-Generation System (Bookmarked & Custom/Mixed Tests) | ✅ Complete |
| **Phase 13** | Exam/Review UI Hierarchy, Single-Question Review & Repository Cleanup | ✅ Complete |

---

## 7. Phase 13: Exam/Review UI Redesign & Repository Transfer Summary

### What Was Implemented:
1. **Exam Screen Action Hierarchy Redesign (`lib/screens/exam/exam_screen.dart`)**:
   - Compact secondary-action row: *Mark for Review* (subtle amber outline) and *Clear Response* (neutral secondary style).
   - Dedicated primary navigation row: *Previous* (38% flex, single line `maxLines: 1`, no wrapping) and *Save & Next* / *Submit Test* (62% primary dominant action).
   - Non-truncating AppBar title column, compact language switcher chip, countdown timer chip, and overflow options menu (`⋮`).
2. **Interactive Single-Question Review Screen (`lib/screens/review/review_screen.dart`)**:
   - Single question-by-question `PageView` navigation replacing vertical scrolling lists.
   - Filter bar (*All*, *Correct*, *Wrong*, *Skipped*) updating position counters (*e.g., Q 1 / 5*) and restricting Next/Previous navigation to the filtered subset.
   - Status indicators (`✓ Correct`, `✕ Wrong Choice`, `— Skipped`), clear option color coding, collapsible explanation section (`ExpansionTile`), per-question bookmark toggle, and review palette drawer.
   - Returns to Results screen (`/result`) on review completion.
3. **Repository Transfer & Cleanup**:
   - Transferred Git repository to root at `mock_master_flutter/` (`.git` located at `mock_master_flutter/.git`).
   - Simplified Explore Subjects cards to show subject name & icon only. Removed sticky FAB from Dashboard.
   - Organized SQL schemas in `sql/` and documentation (`instruction.md`, `roadmap.md`, `uiux.md`, `UI-UX Improvement.md`) inside `mock_master_flutter/`.

### Static Analysis & Verification:
- `flutter analyze` clean: **0 errors, 0 warnings**.
- Git working tree clean: `master` branch up to date.

---

## 8. Credentials & Environment Configuration

Credentials stored safely in `/home/reed/Coding/Mock-Master-V0/mock_master_flutter/.env`:
```env
SUPABASE_URL=https://ttbtburllrmcdnorbqrl.supabase.co
SUPABASE_ANON_KEY=sb_publishable_QqW37wq4Q5vTgwCRdpyolg_2eEgG_Aj
```
*(Added to `.gitignore` to prevent credential leaks)*

---

## 9. Known Issues & Architectural Decisions

1. **Deprecated `WillPopScope` replaced with `PopScope`**: Supports Android predictive back gestures cleanly.
2. **Android SDK configured**: Configured at `/home/reed/Android/Sdk` (API 34 & 36, BuildTools 28.0.3 & 34.0.0, platform-tools/adb).
3. **Static Analysis**: `flutter analyze` passes with **0 errors and 0 warnings**.

---

## 10. Current Status & Next Steps

```
Status: 🟢 ALL PHASES (1-13) & REPOSITORY CLEANUP COMPLETE
Static Analysis: 0 Errors, 0 Warnings
APK Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## 10. Git History Summary

| Hash | Commit Description |
|---|---|
| `1e80b0f` | chore: initial web app commit + Flutter development roadmap |
| (latest) | feat: recreate Mock Master as native Flutter Android application |
