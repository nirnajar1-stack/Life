import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/portal_client.dart';
import '../../domain/providers.dart';

class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionProvider);
    return FutureBuilder(
      future: portalClient.from('v_family_portal_home').select().maybeSingle(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final row = snap.data;
        if (row == null) {
          return const Center(
            child: Text('לא נמצא קישור פרופיל↔אדם למשתמש זה.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'שלום ${row['first_name_he']} ${row['last_name_he']}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('משפחה: ${row['display_name_he']} (${row['family_code']})'),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                title: const Text('בקשות / משימות גלויות'),
                subtitle: Text('${row['visible_open_tasks']} פתוחות'),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('הטבות פתוחות'),
                subtitle: Text('${row['open_benefits']}'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'תקשורת פנימית של צוות המנהלת אינה חשופה בפורטל המשפחות.',
            ),
          ],
        );
      },
    );
  }
}
