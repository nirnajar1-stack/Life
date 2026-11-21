-- Manhelet Portal Demo — 06 rehabilitation

CREATE TABLE IF NOT EXISTS public.rehabilitation_plans (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  person_id uuid NOT NULL REFERENCES public.persons(id),
  treatment_unit_id uuid NOT NULL REFERENCES public.treatment_units(id),
  status public.rehab_plan_status NOT NULL DEFAULT 'draft',
  title_he text NOT NULL,
  goals_he text,
  start_date date,
  target_end_date date,
  case_manager_id uuid REFERENCES public.profiles(id),
  agency_id uuid REFERENCES public.government_agencies(id), -- e.g. Bituach Leumi
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_rehab_plans_person ON public.rehabilitation_plans(person_id)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_rehab_plans_updated
  BEFORE UPDATE ON public.rehabilitation_plans
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.enforce_rehab_person_unit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE v_unit uuid;
BEGIN
  SELECT treatment_unit_id INTO v_unit FROM public.persons WHERE id = NEW.person_id AND deleted_at IS NULL;
  IF v_unit IS NULL THEN
    RAISE EXCEPTION 'person missing';
  END IF;
  IF NEW.treatment_unit_id IS DISTINCT FROM v_unit THEN
    RAISE EXCEPTION 'rehab plan treatment_unit must match person.treatment_unit_id';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_rehab_person_unit ON public.rehabilitation_plans;
CREATE TRIGGER trg_rehab_person_unit
  BEFORE INSERT OR UPDATE OF person_id, treatment_unit_id ON public.rehabilitation_plans
  FOR EACH ROW EXECUTE FUNCTION public.enforce_rehab_person_unit();

CREATE TABLE IF NOT EXISTS public.rehabilitation_activities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.rehabilitation_plans(id) ON DELETE CASCADE,
  title_he text NOT NULL,
  activity_type text NOT NULL DEFAULT 'session'
    CHECK (activity_type IN ('session','assessment','group','home_support','medical','vocational','other')),
  scheduled_at timestamptz,
  completed_at timestamptz,
  status text NOT NULL DEFAULT 'planned'
    CHECK (status IN ('planned','done','missed','cancelled')),
  notes_he text,
  facilitator_id uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_rehab_activities_plan ON public.rehabilitation_activities(plan_id)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_rehab_activities_updated
  BEFORE UPDATE ON public.rehabilitation_activities
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.rehab_milestones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.rehabilitation_plans(id) ON DELETE CASCADE,
  title_he text NOT NULL,
  target_date date,
  achieved_at date,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TRIGGER trg_rehab_milestones_updated
  BEFORE UPDATE ON public.rehab_milestones
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
