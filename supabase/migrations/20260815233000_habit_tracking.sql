create table if not exists public.habits (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  habit_type text not null default 'boolean',
  target_value numeric,
  unit text,
  cue_trigger text,
  time_of_day text not null default 'anytime',
  frequency text not null default 'daily',
  custom_days integer[] not null default '{}'::integer[],
  interval_days integer not null default 1,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  total_completions integer not null default 0,
  freeze_days_allowed_per_month integer not null default 2,
  freeze_days_used_this_month integer not null default 0,
  freeze_month date,
  archived boolean not null default false,
  created_at timestamptz not null default timezone('utc'::text, now())
);

create table if not exists public.habit_logs (
  id uuid primary key default gen_random_uuid(),
  habit_id uuid not null references public.habits(id) on delete cascade,
  log_date date not null,
  completed boolean not null default false,
  used_freeze boolean not null default false,
  value_recorded numeric,
  notes text,
  unique (habit_id, log_date)
);

alter table public.habits drop constraint if exists habits_type_check;
alter table public.habits add constraint habits_type_check
  check (habit_type in ('boolean', 'measurable'));
alter table public.habits drop constraint if exists habits_time_check;
alter table public.habits add constraint habits_time_check
  check (time_of_day in ('morning', 'afternoon', 'evening', 'anytime'));
alter table public.habits drop constraint if exists habits_frequency_check;
alter table public.habits add constraint habits_frequency_check
  check (frequency in ('daily', 'weekdays', 'specific_days', 'interval'));

create index if not exists habit_logs_habit_date_idx
  on public.habit_logs (habit_id, log_date desc);
create index if not exists habits_archived_idx on public.habits (archived);

grant select, insert, update, delete on table public.habits to anon, authenticated, service_role;
grant select, insert, update, delete on table public.habit_logs to anon, authenticated, service_role;
