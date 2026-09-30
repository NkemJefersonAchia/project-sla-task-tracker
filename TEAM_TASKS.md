# Work split

The app is roughly 80% built. What exists is finished and tested; what is left
is described below, one work stream per person, with the seams already in
place.

## How we work

- One branch per person: `feature/<name>-<stream>`, e.g. `feature/amara-stats`.
- Branch off `main`, rebase or merge `main` in before opening a pull request.
- Small commits with real messages. `fix task list overflow on narrow screens`,
  not `update`.
- `flutter analyze` must be clean and `flutter test` must pass before a PR.
- Add a test for anything with logic in it. The existing tests in `test/` are
  the pattern to copy.

---

## Stream A — Task statistics

**Files:** `lib/screens/stats/task_statistics_screen.dart`

The screen is routable and already renders the SLA split and the workflow
counts. Three analyses are outstanding; every input they need is already
exposed.

1. **On-time delivery rate.** Of the tasks that are Done, what share had
   `completedAt` on or before `dueDate`. Show the percentage with the
   numerator and denominator underneath.
2. **Workload by member.** One horizontal bar per member from
   `TaskRepository.instance.byAssignee(id)`, segmented by SLA state.
   `SlaBreakdownBar` can be reused almost unchanged.
3. **Upcoming deadlines.** The next five incomplete tasks sorted by `dueDate`,
   each with its SLA badge. `TaskListTile` already renders the row.

No chart package needed — `SlaBreakdownBar` shows how far plain layout widgets
go. Delete the `_TodoCard` placeholders as each one lands.

**Useful:** `SlaService.summarise(tasks)`, `Task.completedAt`, `Task.dueDate`.

---

## Stream B — Team member management

**Files:** `lib/screens/team/team_members_screen.dart`,
`lib/repositories/member_repository.dart`, plus a new
`lib/screens/team/member_form_screen.dart`

Listing members and drilling into their workload is done. Missing:

1. **Add a member.** A form screen with name, role, email and an accent colour
   picker. `StatusColors.memberColorKeys` is the list of colours;
   `MemberRepository.instance.newId()` generates the id;
   `MemberRepository.instance.save(member)` writes it.
2. **Edit a member.** Same form, pre-filled. `TeamMember.copyWith` is there.
3. **Delete a member.** `MemberRepository` has no `delete` yet, on purpose:
   decide first what happens to the tasks they own. Either unassign them
   (`task.copyWith(assigneeId: '')` — the UI already renders "Unassigned") or
   refuse the delete while they hold open work. Whichever you choose, say why
   in the PR.
4. Add the route to `AppRoutes` and `AppRouter`, and a `+` action in the app
   bar. Remove the `UnbuiltFeatureNotice` from the screen when it is done.

**Validation to reuse:** `Validators.personName`, `Validators.email`.

---

## Stream C — Profile, appearance and about

**Files:** `lib/screens/profile/profile_screen.dart`, plus new screens

Three rows in the settings card are rendered but disabled. Each has a `TODO`
at the call site.

1. **Edit profile.** A form for the signed-in member's name, role and accent
   colour, saved with `MemberRepository.instance.save()`. The change should be
   visible immediately everywhere, because every screen resolves members
   through the repository rather than caching them.
2. **Appearance.** A light / dark / system selector.
   `ThemeController.instance` already loads, saves and applies the mode — this
   row only needs the UI wired to `setMode()`. Check both themes while you are
   in there; the palette has a dark variant for every colour.
3. **About.** A short page describing the SLA rules and the team. The rules
   table in `README.md` is the content.

Remove the `UnbuiltFeatureNotice` and the `trailingNote` labels as each row
starts working.

---

## Shared conventions

**Colours.** Never write a hex value in a screen. `AppColors.of(context)` gives
the palette and resolves light/dark automatically. Anything that maps a domain
value to a colour goes in `StatusColors`.

**Spacing.** Use the `AppSpacing` scale. If a gap needs a value that is not on
the scale, that is usually a sign the layout wants rethinking.

**Text.** Use `AppTypography`. Do not build `TextStyle`s inline.

**Where a widget lives.** Used by two or more screens → `lib/widgets/`. Used by
exactly one → that screen's own `widgets/` folder.

**Storage.** Everything goes through `StorageService`. Add new keys to
`StorageKeys` so two features cannot collide on the same string.

**Errors.** Wrap storage writes in `try`/`catch (StorageException)` and report
through `AppFeedback.showError`. Destructive actions go through
`AppFeedback.confirm` first.

**State.** `setState` plus `widget.onDataChanged()` after anything that writes.
Do not add a state-management package — the assignment asks for `setState`.
