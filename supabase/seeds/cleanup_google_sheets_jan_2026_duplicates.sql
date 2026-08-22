-- Cleanup: remove wrongly imported Google Sheets rows (Jan 2026 batch dates).

-- 1) Fixed monthly bills duplicated 3–4× with incorrect January dates.
DELETE FROM public.expenses_new
WHERE source ILIKE '%google%'
  AND is_fixed = 1
  AND created_at >= '2026-01-01' AND created_at < '2026-02-01';

-- 2) Same-day duplicate rows (keep lowest id per name+date+amount).
DELETE FROM public.expenses_new e
USING (
  SELECT id
  FROM (
    SELECT id,
      ROW_NUMBER() OVER (
        PARTITION BY trim(lower(item_name)), created_at::date, round(amount::numeric, 2)
        ORDER BY id
      ) AS rn
    FROM public.expenses_new
    WHERE source ILIKE '%google%'
      AND created_at >= '2026-01-01' AND created_at < '2026-02-01'
  ) d
  WHERE rn > 1
) dup
WHERE e.id = dup.id;
