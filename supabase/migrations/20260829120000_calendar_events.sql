-- Calendar events synced from Telegram/n8n → Google Calendar, and created in-app.
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  location text,
  source text not null default 'telegram',
  telegram_chat_id text,
  telegram_message_id text,
  google_event_id text,
  google_calendar_id text,
  raw_text text,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint calendar_events_source_check
    check (source in ('telegram', 'app', 'google', 'n8n')),
  constraint calendar_events_range_check
    check (ends_at > starts_at)
);

create index if not exists calendar_events_starts_at_idx
  on public.calendar_events (starts_at);

create index if not exists calendar_events_source_idx
  on public.calendar_events (source);

create unique index if not exists calendar_events_google_event_uidx
  on public.calendar_events (google_event_id)
  where google_event_id is not null;

grant select, insert, update, delete on table public.calendar_events
  to anon, authenticated, service_role;
