-- Manhelet Portal Demo — 04 tasks & communication

CREATE TABLE IF NOT EXISTS public.tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_unit_id uuid NOT NULL REFERENCES public.treatment_units(id),
  person_id uuid REFERENCES public.persons(id),
  family_id uuid NOT NULL REFERENCES public.families(id),
  title_he text NOT NULL,
  description_he text,
  status public.task_status NOT NULL DEFAULT 'open',
  priority public.task_priority NOT NULL DEFAULT 'medium',
  domain text, -- housing, economic, health, rights, psychosocial, education, interagency, other
  due_at timestamptz,
  completed_at timestamptz,
  created_by uuid REFERENCES public.profiles(id),
  owning_agency_id uuid REFERENCES public.government_agencies(id),
  scenario_tag text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_tasks_unit_status ON public.tasks(treatment_unit_id, status)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_person ON public.tasks(person_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_due ON public.tasks(due_at) WHERE deleted_at IS NULL AND status NOT IN ('completed','cancelled');
CREATE INDEX IF NOT EXISTS idx_tasks_scenario ON public.tasks(scenario_tag);

CREATE TRIGGER trg_tasks_updated
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.enforce_task_person_unit_match()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_unit uuid;
  v_family uuid;
BEGIN
  SELECT family_id INTO v_family FROM public.treatment_units WHERE id = NEW.treatment_unit_id;
  IF v_family IS NULL THEN
    RAISE EXCEPTION 'invalid treatment_unit_id %', NEW.treatment_unit_id;
  END IF;
  NEW.family_id := v_family;

  IF NEW.person_id IS NOT NULL THEN
    SELECT treatment_unit_id INTO v_unit
    FROM public.persons
    WHERE id = NEW.person_id AND deleted_at IS NULL;
    IF v_unit IS NULL THEN
      RAISE EXCEPTION 'person % missing or deleted', NEW.person_id;
    END IF;
    IF v_unit IS DISTINCT FROM NEW.treatment_unit_id THEN
      RAISE EXCEPTION 'person.treatment_unit_id (%) must match task.treatment_unit_id (%)',
        v_unit, NEW.treatment_unit_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tasks_person_unit ON public.tasks;
CREATE TRIGGER trg_tasks_person_unit
  BEFORE INSERT OR UPDATE OF treatment_unit_id, person_id, family_id ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.enforce_task_person_unit_match();

CREATE TABLE IF NOT EXISTS public.task_assignees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  assigned_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  assigned_by uuid REFERENCES public.profiles(id),
  UNIQUE (task_id, profile_id)
);

CREATE INDEX IF NOT EXISTS idx_task_assignees_profile ON public.task_assignees(profile_id);

CREATE TABLE IF NOT EXISTS public.task_watchers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  profile_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  UNIQUE (task_id, profile_id)
);

CREATE TABLE IF NOT EXISTS public.communication_threads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_type public.channel_type NOT NULL,
  family_id uuid REFERENCES public.families(id),
  treatment_unit_id uuid REFERENCES public.treatment_units(id),
  subject_he text NOT NULL,
  created_by uuid REFERENCES public.profiles(id),
  is_locked boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz,
  CONSTRAINT communication_threads_scope_chk CHECK (
    (channel_type = 'family_portal' AND family_id IS NOT NULL)
    OR (channel_type IN ('internal','interagency') AND treatment_unit_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_comm_threads_family ON public.communication_threads(family_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_comm_threads_unit ON public.communication_threads(treatment_unit_id)
  WHERE deleted_at IS NULL;

CREATE TRIGGER trg_communication_threads_updated
  BEFORE UPDATE ON public.communication_threads
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.communications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES public.communication_threads(id) ON DELETE CASCADE,
  author_id uuid NOT NULL REFERENCES public.profiles(id),
  body_he text NOT NULL,
  is_system boolean NOT NULL DEFAULT false,
  parent_id uuid REFERENCES public.communications(id),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_communications_thread ON public.communications(thread_id, created_at);
CREATE TRIGGER trg_communications_updated
  BEFORE UPDATE ON public.communications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
