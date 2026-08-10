# UI/UX Improvement Instructions — Mock Master Flutter

Study the existing Flutter application and the `uiux.md` specification carefully before making any changes. The application already uses Material 3, Riverpod, GoRouter, Supabase, local state/offline synchronization, and has defined screens and components. Do not blindly redesign the application or replace the existing architecture. The goal is to improve the UI/UX while preserving all existing functionality, Supabase integration, navigation, state management, exam logic, scoring, and data structures unless a change is genuinely required for the improvement.

## 1. Overall Design Direction

Refine the application toward a polished, modern competitive-exam preparation app rather than a generic educational app. Keep the existing Material 3 foundation, but make the interface cleaner, more focused, less visually crowded, and easier to use during long study sessions.

Use the existing color system as the foundation. Avoid excessive gradients, excessive colors, unnecessary animations, and decorative elements that distract from studying. Use gradients primarily for important hero elements rather than throughout the entire application.

Prioritize:
- Clarity
- Fast navigation
- Low cognitive load
- Touch-friendly controls
- Consistent spacing
- Strong visual hierarchy
- Accessibility
- Mobile-first responsive design
- Clear feedback for every user action
- Excellent exam-taking experience

Do not introduce visual changes merely for the sake of changing things. Every UI change should improve usability or clarity.

## 2. Exam Screen — Highest Priority

The exam screen is the most important part of the application because users will spend most of their time there. Make it the most polished and distraction-free screen.

The exam screen should clearly provide:

- Current question number and total questions
- Countdown timer
- Question text
- Answer options
- Previous
- Save & Next
- Clear Response
- Mark for Review
- Question Palette
- Submit Exam
- Language switcher where applicable

Avoid putting too many controls directly on the screen.

Recommended structure:

```text
┌─────────────────────────────────┐
│ ←  Q 7 / 20       ⏱ 12:43  ⋮  │
├─────────────────────────────────┤
│                                 │
│ Question                        │
│                                 │
│ Question text...                │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ A   Option A                 │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ B   Option B             ✓  │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ C   Option C                 │ │
│ └─────────────────────────────┘ │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ D   Option D                 │ │
│ └─────────────────────────────┘ │
│                                 │
├─────────────────────────────────┤
│ Mark for Review      Clear      │
│                                 │
│ Previous             Save & Next│
└─────────────────────────────────┘
```

Move secondary actions such as language settings, question palette, report question, font size, and other less frequently used controls into an overflow menu or appropriate bottom sheet where doing so improves the layout.

Do not remove important exam functionality merely to simplify the UI.

## 3. Answer Selection Behaviour

Implement and preserve intuitive answer-selection behavior.

Required behavior:

- Tapping an unselected option selects it.
- Tapping the currently selected option again deselects/clears it.
- Selecting another option changes the answer to the new option.
- "Clear Response" explicitly clears the current answer.
- Answer state must persist when navigating between questions.
- Answers must be saved reliably to the active exam session.
- The UI must provide clear visual feedback for selected answers.

Use subtle animations where appropriate, but do not add unnecessary animation that slows down exam navigation.

## 4. Question Palette

Improve the question palette so users can immediately understand the state of every question.

Display clear statistics at the top:

```text
Answered       8
Unanswered     4
Marked         3
Not Visited    5
```

Use a grid of question numbers.

Clearly distinguish:

- Current question
- Answered
- Visited but unanswered
- Marked for review
- Not visited

Do not rely on color alone. Use icons, borders, shapes, or other visual indicators alongside colors for accessibility.

The palette should be fast to open, easy to scan, and easy to navigate.

## 5. Exam Navigation

Implement reliable navigation:

- Previous
- Save & Next
- Submit Exam
- Question Palette
- Mark for Review
- Clear Response

On the final question, "Save & Next" should become "Submit Exam" or provide an equally clear submission action.

Make sure Android back-button behavior is handled correctly.

If the user presses Back during an active exam, show a confirmation dialog:

```text
Exit Test?

Your progress has been saved.

You can resume this test later.

[Continue Test]    [Exit Test]
```

Never silently discard an active test.

## 6. Resumable Exams

Make active exams resilient to accidental app closure, device restart, or temporary interruptions.

If an unfinished exam exists, show an appropriate resume option when the user returns:

```text
Welcome back!

You have an unfinished test.

Electrical Machines
Question 12 / 50
18:34 remaining

[Resume Test]
[Discard]
```

Preserve:

- Current question
- Selected answers
- Marked questions
- Visited questions
- Remaining time
- Language preference
- Other relevant session state

Use the existing session/state architecture where possible rather than creating a second competing state system.

## 7. Submit Confirmation

The submit confirmation should clearly show:

```text
Submit Exam?

Answered          16
Marked for Review  3
Unanswered         4
```

Provide:

