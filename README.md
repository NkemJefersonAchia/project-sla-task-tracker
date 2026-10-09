# Project & SLA Task Tracker

A Flutter app for a small software team to plan work, assign it to people, and
see at a glance what is about to slip. Every task is classified automatically
as **On Track**, **At Risk**, **Overdue** or **Completed** from its deadline,
priority and workflow status, and the app says *why* it reached that verdict.

Built for the Mobile Application Development group assignment (Trimester 6).
Frontend only: all data lives on the device, with no backend..

---

## Features

**Authentication**
- Sign up and sign in with email and password. Passwords are stored as a salted
  SHA-256 hash, never as plain text.
- The session is remembered, so the app reopens signed in.

**Home**
- A greeting and a one-line headline ("3 tasks need you today").
- The SLA health band: one segmented bar and four counts. Tapping a count opens
  the Tasks tab with that filter applied.
- A time-grouped agenda: Overdue, Due today, This week. Completed work never
  appears here.

**Tasks**
- A list ordered most urgent first, with search across title, category and
  description, and SLA filter chips that show live counts.
- Tick a task to complete it without opening it.
- A detail screen with assignee, due date, priority, an editable status, notes,
  and the SLA verdict with the reason in plain language.
- A create/edit form with validation on every field, a date picker bounded to
  the same window the validator enforces, and a prompt before discarding
  unsaved edits.

**Team**
- Add, edit and remove members with an accent colour. Initials handle Unicode
  names.
- Each member shows their workload, and a sheet lists their tasks.

**Statistics** (reached from Home or Profile)
- On-time delivery rate, with the numerator and denominator spelled out.
- Average days from created to done.
- Workload by member, drawn as one segmented bar per person and scaled against
  the busiest person.
- A two-week deadline histogram, with overdue work collected into its own first
  column.

**Profile**
- Your details, a personal workload summary, edit profile, light/dark/system
  theme (remembered between launches), an about page, and sign out.

**Design**
- Notion-inspired: near-white canvas, hairline borders, no drop shadows, muted
  accent colours, tight type. A full dark theme is included.
- All charts are built from ordinary widgets (`Expanded` flex factors and
  `LayoutBuilder`). There is no charting package.

---

## Running it

You need the Flutter SDK (Dart `^3.13.4`) and an Android emulator, an iOS
simulator or a physical device. A browser build is not the target for this
assignment.

```bash
flutter pub get
flutter run
```

Using an Android emulator:

```bash
flutter emulators --launch <your_avd_name>
flutter run
```

The first launch seeds four team members and eight tasks, with deadlines
relative to the day you open the app, so all four SLA states are visible
straight away.

### Signing in the first time

The four seeded team members are people to assign work to, not accounts, so
they have no password. **Tap "Sign Up" and create your own account.** It joins
the team and can then be assigned tasks.

### Checks

```bash
flutter analyze   # clean
flutter test      # 88 tests, all passing
```

### Troubleshooting: black screen on an emulator

Some x86 Android emulators and older GPUs paint a black screen under Flutter's
Impeller renderer. `android/app/src/main/AndroidManifest.xml` already disables
Impeller on Android (`io.flutter.embedding.android.EnableImpeller` set to
`false`), so the app falls back to Skia. If you still see black after pulling
this change, stop the app completely and run it again: a hot reload does not
pick up manifest changes.

---

## How the SLA engine decides

`lib/services/sla_service.dart` is a pure function with no side effects.
`SlaService.evaluate(task)` returns the status, the days remaining and a
sentence explaining the verdict. `SlaService.summarise(tasks)` counts a list
into the four buckets. The first matching rule wins:

| # | Rule | Result |
|---|------|--------|
| 1 | Marked **Done** | **Completed** |
| 2 | Deadline passed, not done | **Overdue** |
| 3 | Deadline inside the priority's warning window | **At Risk** |
| 4 | Still **To Do** and the deadline is 3 days away or less | **At Risk** |
| 5 | Anything else | **On Track** |

Rule 3's window widens with priority, because important work needs more notice
to recover: Urgent 4 days, High 3, Medium 2, Low 1. Rule 4 exists because a
comfortable-looking deadline is not comfortable if nobody has started.

Two decisions worth knowing:

- **The SLA status is never stored.** It is recomputed every time it is shown,
  so a task that was On Track yesterday is Overdue today without anyone
  touching it.
