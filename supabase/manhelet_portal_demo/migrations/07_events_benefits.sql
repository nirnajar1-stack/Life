-- Manhelet Portal Demo — 07 events & benefits

CREATE TABLE IF NOT EXISTS public.portal_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title_he text NOT NULL,
  description_he text,
  location_he text,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  event_type text NOT NULL DEFAULT 'support_group'
    CHECK (event_type IN ('support_group','briefing','workshop','memorial','admin','other')),
  audience text NOT NULL DEFAULT 'families'
    CHECK (audience IN ('families','staff','mixed','gov')),
  capacity int CHECK (capacity IS NULL OR capacity > 0),
  created_by uuid REFERENCES public.profiles(id),
  is_published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz,
  CHECK (ends_at IS NULL OR ends_at >= starts_at)
);

CREATE INDEX IF NOT EXISTS idx_portal_events_starts ON public.portal_events(starts_at)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_portal_events_updated
  BEFORE UPDATE ON public.portal_events
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.event_registrations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES public.portal_events(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES public.profiles(id),
  person_id uuid REFERENCES public.persons(id),
  status text NOT NULL DEFAULT 'registered'
    CHECK (status IN ('registered','waitlist','attended','cancelled','no_show')),
  registered_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (event_id, profile_id),
  CHECK (profile_id IS NOT NULL OR person_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.benefits (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_he text NOT NULL,
  description_he text,
  owning_agency_id uuid REFERENCES public.government_agencies(id),
  category text NOT NULL DEFAULT 'rights'
    CHECK (category IN ('housing','economic','health','education','rights','psychosocial','other')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE TRIGGER trg_benefits_updated
  BEFORE UPDATE ON public.benefits
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.benefit_entitlements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  benefit_id uuid NOT NULL REFERENCES public.benefits(id),
  person_id uuid REFERENCES public.persons(id),
  family_id uuid REFERENCES public.families(id),
  treatment_unit_id uuid REFERENCES public.treatment_units(id),
  status text NOT NULL DEFAULT 'eligible'
    CHECK (status IN ('eligible','applied','approved','rejected','in_payment','closed')),
  reference_number text,
  notes_he text,
  opened_at date NOT NULL DEFAULT CURRENT_DATE,
  closed_at date,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz,
  CHECK (person_id IS NOT NULL OR family_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_benefit_entitlements_person ON public.benefit_entitlements(person_id)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_benefit_entitlements_updated
  BEFORE UPDATE ON public.benefit_entitlements
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
