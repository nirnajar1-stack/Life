-- Income module: separate ledger from expenses, with recurring salary templates.

create table if not exists public.recurring_incomes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  amount numeric,
  amount_variable boolean not null default true,
  category text not null,
  sub_category text not null default 'כללי',
  day_of_month integer not null default 1 check (day_of_month >= 1 and day_of_month <= 28),
  is_active boolean not null default true,
  start_date date not null default (timezone('utc'::text, now()))::date,
  last_recorded_month date,
  created_at timestamptz not null default timezone('utc'::text, now()),
  constraint recurring_incomes_amount_check
    check (amount_variable or (amount is not null and amount > 0))
);

create table if not exists public.incomes (
  id bigserial primary key,
  created_at timestamptz not null,
  title text not null,
  amount numeric not null check (amount > 0),
  category text not null,
  sub_category text not null default 'כללי',
  income_type text not null default 'variable'
    check (income_type in ('salary', 'variable')),
  source text not null default 'life_app',
  recurring_income_id uuid references public.recurring_incomes(id) on delete set null,
  notes text,
  inserted_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists recurring_incomes_active_idx
  on public.recurring_incomes (is_active, created_at desc);

create index if not exists incomes_created_at_idx
  on public.incomes (created_at desc);

create index if not exists incomes_recurring_idx
  on public.incomes (recurring_income_id)
  where recurring_income_id is not null;

grant select, insert, update, delete on table public.recurring_incomes
  to anon, authenticated, service_role;

grant select, insert, update, delete on table public.incomes
  to anon, authenticated, service_role;

grant usage, select on sequence public.incomes_id_seq
  to anon, authenticated, service_role;
