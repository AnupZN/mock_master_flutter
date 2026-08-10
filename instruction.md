# 📖 Mock Master — Handover & Project Context Guide (`instruction.md`)

> **IMPORTANT FOR NEW ANTIGRAVITY ACCOUNTS / AGENTS**:  
> If you have just opened this repository after an account switch or quota reset, **DO NOT RESTART OR REWRITE WORKING CODE**.  
> Read this document completely, then inspect the codebase (`git status`, `git log`, `roadmap.md`, and `lib/`) to verify the live state before taking action.

---

## 1. Project Overview & Objective

**Mock Master** is a high-performance, professional competitive exam preparation application. Originally created as a React/Vite/Supabase web app, it has been completely recreated into a native **Flutter + Dart** application for Android, Linux, and Web, connecting to the exact same **Supabase** backend.

### Key Goals & Core Philosophy:
- **Flawless Exam Engine**: Replicates authentic CBT (Computer-Based Test) exam behavior with timer, question navigation, option selection/deselection, Save & Next, Mark for Review, Question Palette drawer, scoring, result analytics, and single-question review mode.
- **Material 3 Design System**: Modern, accessible UI with smooth HSL colors, responsive layouts, dark/light theme support, and colorblind-accessible badges (`✓`, `🚩`, `—`).
- **Flexible Practice Modes**: Supports Chapter-wise exams, Bookmarked Tests, and Custom/Mixed Tests with automatic question-capping safeguards.
- **Offline First**: All subjects, chapters, and bookmarks cache locally via `shared_preferences` and bundled JSON asset fallbacks (`assets/data/*`), keeping practice working seamlessly even when offline.

---

## 2. Technology Stack & Dependencies

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: Riverpod (`flutter_riverpod`, StateNotifier, AsyncNotifier, StreamProvider)
- **Routing**: `go_router` (declarative shell routing, auth redirects)
- **Backend & Database**: Supabase Flutter SDK (`supabase_flutter`)
- **Local Storage & Cache**: `shared_preferences`
- **Environment Management**: `flutter_dotenv` (loading secrets from `.env`)
- **Markdown & Content Rendering**: `flutter_markdown` (renders math formulas, tables, code blocks, lists)

---

## 3. Directory Structure & Key Files

The project repository root is located at `/home/reed/Coding/Mock-Master-V0/mock_master_flutter/`:

```
mock_master_flutter/
├── .env                       # Supabase credentials (SUPABASE_URL, SUPABASE_ANON_KEY)
├── pubspec.yaml               # Flutter package configuration & assets
├── analysis_options.yaml      # Static analysis lints
├── instruction.md             # This cross-account handover guide
├── roadmap.md                 # Authoritative project roadmap & milestone status
├── uiux.md                    # UI/UX design tokens & sitemap reference
├── UI-UX Improvement.md       # Specific UI/UX directives & guidelines
├── sql/                       # Supabase SQL Database Schemas
│   ├── SUPABASE_SCHEMA.sql
│   └── SUPABASE_SCHEMA_ADDITIONS.sql
├── lib/
│   ├── main.dart              # App entrypoint (initializes dotenv & Supabase)
│   ├── app.dart               # Root MaterialApp.router & global auth sync wrapper
│   ├── core/                  # Infrastructure core
│   │   ├── constants.dart     # Storage keys & default settings
│   │   ├── supabase_client.dart# Global Supabase client getter
│   │   ├── app_theme.dart     # Material 3 ThemeData (Light & Dark)
│   │   └── router.dart        # GoRouter navigation routes & auth redirects
│   ├── models/                # Data domain models
│   │   ├── question.dart      # Question, QuestionTable models
│   │   ├── subject.dart       # Subject, Chapter, SubSubject models
│   │   ├── chapter_data.dart  # ChapterData model (marking scheme & questions)
│   │   ├── exam_session.dart  # ExamSession state model
│   │   ├── attempt_history.dart# AttemptHistoryItem model
│   │   ├── bookmark.dart      # Bookmark model
│   │   ├── srs_card.dart      # SRSCard & SM-2 algorithm logic
│   │   └── app_settings.dart  # AppSettings model
│   ├── services/              # Business logic & Supabase API repositories
│   │   ├── auth_service.dart
│   │   ├── chapter_service.dart
│   │   ├── manifest_service.dart
│   │   ├── history_service.dart
│   │   ├── bookmark_service.dart
│   │   ├── wrong_service.dart
│   │   ├── leaderboard_service.dart
│   │   ├── report_service.dart
│   │   ├── settings_service.dart
│   │   └── test_generator_service.dart # Bookmarked & Custom/Mixed test generation
│   ├── providers/             # Riverpod state providers
│   │   ├── auth_provider.dart
│   │   ├── session_provider.dart
│   │   ├── subjects_provider.dart
│   │   ├── history_provider.dart
│   │   ├── bookmarks_provider.dart
│   │   ├── wrong_provider.dart
│   │   ├── settings_provider.dart
│   │   └── sync_provider.dart
│   ├── screens/               # Application UI Screens
│   │   ├── auth/login_screen.dart
│   │   ├── dashboard/dashboard_screen.dart
│   │   ├── subjects/subjects_screen.dart
│   │   ├── chapters/chapters_screen.dart
│   │   ├── exam/exam_screen.dart
│   │   ├── exam/question_palette.dart
│   │   ├── exam/test_generator_screen.dart
│   │   ├── result/result_screen.dart
│   │   ├── review/review_screen.dart
│   │   ├── bookmarks/bookmarks_screen.dart
│   │   ├── settings/settings_screen.dart
│   │   └── leaderboard/leaderboard_screen.dart
│   └── widgets/               # Reusable UI Components
│       ├── markdown_text.dart
│       ├── option_tile.dart
│       ├── stat_card.dart
│       ├── empty_state.dart
│       ├── loading_widget.dart
│       └── app_bottom_nav.dart
```

