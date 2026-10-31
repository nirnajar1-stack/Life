import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../money/money_hub_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/habits/presentation/screens/habits_screen.dart';
import '../../features/personal_dev/presentation/screens/personal_dev_screen.dart';
import '../../features/tasks/domain/models/task_enums.dart';
import '../../features/tasks/domain/providers/task_providers.dart';
import '../../features/tasks/presentation/screens/tasks_list_screen.dart';
import '../home/home_screen.dart';
import '../layout/app_layout.dart';
import '../theme/app_theme.dart';
import 'app_tab.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(appTabProvider);
    final index = tab.index;
    final isDesktop = AppLayout.isDesktop(context);
    final overdue = ref.watch(activeTasksProvider).valueOrNull
            ?.where((task) => task.isOverdue)
            .length ??
        0;

    final pages = const [
      HomeScreen(),
      TasksListScreen(),
      HabitsScreen(),
      PersonalDevScreen(),
      CalendarScreen(),
      MoneyHubScreen(),
    ];
    Widget badgeIcon({
      required IconData outlined,
      required IconData selected,
      required bool isSelected,
    }) {
      final icon = Icon(isSelected ? selected : outlined);
      if (overdue <= 0) return icon;
      return Badge(
        backgroundColor: AppColors.danger,
        label: Text('$overdue'),
        child: icon,
      );
    }

    void openCapture() {
      ref.read(appTabProvider.notifier).state = AppTab.tasks;
      ref.read(tasksWorkspaceViewProvider.notifier).state =
          TasksWorkspaceView.inbox;
      ref.read(captureFocusTickProvider.notifier).state++;
    }

    final scaffold = isDesktop
        ? Scaffold(
            backgroundColor: AppColors.surface,
            body: Row(
              children: [
                NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1180,
                  selectedIndex: index,
                  labelType: MediaQuery.sizeOf(context).width >= 1180
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (i) {
                    ref.read(appTabProvider.notifier).state = AppTab.values[i];
                  },
                  minExtendedWidth: 196,
                  leading: const Padding(
                    padding: EdgeInsets.fromLTRB(12, 20, 12, 16),
                    child: _BrandMark(),
                  ),
                  destinations: [
                    const NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('בית'),
                    ),
                    NavigationRailDestination(
                      icon: badgeIcon(
                        outlined: Icons.checklist_outlined,
                        selected: Icons.checklist_rtl,
                        isSelected: false,
                      ),
                      selectedIcon: badgeIcon(
                        outlined: Icons.checklist_outlined,
                        selected: Icons.checklist_rtl,
                        isSelected: true,
                      ),
                      label: const Text('משימות'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.loop_outlined),
                      selectedIcon: Icon(Icons.loop),
                      label: Text('הרגלים'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.psychology_outlined),
                      selectedIcon: Icon(Icons.psychology),
                      label: Text('פיתוח'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month),
                      label: Text('יומן'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet),
                      label: Text('כסף'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: index, children: pages),
                ),
              ],
            ),
          )
        : Scaffold(
            body: IndexedStack(index: index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'בית',
                ),
                NavigationDestination(
                  icon: badgeIcon(
                    outlined: Icons.checklist_outlined,
                    selected: Icons.checklist_rtl,
                    isSelected: index == 1,
                  ),
                  label: 'משימות',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.loop_outlined),
                  selectedIcon: Icon(Icons.loop),
                  label: 'הרגלים',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.psychology_outlined),
                  selectedIcon: Icon(Icons.psychology),
                  label: 'פיתוח',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month),
                  label: 'יומן',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: 'כסף',
                ),
              ],
              onDestinationSelected: (i) {
                ref.read(appTabProvider.notifier).state = AppTab.values[i];
              },
            ),
          );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            openCapture,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): openCapture,
      },
      child: Focus(autofocus: true, child: scaffold),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final extended = MediaQuery.sizeOf(context).width >= 1180;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        ),
        if (extended) ...[
          const SizedBox(width: 10),
          const Text(
            'ניהול החיים',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ],
      ],
    );
  }
}
