# 🎨 Mock Master Flutter — UI & UX Architecture Reference

> **Document Version:** 1.0.0  
> **Target Audience:** Developers, Designers, Product Managers  
> **Application Path:** `/home/reed/Coding/Mock-Master-V0/mock_master_flutter/`  
> **Design Language:** Google Material Design 3 (Material 3 Expressive)  

---

## 📋 Table of Contents

1. [Design System & Theme Architecture](#1-design-system--theme-architecture)
2. [User Experience (UX) Flow & Routing](#2-user-experience-ux-flow--routing)
3. [State Management & Data Lifecycle](#3-state-management--data-lifecycle)
4. [Screen-by-Screen UI & UX Specifications](#4-screen-by-screen-ui--ux-specifications)
   - [4.1 Auth & Login Screen (`login_screen.dart`)](#41-auth--login-screen-loginscreendart)
   - [4.2 Dashboard Screen (`dashboard_screen.dart`)](#42-dashboard-screen-dashboardscreendart)
   - [4.3 Subjects Catalog (`subjects_screen.dart`)](#43-subjects-catalog-subjectsscreendart)
   - [4.4 Chapter Browser (`chapters_screen.dart`)](#44-chapter-browser-chaptersscreendart)
   - [4.5 Exam Engine (`exam_screen.dart`)](#45-exam-engine-examscreendart)
   - [4.6 Submit Confirmation Modal](#46-submit-confirmation-modal)
   - [4.7 Result Analytics (`result_screen.dart`)](#47-result-analytics-resultscreendart)
   - [4.8 Question Review Screen (`review_screen.dart`)](#48-question-review-screen-reviewscreendart)
   - [4.9 Bookmarks Manager (`bookmarks_screen.dart`)](#49-bookmarks-manager-bookmarksscreendart)
   - [4.10 Leaderboard Screen (`leaderboard_screen.dart`)](#410-leaderboard-screen-leaderboardscreendart)
   - [4.11 Settings & Profile (`settings_screen.dart`)](#411-settings--profile-settingsscreendart)
5. [Component Inventory & Visual States](#5-component-inventory--visual-states)
6. [Developer Customization Guide](#6-developer-customization-guide)

---

## 1. Design System & Theme Architecture

The UI is built on a **Material 3 Design System** implemented in [`lib/core/app_theme.dart`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/lib/core/app_theme.dart).

### 1.1 Color Tokens

| Semantic Token | Light Mode Hex | Dark Mode Hex | Usage Purpose |
|---|---|---|---|
| **Primary Indigo** | `#4F46E5` | `#6366F1` | Primary buttons, active tabs, progress rings |
| **Secondary Violet** | `#7C3AED` | `#A78BFA` | Accent cards, secondary action chips |
| **Emerald Success** | `#10B981` | `#10B981` | Correct answers, Submit button, positive score |
| **Amber Warning** | `#F59E0B` | `#F59E0B` | Mark for Review flags, low timer warnings (<60s) |
| **Rose Alert** | `#EF4444` | `#EF4444` | Wrong options, Clear Response, negative marking |
| **Surface** | `#FFFFFF` | `#1E293B` | Card backgrounds, dialogs, bottom sheets |
| **Background** | `#F8FAFC` | `#0F172A` | Scaffold background color |
| **Border Line** | `#E2E8F0` | `#334155` | Card outlines, dividers |

### 1.2 Typography Hierarchy

- **Font Family:** `GoogleFonts.inter()`
- **Headings (`titleLarge`, `headlineSmall`):** Bold (700), size 20–24px, tight tracking (`-0.5px`).
- **Subheadings (`titleMedium`):** Semi-bold (600), size 16–18px.
- **Body Text (`bodyMedium`):** Regular (400), size 14–16px, line height `1.5` for legibility.
- **Question Text:** Adjustable font size (default 16.0px) configured in AppSettings.

### 1.3 Card & Elevation Standards

- **Border Radius:** `16px` for standard cards, `20px` for hero banners, `12px` for buttons.
- **Outlines:** `1px` subtle border line (`#E2E8F0` light / `#334155` dark) instead of heavy drop shadows for a modern aesthetic.

---

## 2. User Experience (UX) Flow & Routing

Navigation is configured declaratively using `GoRouter` in [`lib/core/router.dart`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/lib/core/router.dart).

```mermaid
flowchart TD
    A[App Launch] --> B{Authenticated?}
    B -- No --> C[/login - Login / Register Screen\]
    B -- Yes --> D[ShellRoute / AppShell]
    
    D --> E[/dashboard - Home Dashboard]
    D --> F[/subjects - Subject Catalog]
    D --> G[/bookmarks - Bookmarks Manager]
    D --> H[/leaderboard - Global Rankings]
    D --> I[/settings - User Profile & Prefs]
    
    F --> J[/subjects/:id/chapters - Chapter List]
    J --> K[/exam - Active Exam Engine]
    K --> L[/result - Result Summary & Analytics]
    L --> M[/review - Detailed Question Review]
    M --> F
```

### 2.1 Navigation Shell (`AppBottomNav`)

The bottom navigation bar uses Material 3 `NavigationBar` with 5 primary destinations:
1. 🏠 **Home (`/dashboard`)**: Daily progress summary & quick actions.
2. 📚 **Subjects (`/subjects`)**: Subject index & chapter selection.
3. 🔖 **Bookmarks (`/bookmarks`)**: Saved question repository.
4. 🏆 **Rankings (`/leaderboard`)**: Global leaderboards & streaks.
5. 👤 **Settings (`/settings`)**: Dark mode toggle, daily target, sign out.

---

## 3. State Management & Data Lifecycle

State is managed using **Riverpod** providers in `lib/providers/`:

| Provider | Type | Storage & Sync Responsibility |
|---|---|---|
| `authProvider` | `StreamProvider<User?>` | Listens to Supabase Auth state (`onAuthStateChange`) |
| `settingsProvider` | `StateNotifierProvider` | Local `SharedPreferences` + Supabase `users` table sync |
| `subjectsProvider` | `AsyncNotifierProvider` | Fetches `admin_manifest` -> Falls back to `assets/data/manifest.json` |
| `sessionProvider` | `StateNotifierProvider` | Active exam state (timer, answers, marked, visited) |
| `historyProvider` | `StateNotifierProvider` | Attempt history list stored locally & synced to `history` table |
| `bookmarksProvider` | `StateNotifierProvider` | Saved questions list synced to `bookmarks` table |
| `syncProvider` | Provider | Merges local offline storage with Supabase cloud database upon login |

---

## 4. Screen-by-Screen UI & UX Specifications

---

### 4.1 Auth & Login Screen (`login_screen.dart`)

- **Header:** "Mock Master" logo badge + Subtitle *"AI-Powered Exam Preparation"*.
- **Tabs:** Animated Toggle Pill between **Sign In** and **Create Account**.
- **Form Inputs:**
  - Full Name field (signup mode only).
  - Email address input with format validation.
  - Password input (obscured, min 8 chars for signup).
- **CTA:** Full-width `FilledButton` with loading indicator spinner during network requests.
- **Top Bar Action:** Theme toggle button (Sun/Moon icon) top-right.

---

### 4.2 Dashboard Screen (`dashboard_screen.dart`)

- **Hero Header Banner:**
  - Gradient background (Indigo to Deep Violet).
  - User avatar with initial + greeting *"Welcome back, [UserName]"*.
  - Floating Hero Stat Container: **Subjects Count**, **Chapters Count**, **Accuracy %**.
- **Practice Modes Grid:**
  - 4 quick launcher cards with icon badges:
    - 🧭 **Browse Subjects** -> Navigate to `/subjects`.
    - 🔖 **Bookmarks** -> Navigate to `/bookmarks`.
    - 🏆 **Leaderboard** -> Navigate to `/leaderboard`.
    - ⚙️ **Settings** -> Navigate to `/settings`.
- **Recent History Section:**
  - Last 5 test attempts displayed as cards with chapter name, subject, and color-coded score badges:
    - 🟢 **Green (>=75%)**: High performance badge.
    - 🟡 **Amber (50%-74%)**: Moderate score.
    - 🔴 **Red (<50%)**: Needs review.
- **FAB:** Floating Action Button *"Start Test"* anchored bottom right.

---

### 4.3 Subjects Catalog (`subjects_screen.dart`)

- **AppBar:** *"Explore Subjects"* + Refresh Index icon button.
- **Subject Cards:**
  - Custom category gradient header accent per subject:
    - **History:** Indigo accent (`#4F46E5`).
    - **Polity:** Emerald accent (`#10B981`).
    - **Geography:** Amber accent (`#F59E0B`).
  - Circular emoji icon badge (🏛️, ⚖️, 🌍).
  - Chapter count badge (*"X Chapters Available"*).
  - Sub-subject filter pills (*"Ancient History"*, *"Medieval History"*, *"Modern History"*).
  - Arrow indicator trailing right.
- **Pull-to-Refresh:** Pull down to re-sync manifest catalog from Supabase.

---

### 4.4 Chapter Browser (`chapters_screen.dart`)

- **AppBar:** Subject title + sub-caption showing total chapter count.
- **Sub-Subject Filter Chips:** Horizontal scrolling `FilterChip` row (*"All Topics"*, *"Topic 1"*, *"Topic 2"*).
- **Chapter Cards:**
  - Numerical index badge container (`1`, `2`, `3`).
  - Chapter title + Sub-subject tag.
  - Dual Action Buttons:
    - 📖 **"Revise"** (`OutlinedButton`): Launches untimed study mode.
    - ▶️ **"Start Exam"** (`FilledButton`): Launches full timed exam mode.

---

### 4.5 Exam Engine (`exam_screen.dart`)

The core exam taking interface:

- **Top AppBar:**
  - Chapter title.
  - 🌐 **Bilingual Toggle Button**: Toggles question & options text between **English** and **हिन्दी**.
  - ⏱️ **Countdown Timer Chip**: Displays remaining time (`MM:SS`). Turns **solid red** when `< 60s`.
  - 🟢 **Explicit "Submit" Button**: Green button top-right to submit exam at any moment.
- **Sub-Header Bar:**
  - Progress pill: *"Q 1 / 15"*.
  - Flag indicator pill (shown when question is marked for review).
  - 🔳 **"Palette" Button**: Opens the Question Palette drawer.
- **Question Area (`PageView`):**
  - **Question Text:** Formatted GFM Markdown rendered via `MarkdownText`.
  - **Option Tiles (`OptionTile`):**
    - Prefix badges (**A**, **B**, **C**, **D**).
    - **Deselect on Re-tap Logic:** Tapping an already selected option **deselects/clears** the choice (`userAnswers[q.id] = null`).
- **Bottom Navigation Bar:**
  - **Top Action Row:**
    - 🧹 **"Clear Response"** (`OutlinedButton`, Red): Clears selected option for current question.
    - 🚩 **"Mark for Review"** (`OutlinedButton`, Amber): Toggles review flag for current question.
  - **Bottom Navigation Row:**
    - ◀️ **"Previous"**: Moves to previous question.
    - ▶️ **"Save & Next" / "Submit Exam"**: Advances to next question (or opens submit modal on last question).

---

### 4.6 Submit Confirmation Modal

Triggered by clicking **"Submit"** in the top bar or **"Submit Exam"** on the final question:

- **Title:** Icon + *"Submit Exam?"*.
- **Content:** Breakdown container showing real-time question statistics:
  - 🟢 **Answered Questions:** `X`
  - 🟡 **Marked for Review:** `Y`
  - ⚪ **Unanswered Questions:** `Z`
- **Actions:**
  - `OutlinedButton`: *"Continue Test"* (closes modal).
  - `FilledButton` (Green): *"Confirm Submit"* (finalizes test and calculates score).

---

### 4.7 Result Analytics (`result_screen.dart`)

- **Hero Ring Score:** Large circular progress ring displaying score achieved vs max score (`Score: 18.5 / 20`).
- **Accuracy Badge:** Percentage accuracy pill (`Accuracy: 92.5%`).
- **Stat Chips Row:**
  - 🟢 Correct Count chip.
  - 🔴 Wrong Count chip.
  - ⚪ Skipped Count chip.
- **Performance Badge:** Dynamic header (*"Masterful Performance! 🏆"* for >=90%, *"Great Job! ⭐"* for >=75%).
- **Actions:**
  - 🔍 **"Review Answers"** (`FilledButton`): Opens detailed question review screen.
  - 🏠 **"Go to Dashboard"** (`OutlinedButton`): Returns to home screen.

---

### 4.8 Question Review Screen (`review_screen.dart`)

- **Header Bar:** Title + Language switcher (EN/HI).
- **Question Review Cards:**
  - Status Indicator Badge (Green checkmark for Correct, Red X for Wrong, Grey dash for Skipped).
  - Question text rendered in Markdown.
  - 4 Option tiles highlighting answer states:
    - 🟢 **Green background:** Correct Answer (always highlighted).
    - 🔴 **Red background:** User's Wrong selection (if chosen).
  - 💡 **Expandable Explanation Box**: Tap to expand detailed answer rationale formatted in Markdown.
  - 🔖 Bookmark icon toggle per question.

---

### 4.9 Bookmarks Manager (`bookmarks_screen.dart`)

- **Grouped Display:** Bookmarks organized by Subject -> Chapter.
- **Question Preview:** Shows preview text of bookmarked questions.
- **Actions:**
  - Remove Bookmark button (`Trash` icon).
  - ▶️ **"Practice Bookmarks"** button: Starts a custom test generated exclusively from your bookmarked question set.

---

### 4.10 Leaderboard Screen (`leaderboard_screen.dart`)

- **Header:** Trophy badge + global rankings subtitle.
- **User Rank Card:** Highlighted top card showing current user's global rank & score.
- **Ranked User List:**
  - 🥇 1st Place (Gold Badge).
  - 🥈 2nd Place (Silver Badge).
  - 🥉 3rd Place (Bronze Badge).
  - 4th-20th Place tiles displaying Display Name, Total Correct, and Accuracy %.

---

### 4.11 Settings & Profile (`settings_screen.dart`)

- **User Profile Card:** User Avatar + Display Name + Email.
- **Dark Mode Switch Tile:** Instant toggle between Light and Dark themes.
- **Daily Target Tile:** Opens interactive slider dialog (5 to 100 questions per day).
- **Sign Out Button:** Red logout action with exit confirmation dialog.

---

## 5. Component Inventory & Visual States

| Widget Component | File Path | States & Behaviour |
|---|---|---|
| `OptionTile` | `lib/widgets/option_tile.dart` | Normal (outlined), Selected (filled primary), Correct (green fill), Incorrect (red fill). Re-tap deselects. |
| `MarkdownText` | `lib/widgets/markdown_text.dart` | Renders GFM tables, bold text, blockquotes, code blocks. Uses dynamic font size from `AppSettings`. |
| `QuestionPalette` | `lib/screens/exam/question_palette.dart` | Bottom sheet grid. Colors: Grey (unvisited), White/Outline (visited unanswered), Indigo (answered), Amber (marked for review). |
| `AppBottomNav` | `lib/widgets/app_bottom_nav.dart` | Material 3 `NavigationBar`. 5 destinations with distinct outline vs filled rounded icons. |
| `EmptyState` | `lib/widgets/empty_state.dart` | Displays icon, title, subtitle, and optional action button for empty lists/error views. |
| `LoadingWidget` | `lib/widgets/loading_widget.dart` | Centered `CircularProgressIndicator` with optional status label text. |

---

## 6. Developer Customization Guide

### 6.1 Changing Color Themes

Modify the color tokens in [`lib/core/app_theme.dart`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/lib/core/app_theme.dart):

```dart
class AppTheme {
  static const primaryIndigo = Color(0xFF4F46E5); // Change primary theme color
  static const secondaryViolet = Color(0xFF7C3AED); // Change secondary accent
}
```

### 6.2 Modifying Exam Scoring Rules

Scoring formulas are calculated in [`lib/screens/exam/exam_screen.dart`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/lib/screens/exam/exam_screen.dart#L90-L105):

```dart
final score = (correct * session.positiveMarks) - (wrong * session.negativeMarks);
```
Default marks per question are fetched from the chapter data (`positiveMarks: 1.0`, `negativeMarks: 0.33`).

### 6.3 Adding Local Fallback Subject & Chapter Data

To add new offline fallback subjects or chapters:
1. Edit [`mock_master_flutter/assets/data/manifest.json`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/assets/data/manifest.json) to declare the new subject or chapter.
2. Add the corresponding JSON file under [`mock_master_flutter/assets/data/SubjectFolder/chapter.json`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/assets/data/).
3. Ensure the folder is listed under `assets:` in [`pubspec.yaml`](file:///home/reed/Coding/Mock-Master-V0/mock_master_flutter/pubspec.yaml).

---

*Documentation maintained by Antigravity Assistant. For further questions, inspect [`roadmap.md`](file:///home/reed/Coding/Mock-Master-V0/roadmap.md).*
