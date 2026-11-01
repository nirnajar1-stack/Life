/// Demo identities (emails + fixed Auth UUIDs). Passwords live only in
/// gitignored [demo_credentials.local.dart].
class ManheletDemoUser {
  const ManheletDemoUser({
    required this.id,
    required this.email,
    required this.labelHe,
    required this.primaryRole,
  });

  final String id;
  final String email;
  final String labelHe;
  final String primaryRole;
}

const List<ManheletDemoUser> kManheletDemoUsers = [
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111103',
    email: 'case.mgr1@manhelet-demo.example',
    labelHe: 'נועה לוי — מנהלת תיק',
    primaryRole: 'case_manager',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111104',
    email: 'case.mgr2@manhelet-demo.example',
    labelHe: 'איתי כהן — מנהל תיק',
    primaryRole: 'case_manager',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111111',
    email: 'gov.btl@manhelet-demo.example',
    labelHe: 'ליאת — נציגת ביטוח לאומי',
    primaryRole: 'government_representative',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111107',
    email: 'executive@manhelet-demo.example',
    labelHe: 'תמר — הנהלה',
    primaryRole: 'executive',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111121',
    email: 'family.cohen@manhelet-demo.example',
    labelHe: 'רותם כהן — משפחה (תרחיש A)',
    primaryRole: 'family_member',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111122',
    email: 'family.levi@manhelet-demo.example',
    labelHe: 'יוסי לוי — משפחה (תרחיש B)',
    primaryRole: 'family_member',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111106',
    email: 'dept.mgr@manhelet-demo.example',
    labelHe: 'רועי — מנהל מחלקה',
    primaryRole: 'department_manager',
  ),
  ManheletDemoUser(
    id: '11111111-1111-4111-8111-111111111102',
    email: 'system.admin@manhelet-demo.example',
    labelHe: 'דני — מנהל מערכת',
    primaryRole: 'system_admin',
  ),
];
