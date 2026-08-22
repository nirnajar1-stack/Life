-- Recurring expense templates + link from generated charges.

create table if not exists public.recurring_expenses (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  amount numeric not null check (amount > 0),
  category text not null,
  sub_category text not null default 'כללי',
  day_of_month integer not null default 1 check (day_of_month >= 1 and day_of_month <= 28),
  shared_exp smallint not null default 0,
  is_active boolean not null default true,
  start_date date not null default (timezone('utc'::text, now()))::date,
  end_date date,
  last_generated_month date,
  created_at timestamptz not null default timezone('utc'::text, now())
);

alter table public.expenses_new
  add column if not exists recurring_expense_id uuid
  references public.recurring_expenses(id) on delete set null;

create index if not exists recurring_expenses_active_idx
  on public.recurring_expenses (is_active, created_at desc);

create index if not exists expenses_new_recurring_idx
  on public.expenses_new (recurring_expense_id)
  where recurring_expense_id is not null;

grant select, insert, update, delete on table public.recurring_expenses
  to anon, authenticated, service_role;
