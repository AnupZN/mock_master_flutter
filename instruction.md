# 📖 Mock Master — Agent Handover & Project Context Guide

> **FILE PURPOSE**: This is the **first file any new agent or model must read** before touching any code. It answers: What is this project? How is it structured? What are the rules? What must I never do?
>
> **LAST UPDATED**: 2026-08-10 (Post-audit security & architecture fixes applied)

---

## ⚠️ MANDATORY FIRST-ACTION CHECKLIST FOR NEW AGENTS

Before writing a single line of code or modifying any file, every new agent (same or new account, same or new model) MUST:

1. **Read this file completely.**
2. **Read `roadmap.md`** — it is the authoritative log of what has been built, what the current state is, and what comes next.
3. **Run these commands** to verify the live state of the repo:
   ```bash
   export PATH="$PATH:/home/reed/development/flutter/bin"
   git log --oneline -n 10
   git status
   flutter analyze
   ```
4. **Check `flutter analyze` output** — it MUST read `No issues found!` before you make changes, and again after.
5. **Do NOT rewrite working code.** Continue from where the previous agent stopped.

---

## 1. Project Overview

**Mock Master** is a production-grade competitive exam preparation app. It was originally built as a React/Vite/Supabase web app and has been fully rewritten as a **Flutter + Dart** mobile application for Android, Linux, and Web — backed by the same Supabase PostgreSQL project.

### Design Goals
| Goal | Detail |
|---|---|
| Authentic CBT Engine | Timer, question palette, mark-for-review, deselect, Save & Next, auto-submit |
| Material 3 Design | HSL color palette, responsive layouts, dark/light themes, colorblind-accessible |
| Offline-First | Three-tier data loading: Cache → Supabase → Bundled JSON asset |
| Bilingual | Full English + Hindi toggle with graceful fallback |
| Multi-mode Practice | Chapter exams, Bookmarked Tests, Custom/Mixed Tests |
| Zero-Error Build | `flutter analyze` must always be 0 errors, 0 warnings |

---

## 2. Repository Location & Environment

```
Project Root:  /home/reed/Coding/Mock-Master-V0/mock_master_flutter/
Flutter SDK:   /home/reed/development/flutter/bin
Android SDK:   /home/reed/Android/Sdk
```

To set up the environment in any terminal session:
```bash
export PATH="$PATH:/home/reed/development/flutter/bin"
export ANDROID_SDK_ROOT=~/Android/Sdk
```

To run:
```bash
flutter pub get          # Install/update dependencies
flutter analyze          # Static analysis — MUST BE CLEAN before committing
flutter run -d linux     # Run locally on Linux
flutter build apk --release  # Build Android release APK
```

---

## 3. Technology Stack

| Layer | Technology | Version |
|---|---|---|
| Framework | Flutter / Dart | 3.44.9 / 3.12.2 |
| State Management | Riverpod (`flutter_riverpod`) | 2.6.1 |
| Routing | `go_router` | 14.8.1 |
| Backend | `supabase_flutter` | 2.8.4 |
| Markdown Rendering | `flutter_markdown` | 0.7.7 |
| Local Cache | `shared_preferences` | — |
| Secrets | `flutter_dotenv` | 5.2.1 |

---

## 4. Directory Structure

