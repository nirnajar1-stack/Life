-- Post-import dedup: July 2026 already tracked in Google Sheets / manual entry.

UPDATE public.recurring_expenses
SET last_generated_month = '2026-07-01'
WHERE last_generated_month IS NULL;

-- Existing Google Sheets installment (4 payments Jul–Aug 2026).
INSERT INTO public.installment_plans (
  id, title, total_amount, installments_total, plan_type,
  category, sub_category, shared_exp, first_charge_date, purchase_date
)
VALUES (
  '9b5defa2-4dc1-bf27-7836-88c03d598e9a',
  'מקלדת ועכבר',
  1200,
  4,
  'purchase',
  'טכנולוגיה וציוד',
  'ציוד',
  0,
  '2026-07-10',
  '2026-07-10'
)
ON CONFLICT (id) DO NOTHING;
