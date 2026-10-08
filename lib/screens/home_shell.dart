import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'tasks/tasks_screen.dart';
import 'team/team_screen.dart';

import '../core/navigation/tasks_filter_bridge.dart';
import '../models/sla_status.dart';
/// The container that holds the four tabs behind one bottom bar.
///
/// ## Shared file - change it as little as you can
///
/// Everyone's tab is wired up here, so this is the one file all four of you
/// touch. Swapping your placeholder for your real screen is a one-line change;
/// keep it to that line and the four of you will never conflict here.
///
/// ## Why an IndexedStack
///
/// All four tabs are built once and kept alive, so switching away from a tab
/// and back restores its scroll position and anything the user had typed. A
/// `PageView` would animate between them but would throw that state away.
///
/// Two consequences worth knowing, because they have caught people out:
///  * Every tab is alive at the same time, so if two tabs each have a
///    `FloatingActionButton` they need different `heroTag` values or the app
///    crashes the moment you push a route.
///  * A tab rebuilds whenever the shell rebuilds. If your screen reads from a
///    repository inside `build`, it stays current for free.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _openTasks(SlaStatus? filter) {
    TasksFilterBridge.request(filter);
    setState(() => _currentIndex = 1); // the Tasks tab
  }

  @override
  Widget build(BuildContext context) {
    const destinations = <_Destination>[
      _Destination(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard_rounded,
        label: 'Home',
      ),
      _Destination(
        icon: Icons.check_circle_outline_rounded,
        activeIcon: Icons.check_circle_rounded,
        label: 'Tasks',
      ),
      _Destination(
        icon: Icons.people_outline_rounded,
        activeIcon: Icons.people_rounded,
        label: 'Team',
      ),
      _Destination(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        // Replace your own line here with your real screen, and leave the
        // other three alone.
        children: [
          HomeScreen(onOpenTasks: _openTasks),
          const TasksScreen(),
          const TeamScreen(),
          const ProfileScreen(),
        ],
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
/// Material's own `NavigationBar` puts a tinted pill behind the active item
/// and stands quite tall, which fights the flat, hairline-and-text look the
/// rest of the app is going for. Building the row ourselves is a dozen lines.
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
