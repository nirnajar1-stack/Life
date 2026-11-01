// ignore_for_file: avoid_print
/// Smoke: real Auth + RLS read against Minhelet project.
/// Requires synced demo_passwords.dart
import 'dart:io';

import 'package:life_app/manhelet_portal/config/demo_passwords.dart';
import 'package:life_app/manhelet_portal/config/supabase_config.dart';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  final client = SupabaseClient(
    ManheletSupabaseConfig.url,
    ManheletSupabaseConfig.publishableKey,
  );
  const email = 'case.mgr1@manhelet-demo.example';
  final password = kManheletDemoPasswords[email];
  if (password == null || password.isEmpty) {
    stderr.writeln('Missing demo password — run tool/sync_demo_passwords.dart');
    exit(1);
  }
  final auth = await client.auth.signInWithPassword(
    email: email,
    password: password,
  );
  stdout.writeln('signed_in=${auth.user?.id}');
  final tasks = await client
      .from('tasks')
      .select('id, title_he, status')
      .isFilter('deleted_at', null)
      .limit(5);
  stdout.writeln('tasks_sample_count=${(tasks as List).length}');
  final units =
      await client.from('v_treatment_unit_caseload').select().limit(3);
  stdout.writeln('units_sample_count=${(units as List).length}');

  // Family user must not see internal thread for unit A via RLS
  await client.auth.signOut();
  const familyEmail = 'family.cohen@manhelet-demo.example';
  final familyPw = kManheletDemoPasswords[familyEmail]!;
  await client.auth.signInWithPassword(email: familyEmail, password: familyPw);
  try {
    final internal = await client
        .from('communication_threads')
        .select('id')
        .eq('channel_type', 'internal')
        .limit(10);
    stdout.writeln('family_internal_threads_visible=${(internal as List).length}');
  } catch (e) {
    stdout.writeln('family_internal_query_error=$e');
  }
  await client.auth.signOut();
  stdout.writeln('smoke_ok');
}
