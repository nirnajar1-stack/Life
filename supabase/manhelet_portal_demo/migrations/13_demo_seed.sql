-- Manhelet Portal Demo — 13 seed (fictional Hebrew PII only; DEMO-######## IDs)
-- Profiles use fixed UUIDs; provision matching Auth users via Auth Admin (no passwords here).

BEGIN;

-- ---------------------------------------------------------------------------
-- Org units
-- ---------------------------------------------------------------------------
INSERT INTO public.organizational_units (id, code, name_he, unit_type) VALUES
  ('a2000000-0000-4000-8000-000000000001', 'DIR', 'הנהלת המנהלת', 'directorate'),
  ('a2000000-0000-4000-8000-000000000002', 'CASE', 'אגף ליווי משפחות', 'department'),
  ('a2000000-0000-4000-8000-000000000003', 'REHAB', 'אגף שיקום ושבים', 'department'),
  ('a2000000-0000-4000-8000-000000000004', 'CONTENT', 'אגף תוכן וידע', 'department'),
  ('a2000000-0000-4000-8000-000000000005', 'HQ', 'מטה תפעולי', 'team')
ON CONFLICT (code) DO NOTHING;

UPDATE public.organizational_units SET parent_id = 'a2000000-0000-4000-8000-000000000001'
WHERE code IN ('CASE','REHAB','CONTENT','HQ') AND parent_id IS NULL;

-- ---------------------------------------------------------------------------
-- Agencies
-- ---------------------------------------------------------------------------
INSERT INTO public.government_agencies (id, code, name_he, contact_email) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'BTL', 'המוסד לביטוח לאומי', 'demo.btl@example.gov.il'),
  ('a0000000-0000-4000-8000-000000000002', 'MOH', 'משרד הבריאות', 'demo.moh@example.gov.il'),
  ('a0000000-0000-4000-8000-000000000003', 'MOLSA', 'משרד הרווחה והביטחון החברתי', 'demo.molsa@example.gov.il'),
  ('a0000000-0000-4000-8000-000000000004', 'MOJ', 'משרד המשפטים — סיוע משפטי', 'demo.moj@example.gov.il'),
  ('a0000000-0000-4000-8000-000000000005', 'MOE', 'משרד החינוך', 'demo.moe@example.gov.il'),
  ('a0000000-0000-4000-8000-000000000006', 'NII_PROP', 'מס רכוש', 'demo.property@example.gov.il')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Demo profiles (fixed UUIDs) — passwords: set via Auth Admin / invite only
-- ---------------------------------------------------------------------------
INSERT INTO public.profiles (id, email, full_name_he, organizational_unit_id, job_title_he) VALUES
  ('11111111-1111-4111-8111-111111111101', 'super.admin@manhelet-demo.example', 'יעל אדמין', 'a2000000-0000-4000-8000-000000000001', 'מנהלת על'),
  ('11111111-1111-4111-8111-111111111102', 'system.admin@manhelet-demo.example', 'דני מערכות', 'a2000000-0000-4000-8000-000000000001', 'מנהל מערכת'),
  ('11111111-1111-4111-8111-111111111103', 'case.mgr1@manhelet-demo.example', 'נועה לוי', 'a2000000-0000-4000-8000-000000000002', 'מנהלת תיק'),
  ('11111111-1111-4111-8111-111111111104', 'case.mgr2@manhelet-demo.example', 'איתי כהן', 'a2000000-0000-4000-8000-000000000002', 'מנהל תיק'),
  ('11111111-1111-4111-8111-111111111105', 'case.mgr3@manhelet-demo.example', 'מיכל אברהם', 'a2000000-0000-4000-8000-000000000002', 'מלווה אישית'),
  ('11111111-1111-4111-8111-111111111106', 'dept.mgr@manhelet-demo.example', 'רועי מחלקה', 'a2000000-0000-4000-8000-000000000002', 'מנהל מחלקה'),
  ('11111111-1111-4111-8111-111111111107', 'executive@manhelet-demo.example', 'תמר הנהלה', 'a2000000-0000-4000-8000-000000000001', 'סמנכ״לית'),
  ('11111111-1111-4111-8111-111111111108', 'hq.staff@manhelet-demo.example', 'שירה מטה', 'a2000000-0000-4000-8000-000000000005', 'עובדת מטה'),
  ('11111111-1111-4111-8111-111111111109', 'content.editor@manhelet-demo.example', 'עומר עורך', 'a2000000-0000-4000-8000-000000000004', 'עורך תוכן'),
  ('11111111-1111-4111-8111-111111111110', 'content.approver@manhelet-demo.example', 'הדס מאשרת', 'a2000000-0000-4000-8000-000000000004', 'מאשרת תוכן'),
  ('11111111-1111-4111-8111-111111111111', 'gov.btl@manhelet-demo.example', 'ליאת ביטוח לאומי', 'a2000000-0000-4000-8000-000000000005', 'נציגת ביטוח לאומי'),
  ('11111111-1111-4111-8111-111111111112', 'gov.moh@manhelet-demo.example', 'ד״ר אמיר בריאות', 'a2000000-0000-4000-8000-000000000005', 'נציג משרד הבריאות'),
  ('11111111-1111-4111-8111-111111111113', 'gov.molsa@manhelet-demo.example', 'סיגל רווחה', 'a2000000-0000-4000-8000-000000000005', 'נציגת רווחה'),
  -- Family portal actors (scenarios A–E)
  ('11111111-1111-4111-8111-111111111121', 'family.cohen@manhelet-demo.example', 'רותם כהן', NULL, 'נציגת משפחה'),
  ('11111111-1111-4111-8111-111111111122', 'family.levi@manhelet-demo.example', 'יוסי לוי', NULL, 'נציג משפחה'),
  ('11111111-1111-4111-8111-111111111123', 'family.mizrahi@manhelet-demo.example', 'אורלי מזרחי', NULL, 'נציגת משפחה'),
  ('11111111-1111-4111-8111-111111111124', 'family.avraham@manhelet-demo.example', 'דנה אברהם', NULL, 'נציגת משפחה'),
  ('11111111-1111-4111-8111-111111111125', 'family.escalated@manhelet-demo.example', 'גיא פרץ', NULL, 'נציג משפחה')
