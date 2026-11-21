-- Manhelet Portal Demo — 02 users & roles & org skeleton

CREATE TABLE IF NOT EXISTS public.organizational_units (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_he text NOT NULL,
  name_en text,
  parent_id uuid REFERENCES public.organizational_units(id),
  unit_type text NOT NULL DEFAULT 'department'
    CHECK (unit_type IN ('directorate','department','team','desk','external')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE TRIGGER trg_organizational_units_updated
  BEFORE UPDATE ON public.organizational_units
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY, -- matches auth.users.id when provisioned
  email text NOT NULL UNIQUE,
  full_name_he text NOT NULL,
  phone text,
  organizational_unit_id uuid REFERENCES public.organizational_units(id),
  job_title_he text,
  is_active boolean NOT NULL DEFAULT true,
  locale text NOT NULL DEFAULT 'he',
  last_login_at timestamptz,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_profiles_org_unit ON public.profiles(organizational_unit_id)
  WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_name_trgm ON public.profiles USING gin (full_name_he gin_trgm_ops);

CREATE TRIGGER trg_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code public.app_role NOT NULL UNIQUE,
  name_he text NOT NULL,
  description_he text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role_id uuid NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  granted_by uuid REFERENCES public.profiles(id),
  granted_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  expires_at timestamptz,
  UNIQUE (user_id, role_id)
);

CREATE INDEX IF NOT EXISTS idx_user_roles_user ON public.user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_role ON public.user_roles(role_id);

CREATE TABLE IF NOT EXISTS public.government_agencies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  name_he text NOT NULL,
  name_en text,
  contact_email text,
  contact_phone text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE TRIGGER trg_government_agencies_updated
  BEFORE UPDATE ON public.government_agencies
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.government_representatives (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id uuid NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  agency_id uuid NOT NULL REFERENCES public.government_agencies(id),
  title_he text,
  desk_phone text,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE TRIGGER trg_government_representatives_updated
  BEFORE UPDATE ON public.government_representatives
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Seed canonical roles (idempotent)
INSERT INTO public.roles (id, code, name_he, description_he) VALUES
  ('a1000000-0000-4000-8000-000000000001', 'super_admin', 'מנהל על', 'גישה מלאה למערכת'),
  ('a1000000-0000-4000-8000-000000000002', 'system_admin', 'מנהל מערכת', 'ניהול משתמשים והרשאות'),
  ('a1000000-0000-4000-8000-000000000003', 'content_editor', 'עורך תוכן', 'יצירה ועריכת תוכן ארגוני'),
  ('a1000000-0000-4000-8000-000000000004', 'content_approver', 'מאשר תוכן', 'אישור ופרסום תוכן'),
  ('a1000000-0000-4000-8000-000000000005', 'case_manager', 'מנהל תיק / מלווה', 'ניהול יחידות טיפול ומשימות'),
  ('a1000000-0000-4000-8000-000000000006', 'government_representative', 'נציג ממשלתי', 'גישה ליחידות משויכות ובין-משרדי'),
  ('a1000000-0000-4000-8000-000000000007', 'department_manager', 'מנהל מחלקה', 'ניהול צוות ומבט מחלקתי'),
  ('a1000000-0000-4000-8000-000000000008', 'executive', 'הנהלה', 'תמונת מצב ודוחות'),
  ('a1000000-0000-4000-8000-000000000009', 'headquarters_staff', 'מטה המנהלת', 'עובדי מטה כלליים'),
  ('a1000000-0000-4000-8000-00000000000a', 'family_member', 'בן/בת משפחה', 'פורטל משפחות')
ON CONFLICT (code) DO NOTHING;
