-- Manhelet Portal Demo — 11 RLS + invoker helpers (no broad SECURITY DEFINER)

CREATE OR REPLACE FUNCTION public.current_profile_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.has_app_role(p_role public.app_role)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY INVOKER
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
SECURITY INVOKER
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
SECURITY INVOKER
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
SECURITY INVOKER
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
SECURITY INVOKER
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
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT
    public.is_staff_elevated()
    OR public.has_app_role('headquarters_staff')
    OR p_family_id IN (SELECT public.my_family_ids())
    OR EXISTS (
      SELECT 1 FROM public.treatment_units tu
      WHERE tu.family_id = p_family_id
        AND public.can_access_treatment_unit(tu.id)
    );
$$;

-- ---------------------------------------------------------------------------
-- Enable RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.organizational_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.government_agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.government_representatives ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.treatment_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gov_rep_treatment_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.persons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profile_person_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_assignees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_watchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communication_threads ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.communications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rehabilitation_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rehabilitation_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rehab_milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.portal_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.benefits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.benefit_entitlements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------------
-- Policies (drop+create for idempotency)
-- ---------------------------------------------------------------------------

-- roles: readable by authenticated
DROP POLICY IF EXISTS roles_select ON public.roles;
CREATE POLICY roles_select ON public.roles FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS roles_admin_write ON public.roles;
CREATE POLICY roles_admin_write ON public.roles FOR ALL TO authenticated
  USING (public.has_app_role('super_admin') OR public.has_app_role('system_admin'))
  WITH CHECK (public.has_app_role('super_admin') OR public.has_app_role('system_admin'));

-- profiles
DROP POLICY IF EXISTS profiles_select ON public.profiles;
CREATE POLICY profiles_select ON public.profiles FOR SELECT TO authenticated
  USING (
    id = auth.uid()
    OR public.is_internal_staff()
  );

DROP POLICY IF EXISTS profiles_update_self ON public.profiles;
CREATE POLICY profiles_update_self ON public.profiles FOR UPDATE TO authenticated
  USING (id = auth.uid() OR public.has_app_role('system_admin') OR public.has_app_role('super_admin'))
  WITH CHECK (id = auth.uid() OR public.has_app_role('system_admin') OR public.has_app_role('super_admin'));

DROP POLICY IF EXISTS profiles_admin_insert ON public.profiles;
CREATE POLICY profiles_admin_insert ON public.profiles FOR INSERT TO authenticated
  WITH CHECK (public.has_app_role('system_admin') OR public.has_app_role('super_admin'));

-- user_roles
DROP POLICY IF EXISTS user_roles_select ON public.user_roles;
CREATE POLICY user_roles_select ON public.user_roles FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR public.is_staff_elevated() OR public.has_app_role('system_admin'));

DROP POLICY IF EXISTS user_roles_admin ON public.user_roles;
CREATE POLICY user_roles_admin ON public.user_roles FOR ALL TO authenticated
  USING (public.has_app_role('system_admin') OR public.has_app_role('super_admin'))
  WITH CHECK (public.has_app_role('system_admin') OR public.has_app_role('super_admin'));

-- org units & agencies: staff read; admins write
DROP POLICY IF EXISTS org_units_select ON public.organizational_units;
CREATE POLICY org_units_select ON public.organizational_units FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND (public.is_internal_staff() OR public.has_app_role('family_member')));

DROP POLICY IF EXISTS org_units_admin ON public.organizational_units;
CREATE POLICY org_units_admin ON public.organizational_units FOR ALL TO authenticated
  USING (public.has_app_role('system_admin') OR public.has_app_role('super_admin'))
  WITH CHECK (public.has_app_role('system_admin') OR public.has_app_role('super_admin'));

DROP POLICY IF EXISTS agencies_select ON public.government_agencies;
CREATE POLICY agencies_select ON public.government_agencies FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND public.is_internal_staff());

DROP POLICY IF EXISTS agencies_admin ON public.government_agencies;
CREATE POLICY agencies_admin ON public.government_agencies FOR ALL TO authenticated
  USING (public.is_staff_elevated())
  WITH CHECK (public.is_staff_elevated());

DROP POLICY IF EXISTS gov_reps_select ON public.government_representatives;
CREATE POLICY gov_reps_select ON public.government_representatives FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND (profile_id = auth.uid() OR public.is_internal_staff()));

DROP POLICY IF EXISTS gov_reps_admin ON public.government_representatives;
CREATE POLICY gov_reps_admin ON public.government_representatives FOR ALL TO authenticated
  USING (public.is_staff_elevated())
  WITH CHECK (public.is_staff_elevated());

-- families / units / persons
DROP POLICY IF EXISTS families_select ON public.families;
CREATE POLICY families_select ON public.families FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND public.can_access_family(id));

