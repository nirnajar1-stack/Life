-- Manhelet Portal Demo — 03 families / treatment units / persons

CREATE TABLE IF NOT EXISTS public.families (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_code text NOT NULL UNIQUE,
  display_name_he text NOT NULL,
  primary_locality_he text,
  scenario_tag text, -- A–E for demo wiring
  notes_internal text,
  opened_at date NOT NULL DEFAULT CURRENT_DATE,
  closed_at date,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_families_scenario ON public.families(scenario_tag)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_families_updated
  BEFORE UPDATE ON public.families
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.treatment_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id uuid NOT NULL REFERENCES public.families(id),
  unit_code text NOT NULL UNIQUE,
  title_he text NOT NULL,
  status public.treatment_unit_status NOT NULL DEFAULT 'active',
  primary_case_manager_id uuid REFERENCES public.profiles(id),
  secondary_case_manager_id uuid REFERENCES public.profiles(id),
  lead_domain text, -- housing, economic, health, rights, psychosocial, education, other
  opened_at date NOT NULL DEFAULT CURRENT_DATE,
  closed_at date,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz,
  CHECK (
    secondary_case_manager_id IS NULL
    OR secondary_case_manager_id IS DISTINCT FROM primary_case_manager_id
  )
);

CREATE INDEX IF NOT EXISTS idx_treatment_units_family ON public.treatment_units(family_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_treatment_units_pcm ON public.treatment_units(primary_case_manager_id)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_treatment_units_updated
  BEFORE UPDATE ON public.treatment_units
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Gov reps N:M treatment units (after treatment_units exists)
CREATE TABLE IF NOT EXISTS public.gov_rep_treatment_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  government_representative_id uuid NOT NULL
    REFERENCES public.government_representatives(id) ON DELETE CASCADE,
  treatment_unit_id uuid NOT NULL REFERENCES public.treatment_units(id) ON DELETE CASCADE,
  access_level text NOT NULL DEFAULT 'collaborate'
    CHECK (access_level IN ('view', 'collaborate', 'lead_agency')),
  assigned_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  assigned_by uuid REFERENCES public.profiles(id),
  UNIQUE (government_representative_id, treatment_unit_id)
);

CREATE INDEX IF NOT EXISTS idx_gov_rep_units_unit ON public.gov_rep_treatment_units(treatment_unit_id);
CREATE INDEX IF NOT EXISTS idx_gov_rep_units_rep ON public.gov_rep_treatment_units(government_representative_id);

CREATE TABLE IF NOT EXISTS public.persons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  treatment_unit_id uuid NOT NULL REFERENCES public.treatment_units(id),
  family_id uuid NOT NULL REFERENCES public.families(id),
  demo_national_id text NOT NULL, -- fictional DEMO-######## only
  first_name_he text NOT NULL,
  last_name_he text NOT NULL,
  date_of_birth date,
  gender text CHECK (gender IS NULL OR gender IN ('female','male','other','unspecified')),
  status public.person_status NOT NULL,
  relationship_to_index text, -- index_case, spouse, parent, child, sibling, other
  is_index_case boolean NOT NULL DEFAULT false,
  phone text,
  email text,
  locality_he text,
  notes_internal text,
  returned_at date,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz,
  UNIQUE (demo_national_id),
  CONSTRAINT persons_demo_id_format CHECK (demo_national_id ~ '^DEMO-[0-9]{8}$')
);

CREATE INDEX IF NOT EXISTS idx_persons_unit ON public.persons(treatment_unit_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_persons_family ON public.persons(family_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_persons_status ON public.persons(status)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_persons_name_trgm ON public.persons
  USING gin ((first_name_he || ' ' || last_name_he) gin_trgm_ops);

CREATE TRIGGER trg_persons_updated
  BEFORE UPDATE ON public.persons
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Keep persons.family_id aligned with treatment_units.family_id
CREATE OR REPLACE FUNCTION public.enforce_person_family_matches_unit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_family uuid;
BEGIN
  SELECT family_id INTO v_family
  FROM public.treatment_units
  WHERE id = NEW.treatment_unit_id AND deleted_at IS NULL;

  IF v_family IS NULL THEN
    RAISE EXCEPTION 'treatment_unit % missing or deleted', NEW.treatment_unit_id;
  END IF;

  IF NEW.family_id IS DISTINCT FROM v_family THEN
    NEW.family_id := v_family;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_persons_family_match ON public.persons;
CREATE TRIGGER trg_persons_family_match
  BEFORE INSERT OR UPDATE OF treatment_unit_id, family_id ON public.persons
  FOR EACH ROW EXECUTE FUNCTION public.enforce_person_family_matches_unit();

-- Controlled profile ↔ person link (family portal login)
CREATE TABLE IF NOT EXISTS public.profile_person_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  person_id uuid NOT NULL UNIQUE REFERENCES public.persons(id) ON DELETE CASCADE,
  link_reason text NOT NULL DEFAULT 'family_portal',
  verified_at timestamptz,
  created_by uuid REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);
