# Manhelet Portal Demo — SQL package

Isolated from Life App migrations under `supabase/migrations/`.

Apply **in order** against Supabase project `qdwuwxqouazqwvsjhobo` only:

```bash
export DATABASE_URL='postgresql://postgres.<ref>:<DB_PASSWORD>@...:5432/postgres'
for f in migrations/*.sql; do psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"; done
```

Or paste each file in the Supabase SQL Editor.

Docs live in the Project store: `docs/manhelet-portal-demo/`.