DROP POLICY IF EXISTS families_write_staff ON public.families;
CREATE POLICY families_write_staff ON public.families FOR ALL TO authenticated
  USING (public.is_staff_elevated() OR public.has_app_role('case_manager') OR public.has_app_role('headquarters_staff'))
  WITH CHECK (public.is_staff_elevated() OR public.has_app_role('case_manager') OR public.has_app_role('headquarters_staff'));

DROP POLICY IF EXISTS units_select ON public.treatment_units;
CREATE POLICY units_select ON public.treatment_units FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND public.can_access_treatment_unit(id));

DROP POLICY IF EXISTS units_write ON public.treatment_units;
CREATE POLICY units_write ON public.treatment_units FOR ALL TO authenticated
  USING (
    public.is_staff_elevated()
    OR primary_case_manager_id = auth.uid()
    OR secondary_case_manager_id = auth.uid()
    OR public.has_app_role('headquarters_staff')
  )
  WITH CHECK (
    public.is_staff_elevated()
    OR public.has_app_role('case_manager')
    OR public.has_app_role('headquarters_staff')
  );

DROP POLICY IF EXISTS gov_rep_units_select ON public.gov_rep_treatment_units;
CREATE POLICY gov_rep_units_select ON public.gov_rep_treatment_units FOR SELECT TO authenticated
  USING (
    public.is_staff_elevated()
    OR public.can_access_treatment_unit(treatment_unit_id)
  );

DROP POLICY IF EXISTS gov_rep_units_write ON public.gov_rep_treatment_units;
CREATE POLICY gov_rep_units_write ON public.gov_rep_treatment_units FOR ALL TO authenticated
  USING (public.is_staff_elevated() OR public.has_app_role('case_manager'))
  WITH CHECK (public.is_staff_elevated() OR public.has_app_role('case_manager'));

DROP POLICY IF EXISTS persons_select ON public.persons;
CREATE POLICY persons_select ON public.persons FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND public.can_access_treatment_unit(treatment_unit_id));

DROP POLICY IF EXISTS persons_write ON public.persons;
CREATE POLICY persons_write ON public.persons FOR ALL TO authenticated
  USING (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id))
  WITH CHECK (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id));

DROP POLICY IF EXISTS ppl_select ON public.profile_person_links;
CREATE POLICY ppl_select ON public.profile_person_links FOR SELECT TO authenticated
  USING (profile_id = auth.uid() OR public.is_staff_elevated() OR public.has_app_role('system_admin'));

DROP POLICY IF EXISTS ppl_admin ON public.profile_person_links;
CREATE POLICY ppl_admin ON public.profile_person_links FOR ALL TO authenticated
  USING (public.has_app_role('system_admin') OR public.has_app_role('super_admin'))
  WITH CHECK (public.has_app_role('system_admin') OR public.has_app_role('super_admin'));

-- tasks
DROP POLICY IF EXISTS tasks_select ON public.tasks;
CREATE POLICY tasks_select ON public.tasks FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND public.can_access_treatment_unit(treatment_unit_id)
    AND (
      NOT public.has_app_role('family_member')
      OR public.has_app_role('case_manager')
      OR public.is_staff_elevated()
      OR EXISTS (
        -- family sees only tasks flagged family-visible via metadata
        SELECT 1 WHERE COALESCE(metadata->>'family_visible','false') = 'true'
      )
    )
  );

DROP POLICY IF EXISTS tasks_write ON public.tasks;
CREATE POLICY tasks_write ON public.tasks FOR ALL TO authenticated
  USING (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id))
  WITH CHECK (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id));

DROP POLICY IF EXISTS task_assignees_all ON public.task_assignees;
CREATE POLICY task_assignees_all ON public.task_assignees FOR ALL TO authenticated
  USING (
    profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id AND public.can_access_treatment_unit(t.treatment_unit_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id AND public.is_internal_staff()
        AND public.can_access_treatment_unit(t.treatment_unit_id)
    )
  );

DROP POLICY IF EXISTS task_watchers_all ON public.task_watchers;
CREATE POLICY task_watchers_all ON public.task_watchers FOR ALL TO authenticated
  USING (
    profile_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id AND public.can_access_treatment_unit(t.treatment_unit_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id AND public.is_internal_staff()
        AND public.can_access_treatment_unit(t.treatment_unit_id)
    )
  );

