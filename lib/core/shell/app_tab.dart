import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { home, tasks, habits, development, calendar, expenses }

final appTabProvider = StateProvider<AppTab>((ref) => AppTab.home);
