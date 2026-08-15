/// Supabase connection settings for the Life App project (Nir_DB).
///
/// The publishable/anon key is safe to ship in client apps — access is
/// controlled by Row Level Security on the database side.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://grxumlgwgzmnnpxlgzah.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdyeHVtbGd3Z3ptbm5weGxnemFoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MzA0MDYsImV4cCI6MjA5NDAwNjQwNn0.NQDZSO176anvgI6eyQZe0udmzpR_g7qtHwsdCWAuy5M';

  /// Public Web Push VAPID key. The matching private key lives in
  /// `private.app_secrets` and is used only by the Edge Function.
  static const String vapidPublicKey =
      'BMgriNu3_f7uUfjioxPZ__1deLIb8pYlCvEIb2vjFOQv8ySXFmrKt88ceX9-LqhtkN2nEWXJ6eRid63iFGZvhsA';
}