- **Deadlines are whole days.** `Task.dateOnly` strips the time before
  comparing, so a task due today is not "overdue" at 00:01.

---

## Architecture

```
lib/
├── main.dart                  Open storage, load repositories, run the app
├── app.dart                   MaterialApp, theme, initial route
│
├── core/
│   ├── constants/             Route names
│   ├── navigation/            onGenerateRoute table, Home-to-Tasks filter bridge
│   ├── theme/                 Colours, spacing, type, ThemeData, theme controller
│   └── utils/                 Validators, date formatting
│
├── models/                    Task, TeamMember and the SLA, priority, status enums
├── services/                  SLA rules, storage, seed data, list query, statistics
├── repositories/              Task, member and session data access
├── widgets/                   Shared widgets (cards, buttons, badges, avatars)
└── screens/
    ├── auth/                  Sign in, sign up, password hashing
    ├── home/                  Dashboard
    ├── tasks/                 List, detail, create/edit form
    ├── team/                  Members, member form, per-member task sheet
    ├── stats/                 Statistics and its two hand-built charts
    ├── profile/               Profile, edit profile, settings, about
    └── home_shell.dart        Bottom navigation container (Home, Tasks, Team, Profile)
```

**State management.** Plain `setState`. It is enough because the repositories
are already in memory: a screen reads them synchronously inside `build` and
calls `setState` after a change. There are two small `ValueNotifier`
exceptions: `ThemeController` (the theme is read at the top of the tree but
changed from the Profile tab) and `TasksFilterBridge` (lets Home ask the Tasks
tab to apply a filter).

**Persistence.** `SharedPreferences` holding JSON documents, accessed only
through `StorageService`. It was chosen over `sqflite` because the data is
always read in full and never queried relationally, so there is no schema and
no migration to maintain. The repositories keep data in memory and write every
change through to disk, loaded once in `main()` before the first frame. Reads
are defensive: malformed JSON, a missing key or an unknown enum value falls
back to a safe default instead of stopping the app.

**Navigation.** Named routes with typed arguments that carry ids only, never
whole objects, so a screen always reads fresh data from the repository.

**Validation.** `lib/core/utils/validators.dart` follows Flutter's
`FormFieldValidator` contract (`null` means valid) and covers title,
description, category, assignee, due date, email, password and person name.

**Testing.** 88 tests in `test/` cover the SLA rules, list filtering and
search, statistics, validators, storage failure handling, theme persistence,
the Team workflows and accessibility, and the Home and Tasks screens.

Dependencies: `shared_preferences`, `crypto`, `intl` and `cupertino_icons`.

---

## Team and branches

Four members, each working on their own branch and merging into `main`. The
per-person breakdown of who did what is in the group contribution tracker linked
above.

| Area | Branch |
|------|--------|
| Welcome and sign-in | `feature/welcome-login` |
| Home | `feature/home-tab` |
| Tasks | `feature/tasks-tab` |
| Team | `feature/team-tab` |
| Profile | `feature/profile-tab` |
| Dashboard and chart redesign | `feature/dashboard-redesign` |
| Merged integration | `integration/all-tabs` |

Members: Nkem Jeferson Achia, Ikenna Onugha, Engr Fabrice and andrewthonriem.

An earlier complete version of the app is kept at the tag and branch
`v1-complete-app` (`archive/v1-complete-app`) for reference.

---

## Working on it

- Work on a branch, not directly on `main`.
- Run `flutter analyze` and `flutter test` before every push.
- Keep commits small, with messages that say what changed.
- Use `AppColors.of(context)`, `AppTypography` and `AppSpacing` instead of
  hard-coded colours, text styles or gaps.
- Shared code lives in `lib/core`, `lib/models`, `lib/services`,
  `lib/repositories` and `lib/widgets`. Tell the group before changing it.
- Merge `main` into your branch regularly to avoid large conflicts.

---

## Known limitations

- Data is stored on the device only. There is no sync between devices or users,
  so "the team" on one phone is not the team on another.
- Passwords are hashed locally. That is appropriate for a frontend-only
  coursework app, but it is not a substitute for server-side authentication.
- The seeded members cannot sign in; create an account instead.
- Tested on an Android emulator. The iOS project is present but has not been
  run on a simulator or device.

---

## AI usage

AI assistance is declared in [AI_USAGE.md](AI_USAGE.md) and in the project
report.
