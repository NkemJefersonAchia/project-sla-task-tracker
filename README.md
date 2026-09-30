# Project & SLA Task Tracker

A Flutter app for a small software team to plan work, assign it, and see at a
glance what is about to slip. Every task is classified automatically as **On
Track**, **At Risk**, **Overdue** or **Completed** from its deadline and its
workflow status.

Built for the Mobile Application Development formative assignment.

---

## Running it

```bash
flutter pub get
flutter run
```

The app targets Android and iOS. It must be run on an emulator or a physical
device — the assignment does not accept a browser build.

```bash
flutter emulators --launch Pixel_8   # or open a simulator
flutter run
```

First launch seeds four team members and eight tasks so the dashboard has
something to show. The deadlines are relative to the day you open it, so all
four SLA states are visible immediately.

### Tests

```bash
flutter test
```

57 tests: the SLA rules, the list search and ordering, the form validators,
and a set of widget tests that drive the real app end to end (sign in, create
a task, complete a task, open the detail screen, reload from storage).

---

## The SLA rules

Implemented in [`lib/services/sla_service.dart`](lib/services/sla_service.dart)
and covered by [`test/sla_service_test.dart`](test/sla_service_test.dart).
Evaluated in this order — the first rule that matches wins.

| # | Rule | Result |
|---|------|--------|
| 1 | The task is marked **Done** | **Completed** |
| 2 | The deadline has passed and the task is not done | **Overdue** |
| 3 | The deadline is inside the priority's warning window | **At Risk** |
| 4 | The task is still **To Do** and the deadline is ≤ 3 days away | **At Risk** |
| 5 | Anything else | **On Track** |

The warning window in rule 3 depends on priority, because important work needs
more notice to recover:

| Priority | Flagged this many days before the deadline |
|----------|--------------------------------------------|
| Urgent   | 4 |
| High     | 3 |
| Medium   | 2 |
| Low      | 1 |

Rule 4 exists because a deadline that still looks comfortable is not
comfortable if nobody has started the work. A low-priority task due in 3 days
would pass rule 3, but if it is still sitting in *To Do* it gets flagged.

Two decisions worth calling out:

- **The SLA is never stored.** It is recomputed from the deadline every time it
  is displayed, so a task that was On Track yesterday is Overdue today without
  anybody editing it.
- **Deadlines are whole days.** `Task.dateOnly` strips the time before
  comparing, so a task due today is not "overdue" at 00:01.

---

## Interface decisions

The screens were deliberately cut back after the first working version. What
was removed, and why:

- **The task row shows a title, an SLA badge, the owner and the deadline.**
  Category and priority moved to the detail screen. Five labels per row meant
  nothing stood out; a list answers "what needs me next", not "tell me
  everything".
- **The dashboard is four counters and the work that needs attention.** A
  proportional SLA bar and a recent-activity feed were both cut - the bar
  restated the counters, and the feed was information nobody acts on. The
  counters are tappable shortcuts into the filtered list, so the dashboard
  leads somewhere.
- **The task list has two controls: search, and the SLA chips.** A
  priority/assignee/sort sheet was built and then removed: on a board this
  size it took three taps to reproduce what the default urgency ordering
  already does for free.
- **Three workflow statuses, not five.** A task is waiting, being worked on,
  or finished. "In Review" and similar are a conversation, not a status field.
- **Category is a dropdown of six options,** replacing a free-text field plus
  a row of suggestion chips. One control instead of seven, one less validation
  path, and the search results stay tidy.

---

## Architecture

```
lib/
├── main.dart                  Start-up: open storage, load repositories, run
├── app.dart                   MaterialApp, theme, initial route
│
├── core/
│   ├── constants/app_routes.dart   Route names + typed route arguments
│   ├── navigation/app_router.dart  onGenerateRoute table
│   ├── theme/                      Colours, spacing, type, ThemeData
│   └── utils/                      Validators, date formatting
│
├── models/                    Task, TeamMember + the three enums
├── services/                  SLA rules, storage, seed data, list query
├── repositories/              Task / member / session data access
├── widgets/                   Widgets shared by more than one screen
└── screens/                   One folder per screen, one file per screen
    ├── auth/sign_in_screen.dart
    ├── dashboard/dashboard_screen.dart
    ├── tasks/task_list_screen.dart
    ├── tasks/task_detail_screen.dart
    ├── tasks/task_form_screen.dart
    ├── team/team_members_screen.dart
    ├── profile/profile_screen.dart
    ├── stats/task_statistics_screen.dart
    └── home_shell.dart        Bottom navigation container
```

A widget used by two or more screens lives in `lib/widgets/`. A widget used by
exactly one screen lives in that screen's own `widgets/` folder. No screen
imports another screen's private widgets.

### State management

Plain `setState`, as the assignment asks for. It works because the
repositories keep the data in memory:

- Every screen reads `TaskRepository.instance.all` **inside `build`**, so it is
  never holding a stale copy.
- After a screen changes something it calls `setState` and then
  `widget.onDataChanged()`, which rebuilds `HomeShell` and therefore all four
  tabs. That is why completing a task in the list immediately moves the
  dashboard counters.
- Navigation results carry the same signal: `Navigator.pushNamed<bool>` returns
  `true` when the form saved or the detail screen deleted something.

The one exception is `ThemeController`, a `ValueNotifier`. The theme is read at
the very top of the tree (`MaterialApp`) but changed from deep inside the
profile screen, and `setState` cannot cross that distance.

### Navigation

Named routes through `onGenerateRoute` (`core/navigation/app_router.dart`),
because two routes take typed arguments. Only a task **id** is ever passed
between screens, never a `Task` object — the destination re-reads it from the
repository so it cannot show a stale copy.

`HomeShell` holds the four tabs in an `IndexedStack`, which keeps each tab's
scroll position and filters alive while you switch between them.

### Persistence: why SharedPreferences and not sqflite

The app stores two small collections that are always read in full and never
queried relationally — the dashboard, the list and the statistics screen all
start from "give me every task" and filter in Dart. A key-value store holding
two JSON documents does that in one read, with no schema and no migrations.
sqflite would only start to pay off with indexed queries or thousands of rows.

Everything goes through `StorageService`, so swapping the backing store later
means rewriting one file.

### Validation

Rules live in `core/utils/validators.dart`, not in the widgets, so the same
rule can be reused and unit tested. Highlights:

- **Title** — required, 3–80 characters after trimming.
- **Category** — required.
- **Assignee** — required, because a task nobody owns can never be chased when
  its SLA turns red.
- **Due date** — required, cannot be in the past, cannot be more than two years
  ahead. The date picker enforces the same window, so the validator is the
  safety net rather than the only defence.
- **Email** — checked against a pattern that catches the realistic typos.
- Leaving the form with unsaved edits asks for confirmation first (`PopScope`).

---

## What is not finished

This is an ~80% build. Three work streams are deliberately left for the rest of
the team — see [TEAM_TASKS.md](TEAM_TASKS.md). The app names them in the UI
rather than hiding them behind buttons that silently do nothing.

| Stream | Area | Status |
|--------|------|--------|
| A | Task statistics screen | Scaffolded; three analyses outstanding |
| B | Team member add / edit / delete | List works, CRUD missing |
| C | Edit profile, appearance, about | Rows present and disabled |

---

## Team

See [TEAM_TASKS.md](TEAM_TASKS.md) for branch names and the split of work, and
[AI_USAGE.md](AI_USAGE.md) for the AI usage declaration.