-- communications: channel separation
DROP POLICY IF EXISTS threads_select ON public.communication_threads;
CREATE POLICY threads_select ON public.communication_threads FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND (
      (channel_type = 'family_portal'
        AND family_id IS NOT NULL
        AND (family_id IN (SELECT public.my_family_ids()) OR public.is_internal_staff()))
      OR (channel_type = 'internal'
        AND public.is_internal_staff()
        AND treatment_unit_id IS NOT NULL
        AND public.can_access_treatment_unit(treatment_unit_id)
        AND NOT (public.has_app_role('family_member') AND NOT public.has_app_role('case_manager') AND NOT public.is_staff_elevated() AND NOT public.has_app_role('headquarters_staff') AND NOT public.has_app_role('government_representative')))
      OR (channel_type = 'interagency'
        AND treatment_unit_id IS NOT NULL
        AND public.can_access_treatment_unit(treatment_unit_id)
        AND (public.has_app_role('government_representative') OR public.has_app_role('case_manager') OR public.is_staff_elevated() OR public.has_app_role('headquarters_staff')))
    )
  );

DROP POLICY IF EXISTS threads_write ON public.communication_threads;
CREATE POLICY threads_write ON public.communication_threads FOR ALL TO authenticated
  USING (
    (channel_type = 'family_portal' AND (family_id IN (SELECT public.my_family_ids()) OR public.is_internal_staff()))
    OR (channel_type IN ('internal','interagency') AND public.is_internal_staff())
  )
  WITH CHECK (
    (channel_type = 'family_portal' AND (family_id IN (SELECT public.my_family_ids()) OR public.is_internal_staff()))
    OR (channel_type IN ('internal','interagency') AND public.is_internal_staff())
  );

DROP POLICY IF EXISTS communications_select ON public.communications;
CREATE POLICY communications_select ON public.communications FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.communication_threads t
      WHERE t.id = thread_id
    )
  );

DROP POLICY IF EXISTS communications_insert ON public.communications;
CREATE POLICY communications_insert ON public.communications FOR INSERT TO authenticated
  WITH CHECK (
    author_id = auth.uid()
    AND EXISTS (SELECT 1 FROM public.communication_threads t WHERE t.id = thread_id AND t.is_locked = false)
  );

DROP POLICY IF EXISTS communications_update ON public.communications;
CREATE POLICY communications_update ON public.communications FOR UPDATE TO authenticated
  USING (author_id = auth.uid() OR public.is_staff_elevated())
  WITH CHECK (author_id = auth.uid() OR public.is_staff_elevated());

-- interactions: family only if family_visible
DROP POLICY IF EXISTS interactions_select ON public.interactions;
CREATE POLICY interactions_select ON public.interactions FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND public.can_access_treatment_unit(treatment_unit_id)
    AND (
      public.is_internal_staff()
      OR visibility = 'family_visible'
    )
  );

DROP POLICY IF EXISTS interactions_write ON public.interactions;
CREATE POLICY interactions_write ON public.interactions FOR ALL TO authenticated
  USING (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id))
  WITH CHECK (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id));

-- rehab
DROP POLICY IF EXISTS rehab_plans_select ON public.rehabilitation_plans;
CREATE POLICY rehab_plans_select ON public.rehabilitation_plans FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND public.can_access_treatment_unit(treatment_unit_id));

DROP POLICY IF EXISTS rehab_plans_write ON public.rehabilitation_plans;
CREATE POLICY rehab_plans_write ON public.rehabilitation_plans FOR ALL TO authenticated
  USING (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id))
  WITH CHECK (public.is_internal_staff() AND public.can_access_treatment_unit(treatment_unit_id));

DROP POLICY IF EXISTS rehab_act_all ON public.rehabilitation_activities;
CREATE POLICY rehab_act_all ON public.rehabilitation_activities FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.rehabilitation_plans p
      WHERE p.id = plan_id AND public.can_access_treatment_unit(p.treatment_unit_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.rehabilitation_plans p
      WHERE p.id = plan_id AND public.is_internal_staff()
        AND public.can_access_treatment_unit(p.treatment_unit_id)
    )
  );

DROP POLICY IF EXISTS rehab_ms_all ON public.rehab_milestones;
CREATE POLICY rehab_ms_all ON public.rehab_milestones FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.rehabilitation_plans p
      WHERE p.id = plan_id AND public.can_access_treatment_unit(p.treatment_unit_id)
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.rehabilitation_plans p
      WHERE p.id = plan_id AND public.is_internal_staff()
        AND public.can_access_treatment_unit(p.treatment_unit_id)
    )
  );

-- events / benefits
DROP POLICY IF EXISTS events_select ON public.portal_events;
CREATE POLICY events_select ON public.portal_events FOR SELECT TO authenticated
  USING (deleted_at IS NULL AND (is_published OR public.is_internal_staff()));

DROP POLICY IF EXISTS events_write ON public.portal_events;
CREATE POLICY events_write ON public.portal_events FOR ALL TO authenticated
  USING (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated() OR public.has_app_role('headquarters_staff'))
  WITH CHECK (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated() OR public.has_app_role('headquarters_staff'));

