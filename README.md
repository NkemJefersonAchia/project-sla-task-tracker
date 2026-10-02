# Project & SLA Task Tracker

A Flutter app for a small software team to plan work, assign it, and see at a
glance what is about to slip. Every task is classified automatically as **On
Track**, **At Risk**, **Overdue** or **Completed** from its deadline and its
workflow status.

Built for the Mobile Application Development formative assignment.

---

## Status: the foundation is built, the screens are not

The data layer, the SLA engine, local storage and the design system are
finished and tested. **Every screen is empty.** Each one is owned by a team
member and built from scratch — see [Who builds what](#who-builds-what).

Open the app and each tab tells you what it is supposed to become.

---

## Running it

```bash
flutter pub get
flutter run
```

Android and iOS. It must run on an emulator or a real device — a browser build
is not accepted for this assignment.

```bash
flutter emulators --launch Pixel_8
flutter run
```

First launch seeds four team members and eight tasks, with deadlines relative
to the day you open it, so all four SLA states are visible straight away.

```bash
flutter analyze   # must be clean before you push
flutter test      # 46 tests, must pass before you push
```

---

## Who builds what

Five areas, one branch each. Everything in `lib/core`, `lib/models`,
`lib/services`, `lib/repositories` and `lib/widgets/common` is shared — use it,
don't rewrite it.

| Area | Branch | Folder |
|------|--------|--------|
| Welcome / sign-in | `feature/welcome-login` | `lib/screens/welcome/` *(create it)* |
| Home | `feature/home-tab` | `lib/screens/home/` |
| Tasks | `feature/tasks-tab` | `lib/screens/tasks/` |
| Team | `feature/team-tab` | `lib/screens/team/` |
| Profile | `feature/profile-tab` | `lib/screens/profile/` |

Each screen file starts with a doc comment describing exactly what to build.
The full brief lives in the handover document.

---

## What already works

### The SLA engine — `lib/services/sla_service.dart`

Call `SlaService.evaluate(task)` and you get back the status, the days
remaining, and a sentence explaining the verdict that you can put straight on
screen. `SlaService.summarise(tasks)` counts a list into the four buckets.

The rules, in order — the first one that matches wins:

| # | Rule | Result |
|---|------|--------|
| 1 | Marked **Done** | **Completed** |
| 2 | Deadline passed, not done | **Overdue** |
| 3 | Deadline inside the priority's warning window | **At Risk** |
| 4 | Still **To Do** and the deadline is ≤ 3 days away | **At Risk** |
| 5 | Anything else | **On Track** |

Rule 3's window widens with priority, because important work needs more notice
to recover: Urgent 4 days, High 3, Medium 2, Low 1.

Rule 4 exists because a deadline that looks comfortable isn't, if nobody has
started. A low-priority task due in 3 days passes rule 3 — but if it is still
sitting in *To Do*, it gets flagged.

Two decisions to be able to explain:

- **The SLA status is never stored.** It is recomputed every time it is shown,
  so a task that was On Track yesterday is Overdue today without anyone
  touching it.
- **Deadlines are whole days.** `Task.dateOnly` strips the time before
  comparing, so a task due today isn't "overdue" at 00:01.

### Data and storage

`TaskRepository`, `MemberRepository` and `SessionRepository` hold everything in
memory and mirror each write to disk. Read them **synchronously inside
`build`** — no `FutureBuilder`, no `async`:

```dart
final tasks = TaskRepository.instance.all;
final counts = SlaService.summarise(tasks);
```

Persistence is SharedPreferences holding two JSON documents. It was chosen over
sqflite because both collections are always read in full and never queried
relationally, so there is no schema and no migrations to maintain. Everything
goes through `StorageService`, so changing that later is a one-file job.

### The design system — `lib/core/theme/`

Notion-inspired: a near-white canvas, 1px hairline borders, no drop shadows,
muted accent colours used as a foreground/background pair, tight letter
spacing. There is a full dark theme and it already works.

```dart
final c = AppColors.of(context);   // resolves light/dark for you
```

Never write a hex value in a screen. Never build a `TextStyle` inline — use
`AppTypography`. Never invent a gap — use `AppSpacing`.

### Shared widgets — `lib/widgets/`

`AppCard`, `PrimaryButton`, `SecondaryButton`, `SlaBadge`, `ToneBadge`,
`MemberAvatar`, `SectionHeader`, `PropertyRow`, `EmptyState`, `AppFeedback`
(snack bars and confirm dialogs).

Build your screen out of these. A widget only you use lives in your own
`screens/<your-tab>/widgets/` folder; one that two tabs need moves up to
`lib/widgets/common/` — tell the others when you move something there.

### Validation — `lib/core/utils/validators.dart`

Title, description, category, assignee, due date, email, password, person name.
They follow Flutter's `FormFieldValidator` contract: `null` means valid.

---

## Project layout

```
lib/
├── main.dart                  Start-up: open storage, load repositories, run
├── app.dart                   MaterialApp, theme, initial route
│
├── core/
│   ├── constants/app_routes.dart   Route names
│   ├── navigation/app_router.dart  onGenerateRoute table
│   ├── theme/                      Colours, spacing, type, ThemeData
│   └── utils/                      Validators, date formatting
│
├── models/                    Task, TeamMember + the three enums
├── services/                  SLA rules, storage, seed data, list query
├── repositories/              Task / member / session data access
├── widgets/common/            Widgets shared across tabs
└── screens/
    ├── home_shell.dart        The bottom navigation container (shared)
    ├── home/                  ← Home owner
    ├── tasks/                 ← Tasks owner
    ├── team/                  ← Team owner
    └── profile/               ← Profile owner
```

---

## State management

Plain `setState`, as the assignment requires. It works because the repositories
are already in memory: read them inside `build`, call `setState` after you
change something, and the screen is correct.

The one exception is `ThemeController`, a `ValueNotifier`. The theme is read at
the very top of the tree (`MaterialApp`) but changed from inside the Profile
tab, and `setState` cannot reach that far.

---

## Shared files — coordinate before you edit

Four of these, and they are where merge conflicts will come from:

- `lib/screens/home_shell.dart` — swapping your placeholder for your real
  screen is **one line**. Keep it to that line.
- `lib/core/constants/app_routes.dart` and `lib/core/navigation/app_router.dart`
  — add your routes in one small commit on day one and push it immediately.
- `lib/widgets/common/` — tell the group before you add or change anything here.

Merge `main` into your branch every day. A branch that has not seen `main` in a
week is a bad afternoon waiting to happen.

---

## Rules for everyone

- Work on your own branch. Never commit directly to `main`.
- `flutter analyze` clean and `flutter test` passing before every push.
- Small commits, real messages: `add SLA filter chips to task list`, not
  `update`.
- Add a test for anything with logic in it. `test/` has the pattern.
- Delete your tab's `TabPlaceholder` as soon as you have something real.
- You explain your own screen in the demo video. Everyone speaks.

## Recovering the earlier version

A complete working version of this app exists at the tag `v1-complete-app` if
you ever need to see one way of solving a screen:

```bash
git show v1-complete-app:lib/screens/tasks/task_list_screen.dart
```

Read it for ideas, but write your own — you have to explain your code on
camera, and the marks are for what you understand, not what you copy.

---

## Team

Work split and individual contributions are tracked in the group contribution
tracker. [AI_USAGE.md](AI_USAGE.md) carries the AI usage declaration.
