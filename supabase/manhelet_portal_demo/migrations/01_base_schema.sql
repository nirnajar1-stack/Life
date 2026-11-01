-- Manhelet Portal Demo — 01 base schema / extensions / helpers
-- Target: qdwuwxqouazqwvsjhobo (dedicated sandbox)

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
DO $$ BEGIN
  CREATE TYPE public.app_role AS ENUM (
    'super_admin',
    'system_admin',
    'content_editor',
    'content_approver',
    'case_manager',
    'government_representative',
    'department_manager',
    'executive',
    'headquarters_staff',
    'family_member'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.person_status AS ENUM (
    'captive',
    'missing',
    'returned',
    'deceased_confirmed',
    'family_member_only',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.treatment_unit_status AS ENUM (
    'active',
    'on_hold',
    'closed',
    'archived'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.task_status AS ENUM (
    'open',
    'in_progress',
    'waiting_external',
    'waiting_family',
    'blocked',
    'completed',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.task_priority AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.channel_type AS ENUM (
    'family_portal',
    'internal',
    'interagency'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.interaction_type AS ENUM (
    'phone',
    'in_person',
    'video',
    'email',
    'whatsapp',
    'home_visit',
    'hospital_visit',
    'agency_meeting',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.content_status AS ENUM (
    'draft',
    'in_review',
    'approved',
    'published',
    'archived',
    'rejected'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.rehab_plan_status AS ENUM (
    'draft',
    'active',
    'completed',
    'paused',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.notification_channel AS ENUM (
    'in_app',
    'email',
    'sms'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ---------------------------------------------------------------------------
-- updated_at helper
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := timezone('utc', now());
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_updated_at() IS
  'Sets updated_at to UTC now() on row UPDATE.';