---

## 4. Supabase Backend Architecture & Credentials

The app communicates with the following Supabase project:
- **URL**: `https://ttbtburllrmcdnorbqrl.supabase.co`
- **Tables**:
  - `admin_manifest`: Holds master catalog of subjects, chapters, folders, and icons.
  - `admin_chapters_data`: Holds question sets keyed by `id = '{subjectId}_{chapterId}'`.
  - `history`: User exam attempt records (score, accuracy, user answers, time taken).
  - `bookmarks`: User saved bookmarked questions (`user_id`, `subject_id`, `chapter_id`, `question_id`).
  - `wrong_questions`: Questions answered incorrectly by users for targeted practice.
  - `users`: Profile settings (theme, dark mode, daily target, display name).

> **Secrets Management**: Credentials must be read from `.env` via `flutter_dotenv`. **NEVER hardcode secrets into code or commit API keys.** If `.env` is missing, ask the user for `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

---

## 5. Architectural Principles & Coding Conventions

When continuing development, follow these rules:

1. **Re-use Existing Engines**:
   - **Do NOT create a second exam engine or second review screen.** All exam modes (Chapter exams, Bookmarked Tests, Custom/Mixed Tests) instantiate an `ExamSession` and use `ExamScreen` (`lib/screens/exam/exam_screen.dart`).
   - **Review Mode**: Single interactive review screen (`lib/screens/review/review_screen.dart`) handles review filtering (All, Correct, Wrong, Skipped) and question-by-question navigation.

2. **Deselect & Option Selection Logic**:
   - Re-tapping an already selected option tile deselects/clears that selection (`userAnswers[q.id] = isSelected ? null : optIdx`).
   - Option tiles render explicit checkmarks `✓` when selected.

3. **Timer Contract**:
   - Countdowns **MUST NOT start automatically** before the user explicitly presses **Start Test** in the pre-exam instruction overview dialog or test generator preview modal.

4. **Automatic Question Capping Safeguard**:
   - For Bookmarked or Custom tests, 25/50 is treated as a maximum requested count.
   - If available questions < requested (e.g. 18 available < 25 requested), automatically cap test size to 18 and present an explicit warning card on the preview screen. Never silently drop questions or crash on empty sets.

5. **Static Analysis Standard**:
   - Code changes MUST pass `flutter analyze` with **0 errors and 0 warnings**.

6. **Mandatory Git Commit & Roadmap Logging Protocol**:
   - **Commit Frequency**: After completing any major feature, bug fix, or UI milestone, the agent MUST verify the build with `flutter analyze` and create a descriptive Git commit following Conventional Commits format (`feat(...)`, `fix(...)`, `style(...)`, `docs(...)`).
   - **Roadmap Synchronization**: After committing, the agent MUST update `roadmap.md` logging:
     - What was implemented.
     - What was tested and verified.
     - Known limitations (if any).
     - Recommended next steps for the next agent.
   - **Traceability**: This allows any new agent or model to run `git log --oneline -n 10` and inspect `roadmap.md` to trace the project history with 100% confidence.

---

## 6. How to Run, Test, & Preview

Run commands from `/home/reed/Coding/Mock-Master-V0/mock_master_flutter`:

```bash
# 1. Environment Path Setup
export PATH="$PATH:/home/reed/development/flutter/bin"
export ANDROID_SDK_ROOT=~/Android/Sdk

# 2. Get Dependencies
flutter pub get

# 3. Static Analysis (MUST BE CLEAN)
flutter analyze

# 4. Run Application locally on Linux bundle or connected device
flutter run -d linux

# 5. Build Release Android APK
flutter build apk --release
```

---

## 7. Current Project State & Next Steps for New Agent

### Completed Phases (1 – 12):
- ✅ **Phase 1–5**: Infrastructure, Supabase API client, Riverpod providers, Models, Auth, Subject/Chapter browsing, Exam engine & Scoring.
- ✅ **Phase 6–9**: Bookmarks & Wrong Questions persistence, Dashboard analytics, Settings, Dark mode, Leaderboard, SRS SM-2 implementation.
- ✅ **Phase 10**: Android build chain, Linux bundle build, static analysis clean.
- ✅ **Phase 11**: UI/UX polish (Resumable exam card, Today's Goal progress, pre-exam overview modal, live catalog search bar, accessible palette grid).
- ✅ **Phase 12**: Flexible Test-Generation System (Bookmarked Test & Custom/Mixed Test with mode selector, subject chips, 25/50 count chips, 10-30m & custom duration, availability counter & preview modal).
- ✅ **Exam & Review UI Redesign**: Single-question Review screen with category filter chips (All, Correct, Wrong, Skipped), status badges (`✓ Correct`, `✕ Wrong Choice`, `— Skipped`), collapsible explanations, review palette, and sticky dual-row exam navigation bar.
- ✅ **Repository Cleanup**: Self-contained repository located at `mock_master_flutter/` with working tree clean.

### What the New Agent Should Do Next:
1. **Verify Live State**: Run `git status` and `flutter analyze` inside `mock_master_flutter/`.
2. **Consult `roadmap.md`**: Read [`roadmap.md`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/roadmap.md) to check the latest milestone tasks or user requests.
3. **Address User Prompt**: Read the user's latest request and continue building upon the existing codebase without rewriting working logic.
