-- Installment / loan plan headers (charges live in expenses_new).

create table if not exists public.installment_plans (
  id uuid primary key,
  title text not null,
  total_amount numeric not null check (total_amount > 0),
  installments_total integer not null check (installments_total >= 2),
  plan_type text not null default 'purchase'
    check (plan_type in ('purchase', 'loan')),
  category text not null,
  sub_category text not null default 'כללי',
  shared_exp smallint not null default 0,
  first_charge_date date not null,
  purchase_date date not null,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc'::text, now())
);

create index if not exists installment_plans_active_idx
  on public.installment_plans (is_active, created_at desc);

grant select, insert, update, delete on table public.installment_plans
  to anon, authenticated, service_role;
