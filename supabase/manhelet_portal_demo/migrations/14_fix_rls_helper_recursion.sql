-- Fix RLS helper recursion: SECURITY INVOKER helpers that SELECT policy-protected
-- tables re-enter the same policies → stack depth exceeded.
-- Standard Supabase pattern: narrow SECURITY DEFINER authz helpers with fixed search_path.
-- These only return booleans / id sets for the current auth.uid(); they do not expose rows.

CREATE OR REPLACE FUNCTION public.has_app_role(p_role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.user_roles ur
    JOIN public.roles r ON r.id = ur.role_id
    WHERE ur.user_id = auth.uid()
      AND r.code = p_role
      AND (ur.expires_at IS NULL OR ur.expires_at > timezone('utc', now()))
  );
$$;

CREATE OR REPLACE FUNCTION public.is_staff_elevated()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.has_app_role('super_admin')
      OR public.has_app_role('system_admin')
      OR public.has_app_role('executive')
      OR public.has_app_role('department_manager');
$$;

CREATE OR REPLACE FUNCTION public.is_internal_staff()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.is_staff_elevated()
      OR public.has_app_role('case_manager')
      OR public.has_app_role('headquarters_staff')
      OR public.has_app_role('content_editor')
      OR public.has_app_role('content_approver')
      OR public.has_app_role('government_representative');
$$;

CREATE OR REPLACE FUNCTION public.my_family_ids()
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.family_id
  FROM public.profile_person_links l
  JOIN public.persons p ON p.id = l.person_id
  WHERE l.profile_id = auth.uid()
    AND p.deleted_at IS NULL;
$$;

CREATE OR REPLACE FUNCTION public.can_access_treatment_unit(p_unit_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.is_staff_elevated()
    OR public.has_app_role('headquarters_staff')
    OR EXISTS (
      SELECT 1 FROM public.treatment_units tu
      WHERE tu.id = p_unit_id
        AND tu.deleted_at IS NULL
        AND (
          tu.primary_case_manager_id = auth.uid()
          OR tu.secondary_case_manager_id = auth.uid()
        )
    )
    OR EXISTS (
      SELECT 1
      FROM public.gov_rep_treatment_units g
      JOIN public.government_representatives gr ON gr.id = g.government_representative_id
      WHERE g.treatment_unit_id = p_unit_id
        AND gr.profile_id = auth.uid()
        AND gr.deleted_at IS NULL
    )
    OR EXISTS (
      SELECT 1
      FROM public.treatment_units tu
      WHERE tu.id = p_unit_id
        AND tu.family_id IN (SELECT public.my_family_ids())
    );
$$;

CREATE OR REPLACE FUNCTION public.can_access_family(p_family_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    public.is_staff_elevated()
    OR public.has_app_role('headquarters_staff')
    OR p_family_id IN (SELECT public.my_family_ids())
    OR EXISTS (
      SELECT 1 FROM public.treatment_units tu
      WHERE tu.family_id = p_family_id
        AND tu.deleted_at IS NULL
        AND (
          tu.primary_case_manager_id = auth.uid()
          OR tu.secondary_case_manager_id = auth.uid()
          OR EXISTS (
            SELECT 1
            FROM public.gov_rep_treatment_units g
            JOIN public.government_representatives gr ON gr.id = g.government_representative_id
            WHERE g.treatment_unit_id = tu.id
              AND gr.profile_id = auth.uid()
              AND gr.deleted_at IS NULL
          )
        )
    );
$$;

REVOKE ALL ON FUNCTION public.has_app_role(public.app_role) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_staff_elevated() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.is_internal_staff() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.my_family_ids() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_access_treatment_unit(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.can_access_family(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.has_app_role(public.app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff_elevated() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_internal_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_family_ids() TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_treatment_unit(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.can_access_family(uuid) TO authenticated;