- Continue Test
- Confirm Submit

The user must clearly understand that Confirm Submit will finalize the test.

Do not make accidental submission easy.

## 8. Exit and Network Resilience

The exam should be as resilient as possible to network problems.

If the test has already been downloaded and the required data is locally available, users should be able to continue answering questions even if the network temporarily disappears.

Show clear but unobtrusive network state information when useful:

```text
● Offline
Your answers are being saved on this device.
```

When synchronization resumes:

```text
✓ Synced
```

Do not constantly display distracting network messages.

## 9. Dashboard Improvement

Improve the dashboard hierarchy so it answers the user's most important question:

> "What should I study next?"

Make a "Continue Studying" or equivalent card more prominent than decorative statistics.

Recommended hierarchy:

```text
Welcome back, [Name]

Continue Studying
┌──────────────────────────────┐
│ Electrical Machines          │
│ Chapter 7                    │
│ 63% completed                │
│                              │
│              Continue →      │
└──────────────────────────────┘

Today's Goal
32 / 50 questions
████████████░░░

Quick Practice
[Subjects] [Bookmarks]

Recent Tests
...
```

Keep existing dashboard functionality, but improve information hierarchy.

## 10. Daily Goal

Use the existing daily-target functionality more effectively.

Display daily progress prominently:

```text
Today's Goal

32 / 50 questions

██████████████░░░░

18 questions remaining
```

Provide an obvious action to continue practicing.

Do not turn this into excessive gamification.

## 11. Subject Screen

Improve subject discovery.

Keep the existing subject/chapter organization, but add:

- Search
- Clear filtering
- Chapter counts
- Progress where available
- Consistent subject cards
- Easy access to chapter selection

Allow users to search for a subject or chapter such as:

```text
Search subjects or chapters...
```

and quickly reach the relevant content.

## 12. Chapter Cards

Improve chapter cards by showing useful progress information where available.

For example:

```text
AC Fundamentals

438 Questions

Progress
██████████░░░░ 68%

Accuracy: 74%

[Revise] [Start Test]
```

Do not overcrowd cards. Only display metrics that are genuinely useful.

Keep both:

- Revise
- Start Exam

as clearly distinguishable actions.

## 13. Exam Start Screen

Before starting a timed exam, show a concise test overview.

Example:

```text
AC Fundamentals

20 Questions
20 Minutes

+1 Correct
−0.33 Wrong

English + हिन्दी

[Start Test]
```

This gives users a clear understanding of the exam before the timer starts.

Do not start the timer until the user explicitly starts the test.

## 14. Result Screen

Improve the result screen so it is useful for learning, not just displaying a score.

Keep:

- Score
- Accuracy
- Correct
- Wrong
- Skipped
- Review Answers
- Dashboard

Also consider adding:

```text
Time Taken
38:42 / 45:00
```

and useful performance insights:

```text
Your Accuracy       78%
Chapter Average     71%
Your Best           84%
```

Where sufficient data exists, show weak areas:

```text
Needs Improvement

AC Fundamentals       52%
Circuit Laws           61%
Magnetic Circuits     84%
```

Provide an action such as:

```text
Practice Weak Topics
```

Do not fabricate statistics if the required data is unavailable.

## 15. Review Screen

Keep the existing correct/wrong/skipped visual states.

Make the review screen extremely clear:

- Correct answer
- User's selected answer
- Wrong answer
- Skipped question
- Explanation
- Bookmark

Use color plus icons/text so meaning is not dependent on color alone.

Keep explanations collapsed by default if they are long, so users can scan questions quickly.

## 16. Bookmarks

Improve the bookmark experience with:

- Search
- Subject filters
- Chapter filters
- Correct/incorrect/unattempted filters where data exists
- Practice bookmarked questions
- Remove bookmark

Consider providing:

```text
All
Unattempted
Incorrect
Correct
```

Do not add filters that cannot be supported by the existing data.

## 17. Mistakes / Weak Areas

If the existing data architecture can support it, introduce a dedicated learning workflow for questions the user previously answered incorrectly.

For example:

```text
My Practice

📌 Bookmarks
❌ Mistakes
📊 Weak Topics
🕐 Recent Tests
```

Prioritize this over unnecessary gamification because it directly improves exam preparation.

Do not create a new backend structure unless required. Reuse existing history/answer data where possible.

## 18. Report Question

Add a "Report Question" option to the exam/review overflow menu.

Possible reasons:

```text
Incorrect answer
Question is unclear
Typo/error
Duplicate question
Other
```

Allow the user to submit the report.

Do not expose this feature prominently enough to distract from the exam.

## 19. Typography and Accessibility

Maintain the existing typography system but make the exam experience configurable.

Consider:

- Small / Medium / Large question text
- Comfortable line spacing
- Proper Hindi/English rendering
- Adequate contrast
- Minimum touch target sizes
- Clear focus/selected states
- Accessibility-friendly color usage

