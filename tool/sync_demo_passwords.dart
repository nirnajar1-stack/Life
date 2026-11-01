// ignore_for_file: avoid_print
/// Syncs demo passwords from Project store credentials markdown into
/// lib/manhelet_portal/config/demo_passwords.dart (do not commit filled file).
///
/// Usage:
///   dart run tool/sync_demo_passwords.dart /cursor/stores/self/internal/manhelet-demo-auth-credentials.md
import 'dart:io';

void main(List<String> args) {
  final srcPath = args.isNotEmpty
      ? args.first
      : '/cursor/stores/self/internal/manhelet-demo-auth-credentials.md';
  final src = File(srcPath);
  if (!src.existsSync()) {
    stderr.writeln('Missing credentials file: $srcPath');
    exit(1);
  }
  final map = <String, String>{};
  for (final line in src.readAsLinesSync()) {
    if (!line.startsWith('| `')) continue;
    final parts = line.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.length < 3) continue;
    final email = parts[0].replaceAll('`', '');
    final password = parts[2].replaceAll('`', '');
    if (email.contains('@') && password.isNotEmpty && password != '—') {
      map[email] = password;
    }
  }
  final out = File('lib/manhelet_portal/config/demo_passwords.dart');
  final buf = StringBuffer()
    ..writeln('/// GENERATED — do not commit with real passwords.')
    ..writeln('const Map<String, String> kManheletDemoPasswords = {');
  for (final e in map.entries) {
    buf.writeln("  '${e.key}': '${e.value}',");
  }
  buf.writeln('};');
  out.writeAsStringSync(buf.toString());
  stdout.writeln('Wrote ${map.length} passwords to ${out.path}');
}
