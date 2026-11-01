import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'manhelet_portal/config/supabase_config.dart';
import 'manhelet_portal/presentation/router.dart';
import 'manhelet_portal/presentation/theme/portal_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    initializeDateFormatting('he'),
    Supabase.initialize(
      url: ManheletSupabaseConfig.url,
      publishableKey: ManheletSupabaseConfig.publishableKey,
    ),
  ]);

  runApp(const ProviderScope(child: ManheletPortalApp()));
}

class ManheletPortalApp extends ConsumerWidget {
  const ManheletPortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(portalRouterProvider);
    return MaterialApp.router(
      title: 'פורטל המנהלת',
      debugShowCheckedModeBanner: false,
      theme: PortalTheme.light(),
      locale: const Locale('he', 'IL'),
      supportedLocales: const [Locale('he', 'IL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: router,
    );
  }
}
