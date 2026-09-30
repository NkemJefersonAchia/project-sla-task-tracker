import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../models/sla_status.dart';
import 'dashboard/dashboard_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/task_list_screen.dart';
import 'team/team_members_screen.dart';

/// The signed-in container: four destinations behind one bottom bar.
///
/// ## Why an IndexedStack
///
/// All four tabs are built once and kept alive, so switching back to the task
/// list restores its scroll position and its filters instead of rebuilding it
/// from scratch. A `PageView` would animate between them but would also
/// dispose off-screen tabs; for a four-item bottom bar, keeping state is the
/// behaviour users expect.
///
/// ## How the tabs stay in sync
///
/// The repositories hold the data in memory, so every tab reads the same list
/// synchronously inside `build`. When a tab changes something it calls
/// [_handleDataChanged], the shell rebuilds, and all four tabs re-read - which
/// is why completing a task in the list immediately moves the dashboard
/// counters.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  /// Lets the dashboard reach into the already-built task list and apply a
  /// filter to it - tapping the "Overdue" tile jumps to the list showing only
  /// overdue work. A key is the simplest way to call a method on a sibling's
  /// State without introducing a state-management package.
  final _taskListKey = GlobalKey<TaskListScreenState>();

  void _handleDataChanged() {
    if (!mounted) return;
    setState(() {});
  }

  /// Switches to the task list and filters it to [status] in one step.
  void _openTasksFiltered(SlaStatus? status) {
    setState(() => _currentIndex = 1);
    // The list may not exist yet on the very first switch, so the filter is
    // applied after this frame, once the tab has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _taskListKey.currentState?.applySlaFilter(status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinations = <_Destination>[
      const _Destination(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      const _Destination(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: 'Tasks',
      ),
      const _Destination(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Team',
      ),
      const _Destination(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardScreen(
              onDataChanged: _handleDataChanged,
              onOpenTasks: _openTasksFiltered,
            ),
            TaskListScreen(
              key: _taskListKey,
              onDataChanged: _handleDataChanged,
            ),
            TeamMembersScreen(onDataChanged: _handleDataChanged),
            ProfileScreen(onDataChanged: _handleDataChanged),
          ],
        ),
      ),
      bottomNavigationBar: _BottomBar(
        destinations: destinations,
        currentIndex: _currentIndex,
        onSelected: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// A hand-rolled bottom bar.
///
/// Material's own `NavigationBar` carries a tinted pill behind the active
/// item and a tall default height, which fights the flat, hairline-and-text
/// look of the rest of the app. Building the row ourselves is a dozen lines
/// and keeps the navigation visually part of the same product.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.canvas,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var index = 0; index < destinations.length; index++)
                Expanded(
                  child: _BottomBarItem(
                    destination: destinations[index],
                    selected: index == currentIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final color = selected ? c.textPrimary : c.textTertiary;

    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.activeIcon : destination.icon,
              size: 21,
              color: color,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              destination.label,
              style: AppTypography.badge.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
