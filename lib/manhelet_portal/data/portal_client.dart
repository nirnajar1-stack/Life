import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin accessor — UI must go through domain services, not this directly.
SupabaseClient get portalClient => Supabase.instance.client;
