import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models.dart';
import '../../domain/providers.dart';
import '../theme/portal_theme.dart';

class PortalShell extends ConsumerWidget {
  const PortalShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 960;
    final location = GoRouterState.of(context).uri.toString();

    final destinations = _destinationsFor(profile);

    if (!desktop) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('פורטל המנהלת'),
          actions: [
            IconButton(
              tooltip: 'התראות',
              onPressed: () => context.go('/notifications'),
              icon: const Icon(Icons.notifications_outlined),
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'logout') {
                  await ref.read(authServiceProvider).signOut();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  enabled: false,
                  child: Text(profile?.fullNameHe ?? ''),
                ),
                const PopupMenuItem(value: 'logout', child: Text('התנתקות')),
              ],
            ),
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex(location, destinations),
          onDestinationSelected: (i) => context.go(destinations[i].path),
          destinations: [
            for (final d in destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: width >= 1200,
            selectedIndex: _selectedIndex(location, destinations),
            onDestinationSelected: (i) => context.go(destinations[i].path),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              child: Column(
                children: [
                  Text(
                    'פורטל המנהלת',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: PortalColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (profile != null)
                    Text(
                      profile.fullNameHe,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: PortalColors.muted),
                    ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'התנתקות',
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _titleFor(location),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'התראות',
                          onPressed: () => context.go('/notifications'),
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                        if (profile != null)
                          Chip(
                            label: Text(
                              profile.roles.isEmpty
                                  ? 'משתמש'
                                  : appRoleLabelHe(profile.roles.first),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _selectedIndex(String location, List<_NavDest> dests) {
    final i = dests.indexWhere((d) => location.startsWith(d.path));
    return i < 0 ? 0 : i;
  }

  String _titleFor(String location) {
    if (location.startsWith('/tasks')) return 'מרכז המשימות';
    if (location.startsWith('/families')) return 'משפחות';
    if (location.startsWith('/units')) return 'יחידות טיפול';
    if (location.startsWith('/notifications')) return 'התראות';
    if (location.startsWith('/executive')) return 'תמונת מצב';
    if (location.startsWith('/family-home')) return 'הבית שלי';
    return 'סביבת העבודה שלי';
  }

  List<_NavDest> _destinationsFor(PortalProfile? profile) {
    if (profile == null) {
      return const [_NavDest('/home', 'בית', Icons.home_outlined)];
    }
    if (profile.isFamily) {
      return const [
        _NavDest('/family-home', 'הבית שלי', Icons.home_outlined),
        _NavDest('/notifications', 'התראות', Icons.notifications_outlined),
      ];
    }
    if (profile.isGovRep && !profile.isCaseManager) {
      return const [
        _NavDest('/home', 'התכלול שלי', Icons.dashboard_outlined),
        _NavDest('/tasks', 'משימות', Icons.task_alt_outlined),
        _NavDest('/units', 'יחידות', Icons.groups_outlined),
        _NavDest('/notifications', 'התראות', Icons.notifications_outlined),
      ];
    }
    final list = <_NavDest>[
      const _NavDest('/home', 'סביבת העבודה', Icons.dashboard_outlined),
      const _NavDest('/tasks', 'משימות', Icons.task_alt_outlined),
      const _NavDest('/families', 'משפחות', Icons.family_restroom),
      const _NavDest('/units', 'יחידות', Icons.groups_outlined),
      const _NavDest('/notifications', 'התראות', Icons.notifications_outlined),
    ];
    if (profile.isExecutive) {
      list.add(
        const _NavDest('/executive', 'הנהלה', Icons.insights_outlined),
      );
    }
    return list;
  }
}

class _NavDest {
  const _NavDest(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}
