# 📱 Mock Master Flutter — Development Roadmap & Agent Log

> **Last Updated:** 2026-08-10
> **Status:** 🟢 All Core Phases (1–13) + Security/Architecture Audit Complete
> **Purpose:** Authoritative milestone log and task queue. Every agent MUST update this file after completing work.

---

## Table of Contents

1. [Project Summary](#1-project-summary)
2. [Database & Supabase Schema](#2-database--supabase-schema)
3. [Feature Conversion Matrix (React → Flutter)](#3-feature-conversion-matrix)
4. [Flutter Architecture Overview](#4-flutter-architecture-overview)
5. [Supabase Security Model](#5-supabase-security-model)
6. [Implementation Phases & Status](#6-implementation-phases--status)
7. [Phase 13 — Exam/Review Redesign (Detail)](#7-phase-13--examreview-redesign-detail)
8. [Phase 14 — Security & Architecture Audit (Detail)](#8-phase-14--security--architecture-audit-detail)
9. [Environment & Credentials](#9-environment--credentials)
10. [Known Issues & Decisions](#10-known-issues--decisions)
11. [Current Status & Next Steps](#11-current-status--next-steps)
12. [Git History](#12-git-history)
13. [Agent Handover Protocol](#13-agent-handover-protocol)

---

## 1. Project Summary

Mock Master is a competitive exam preparation app (UPSC, SSC, etc.) originally built as a React/Vite/Supabase web app and fully rewritten as a Flutter native app for Android, Linux, and Web using the same Supabase backend.

**Key Numbers:**
- ~50 Dart source files across `lib/`
- 13 completed feature phases
- 1 completed security + architecture audit
- 0 `flutter analyze` errors or warnings

---

## 2. Database & Supabase Schema

### Tables & Access Control

| Table | RLS Policy | Purpose |
|---|---|---|
| `users` | `auth.uid() = id` | User settings, profile, display name, admin flag |
| `history` | `auth.uid() = user_id` | Exam attempt records (score, answers, timing) |
| `bookmarks` | `auth.uid() = user_id` | User bookmarked questions |
| `wrong_questions` | `auth.uid() = user_id` | Incorrectly answered questions for practice |
| `custom_questions` | `auth.uid() = user_id` | User-defined question overrides |
| `srs_cards` | `auth.uid() = user_id` | Spaced repetition (SM-2) card data |
| `question_reports` | `auth.uid() = user_id` | User question reports (**NOT** `reports`) |
| `admin_manifest` | Public Read / Admin Write | Master subject & chapter catalog |
| `admin_chapters_data` | Public Read / Admin Write | Full question datasets per chapter |
| `leaderboard` | Public Read / User Write | Global rankings — **PII risk, consent required** |

> ⚠️ **Table name critical**: Question reports go to `question_reports`, not `reports`. This was a bug fixed in commit `4de74f3`.

---

## 3. Feature Conversion Matrix

| Feature | React Web | Flutter | Status |
|---|---|---|---|
| Authentication | Supabase Auth (email) | `AuthService` + `LoginScreen` (Form validated) | ✅ |
| Subject Browser | `SubjectsView.tsx` | `SubjectsScreen` + `subjectsProvider` | ✅ |
| Chapter Browser | `ChaptersView.tsx` | `ChaptersScreen` (attempt + bookmark stats) | ✅ |
| Exam Engine | `ExamView.tsx` | `ExamScreen` (timer, PopScope, PageView, bilingual) | ✅ |
| Question Palette | Overlay drawer | `QuestionPalette` widget (colored grid) | ✅ |
| Scoring Engine | Positive/negative marks | Exact formula match in `ExamScreen` | ✅ |
| Result Screen | `ResultView.tsx` | `ResultScreen` (ring score, analytics, chips) | ✅ |
| Question Review | `ReviewView.tsx` | `ReviewScreen` (single-question, filter chips) | ✅ |
| Bookmarks | `BookmarksView.tsx` | `BookmarksScreen` + `bookmarksProvider` | ✅ |
| Wrong Questions | Implicit | `WrongScreen` + `WrongService` + `WrongQuestion` model | ✅ |
| Dashboard | `DashboardView.tsx` | `DashboardScreen` (progress, activity, goals) | ✅ |
| Settings | `SettingsView.tsx` | `SettingsScreen` (dark mode, target, sign out) | ✅ |
| Leaderboard | `LeaderboardView.tsx` | `LeaderboardScreen` + `leaderboardProvider` | ✅ |
| SRS (SM-2) | None | `SRSCard` model + SM-2 algorithm | ✅ |
| Markdown | Custom renderer | `flutter_markdown` (`MarkdownText` widget) | ✅ |
| Shell Navigation | `currentView` state | `GoRouter` + `ShellRoute` + `AppBottomNav` | ✅ |
| Report Question | None | `ReportService` → `question_reports` table | ✅ |

---

## 4. Flutter Architecture Overview

### State Flow

```
User Action
  → Screen (ConsumerWidget / ConsumerStatefulWidget)
  → Provider (StateNotifier / AsyncNotifier / StreamProvider)
  → Service (Supabase API + SharedPreferences cache)
  → Model (immutable, copyWith pattern)
```

### Key Architecture Decisions

| Decision | Rationale |
|---|---|
| Riverpod (not Provider/Bloc) | Fine-grained reactivity, no BuildContext dependency in services |
| `ref.watch` in all Provider builders | Ensures re-evaluation on dependency changes |
| `currentUserProvider` watches `authStateProvider` | Never reads `supabase.auth.currentUser` directly |
| Stale-while-revalidate in ManifestService | Cache shown instantly; Supabase refreshed in background |
| Three-tier data loading | Cache → Supabase → Bundled asset (prevents empty states) |
| `WrongQuestion` model separate from `Bookmark` | Domain correctness; independent field evolution |
| Timer starts in `addPostFrameCallback` | Satisfies "no auto-start" timer contract |
| Form validation on LoginScreen | Prevents empty/invalid data reaching Supabase API |

---

## 5. Supabase Security Model

- **RLS**: Row Level Security enforced on all user tables via `auth.uid() = user_id`.
- **Publishable Key**: The `SUPABASE_ANON_KEY` is a publishable key, but it still must not be hardcoded in source code — it gets embedded in the binary and is extractable from the APK.
- **`.env` NOT bundled**: The `.env` file is intentionally excluded from `pubspec.yaml`'s `assets:` list. Loading it as an asset would expose it inside the APK zip. This was fixed in commit `4de74f3` (SEC-2).
- **Production builds**: Use `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` at build time.
- **Leaderboard**: Public Read — user `display_name` is visible globally. Consent prompt required before first write.

---

## 6. Implementation Phases & Status

| Phase | Description | Status |
|---|---|---|
| **Phase 0** | Audit React web app & build development roadmap | ✅ Complete |
| **Phase 1** | Flutter project setup, directory structure & pubspec | ✅ Complete |
| **Phase 2** | Auth, Riverpod providers & GoRouter shell | ✅ Complete |
| **Phase 3** | Subject & Chapter browsing screens | ✅ Complete |
| **Phase 4** | Exam Engine (timer, question palette, bilingual, PopScope) | ✅ Complete |
| **Phase 5** | Scoring engine, Result screen & Question Review screen | ✅ Complete |
| **Phase 6** | Bookmarks & Wrong Questions persistence | ✅ Complete |
| **Phase 7** | Dashboard, stats cards & quick practice launcher | ✅ Complete |
| **Phase 8** | Settings screen, dark mode, daily target picker | ✅ Complete |
| **Phase 9** | Leaderboard & SRS SM-2 logic | ✅ Complete |
| **Phase 10** | Android toolchain, static analysis & APK build | ✅ Complete |
| **Phase 11** | Comprehensive UI/UX polish | ✅ Complete |
| **Phase 12** | Flexible Test-Generation System (Bookmarked + Custom/Mixed) | ✅ Complete |
| **Phase 13** | Exam/Review UI Redesign & Repository Cleanup | ✅ Complete |
| **Phase 14** | Security & Architecture Audit + All Fixes Applied | ✅ Complete |

---

## 7. Phase 13 — Exam/Review Redesign (Detail)

**Commit:** `c9cb05d` / `baeca46`

### What Was Implemented:
1. **Exam Screen Action Hierarchy** (`exam_screen.dart`):
   - Compact secondary-action row: *Mark for Review* (amber outline) and *Clear Response* (neutral).
   - Primary navigation row: *Previous* (38% flex) and *Save & Next* / *Submit Test* (62% primary).
   - Non-truncating AppBar title, language switcher chip, countdown timer chip, overflow options menu.

2. **Single-Question Review Screen** (`review_screen.dart`):
   - PageView navigation (single question at a time, not vertical scroll list).
   - Filter bar: *All*, *Correct*, *Wrong*, *Skipped* — updates position counters.
   - Status badges: `✓ Correct`, `✕ Wrong Choice`, `— Skipped`.
   - Collapsible explanations (`ExpansionTile`), per-question bookmark toggle, review palette drawer.
   - Returns to `/result` on completion.

3. **Repository Cleanup**: Moved to self-contained `mock_master_flutter/` with `.git` at root.

**Static Analysis:** 0 errors, 0 warnings.

---

## 8. Phase 14 — Security & Architecture Audit (Detail)

**Commit:** `4de74f3` — 21 files changed, 421 insertions, 1119 deletions

### Security Fixes

| ID | Fix | File(s) |
|---|---|---|
| SEC-1 | Removed hardcoded `SUPABASE_URL`/`SUPABASE_ANON_KEY` fallbacks from Dart source. App now throws with a clear message if `.env` is missing. | `supabase_client.dart` |
| SEC-2 | Removed `.env` from `pubspec.yaml` assets (was being bundled into APK). Added `.env.example`. `main.dart` now shows error widget if init fails. | `pubspec.yaml`, `main.dart` |
| SEC-3 | Fixed `ReportService` targeting wrong table (`reports` → `question_reports`). Wired `ReportService.submitReport()` into `ExamScreen` report dialog — was previously never called. | `report_service.dart`, `exam_screen.dart` |

### Architecture Fixes

| ID | Fix | File(s) |
|---|---|---|
| ARCH-1 | Fixed `currentUserProvider` using `ref.read` inside a `Provider` builder — changed to `ref.watch(authStateProvider)` for reactivity. | `auth_provider.dart` |
| ARCH-2 | Exam timer no longer starts in `initState`. Now starts via `_beginExam()` in `addPostFrameCallback`, honoring the "no auto-start" contract. | `exam_screen.dart` |
| ARCH-3 | `ManifestService` no longer short-circuits on cache (would permanently freeze catalog). Now uses stale-while-revalidate: returns cache instantly, refreshes Supabase in background. | `manifest_service.dart` |
| ARCH-4 | Created `WrongQuestion` model (`lib/models/wrong_question.dart`). Migrated `WrongService` and `wrong_provider` off the misused `Bookmark` type. | `wrong_question.dart`, `wrong_service.dart`, `wrong_provider.dart` |
| ARCH-5 | Login screen now uses `Form` + `TextFormField` with email regex, password length validation, visibility toggle, and controller disposal. | `login_screen.dart` |

### Code Quality Fixes

| ID | Fix | File(s) |
|---|---|---|
| BUG-1 | Replaced commented-out `// print(e)` with `debugPrint` in `HistoryService.saveHistoryItem`. | `history_service.dart` |
| BUG-2 | Replaced `// ignore` silent catches with `debugPrint` in `SettingsService`. | `settings_service.dart` |
| BUG-3 | Fixed unsafe `value as int?` hard cast in `ExamSession.fromJson` — JSON numbers can be `double`. | `exam_session.dart` |
| BUG-4 | Same fix applied to `AttemptHistoryItem.fromJson`. | `attempt_history.dart` |
| BUG-7 | Replaced empty comment catch in `SyncService.syncAllData` with `debugPrint`. | `sync_provider.dart` |

### Documentation Fixes

| ID | Fix |
|---|---|
| DOC-1 | Removed live Supabase credentials from `roadmap.md` — replaced with `<YOUR_...>` placeholders. |
| DOC-2 | Removed broken references to `uiux.md` and `UI-UX Improvement.md` (files did not exist). |
| DOC-3 | Updated Git history table in `roadmap.md` to include all 4 commits. |

**Static Analysis:** 0 errors, 0 warnings after all fixes.

---

## 9. Environment & Credentials

```env
# .env (located at project root — NOT committed, NOT bundled as asset)
SUPABASE_URL=<YOUR_SUPABASE_PROJECT_URL>
SUPABASE_ANON_KEY=<YOUR_SUPABASE_PUBLISHABLE_ANON_KEY>
```

- Copy `.env.example` to `.env` and fill in your project values.
- See `lib/core/supabase_client.dart` for how credentials are loaded.
- For production APK builds: inject via `--dart-define` instead of `.env`.

---

## 10. Known Issues & Decisions

| # | Item | Status |
|---|---|---|
| 1 | `flutter_markdown` discontinued (replaced by `flutter_markdown_plus`) | Known — not yet migrated |
| 2 | 41 packages have newer versions incompatible with current constraints | Known — run `flutter pub outdated` to audit |
| 3 | Leaderboard `display_name` PII — no consent prompt yet before first write | Open — needs a one-time opt-in dialog |
| 4 | `PopScope` used (not deprecated `WillPopScope`) | ✅ Resolved |
| 5 | Android SDK at `/home/reed/Android/Sdk` (API 34, BuildTools 34.0.0) | ✅ Configured |
| 6 | `.env` not bundled as asset — prod builds need `--dart-define` workflow | Open — document in README |

---

## 11. Current Status & Next Steps

```
Build Status:     ✅ flutter analyze — No issues found!
Active Branch:    master
Working Tree:     Clean
Last Commit:      4de74f3 — Security & Architecture audit fixes
```

### Recommended Next Tasks (in priority order)

1. **Leaderboard PII Consent Dialog** — Before the first leaderboard write, show a one-time opt-in dialog explaining that `display_name` will be publicly visible. Let users set a leaderboard alias separate from their settings name.

2. **Production Build Workflow** — Document and set up `--dart-define` based credential injection for release APK builds so `.env` is never needed in production.

3. **Migrate `flutter_markdown` → `flutter_markdown_plus`** — The current package is discontinued. Migration should be straightforward (API is compatible).

4. **SRS Screen** — The SM-2 model and cards exist in Supabase but there is no dedicated SRS practice screen in the app yet.

5. **Offline Sync Conflict Resolution** — When the app goes from offline to online, local SharedPreferences data and Supabase data can diverge. Implement a merge/conflict strategy in `SyncService`.

6. **Push Notifications** — Daily study reminders tied to the user's `daily_target` setting.

---

## 12. Git History

| Hash | Author | Date | Description |
|---|---|---|---|
| `4de74f3` | Agent | 2026-08-10 | fix(security+arch): apply full audit — SEC-1/2/3, ARCH-1–5, BUG-1/2/3/4/7, DOC-1/2/3 |
| `c9cb05d` | Agent | 2026-08-10 | docs: define mandatory Git commit & roadmap logging protocol |
| `baeca46` | Agent | 2026-08-10 | docs: update roadmap.md with Phase 13 completion summary |
| `2a1eedd` | Agent | 2026-08-10 | docs: add instruction.md cross-account handover guide |
| `b562d53` | Agent | 2026-08-10 | feat(init): initialize Mock Master Flutter standalone repository |

---

## 13. Agent Handover Protocol

### When you start a new session:

```bash
# 1. Verify environment
export PATH="$PATH:/home/reed/development/flutter/bin"
git log --oneline -n 10     # See recent work
git status                   # Confirm clean tree
flutter analyze              # Must be 0 issues before you start

# 2. Read documentation
# - instruction.md → architecture rules, what not to do
# - roadmap.md §11 → current status & next tasks
# - roadmap.md §12 → git history

# 3. Begin work on the next task from §11 above
```

### When you finish a session:

```bash
# 1. Verify build
flutter analyze              # Must output: "No issues found!"

# 2. Commit
git add -A
git commit -m "feat/fix/docs(scope): summary

- What was done
- Why it was done this way
- Any known limitations

Static analysis: 0 errors, 0 warnings."

# 3. Update this roadmap
# - Add a new Phase entry in §6 if it's a full feature
# - Add a detail section (like §7 or §8) describing what changed
# - Update §11 Current Status
# - Add commit to §12 Git History
# - Update "Last Updated" date at the top of this file
```

### What to log in this roadmap:
- ✅ What was implemented (feature name, key files changed)
- ✅ Static analysis result
- ✅ Any known limitations or tradeoffs
- ✅ Recommended next steps for the next agent
- ❌ Do NOT log credentials, raw API keys, or personal data here
