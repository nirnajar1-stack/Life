import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/providers.dart';
import 'auth/login_screen.dart';
import 'dashboard/case_manager_home.dart';
import 'executive/executive_screen.dart';
import 'families/families_screen.dart';
import 'family_portal/family_home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'shell/portal_shell.dart';
import 'tasks/task_center_screen.dart';
import 'tasks/task_detail_panel.dart';
import 'units/units_screens.dart';

final _rootKey = GlobalKey<NavigatorState>();

final portalRouterProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final loggedIn = session != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn && !loggingIn) return '/login';
      if (loggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => PortalShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const CaseManagerHome()),
          GoRoute(
            path: '/family-home',
            builder: (_, __) => const FamilyHomeScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => TaskCenterScreen(
              openCompose: state.uri.queryParameters['compose'] == '1',
            ),
            routes: [
              GoRoute(
                path: ':taskId',
                builder: (context, state) => TaskDetailPage(
                  taskId: state.pathParameters['taskId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/families',
            builder: (_, __) => const FamiliesScreen(),
            routes: [
              GoRoute(
                path: ':familyId',
                builder: (context, state) => FamilyDetailScreen(
                  familyId: state.pathParameters['familyId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/units',
            builder: (_, __) => const UnitsListScreen(),
            routes: [
              GoRoute(
                path: ':unitId',
                builder: (context, state) => UnitDetailScreen(
                  unitId: state.pathParameters['unitId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/persons/:personId',
            builder: (context, state) => PersonProfileScreen(
              personId: state.pathParameters['personId']!,
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/executive',
            builder: (_, __) => const ExecutiveScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen(sessionProvider, (_, __) => notifyListeners());
  }

  final Ref ref;
}