DROP POLICY IF EXISTS event_reg_all ON public.event_registrations;
CREATE POLICY event_reg_all ON public.event_registrations FOR ALL TO authenticated
  USING (profile_id = auth.uid() OR public.is_internal_staff())
  WITH CHECK (profile_id = auth.uid() OR public.is_internal_staff());

DROP POLICY IF EXISTS benefits_select ON public.benefits;
CREATE POLICY benefits_select ON public.benefits FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

DROP POLICY IF EXISTS benefits_write ON public.benefits;
CREATE POLICY benefits_write ON public.benefits FOR ALL TO authenticated
  USING (public.is_staff_elevated() OR public.has_app_role('headquarters_staff'))
  WITH CHECK (public.is_staff_elevated() OR public.has_app_role('headquarters_staff'));

DROP POLICY IF EXISTS entitlements_select ON public.benefit_entitlements;
CREATE POLICY entitlements_select ON public.benefit_entitlements FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND (
      public.is_internal_staff()
      OR (family_id IN (SELECT public.my_family_ids()))
      OR EXISTS (
        SELECT 1 FROM public.persons p
        WHERE p.id = person_id AND p.family_id IN (SELECT public.my_family_ids())
      )
    )
  );

DROP POLICY IF EXISTS entitlements_write ON public.benefit_entitlements;
CREATE POLICY entitlements_write ON public.benefit_entitlements FOR ALL TO authenticated
  USING (public.is_internal_staff())
  WITH CHECK (public.is_internal_staff());

-- content & knowledge
DROP POLICY IF EXISTS content_select ON public.content_items;
CREATE POLICY content_select ON public.content_items FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND (
      status = 'published'
      OR public.has_app_role('content_editor')
      OR public.has_app_role('content_approver')
      OR public.is_staff_elevated()
    )
  );

DROP POLICY IF EXISTS content_write ON public.content_items;
CREATE POLICY content_write ON public.content_items FOR ALL TO authenticated
  USING (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated())
  WITH CHECK (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated());

DROP POLICY IF EXISTS content_versions_all ON public.content_versions;
CREATE POLICY content_versions_all ON public.content_versions FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.content_items c WHERE c.id = content_item_id
    )
  )
  WITH CHECK (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated());

DROP POLICY IF EXISTS knowledge_cat_select ON public.knowledge_categories;
CREATE POLICY knowledge_cat_select ON public.knowledge_categories FOR SELECT TO authenticated
  USING (deleted_at IS NULL);

DROP POLICY IF EXISTS knowledge_cat_write ON public.knowledge_categories;
CREATE POLICY knowledge_cat_write ON public.knowledge_categories FOR ALL TO authenticated
  USING (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated())
  WITH CHECK (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated());

DROP POLICY IF EXISTS knowledge_art_select ON public.knowledge_articles;
CREATE POLICY knowledge_art_select ON public.knowledge_articles FOR SELECT TO authenticated
  USING (
    deleted_at IS NULL
    AND (is_published OR public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated())
  );

DROP POLICY IF EXISTS knowledge_art_write ON public.knowledge_articles;
CREATE POLICY knowledge_art_write ON public.knowledge_articles FOR ALL TO authenticated
  USING (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated())
  WITH CHECK (public.has_app_role('content_editor') OR public.has_app_role('content_approver') OR public.is_staff_elevated());

-- notifications: recipient only
DROP POLICY IF EXISTS notifications_select ON public.notifications;
CREATE POLICY notifications_select ON public.notifications FOR SELECT TO authenticated
  USING (recipient_id = auth.uid());

DROP POLICY IF EXISTS notifications_update ON public.notifications;
CREATE POLICY notifications_update ON public.notifications FOR UPDATE TO authenticated
  USING (recipient_id = auth.uid())
  WITH CHECK (recipient_id = auth.uid());

DROP POLICY IF EXISTS notifications_insert ON public.notifications;
CREATE POLICY notifications_insert ON public.notifications FOR INSERT TO authenticated
  WITH CHECK (public.is_internal_staff() OR recipient_id = auth.uid());

-- audit: elevated read; insert by staff (app layer)
DROP POLICY IF EXISTS audit_select ON public.audit_logs;
CREATE POLICY audit_select ON public.audit_logs FOR SELECT TO authenticated
  USING (public.is_staff_elevated() OR public.has_app_role('system_admin') OR actor_id = auth.uid());

DROP POLICY IF EXISTS audit_insert ON public.audit_logs;
CREATE POLICY audit_insert ON public.audit_logs FOR INSERT TO authenticated
  WITH CHECK (public.is_internal_staff());

-- service_role bypasses RLS by default in Supabase — no policy required
