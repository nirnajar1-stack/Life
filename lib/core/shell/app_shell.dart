import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/expenses/presentation/screens/expenses_screen.dart';
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
      ExpensesScreen(),
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

    if (isDesktop) {
      return Scaffold(
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
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet),
                  label: Text('הוצאות'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(index: index, children: pages),
            ),
          ],
        ),
      );
    }

    return Scaffold(
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
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'הוצאות',
          ),
        ],
        onDestinationSelected: (i) {
          ref.read(appTabProvider.notifier).state = AppTab.values[i];
        },
      ),
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