ON CONFLICT (id) DO NOTHING;

-- Roles assignment
INSERT INTO public.user_roles (user_id, role_id)
SELECT p.id, r.id FROM (VALUES
  ('11111111-1111-4111-8111-111111111101'::uuid, 'super_admin'::public.app_role),
  ('11111111-1111-4111-8111-111111111102', 'system_admin'),
  ('11111111-1111-4111-8111-111111111103', 'case_manager'),
  ('11111111-1111-4111-8111-111111111104', 'case_manager'),
  ('11111111-1111-4111-8111-111111111105', 'case_manager'),
  ('11111111-1111-4111-8111-111111111106', 'department_manager'),
  ('11111111-1111-4111-8111-111111111107', 'executive'),
  ('11111111-1111-4111-8111-111111111108', 'headquarters_staff'),
  ('11111111-1111-4111-8111-111111111109', 'content_editor'),
  ('11111111-1111-4111-8111-111111111110', 'content_approver'),
  ('11111111-1111-4111-8111-111111111111', 'government_representative'),
  ('11111111-1111-4111-8111-111111111112', 'government_representative'),
  ('11111111-1111-4111-8111-111111111113', 'government_representative'),
  ('11111111-1111-4111-8111-111111111121', 'family_member'),
  ('11111111-1111-4111-8111-111111111122', 'family_member'),
  ('11111111-1111-4111-8111-111111111123', 'family_member'),
  ('11111111-1111-4111-8111-111111111124', 'family_member'),
  ('11111111-1111-4111-8111-111111111125', 'family_member')
) AS x(uid, rcode)
JOIN public.profiles p ON p.id = x.uid
JOIN public.roles r ON r.code = x.rcode
ON CONFLICT (user_id, role_id) DO NOTHING;

INSERT INTO public.government_representatives (id, profile_id, agency_id, title_he) VALUES
  ('a3000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111111', 'a0000000-0000-4000-8000-000000000001', 'עובדת שיקום'),
  ('a3000000-0000-4000-8000-000000000002', '11111111-1111-4111-8111-111111111112', 'a0000000-0000-4000-8000-000000000002', 'רופא מתאם'),
  ('a3000000-0000-4000-8000-000000000003', '11111111-1111-4111-8111-111111111113', 'a0000000-0000-4000-8000-000000000003', 'עו״ס מלווה')
