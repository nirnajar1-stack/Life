-- Habit lifecycle: difficulty, tracking modes, weekly maintenance logs.
-- Additive only. No user_id (single-user app; habits table has none).

DO $$ BEGIN
  CREATE TYPE public.habit_difficulty AS ENUM ('EASY', 'HARD');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.habit_tracking_mode AS ENUM ('DAILY_ACTIVE', 'WEEKLY_MAINTENANCE', 'ARCHIVED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.weekly_checkin_status AS ENUM ('PERFECT', 'GOOD', 'SLIPPED');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.habits
  ADD COLUMN IF NOT EXISTS difficulty public.habit_difficulty NOT NULL DEFAULT 'EASY';

ALTER TABLE public.habits
  ADD COLUMN IF NOT EXISTS tracking_mode public.habit_tracking_mode NOT NULL DEFAULT 'DAILY_ACTIVE';

ALTER TABLE public.habits
  ADD COLUMN IF NOT EXISTS graduated_at timestamptz DEFAULT NULL;

ALTER TABLE public.habits
  ADD COLUMN IF NOT EXISTS last_relapsed_at timestamptz DEFAULT NULL;

UPDATE public.habits
SET difficulty = 'EASY'
WHERE difficulty IS NULL;

UPDATE public.habits
SET tracking_mode = CASE
  WHEN archived = true THEN 'ARCHIVED'::public.habit_tracking_mode
  ELSE 'DAILY_ACTIVE'::public.habit_tracking_mode
END
WHERE tracking_mode IS NULL
   OR (archived = true AND tracking_mode <> 'ARCHIVED');

CREATE TABLE IF NOT EXISTS public.habit_weekly_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  habit_id uuid NOT NULL REFERENCES public.habits(id) ON DELETE CASCADE,
  week_start_date date NOT NULL,
  status public.weekly_checkin_status NOT NULL,
  notes text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc'::text, now()),
  UNIQUE (habit_id, week_start_date)
);

CREATE INDEX IF NOT EXISTS idx_habits_tracking_mode
  ON public.habits (tracking_mode);

CREATE INDEX IF NOT EXISTS idx_habits_archived_tracking
  ON public.habits (archived, tracking_mode);

CREATE INDEX IF NOT EXISTS idx_weekly_logs_habit_week
  ON public.habit_weekly_logs (habit_id, week_start_date DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.habit_weekly_logs
  TO anon, authenticated, service_role;
