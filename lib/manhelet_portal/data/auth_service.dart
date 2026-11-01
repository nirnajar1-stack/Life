import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/demo_passwords.dart';
import '../config/demo_users.dart';
import '../domain/models.dart';
import 'portal_client.dart';

class AuthService {
  Session? get currentSession => portalClient.auth.currentSession;

  User? get currentUser => portalClient.auth.currentUser;

  Stream<AuthState> get onAuthStateChange => portalClient.auth.onAuthStateChange;

  Future<void> signIn({required String email, required String password}) async {
    await portalClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => portalClient.auth.signOut();

  /// Authenticates as a seeded demo identity via real Supabase Auth.
  Future<void> signInAsDemo(ManheletDemoUser user) async {
    final password = kManheletDemoPasswords[user.email];
    if (password == null || password.isEmpty) {
      throw StateError(
        'סיסמת הדגמה ל-${user.email} חסרה. הרץ tool/sync_demo_passwords.dart',
      );
    }
    await signIn(email: user.email, password: password);
  }

  Future<PortalProfile?> loadMyProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final profileRow = await portalClient
        .from('profiles')
        .select('id, email, full_name_he, job_title_he')
        .eq('id', uid)
        .maybeSingle();

    if (profileRow == null) return null;

    final roleRows = await portalClient
        .from('user_roles')
        .select('roles(code)')
        .eq('user_id', uid);

    final roles = <AppRole>[];
    for (final row in (roleRows as List)) {
      final rolesNode = row['roles'];
      final code = rolesNode is Map ? rolesNode['code'] as String? : null;
      final parsed = code == null ? null : appRoleFromDb(code);
      if (parsed != null) roles.add(parsed);
    }

    return PortalProfile(
      id: profileRow['id'] as String,
      email: profileRow['email'] as String,
      fullNameHe: profileRow['full_name_he'] as String,
      jobTitleHe: profileRow['job_title_he'] as String?,
      roles: roles,
    );
  }
}
