-- Manhelet Portal Demo — 12 views (security_invoker)

CREATE OR REPLACE VIEW public.v_treatment_unit_caseload
WITH (security_invoker = true)
AS
SELECT
  tu.id AS treatment_unit_id,
  tu.unit_code,
  tu.title_he,
  tu.status,
  f.id AS family_id,
  f.family_code,
  f.display_name_he AS family_name_he,
  tu.primary_case_manager_id,
  pcm.full_name_he AS primary_case_manager_name,
  (SELECT count(*) FROM public.persons p
    WHERE p.treatment_unit_id = tu.id AND p.deleted_at IS NULL) AS person_count,
  (SELECT count(*) FROM public.tasks t
    WHERE t.treatment_unit_id = tu.id AND t.deleted_at IS NULL
      AND t.status NOT IN ('completed','cancelled')) AS open_task_count
FROM public.treatment_units tu
JOIN public.families f ON f.id = tu.family_id AND f.deleted_at IS NULL
LEFT JOIN public.profiles pcm ON pcm.id = tu.primary_case_manager_id
WHERE tu.deleted_at IS NULL;

CREATE OR REPLACE VIEW public.v_my_open_tasks
WITH (security_invoker = true)
AS
SELECT
  t.*,
  tu.unit_code,
  f.display_name_he AS family_name_he
FROM public.tasks t
JOIN public.task_assignees ta ON ta.task_id = t.id AND ta.profile_id = auth.uid()
JOIN public.treatment_units tu ON tu.id = t.treatment_unit_id
JOIN public.families f ON f.id = t.family_id
WHERE t.deleted_at IS NULL
  AND t.status NOT IN ('completed','cancelled');

CREATE OR REPLACE VIEW public.v_family_portal_home
WITH (security_invoker = true)
AS
SELECT
  f.id AS family_id,
  f.family_code,
  f.display_name_he,
  p.id AS my_person_id,
  p.first_name_he,
  p.last_name_he,
  (SELECT count(*) FROM public.tasks t
    WHERE t.family_id = f.id AND t.deleted_at IS NULL
      AND COALESCE(t.metadata->>'family_visible','false') = 'true'
      AND t.status NOT IN ('completed','cancelled')) AS visible_open_tasks,
  (SELECT count(*) FROM public.benefit_entitlements be
    WHERE be.family_id = f.id AND be.deleted_at IS NULL
      AND be.status IN ('eligible','applied','approved','in_payment')) AS open_benefits
FROM public.profile_person_links l
JOIN public.persons p ON p.id = l.person_id AND p.deleted_at IS NULL
JOIN public.families f ON f.id = p.family_id AND f.deleted_at IS NULL
WHERE l.profile_id = auth.uid();

CREATE OR REPLACE VIEW public.v_rehab_dashboard
WITH (security_invoker = true)
AS
SELECT
  rp.id AS plan_id,
  rp.title_he,
  rp.status,
  rp.start_date,
  rp.target_end_date,
  pe.first_name_he || ' ' || pe.last_name_he AS person_name_he,
  pe.status AS person_status,
  tu.unit_code,
  (SELECT count(*) FROM public.rehabilitation_activities a
    WHERE a.plan_id = rp.id AND a.deleted_at IS NULL AND a.status = 'planned') AS planned_activities,
  (SELECT count(*) FROM public.rehab_milestones m
    WHERE m.plan_id = rp.id AND m.achieved_at IS NULL) AS open_milestones
FROM public.rehabilitation_plans rp
JOIN public.persons pe ON pe.id = rp.person_id
JOIN public.treatment_units tu ON tu.id = rp.treatment_unit_id
WHERE rp.deleted_at IS NULL;

CREATE OR REPLACE VIEW public.v_executive_situation
WITH (security_invoker = true)
AS
SELECT
  (SELECT count(*) FROM public.families WHERE deleted_at IS NULL AND closed_at IS NULL) AS open_families,
  (SELECT count(*) FROM public.treatment_units WHERE deleted_at IS NULL AND status = 'active') AS active_units,
  (SELECT count(*) FROM public.persons WHERE deleted_at IS NULL AND status = 'captive') AS persons_captive,
  (SELECT count(*) FROM public.persons WHERE deleted_at IS NULL AND status = 'missing') AS persons_missing,
  (SELECT count(*) FROM public.persons WHERE deleted_at IS NULL AND status = 'returned') AS persons_returned,
  (SELECT count(*) FROM public.tasks WHERE deleted_at IS NULL AND status NOT IN ('completed','cancelled')) AS open_tasks,
  (SELECT count(*) FROM public.tasks WHERE deleted_at IS NULL AND priority = 'critical'
     AND status NOT IN ('completed','cancelled')) AS critical_open_tasks,
  (SELECT count(*) FROM public.rehabilitation_plans WHERE deleted_at IS NULL AND status = 'active') AS active_rehab_plans;
