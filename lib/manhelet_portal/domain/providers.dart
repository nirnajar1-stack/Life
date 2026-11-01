import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';
import '../data/caseload_service.dart';
import '../data/content_service.dart';
import '../data/notification_service.dart';
import '../data/task_service.dart';
import 'models.dart';

final authServiceProvider = Provider((ref) => AuthService());
final taskServiceProvider = Provider((ref) => TaskService());
final caseloadServiceProvider = Provider((ref) => CaseloadService());
final notificationServiceProvider = Provider((ref) => NotificationService());
final contentServiceProvider = Provider((ref) => ContentService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthStateChange;
});

final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentSession;
});

final myProfileProvider = FutureProvider<PortalProfile?>((ref) async {
  ref.watch(sessionProvider);
  return ref.watch(authServiceProvider).loadMyProfile();
});

enum TaskCenterViewMode { byTasks, byUnits }

final taskCenterViewModeProvider =
    StateProvider<TaskCenterViewMode>((ref) => TaskCenterViewMode.byTasks);

final taskFiltersProvider =
    StateProvider<TaskFilters>((ref) => const TaskFilters());

final tasksProvider = FutureProvider.autoDispose<List<PortalTask>>((ref) {
  final filters = ref.watch(taskFiltersProvider);
  return ref.watch(taskServiceProvider).listTasks(filters: filters);
});

final myUnitsProvider =
    FutureProvider.autoDispose<List<TreatmentUnitSummary>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(caseloadServiceProvider).listMyUnits();
});

final familiesProvider =
    FutureProvider.family.autoDispose<List<FamilySummary>, String>((ref, search) {
  ref.watch(sessionProvider);
  return ref.watch(caseloadServiceProvider).listFamilies(search: search);
});

final notificationsProvider =
    FutureProvider.autoDispose<List<PortalNotification>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(notificationServiceProvider).listMine();
});

final publishedContentProvider =
    FutureProvider.autoDispose<List<ContentItem>>((ref) {
  ref.watch(sessionProvider);
  return ref.watch(contentServiceProvider).listPublished();
});

final selectedTaskIdProvider = StateProvider<String?>((ref) => null);