```
mock_master_flutter/
├── .env                        # Secrets file — NEVER commit, listed in .gitignore
├── .env.example                # Safe template — shows required keys with placeholders
├── pubspec.yaml                # Package config (note: .env NOT listed as asset — see §10)
├── analysis_options.yaml       # Strict lint rules
├── instruction.md              # ← This file (read first)
├── roadmap.md                  # Project roadmap, milestone log, current status
├── sql/
│   ├── SUPABASE_SCHEMA.sql     # Full Supabase table schema
│   └── SUPABASE_SCHEMA_ADDITIONS.sql
└── lib/
    ├── main.dart               # App entrypoint: loads .env, inits Supabase, runs app
    ├── app.dart                # Root widget: AppShell + sync listener
    ├── core/
    │   ├── supabase_client.dart # Supabase init + client getter (NO hardcoded secrets)
    │   ├── router.dart          # GoRouter: all routes + auth redirect guards
    │   ├── app_theme.dart       # Material 3 light + dark ThemeData
    │   └── constants.dart       # StorageKeys + DefaultSettings constants
    ├── models/                  # Pure data models (no business logic)
    │   ├── question.dart        # Question, QuestionTable
    │   ├── subject.dart         # Subject, Chapter, SubSubject
    │   ├── chapter_data.dart    # ChapterData (marking scheme + question list)
    │   ├── exam_session.dart    # ExamSession (active test state)
    │   ├── attempt_history.dart # AttemptHistoryItem (completed test record)
    │   ├── bookmark.dart        # Bookmark model
    │   ├── wrong_question.dart  # WrongQuestion model (separate from Bookmark)
    │   ├── srs_card.dart        # SRSCard + SM-2 algorithm
    │   └── app_settings.dart    # AppSettings (theme, daily target, display name)
    ├── services/                # All Supabase API calls + local cache logic
    │   ├── auth_service.dart
    │   ├── manifest_service.dart   # Subject catalog (stale-while-revalidate)
    │   ├── chapter_service.dart    # Chapter questions (3-tier loading)
    │   ├── history_service.dart    # Exam attempt CRUD
    │   ├── bookmark_service.dart   # Bookmarks CRUD
    │   ├── wrong_service.dart      # Wrong questions CRUD
    │   ├── leaderboard_service.dart
    │   ├── report_service.dart     # Question reports → `question_reports` table
    │   ├── settings_service.dart   # Settings sync (local + Supabase `users` table)
    │   └── test_generator_service.dart # Bookmarked + Custom/Mixed test generation
    ├── providers/               # Riverpod state providers (bridge services → UI)
    │   ├── auth_provider.dart       # authStateProvider (StreamProvider), currentUserProvider
    │   ├── session_provider.dart    # Active ExamSession StateNotifier
    │   ├── subjects_provider.dart   # Subject catalog AsyncNotifier
    │   ├── history_provider.dart    # Attempt history StateNotifier
    │   ├── bookmarks_provider.dart  # Bookmarks StateNotifier
    │   ├── wrong_provider.dart      # Wrong questions StateNotifier (uses WrongQuestion)
    │   ├── settings_provider.dart   # App settings StateNotifier
    │   └── sync_provider.dart       # Full-user cloud sync coordinator
    ├── screens/                 # UI screens (one per route)
    │   ├── auth/login_screen.dart        # Login + signup (Form validated)
    │   ├── dashboard/dashboard_screen.dart
    │   ├── subjects/subjects_screen.dart
    │   ├── chapters/chapters_screen.dart
    │   ├── exam/exam_screen.dart         # Core exam interface
    │   ├── exam/question_palette.dart    # Color-coded grid overlay
    │   ├── exam/test_generator_screen.dart
    │   ├── result/result_screen.dart
    │   ├── review/review_screen.dart
    │   ├── bookmarks/bookmarks_screen.dart
    │   ├── settings/settings_screen.dart
    │   └── leaderboard/leaderboard_screen.dart
    └── widgets/                 # Shared reusable UI components
        ├── markdown_text.dart   # GFM + math rendering
        ├── option_tile.dart     # Quiz answer option tile
        ├── stat_card.dart       # Dashboard stat card
        ├── empty_state.dart
        ├── loading_widget.dart
        └── app_bottom_nav.dart
```

---

## 5. Supabase Backend

**Project URL**: `https://ttbtburllrmcdnorbqrl.supabase.co` (reference only — never hardcode this in Dart source)

### Tables