ON CONFLICT (profile_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Scenario families A–E (fixed IDs) + bulk families 06–30
-- ---------------------------------------------------------------------------
INSERT INTO public.families (id, family_code, display_name_he, primary_locality_he, scenario_tag, notes_internal) VALUES
  ('f0000000-0000-4000-8000-00000000000a', 'FAM-A-COHEN', 'משפחת כהן', 'שדרות', 'A', 'חטוף פעיל — תרחיש A'),
  ('f0000000-0000-4000-8000-00000000000b', 'FAM-B-LEVI', 'משפחת לוי', 'ניר עוז', 'B', 'שב בשיקום — תרחיש B'),
  ('f0000000-0000-4000-8000-00000000000c', 'FAM-C-MIZRAHI', 'משפחת מזרחי', 'בארי', 'C', 'נעדר — תרחיש C'),
  ('f0000000-0000-4000-8000-00000000000d', 'FAM-D-AVRAHAM', 'משפחת אברהם', 'כפר עזה', 'D', 'יחידות מרובות — תרחיש D'),
  ('f0000000-0000-4000-8000-00000000000e', 'FAM-E-PERETZ', 'משפחת פרץ', 'תל אביב', 'E', 'בין-משרדי מוסלם — תרחיש E')
ON CONFLICT (family_code) DO NOTHING;

INSERT INTO public.families (id, family_code, display_name_he, primary_locality_he, scenario_tag)
SELECT
  ('f0000000-0000-4000-8000-' || lpad(to_hex(100 + g), 12, '0'))::uuid,
  'FAM-' || lpad(g::text, 3, '0'),
  (ARRAY['משפחת דהן','משפחת ביטון','משפחת אזולאי','משפחת חדד','משפחת אוחיון',
         'משפחת ממן','משפחת פרץ','משפחת סיטבון','משפחת אלבז','משפחת בן דוד',
         'משפחת שמש','משפחת מלכה','משפחת וקנין','משפחת סבג','משפחת אמסלם',
         'משפחת גבאי','משפחת אטיאס','משפחת בן חיים','משפחת לביא','משפחת רוזן',
         'משפחת שפירא','משפחת גולן','משפחת נחום','משפחת טל','משפחת ברק'])[1 + ((g-1) % 25)],
  (ARRAY['אשדוד','אשקלון','באר שבע','רעננה','חיפה','ירושלים','נתניה','חולון'])[1 + ((g-1) % 8)],
  'BULK'
FROM generate_series(6, 30) AS g
ON CONFLICT (family_code) DO NOTHING;

-- Treatment units: scenarios + bulk to reach ~45
INSERT INTO public.treatment_units (id, family_id, unit_code, title_he, status, primary_case_manager_id, secondary_case_manager_id, lead_domain, metadata) VALUES
  ('a4000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-00000000000a', 'TU-A-01', 'יחידת טיפול כהן — ליבה', 'active', '11111111-1111-4111-8111-111111111103', '11111111-1111-4111-8111-111111111105', 'psychosocial', '{"scenario":"A"}'::jsonb),
  ('a4000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-00000000000b', 'TU-B-01', 'יחידת שיקום לוי', 'active', '11111111-1111-4111-8111-111111111104', '11111111-1111-4111-8111-111111111103', 'health', '{"scenario":"B"}'::jsonb),
  ('a4000000-0000-4000-8000-00000000000c', 'f0000000-0000-4000-8000-00000000000c', 'TU-C-01', 'יחידת נעדר מזרחי', 'active', '11111111-1111-4111-8111-111111111105', NULL, 'rights', '{"scenario":"C"}'::jsonb),
  ('a4000000-0000-4000-8000-0000000000d1', 'f0000000-0000-4000-8000-00000000000d', 'TU-D-01', 'יחידת אברהם — אח בכור', 'active', '11111111-1111-4111-8111-111111111103', NULL, 'housing', '{"scenario":"D"}'::jsonb),
  ('a4000000-0000-4000-8000-0000000000d2', 'f0000000-0000-4000-8000-00000000000d', 'TU-D-02', 'יחידת אברהם — אחות', 'active', '11111111-1111-4111-8111-111111111104', NULL, 'education', '{"scenario":"D"}'::jsonb),
  ('a4000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-00000000000e', 'TU-E-01', 'יחידת פרץ — תיאום בין-משרדי', 'active', '11111111-1111-4111-8111-111111111104', '11111111-1111-4111-8111-111111111105', 'interagency', '{"scenario":"E"}'::jsonb)
ON CONFLICT (unit_code) DO NOTHING;

INSERT INTO public.treatment_units (id, family_id, unit_code, title_he, status, primary_case_manager_id, lead_domain)
SELECT
  ('a4000000-0000-4000-8000-' || lpad(to_hex(8192 + g), 12, '0'))::uuid,
  ('f0000000-0000-4000-8000-' || lpad(to_hex(100 + g), 12, '0'))::uuid,
  'TU-BULK-' || lpad(g::text, 3, '0'),
  'יחידת טיפול ' || lpad(g::text, 3, '0'),
  'active',
  (ARRAY[
    '11111111-1111-4111-8111-111111111103'::uuid,
    '11111111-1111-4111-8111-111111111104'::uuid,
    '11111111-1111-4111-8111-111111111105'::uuid
  ])[1 + ((g-1) % 3)],
  (ARRAY['housing','economic','health','rights','psychosocial','education'])[1 + ((g-1) % 6)]
FROM generate_series(6, 30) AS g
ON CONFLICT (unit_code) DO NOTHING;

-- Extra units on some bulk families to reach ~45
INSERT INTO public.treatment_units (id, family_id, unit_code, title_he, status, primary_case_manager_id, lead_domain)
SELECT
  ('a4000000-0000-4000-8000-' || lpad(to_hex(12288 + g), 12, '0'))::uuid,
  ('f0000000-0000-4000-8000-' || lpad(to_hex(100 + g), 12, '0'))::uuid,
  'TU-BULK-X-' || lpad(g::text, 3, '0'),
  'יחידת משנה ' || lpad(g::text, 3, '0'),
  'active',
  '11111111-1111-4111-8111-111111111105',
  'economic'
FROM generate_series(6, 19) AS g
ON CONFLICT (unit_code) DO NOTHING;

-- Gov rep attachments for A/B/E
INSERT INTO public.gov_rep_treatment_units (government_representative_id, treatment_unit_id, access_level, assigned_by)
SELECT x.rid, x.uid, x.lvl, '11111111-1111-4111-8111-111111111103'
FROM (VALUES
  ('a3000000-0000-4000-8000-000000000001'::uuid, 'a4000000-0000-4000-8000-00000000000a'::uuid, 'collaborate'),
  ('a3000000-0000-4000-8000-000000000002', 'a4000000-0000-4000-8000-00000000000b', 'lead_agency'),
  ('a3000000-0000-4000-8000-000000000003', 'a4000000-0000-4000-8000-00000000000a', 'collaborate'),
  ('a3000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-00000000000e', 'collaborate'),
  ('a3000000-0000-4000-8000-000000000002', 'a4000000-0000-4000-8000-00000000000e', 'collaborate'),
  ('a3000000-0000-4000-8000-000000000003', 'a4000000-0000-4000-8000-00000000000e', 'lead_agency')
) AS x(rid, uid, lvl)
ON CONFLICT (government_representative_id, treatment_unit_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Persons: scenario index cases + family members + bulk (~120)
-- ---------------------------------------------------------------------------
INSERT INTO public.persons (
  id, treatment_unit_id, family_id, demo_national_id, first_name_he, last_name_he,
  date_of_birth, gender, status, relationship_to_index, is_index_case, locality_he
) VALUES
  ('a5000000-0000-4000-8000-0000000000a1', 'a4000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-00000000000a', 'DEMO-10000001', 'יונתן', 'כהן', '1992-04-12', 'male', 'captive', 'index_case', true, 'שדרות'),
  ('a5000000-0000-4000-8000-0000000000a2', 'a4000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-00000000000a', 'DEMO-10000002', 'רותם', 'כהן', '1994-08-03', 'female', 'family_member_only', 'spouse', false, 'שדרות'),
  ('a5000000-0000-4000-8000-0000000000b1', 'a4000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-00000000000b', 'DEMO-10000003', 'אלון', 'לוי', '1988-01-22', 'male', 'returned', 'index_case', true, 'ניר עוז'),
  ('a5000000-0000-4000-8000-0000000000b2', 'a4000000-0000-4000-8000-00000000000b', 'f0000000-0000-4000-8000-00000000000b', 'DEMO-10000004', 'יוסי', 'לוי', '1960-05-15', 'male', 'family_member_only', 'parent', false, 'ניר עוז'),
  ('a5000000-0000-4000-8000-0000000000c1', 'a4000000-0000-4000-8000-00000000000c', 'f0000000-0000-4000-8000-00000000000c', 'DEMO-10000005', 'נועם', 'מזרחי', '1995-11-09', 'male', 'missing', 'index_case', true, 'בארי'),
  ('a5000000-0000-4000-8000-0000000000c2', 'a4000000-0000-4000-8000-00000000000c', 'f0000000-0000-4000-8000-00000000000c', 'DEMO-10000006', 'אורלי', 'מזרחי', '1968-02-28', 'female', 'family_member_only', 'parent', false, 'בארי'),
  ('a5000000-0000-4000-8000-000000000d11', 'a4000000-0000-4000-8000-0000000000d1', 'f0000000-0000-4000-8000-00000000000d', 'DEMO-10000007', 'עידו', 'אברהם', '1990-07-01', 'male', 'returned', 'index_case', true, 'כפר עזה'),
  ('a5000000-0000-4000-8000-000000000d21', 'a4000000-0000-4000-8000-0000000000d2', 'f0000000-0000-4000-8000-00000000000d', 'DEMO-10000008', 'מאיה', 'אברהם', '1993-09-18', 'female', 'returned', 'index_case', true, 'כפר עזה'),
  ('a5000000-0000-4000-8000-000000000d22', 'a4000000-0000-4000-8000-0000000000d2', 'f0000000-0000-4000-8000-00000000000d', 'DEMO-10000009', 'דנה', 'אברהם', '1965-12-12', 'female', 'family_member_only', 'parent', false, 'כפר עזה'),
  ('a5000000-0000-4000-8000-0000000000e1', 'a4000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-00000000000e', 'DEMO-10000010', 'תום', 'פרץ', '1991-03-30', 'male', 'returned', 'index_case', true, 'תל אביב'),
  ('a5000000-0000-4000-8000-0000000000e2', 'a4000000-0000-4000-8000-00000000000e', 'f0000000-0000-4000-8000-00000000000e', 'DEMO-10000011', 'גיא', 'פרץ', '1987-06-06', 'male', 'family_member_only', 'sibling', false, 'תל אביב')
ON CONFLICT (demo_national_id) DO NOTHING;

UPDATE public.persons SET returned_at = CURRENT_DATE - 40 WHERE id = 'a5000000-0000-4000-8000-0000000000b1';
UPDATE public.persons SET returned_at = CURRENT_DATE - 90 WHERE id IN (
  'a5000000-0000-4000-8000-000000000d11',
  'a5000000-0000-4000-8000-000000000d21',
  'a5000000-0000-4000-8000-0000000000e1'
);

-- Family portal links
INSERT INTO public.profile_person_links (profile_id, person_id, verified_at, created_by) VALUES
  ('11111111-1111-4111-8111-111111111121', 'a5000000-0000-4000-8000-0000000000a2', timezone('utc', now()), '11111111-1111-4111-8111-111111111102'),
  ('11111111-1111-4111-8111-111111111122', 'a5000000-0000-4000-8000-0000000000b2', timezone('utc', now()), '11111111-1111-4111-8111-111111111102'),
  ('11111111-1111-4111-8111-111111111123', 'a5000000-0000-4000-8000-0000000000c2', timezone('utc', now()), '11111111-1111-4111-8111-111111111102'),
  ('11111111-1111-4111-8111-111111111124', 'a5000000-0000-4000-8000-000000000d22', timezone('utc', now()), '11111111-1111-4111-8111-111111111102'),
  ('11111111-1111-4111-8111-111111111125', 'a5000000-0000-4000-8000-0000000000e2', timezone('utc', now()), '11111111-1111-4111-8111-111111111102')
ON CONFLICT (profile_id) DO NOTHING;

-- Bulk persons (~109 more to approach 120)
INSERT INTO public.persons (
  id, treatment_unit_id, family_id, demo_national_id, first_name_he, last_name_he,
  date_of_birth, gender, status, relationship_to_index, is_index_case, locality_he
)
SELECT
  ('a5000000-0000-4000-8000-' || lpad(to_hex(1000 + g), 12, '0'))::uuid,
  tu.id,
  tu.family_id,
  'DEMO-' || lpad((20000000 + g)::text, 8, '0'),
  (ARRAY['אבי','נועה','יואב','שירה','עידן','מאיה','רון','יעל','תום','הדר','ליאור','ספיר'])[1 + ((g-1) % 12)],
  (ARRAY['דהן','ביטון','אזולאי','חדד','אוחיון','ממן','סיטבון','אלבז','שמש','מלכה','וקנין','סבג'])[1 + ((g-1) % 12)],
  DATE '1975-01-01' + ((g * 37) % 12000),
  (ARRAY['female','male','unspecified'])[1 + ((g-1) % 3)],
  (ARRAY['captive','missing','returned','returned','family_member_only','family_member_only']::public.person_status[])[1 + ((g-1) % 6)],
  CASE WHEN (g % 3) = 1 THEN 'index_case' ELSE 'family_member' END,
  (g % 3) = 1,
  'ישראל'
FROM generate_series(1, 109) AS g
JOIN LATERAL (
  SELECT id, family_id
  FROM public.treatment_units
  WHERE unit_code LIKE 'TU-BULK-%' AND unit_code NOT LIKE 'TU-BULK-X-%'
  ORDER BY unit_code
  OFFSET ((g - 1) % 25)
  LIMIT 1
) tu ON true
ON CONFLICT (demo_national_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- Tasks: scenario-specific + bulk 400+
-- ---------------------------------------------------------------------------
INSERT INTO public.tasks (id, treatment_unit_id, person_id, family_id, title_he, description_he, status, priority, domain, due_at, created_by, owning_agency_id, scenario_tag, metadata)
VALUES
  ('a6000000-0000-4000-8000-0000000000a1', 'a4000000-0000-4000-8000-00000000000a', 'a5000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-00000000000a',
   'תיאום מענה דיור זמני למשפחה', 'בדיקת זכאות והצבת דיור', 'in_progress', 'high', 'housing',
   timezone('utc', now()) + interval '5 days', '11111111-1111-4111-8111-111111111103', NULL, 'A',
   '{"family_visible":"true"}'::jsonb),
  ('a6000000-0000-4000-8000-0000000000a2', 'a4000000-0000-4000-8000-00000000000a', 'a5000000-0000-4000-8000-0000000000a2', 'f0000000-0000-4000-8000-00000000000a',
   'ליווי רגשי — פגישת עו״ס', NULL, 'open', 'medium', 'psychosocial',
   timezone('utc', now()) + interval '2 days', '11111111-1111-4111-8111-111111111105', 'a0000000-0000-4000-8000-000000000003', 'A',
   '{"family_visible":"true"}'::jsonb),
  ('a6000000-0000-4000-8000-0000000000b1', 'a4000000-0000-4000-8000-00000000000b', 'a5000000-0000-4000-8000-0000000000b1', 'f0000000-0000-4000-8000-00000000000b',
   'קביעת תור מרפאת שיקום', NULL, 'waiting_external', 'high', 'health',
   timezone('utc', now()) + interval '3 days', '11111111-1111-4111-8111-111111111104', 'a0000000-0000-4000-8000-000000000002', 'B',
   '{"family_visible":"true"}'::jsonb),
  ('a6000000-0000-4000-8000-0000000000c1', 'a4000000-0000-4000-8000-00000000000c', 'a5000000-0000-4000-8000-0000000000c1', 'f0000000-0000-4000-8000-00000000000c',
   'עדכון פנימי — סטטוס נעדר', 'לשימוש פנימי בלבד', 'open', 'critical', 'interagency',
   timezone('utc', now()) + interval '1 day', '11111111-1111-4111-8111-111111111105', NULL, 'C',
   '{"family_visible":"false"}'::jsonb),
  ('a6000000-0000-4000-8000-0000000000e1', 'a4000000-0000-4000-8000-00000000000e', 'a5000000-0000-4000-8000-0000000000e1', 'f0000000-0000-4000-8000-00000000000e',
   'הסלמה בין-משרדית — דיור + זכויות', 'תיאום ביטוח לאומי, רווחה ובריאות', 'blocked', 'critical', 'interagency',
   timezone('utc', now()) + interval '1 day', '11111111-1111-4111-8111-111111111104', 'a0000000-0000-4000-8000-000000000001', 'E',
   '{"family_visible":"true","escalated":"true"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.task_assignees (task_id, profile_id, assigned_by)
SELECT t.id, a.pid, '11111111-1111-4111-8111-111111111103'
FROM (VALUES
  ('a6000000-0000-4000-8000-0000000000a1'::uuid, '11111111-1111-4111-8111-111111111103'::uuid),
  ('a6000000-0000-4000-8000-0000000000a2', '11111111-1111-4111-8111-111111111105'),
  ('a6000000-0000-4000-8000-0000000000b1', '11111111-1111-4111-8111-111111111104'),
  ('a6000000-0000-4000-8000-0000000000c1', '11111111-1111-4111-8111-111111111105'),
  ('a6000000-0000-4000-8000-0000000000e1', '11111111-1111-4111-8111-111111111104'),
  ('a6000000-0000-4000-8000-0000000000e1', '11111111-1111-4111-8111-111111111111')
) AS a(tid, pid)
JOIN public.tasks t ON t.id = a.tid
ON CONFLICT (task_id, profile_id) DO NOTHING;

INSERT INTO public.tasks (
  treatment_unit_id, person_id, family_id, title_he, status, priority, domain,
  due_at, created_by, scenario_tag, metadata
)
SELECT
  tu.id,
  pe.id,
  tu.family_id,
  (ARRAY[
    'בדיקת זכאות כלכלית',
    'תיאום חינוך לילדים',
    'פנייה למס רכוש',
    'עדכון פרטי קשר',
    'ליווי רפואי שוטף',
    'סיוע משפטי ראשוני',
    'תיאום דיור',
    'מעקב חוסן'
  ])[1 + ((g-1) % 8)],
  (ARRAY['open','in_progress','waiting_external','waiting_family','completed']::public.task_status[])[1 + ((g-1) % 5)],
  (ARRAY['low','medium','high','critical']::public.task_priority[])[1 + ((g-1) % 4)],
  (ARRAY['housing','economic','health','rights','psychosocial','education','other'])[1 + ((g-1) % 7)],
  timezone('utc', now()) + ((g % 30) || ' days')::interval,
  (ARRAY[
    '11111111-1111-4111-8111-111111111103'::uuid,
    '11111111-1111-4111-8111-111111111104'::uuid,
    '11111111-1111-4111-8111-111111111105'::uuid
  ])[1 + ((g-1) % 3)],
  COALESCE(tu.metadata->>'scenario', 'BULK'),
  jsonb_build_object('family_visible', CASE WHEN g % 4 = 0 THEN 'true' ELSE 'false' END)
FROM generate_series(1, 420) AS g
JOIN LATERAL (
  SELECT id, family_id, metadata FROM public.treatment_units
  WHERE deleted_at IS NULL
  ORDER BY unit_code
  OFFSET ((g - 1) % (SELECT count(*) FROM public.treatment_units WHERE deleted_at IS NULL))
  LIMIT 1
) tu ON true
LEFT JOIN LATERAL (
  SELECT id FROM public.persons
  WHERE treatment_unit_id = tu.id AND deleted_at IS NULL
  ORDER BY created_at
  LIMIT 1
) pe ON true;

INSERT INTO public.task_assignees (task_id, profile_id, assigned_by)
SELECT t.id,
  COALESCE(tu.primary_case_manager_id, '11111111-1111-4111-8111-111111111103'),
  '11111111-1111-4111-8111-111111111106'
FROM public.tasks t
JOIN public.treatment_units tu ON tu.id = t.treatment_unit_id
WHERE t.created_at > timezone('utc', now()) - interval '1 minute'
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------------------
-- Communications (family / internal / interagency) for A–E
-- ---------------------------------------------------------------------------
INSERT INTO public.communication_threads (id, channel_type, family_id, treatment_unit_id, subject_he, created_by) VALUES
  ('c1000000-0000-4000-8000-0000000000a1', 'family_portal', 'f0000000-0000-4000-8000-00000000000a', NULL, 'עדכונים למשפחת כהן', '11111111-1111-4111-8111-111111111103'),
  ('c1000000-0000-4000-8000-0000000000a2', 'internal', NULL, 'a4000000-0000-4000-8000-00000000000a', 'צוות פנימי — כהן', '11111111-1111-4111-8111-111111111103'),
  ('c1000000-0000-4000-8000-0000000000b1', 'family_portal', 'f0000000-0000-4000-8000-00000000000b', NULL, 'שיקום — משפחת לוי', '11111111-1111-4111-8111-111111111104'),
  ('c1000000-0000-4000-8000-0000000000c1', 'internal', NULL, 'a4000000-0000-4000-8000-00000000000c', 'הערות פנימיות — נעדר', '11111111-1111-4111-8111-111111111105'),
  ('c1000000-0000-4000-8000-0000000000e1', 'interagency', NULL, 'a4000000-0000-4000-8000-00000000000e', 'תיאום בין-משרדי — פרץ', '11111111-1111-4111-8111-111111111104')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.communications (thread_id, author_id, body_he) VALUES
  ('c1000000-0000-4000-8000-0000000000a1', '11111111-1111-4111-8111-111111111103', 'שלום רותם, עדכון לגבי הדיור הזמני — ממתינים לאישור.'),
  ('c1000000-0000-4000-8000-0000000000a1', '11111111-1111-4111-8111-111111111121', 'תודה נועה, נשמח לעדכון נוסף מחר.'),
  ('c1000000-0000-4000-8000-0000000000a2', '11111111-1111-4111-8111-111111111103', 'לתשומת לב הצוות: עדיפות גבוהה לדיור.'),
  ('c1000000-0000-4000-8000-0000000000b1', '11111111-1111-4111-8111-111111111104', 'נקבע תור ראשוני למרפאת שיקום.'),
  ('c1000000-0000-4000-8000-0000000000c1', '11111111-1111-4111-8111-111111111105', 'אין למסור פרטים מבצעיים למשפחה דרך הפורטל.'),
  ('c1000000-0000-4000-8000-0000000000e1', '11111111-1111-4111-8111-111111111104', 'נדרש תיאום דחוף בין ביטוח לאומי, בריאות ורווחה.'),
  ('c1000000-0000-4000-8000-0000000000e1', '11111111-1111-4111-8111-111111111111', 'ביטוח לאומי: נפתח תיק זכאות — ממתין למסמכים.'),
  ('c1000000-0000-4000-8000-0000000000e1', '11111111-1111-4111-8111-111111111112', 'בריאות: אחות מלווה שובצה.');

-- ---------------------------------------------------------------------------
-- Interactions (~150)
-- ---------------------------------------------------------------------------
INSERT INTO public.interactions (
  treatment_unit_id, family_id, person_id, interaction_type, occurred_at,
  duration_minutes, summary_he, conducted_by, visibility
)
SELECT
  tu.id,
  tu.family_id,
  pe.id,
  (ARRAY['phone','in_person','video','email','whatsapp','home_visit','agency_meeting']::public.interaction_type[])[1 + ((g-1) % 7)],
  timezone('utc', now()) - ((g || ' hours')::interval),
  15 + (g % 60),
  (ARRAY[
    'שיחת עדכון עם המשפחה',
    'ביקור בית',
    'פגישה עם נציג משרד',
    'תיאום טלפוני קצר',
    'שיחת וידאו לליווי'
  ])[1 + ((g-1) % 5)],
  (ARRAY[
    '11111111-1111-4111-8111-111111111103'::uuid,
    '11111111-1111-4111-8111-111111111104'::uuid,
    '11111111-1111-4111-8111-111111111105'::uuid
  ])[1 + ((g-1) % 3)],
  CASE WHEN g % 5 = 0 THEN 'family_visible' WHEN g % 5 = 1 THEN 'interagency' ELSE 'internal' END
FROM generate_series(1, 150) AS g
JOIN LATERAL (
  SELECT id, family_id FROM public.treatment_units WHERE deleted_at IS NULL
  ORDER BY unit_code OFFSET ((g-1) % (SELECT count(*) FROM public.treatment_units)) LIMIT 1
) tu ON true
LEFT JOIN LATERAL (
  SELECT id FROM public.persons WHERE treatment_unit_id = tu.id LIMIT 1
) pe ON true;

-- ---------------------------------------------------------------------------
-- Rehabilitation for ~80 returned / eligible persons
-- ---------------------------------------------------------------------------
INSERT INTO public.rehabilitation_plans (
  id, person_id, treatment_unit_id, status, title_he, goals_he, start_date, target_end_date,
  case_manager_id, agency_id
)
SELECT
  ('a7000000-0000-4000-8000-' || lpad(to_hex(g), 12, '0'))::uuid,
  p.id,
  p.treatment_unit_id,
  CASE WHEN g % 10 = 0 THEN 'completed'::public.rehab_plan_status
       WHEN g % 7 = 0 THEN 'paused'
       ELSE 'active' END,
  'תוכנית שיקום — ' || p.first_name_he || ' ' || p.last_name_he,
  'יציבות מגורים, בריאות וחוסן',
  CURRENT_DATE - ((g % 60) * INTERVAL '1 day'),
  CURRENT_DATE + ((90 + g % 120) * INTERVAL '1 day'),
  COALESCE(tu.primary_case_manager_id, '11111111-1111-4111-8111-111111111104'),
  'a0000000-0000-4000-8000-000000000001'
FROM (
  SELECT p.*, row_number() OVER (ORDER BY p.created_at, p.id) AS g
  FROM public.persons p
  WHERE p.deleted_at IS NULL
    AND p.status IN ('returned', 'family_member_only', 'captive')
  LIMIT 80
) p
JOIN public.treatment_units tu ON tu.id = p.treatment_unit_id
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.rehabilitation_activities (plan_id, title_he, activity_type, scheduled_at, status, facilitator_id)
SELECT
  rp.id,
  (ARRAY['מפגש שיקום','הערכה רפואית','קבוצת תמיכה','סיוע ביתי','ייעוץ תעסוקתי'])[1 + ((n-1) % 5)],
  (ARRAY['session','assessment','group','home_support','vocational'])[1 + ((n-1) % 5)],
  timezone('utc', now()) + ((n || ' days')::interval),
  CASE WHEN n % 4 = 0 THEN 'done' ELSE 'planned' END,
  '11111111-1111-4111-8111-111111111104'
FROM public.rehabilitation_plans rp
CROSS JOIN generate_series(1, 3) AS n
WHERE rp.deleted_at IS NULL;

INSERT INTO public.rehab_milestones (plan_id, title_he, target_date, sort_order)
SELECT rp.id, m.title, CURRENT_DATE + m.d, m.ord
FROM public.rehabilitation_plans rp
CROSS JOIN (VALUES
  ('השלמת הערכה ראשונית', 14, 1),
  ('יציבות דיור', 45, 2),
  ('חזרה לשגרה חלקית', 90, 3)
) AS m(title, d, ord)
WHERE rp.deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- Benefits, events, content, knowledge, notifications, audit sample
-- ---------------------------------------------------------------------------
INSERT INTO public.benefits (id, code, name_he, category, owning_agency_id) VALUES
  ('b0000000-0000-4000-8000-000000000001', 'BEN-HOUSING', 'סיוע בדיור', 'housing', 'a0000000-0000-4000-8000-000000000006'),
  ('b0000000-0000-4000-8000-000000000002', 'BEN-INCOME', 'מענק כלכלי', 'economic', 'a0000000-0000-4000-8000-000000000001'),
  ('b0000000-0000-4000-8000-000000000003', 'BEN-HEALTH', 'ליווי רפואי', 'health', 'a0000000-0000-4000-8000-000000000002'),
  ('b0000000-0000-4000-8000-000000000004', 'BEN-LEGAL', 'סיוע משפטי', 'rights', 'a0000000-0000-4000-8000-000000000004'),
  ('b0000000-0000-4000-8000-000000000005', 'BEN-EDU', 'מעטפת חינוך', 'education', 'a0000000-0000-4000-8000-000000000005')
ON CONFLICT (code) DO NOTHING;

INSERT INTO public.benefit_entitlements (benefit_id, person_id, family_id, treatment_unit_id, status, reference_number)
SELECT
  b.id, p.id, p.family_id, p.treatment_unit_id,
  (ARRAY['eligible','applied','approved','in_payment'])[1 + ((row_number() OVER ()) % 4)],
  'REF-DEMO-' || lpad((row_number() OVER ())::text, 4, '0')
FROM public.persons p
CROSS JOIN public.benefits b
WHERE p.is_index_case
LIMIT 100;

INSERT INTO public.portal_events (id, title_he, description_he, location_he, starts_at, ends_at, event_type, audience, capacity, created_by, is_published)
VALUES
  ('e0000000-0000-4000-8000-000000000001', 'מפגש חוסן למשפחות', 'קבוצת תמיכה בהנחיית עו״ס', 'תל אביב', timezone('utc', now()) + interval '7 days', timezone('utc', now()) + interval '7 days 2 hours', 'support_group', 'families', 40, '11111111-1111-4111-8111-111111111109', true),
  ('e0000000-0000-4000-8000-000000000002', 'תדרוך נציגים ממשלתיים', 'סנכרון מענים', 'ירושלים', timezone('utc', now()) + interval '10 days', timezone('utc', now()) + interval '10 days 3 hours', 'briefing', 'gov', 60, '11111111-1111-4111-8111-111111111108', true),
  ('e0000000-0000-4000-8000-000000000003', 'סדנת זכויות', 'מיצוי זכויות בסיסי', 'באר שבע', timezone('utc', now()) + interval '14 days', NULL, 'workshop', 'families', 50, '11111111-1111-4111-8111-111111111109', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.event_registrations (event_id, profile_id, status) VALUES
  ('e0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111121', 'registered'),
  ('e0000000-0000-4000-8000-000000000001', '11111111-1111-4111-8111-111111111122', 'registered'),
  ('e0000000-0000-4000-8000-000000000003', '11111111-1111-4111-8111-111111111125', 'registered')
ON CONFLICT DO NOTHING;

INSERT INTO public.content_items (id, slug, title_he, summary_he, body_he, status, audience, category, author_id, reviewer_id, published_at)
VALUES
  ('a8000000-0000-4000-8000-000000000001', 'welcome-families', 'ברוכים הבאים לפורטל המשפחות', 'מידע ראשוני', 'תוכן הדגמה: מדריך קצר למשפחות.', 'published', 'families', 'guide', '11111111-1111-4111-8111-111111111109', '11111111-1111-4111-8111-111111111110', timezone('utc', now())),
  ('a8000000-0000-4000-8000-000000000002', 'staff-sop-tasks', 'נוהל פתיחת משימות', 'לצוות פנימי', 'תוכן הדגמה: נוהל פנימי.', 'published', 'staff', 'procedure', '11111111-1111-4111-8111-111111111109', '11111111-1111-4111-8111-111111111110', timezone('utc', now())),
  ('a8000000-0000-4000-8000-000000000003', 'draft-announcement', 'הודעה בעריכה', 'טיוטה', 'טיוטה בלבד', 'draft', 'staff', 'announcement', '11111111-1111-4111-8111-111111111109', NULL, NULL)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.content_versions (content_item_id, version_number, title_he, body_he, edited_by, change_note_he)
SELECT id, 1, title_he, body_he, author_id, 'גרסה ראשונה'
FROM public.content_items
ON CONFLICT DO NOTHING;

INSERT INTO public.knowledge_categories (id, slug, name_he, sort_order) VALUES
  ('a8100000-0000-4000-8000-000000000001', 'rights', 'מיצוי זכויות', 1),
  ('a8100000-0000-4000-8000-000000000002', 'health', 'בריאות ושיקום', 2),
  ('a8100000-0000-4000-8000-000000000003', 'housing', 'דיור', 3)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.knowledge_articles (id, category_id, slug, title_he, summary_he, body_he, audience, is_published, author_id, published_at)
VALUES
  ('a8200000-0000-4000-8000-000000000001', 'a8100000-0000-4000-8000-000000000001', 'rights-overview', 'סקירת זכויות למשפחות', 'תקציר', 'מאמר הדגמה על זכויות.', 'mixed', true, '11111111-1111-4111-8111-111111111109', timezone('utc', now())),
  ('a8200000-0000-4000-8000-000000000002', 'a8100000-0000-4000-8000-000000000002', 'rehab-path', 'מסלול שיקום לשבים', 'תקציר', 'מאמר הדגמה על שיקום.', 'families', true, '11111111-1111-4111-8111-111111111109', timezone('utc', now())),
  ('a8200000-0000-4000-8000-000000000003', 'a8100000-0000-4000-8000-000000000003', 'housing-aid', 'סיוע בדיור — שאלות נפוצות', 'תקציר', 'מאמר הדגמה.', 'families', true, '11111111-1111-4111-8111-111111111109', timezone('utc', now()))
ON CONFLICT (slug) DO NOTHING;

INSERT INTO public.notifications (recipient_id, channel, title_he, body_he, link_path)
VALUES
  ('11111111-1111-4111-8111-111111111103', 'in_app', 'משימה חדשה בתיק כהן', 'נפתחה משימת דיור', '/tasks/a6000000-0000-4000-8000-0000000000a1'),
  ('11111111-1111-4111-8111-111111111121', 'in_app', 'הודעה חדשה מהמלווה', 'עדכון בשיחת הפורטל', '/messages'),
  ('11111111-1111-4111-8111-111111111111', 'in_app', 'תיאום בין-משרדי', 'נדרשת התייחסות לתיק פרץ', '/tasks/a6000000-0000-4000-8000-0000000000e1');

INSERT INTO public.audit_logs (actor_id, action, entity_table, entity_id, family_id, treatment_unit_id, after_data)
VALUES
  ('11111111-1111-4111-8111-111111111102', 'seed.complete', 'families', 'f0000000-0000-4000-8000-00000000000a', 'f0000000-0000-4000-8000-00000000000a', 'a4000000-0000-4000-8000-00000000000a', '{"note":"demo seed applied"}'::jsonb);

COMMIT;

-- Expected approximate counts after seed:
-- families >= 30; treatment_units >= 45; persons >= 120;
-- tasks >= 400; interactions = 150; rehab plans = 80
