import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { home, tasks, expenses }

final appTabProvider = StateProvider<AppTab>((ref) => AppTab.home);
