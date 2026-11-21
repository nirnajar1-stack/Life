-- Money module: receipt amount breakdown, date provenance, monthly budgets.
-- Backward compatible — existing `amount` stays untouched.

alter table public.expenses_new
  add column if not exists paid_amount numeric,
  add column if not exists gross_amount numeric,
  add column if not exists discount_amount numeric,
  add column if not exists date_source text,
  add column if not exists source_message_timestamp timestamptz,
  add column if not exists extraction_confidence numeric,
  add column if not exists extracted_total_label text;

do $$ begin
  alter table public.expenses_new
    add constraint expenses_new_date_source_check
    check (
      date_source is null
      or date_source in ('receipt', 'telegram', 'manual', 'import', 'legacy')
    );
exception when duplicate_object then null;
end $$;

-- purchase_date is the transaction_date source of truth.
update public.expenses_new
set purchase_date = (created_at at time zone 'UTC')::date
where purchase_date is null;

update public.expenses_new
set date_source = 'legacy'
where date_source is null;

create table if not exists public.monthly_budgets (
  id uuid primary key default gen_random_uuid(),
  year integer not null,
  month integer not null check (month between 1 and 12),
  category text not null,
  budget_amount numeric not null check (budget_amount >= 0),
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  unique (year, month, category)
);

create index if not exists monthly_budgets_year_month_idx
  on public.monthly_budgets (year, month);