| Table | RLS | Purpose |
|---|---|---|
| `users` | `auth.uid()` | User settings, profile, admin flag |
| `history` | `auth.uid()` | Exam attempt records (JSONB answers, stats) |
| `bookmarks` | `auth.uid()` | User bookmarked questions |
| `wrong_questions` | `auth.uid()` | Incorrectly answered questions |
| `custom_questions` | `auth.uid()` | User question overrides |
| `srs_cards` | `auth.uid()` | Spaced repetition card data (SM-2) |
| `question_reports` | `auth.uid()` | User question reports (NOT `reports`) |
| `admin_manifest` | Public Read | Master subject/chapter catalog |
| `admin_chapters_data` | Public Read | Full question datasets per chapter |
| `leaderboard` | Public Read | Global rankings (consent required — PII risk) |

---

## 6. Architecture & Coding Rules

### 6.1 — What NEVER to Do

> These are the most common mistakes a new agent makes. Read and follow every single one.

| ❌ DON'T | ✅ DO instead |
|---|---|
| Hardcode `SUPABASE_URL` or `SUPABASE_ANON_KEY` in any Dart file | Read from `dotenv.env['KEY']` and throw if missing |
| `.env` NOT listed in pubspec.yaml `assets:` | **.env MUST be in assets** — flutter_dotenv uses `rootBundle` (not OS filesystem). For production builds, use `--dart-define` so the `.env` file is not needed at all. |
| Create a second exam engine, result screen, or review screen | Reuse `ExamScreen`, `ResultScreen`, `ReviewScreen` |
| Use `ref.read` inside a `Provider` builder | Use `ref.watch` to stay reactive |
| Start the exam timer in `initState` directly | Start it in `addPostFrameCallback` via `_beginExam()` |
| Use the `Bookmark` model for wrong questions | Use `WrongQuestion` model (`lib/models/wrong_question.dart`) |
| Submit reports to the `reports` table | Submit to `question_reports` |
| Swallow exceptions with `} catch (e) { // ignore }` | Use `debugPrint('Service.method error: $e')` at minimum |
| Cast JSON number values with `value as int?` | Use `value is int ? value : (value as num).toInt()` |
| Commit without running `flutter analyze` | Run analyze, fix all issues, then commit |
| Rewrite working, complete features from scratch | Extend or fix the existing implementation |

### 6.2 — Riverpod Patterns

- `Provider<T>` builders must use `ref.watch`, NOT `ref.read` (except one-time reads in callbacks)
- `currentUserProvider` derives from `authStateProvider` (StreamProvider) — never from `supabase.auth.currentUser` directly
- All state mutations use `copyWith` + new List/Map — never mutate in place

### 6.3 — Data Loading Pattern (Three-Tier)

Services follow this consistent pattern:

```
1. Return cached data (SharedPreferences) immediately
2. Trigger background refresh from Supabase (stale-while-revalidate)
3. If cache empty → try Supabase synchronously
4. If Supabase fails → fall back to bundled asset JSON
```

**ManifestService** is the canonical example. **Never** short-circuit on cache and skip Supabase entirely.

### 6.4 — Scoring & Exam Logic

- `correct` field on `Question` is a **0-indexed** integer (0=A, 1=B, 2=C, 3=D)
- `userAnswers` is `Map<int, int?>` — question ID → selected option index (or null=skipped)
- Scoring formula: `score = (correctCount × markPerQ) - (wrongCount × negativeMarks)`
- `accuracy` is computed from *answered* questions only (not skipped)

### 6.5 — Option Selection Behavior

Re-tapping an already-selected option deselects it:
```dart
userAnswers[q.id] = isSelected ? null : optIdx;
```

### 6.6 — Timer Contract

> **CRITICAL**: Countdowns **MUST NOT start** before the user presses "Start Test".

Timer is started inside `_beginExam()`, which is called from `addPostFrameCallback` after the first frame renders — never directly in `initState`.

### 6.7 — Question Count Safeguard

For Bookmarked and Custom tests: if available questions < requested count, cap to available and show an explicit warning card on the preview screen. Never crash on empty sets.

