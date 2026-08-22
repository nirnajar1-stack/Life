-- Allow recurring templates with unknown monthly amount (electricity, water, etc.).

alter table public.recurring_expenses
  add column if not exists amount_variable boolean not null default false;

alter table public.recurring_expenses
  alter column amount drop not null;

alter table public.recurring_expenses
  drop constraint if exists recurring_expenses_amount_check;

alter table public.recurring_expenses
  add constraint recurring_expenses_amount_check
  check (
    (amount_variable = true)
    or (amount is not null and amount > 0)
  );
