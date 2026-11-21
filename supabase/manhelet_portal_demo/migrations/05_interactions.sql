-- Manhelet Portal Demo — 05 interactions

CREATE TABLE IF NOT EXISTS public.interactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_unit_id uuid NOT NULL REFERENCES public.treatment_units(id),
  family_id uuid NOT NULL REFERENCES public.families(id),
  person_id uuid REFERENCES public.persons(id),
  interaction_type public.interaction_type NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  duration_minutes int CHECK (duration_minutes IS NULL OR duration_minutes >= 0),
  summary_he text NOT NULL,
  details_he text,
  conducted_by uuid REFERENCES public.profiles(id),
  related_task_id uuid REFERENCES public.tasks(id),
  visibility text NOT NULL DEFAULT 'internal'
    CHECK (visibility IN ('internal', 'interagency', 'family_visible')),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_interactions_unit_time ON public.interactions(treatment_unit_id, occurred_at DESC)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_interactions_person ON public.interactions(person_id)
  WHERE deleted_at IS NULL;

CREATE TRIGGER trg_interactions_updated
  BEFORE UPDATE ON public.interactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.enforce_interaction_unit_family()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_family uuid;
  v_unit uuid;
BEGIN
  SELECT family_id INTO v_family FROM public.treatment_units WHERE id = NEW.treatment_unit_id;
  IF v_family IS NULL THEN
    RAISE EXCEPTION 'invalid treatment_unit_id %', NEW.treatment_unit_id;
  END IF;
  NEW.family_id := v_family;

  IF NEW.person_id IS NOT NULL THEN
    SELECT treatment_unit_id INTO v_unit FROM public.persons WHERE id = NEW.person_id AND deleted_at IS NULL;
    IF v_unit IS DISTINCT FROM NEW.treatment_unit_id THEN
      RAISE EXCEPTION 'interaction person must belong to treatment_unit';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_interactions_scope ON public.interactions;
CREATE TRIGGER trg_interactions_scope
  BEFORE INSERT OR UPDATE OF treatment_unit_id, person_id, family_id ON public.interactions
  FOR EACH ROW EXECUTE FUNCTION public.enforce_interaction_unit_family();
