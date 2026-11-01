# פורטל המנהלת — Flutter entrypoint

Separate app inside the Life repo (does **not** use Life / Nir_DB).

## Run

```bash
# Sync demo passwords from Project store (agent/dev machines only)
dart run tool/sync_demo_passwords.dart /cursor/stores/self/internal/manhelet-demo-auth-credentials.md

flutter run -t lib/main_manhelet.dart -d chrome
# or
flutter build web -t lib/main_manhelet.dart
```

## Config

- `config/supabase_config.dart` — Minhelet URL + **publishable** key only
- `config/demo_passwords.dart` — empty in git; fill via sync tool
- Backend: `qdwuwxqouazqwvsjhobo`

## Architecture

UI → Riverpod providers → domain services (`data/*_service.dart`) → Supabase (RLS enforced).

Life App remains on `lib/main.dart` / Nir_DB.