---

## 7. Secrets & Security Rules

1. **`.env` is NOT a Flutter asset.** It is NOT listed under `assets:` in `pubspec.yaml`. This was fixed in commit `4de74f3` (SEC-2). Do not re-add it.
2. **Credentials must never be hardcoded** as fallback values (`?? 'hardcoded-key'`) anywhere in Dart source.
3. The `initSupabase()` function in `supabase_client.dart` now **throws** if env vars are missing — this is intentional. It surfaces the problem clearly instead of silently using stale secrets.
4. For production/release APKs: use `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` at build time instead of `.env`.
5. **`.env.example`** exists at the project root as a safe template. Point new developers to it.
6. The `leaderboard` table is Public Read. Before writing `display_name` there, prompt users for consent — they may not want their real name publicly visible.

---

## 8. What to Edit vs. What NOT to Edit

### ✅ Safe to Add / Modify
- New screens in `lib/screens/`
- New providers in `lib/providers/`
- New services in `lib/services/`
- New models in `lib/models/`
- New widgets in `lib/widgets/`
- `roadmap.md` — always update after completing work
- `instruction.md` — update if new rules, patterns, or structural changes happen

### ⛔ Do NOT Modify Without Reading Context First
| File | Why dangerous |
|---|---|
| `lib/core/supabase_client.dart` | Credential init — must not add fallback secrets |
| `lib/core/router.dart` | Auth guards — a wrong redirect breaks all navigation |
| `pubspec.yaml` — `assets:` section | Adding `.env` here re-introduces SEC-2 vulnerability |
| `lib/screens/exam/exam_screen.dart` | Complex state machine — read fully before modifying |
| `lib/providers/auth_provider.dart` | `ref.watch` vs `ref.read` is critical here |
| `lib/models/exam_session.dart` | userAnswers JSON cast is intentionally safe — keep it |

### ⛔ Do NOT Create
- A second exam screen or session manager
- A second router or navigation system
- A global `try { ... } catch (e) {}` wrapper that swallows all errors
- Any file that re-imports `.env` as an asset

---

## 9. Git Commit Protocol (Mandatory)

Every agent working on this codebase MUST follow this protocol after completing any feature, fix, or UI milestone:

```bash
# Step 1 — Verify the build is clean
flutter analyze    # Must output: "No issues found!"

# Step 2 — Stage all changes
git add -A

# Step 3 — Commit with Conventional Commits format
git commit -m "feat(scope): short description

Longer description of what changed and why.
- Bullet point 1
- Bullet point 2

Static analysis: 0 errors, 0 warnings."

# Step 4 — Update roadmap.md to log what was done
# (See roadmap.md §10 and §11 for the format)
```

**Commit message format:**
- `feat(scope):` — new feature
- `fix(scope):` — bug fix
- `fix(security):` — security fix
- `style(scope):` — UI/visual only
- `refactor(scope):` — internal restructuring, no behavior change
- `docs:` — documentation only

---

## 10. Current Project State

**All 13 phases + full security/architecture audit are complete.**

| Area | Status |
|---|---|
| Core exam engine | ✅ Complete |
| All screens (13 screens) | ✅ Complete |
| Security audit (SEC-1/2/3) | ✅ Fixed — commit `4de74f3` |
| Architecture audit (ARCH-1–5) | ✅ Fixed — commit `4de74f3` |
| `flutter analyze` | ✅ 0 errors, 0 warnings |
| `.env` security | ✅ Not bundled as asset |
| Form validation (login) | ✅ Complete |
| WrongQuestion model | ✅ Separate from Bookmark |
| ManifestService | ✅ Stale-while-revalidate |

### For the Next Agent — Do This First:
```bash
git log --oneline -n 10    # See what's been done
git status                  # Confirm clean working tree
flutter analyze             # Confirm 0 issues
```
Then read `roadmap.md` for the current task queue and recommended next steps.
