-- Forward-only nullable behavior type. No historical backfill.
alter table public.expenses_new
  add column if not exists expense_behavior_type text;

do $$ begin
  alter table public.expenses_new
    add constraint expenses_new_behavior_type_check
    check (
      expense_behavior_type is null
      or expense_behavior_type in (
        'fixed_commitment',
        'recurring_variable',
        'variable_discretionary',
        'one_time'
      )
    );
exception when duplicate_object then null;
end $$;

alter table public.recurring_expenses
  add column if not exists expense_behavior_type text;

do $$ begin
  alter table public.recurring_expenses
    add constraint recurring_expenses_behavior_type_check
    check (
      expense_behavior_type is null
      or expense_behavior_type in (
        'fixed_commitment',
        'recurring_variable',
        'variable_discretionary',
        'one_time'
      )
    );
exception when duplicate_object then null;
end $$;
