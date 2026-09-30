# AI usage declaration

**This file is a starting point. Before submitting, edit it so it describes
what your group actually did — including the parts each of you wrote without
AI. An inaccurate declaration is worse than no declaration.**

---

## What AI was used for

An AI coding assistant (Claude, via Claude Code) was used to produce the first
working version of the application: the project structure, the design system,
the models, the SLA service, the repositories and the six screens, together
with the test suite and this documentation.

## What it was used for specifically

| Area | AI involvement |
|------|----------------|
| Project structure and folder layout | Generated, then reviewed against the assignment brief |
| Design tokens (colours, spacing, type) | Generated from a Notion-inspired brief we gave it |
| Models and JSON serialisation | Generated |
| SLA rules | Rules **decided by the team**, implementation generated |
| Repositories and storage | Generated |
| Screens and widgets | Generated |
| Tests | Generated |

## What was verified and changed

The generated code did not work first time. Running the widget tests surfaced
four genuine defects that were found and fixed before anything was committed:

1. **Duplicate hero tags on the floating action buttons.** The dashboard and
   the task list are both alive inside the shell's `IndexedStack`, so their two
   `FloatingActionButton`s shared Flutter's default hero tag. This threw as
   soon as any route was pushed. Fixed by giving each FAB an explicit
   `heroTag`.
2. **Routes built with the wrong result type.** `onGenerateRoute` returned
   `MaterialPageRoute<dynamic>`, which fails the cast `Navigator.pushNamed<bool>`
   performs to `Route<bool?>`. Fixed by building the two result-returning routes
   as `Route<bool>`.
3. **Infinite height in the dashboard metric grid.** A `Row` with
   `CrossAxisAlignment.stretch` inside a scrolling `ListView` has an unbounded
   vertical constraint and throws. Fixed by wrapping each row in an
   `IntrinsicHeight`.
4. **`EmptyState` used a `Center`**, which has the same unbounded-height
   problem when placed in a `ListView`. Rewritten to size itself to its
   children, with the callers that want centring wrapping it themselves.

Verification performed:

- `flutter analyze` — clean, no warnings.
- `flutter test` — 58 tests passing, including widget tests that drive the real
  app: sign in, create a task, complete a task, open the detail screen and
  reload from storage.
- `flutter build apk --debug` — builds.
- The app was run on an Android emulator and walked through by hand.

## What the team must be able to explain

Every member is responsible for understanding the code they present. Before the
demonstration, make sure you can explain, in your own words:

- The five SLA rules, in order, and why priority changes the warning window.
- Why the SLA status is recomputed rather than stored.
- Why `Task` is immutable and what `copyWith` is for.
- Why `HomeShell` uses an `IndexedStack` and how `onDataChanged` keeps the four
  tabs in step.
- Why only a task id is passed between screens, never a `Task`.
- Why SharedPreferences was chosen over sqflite for this app.
- What each validator rejects and where the rule lives.

## Declaration

We used AI assistance as described above. We have read, run and tested the
submitted code, we found and fixed real defects in it, and we are able to
explain and modify any part of it on request.

_Signed:_ <!-- add each member's name -->