Do not make the UI unnecessarily dense.

## 20. Bottom Navigation

Review the current five-item bottom navigation and determine whether all five destinations genuinely deserve permanent navigation space.

Do not remove functionality, but consider whether secondary destinations such as Leaderboard can be accessed from Home/Profile instead.

If retaining five destinations, ensure the labels and icons remain readable and usable on smaller Android phones.

## 21. Dark Mode

Keep the existing dark theme.

Avoid pure black backgrounds where possible.

Ensure:

- Selected options remain clearly visible
- Correct/wrong states remain readable
- Borders remain visible
- Text contrast is sufficient
- Timer warnings remain noticeable without being overly bright
- Cards do not become visually heavy

Test both light and dark themes across all major screens.

## 22. Animations

Use animation only when it improves understanding or perceived responsiveness.

Good uses:

- Option selection
- Page transitions
- Progress changes
- Bottom sheets
- Palette opening

Avoid:

- Long animations
- Excessive bouncing
- Decorative animations during exams
- Anything that delays navigation

Exam interactions should feel instantaneous.

## 23. Loading, Empty and Error States

Every data-dependent screen should have appropriate:

- Loading state
- Empty state
- Error state
- Retry action
- Offline state where relevant

Avoid blank screens or infinite loading indicators.

Error messages should explain what happened in simple language and provide an appropriate next action.

## 24. Mobile Responsiveness

The application must work well on:

- Small Android phones
- Standard Android phones
- Large phones
- Portrait orientation
- Landscape where supported

Do not simply scale the desktop layout down.

Design the exam screen specifically for touch-based mobile interaction.

Avoid:

- Text overflow
- Buttons being cut off
- Overlapping elements
- Excessive scrolling
- Tiny controls
- Bottom controls being hidden by Android system navigation

## 25. Visual Consistency

Create and reuse consistent components for:

- Buttons
- Cards
- Chips
- Dialogs
- Option tiles
- Section headers
- Empty states
- Loading states
- Error states
- Progress indicators

Do not implement visually similar components differently in different screens.

## 26. Performance

Do not sacrifice performance for visual effects.

The exam screen should:

- Switch questions quickly
- Scroll smoothly
- Render Markdown efficiently
- Avoid unnecessary rebuilds
- Avoid unnecessary Supabase requests
- Preserve local exam state reliably

Use the existing Riverpod architecture efficiently.

## 27. Important Constraints

Do NOT:

- Rewrite the entire application unnecessarily.
- Replace Riverpod without a strong reason.
- Replace GoRouter without a strong reason.
- Replace Supabase.
- Create a second Supabase project.
- Change database structures unnecessarily.
- Remove existing features.
- Remove offline functionality.
- Add fake statistics.
- Hard-code sensitive credentials.
- Expose Supabase service-role/admin credentials in the Android app.
- Add unnecessary dependencies.
- Add excessive animations.
- Make the exam UI visually cluttered.

Before changing architecture, inspect the existing implementation and determine whether the current architecture can support the desired UX.

## 28. Implementation Process

Work incrementally.

First inspect the existing implementation and compare it with `uiux.md`.

Then:

1. Identify existing UI/UX problems.
2. Create a prioritized implementation plan.
3. Implement the highest-impact improvements first.
4. Test each affected screen.
5. Test both light and dark modes.
6. Test different Android screen sizes.
7. Test exam navigation thoroughly.
8. Test answer selection/deselection.
9. Test Mark for Review.
10. Test Clear Response.
11. Test Save & Next.
12. Test Previous.
13. Test Question Palette.
14. Test Submit and confirmation.
15. Test Android back-button behavior.
16. Test interrupted/resumed exams.
17. Test offline/network recovery.
18. Run `flutter analyze`.
19. Run available automated tests.
20. Build and test the Android APK.

After every meaningful phase, update `roadmap.md` with:

- What was changed
- What was tested
- Any remaining issues
- Important design decisions
- Next recommended tasks

Create meaningful Git commits so another coding agent can understand the progression of the project.

## 29. Final Goal

The goal is not simply to make the application look prettier.

The goal is to create a **fast, clean, reliable and professional competitive-exam preparation app** where:

- Students can quickly find what they want to study.
- Starting a test is straightforward.
- Taking a test is distraction-free.
- Answer state is never accidentally lost.
- Navigation is obvious.
- The question palette is easy to understand.
- Submission is safe and predictable.
- Results provide useful learning insights.
- Weak areas are easy to practice.
- The application works reliably with poor or temporarily unavailable internet.
- The UI feels polished on a real Android phone.

Prioritize **exam usability and reliability over decorative UI changes**. Preserve the existing architecture and backend wherever possible, and make changes incrementally with proper testing and documentation.