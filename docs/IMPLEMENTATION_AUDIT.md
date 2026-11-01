# Manhelet Portal — Implementation Audit (Phase 0)

**Date:** 2026-11-01  
**Target backend:** Supabase `qdwuwxqouazqwvsjhobo` (פורטל המנהלת demo)  
**Repo:** `nirnajar1-stack/Life` (Flutter Life App monorepo)  
**Auditor branch:** `cursor/manhelet-portal-app-133d`

## 1. What this repository is today

| Area | Finding |
|------|---------|
| Framework | **Flutter** (Dart ≥3), Riverpod, `supabase_flutter`, Hebrew RTL |
| Product in `lib/` | **Life App** — personal tasks/habits/expenses/income/calendar |
| Supabase wired in client | **Life / Nir_DB** `grxumlgwgzmnnpxlgzah` via `lib/core/supabase/supabase_config.dart` |
| Routing | No `go_router`; `MaterialApp(home: AppShell)` + tab provider |
| Auth (Life) | Supabase initialized; **no login/role UI** for multi-user portal |
| State | Riverpod providers per Life feature |
| Design system | Life App navy/cream (`AppTheme`); `design-system/life-app/` |
| Google Stitch assets | **Not present** in repo or Project store (`media/`, docs) |
| Manhelet SQL | Isolated under `supabase/manhelet_portal_demo/migrations/` (PR #10) |
| Data-access stub | `integrations/manhelet_portal_demo/data_access.ts` (TS contracts only) |
| Flutter SDK in CI image | Not preinstalled; installed for this agent at `/opt/flutter` |

## 2. Live Minhelet schema (inspected via pooler)

**30 tables** with RLS enabled; **5 views**.

Core hierarchy: `families` → `treatment_units` → `persons` (+ `profile_person_links`).

Identity: `profiles`, `roles`, `user_roles`, `organizational_units`, `government_agencies`, `government_representatives`, `gov_rep_treatment_units`.

Work: `tasks`, `task_assignees`, `task_watchers`, `communication_threads`, `communications`, `interactions`.

Rehab: `rehabilitation_plans`, `rehabilitation_activities`, `rehab_milestones`.

Events/benefits: `portal_events`, `event_registrations`, `benefits`, `benefit_entitlements`.

Org/knowledge: `content_items`, `content_versions`, `knowledge_categories`, `knowledge_articles`, `notifications`, `audit_logs`.

Enums in use: `app_role`, `task_status`, `task_priority`, `channel_type`, `interaction_type`, `person_status`, `content_status`, `rehab_plan_status`, etc.

Views: `v_my_open_tasks`, `v_treatment_unit_caseload`, `v_family_portal_home`, `v_rehab_dashboard`, `v_executive_situation`.

Demo seed verified live: 30 families, 45 units, 120 persons, 425 tasks, 150 interactions, 80 rehab plans; 18 Auth users.

## 3. Classification

### Already works (backend)

- Relational model + FKs/triggers (person↔unit on tasks, etc.)
- RLS helpers / policies for roles
- Demo Auth users (credentials only under Project `internal/`)
- Seeded scenarios A–E

### Partially implemented

- TS service **interfaces** (no Flutter adapter yet)
- Architecture docs under Project store `docs/manhelet-portal-demo/`

### Visual only / missing in repo

- Entire Manhelet UI (dashboard, task center, family portal, gov portal, …)
- Stitch design source files (gap)
- Manhelet Auth / role routing
- Attachment storage, mentions table, service-request entity, activity candidate/response workflow beyond basic `event_registrations`
- Interaction multi-participant junction
- Content acknowledgement records

### Must not do

- Point Life App client at Minhelet DB
- Drop/alter unrelated Life migrations or Nir_DB
- Put `service_role` or DB password in browser/Flutter client

## 4. Schema gaps vs product brief (blocking vs adaptable)

| Brief need | DB today | Approach |
|------------|----------|----------|
| Task statuses | `task_status` enum | Use as-is; Hebrew labels in UI |
| Overdue / SLA | `due_at` nullable | Overdue = `due_at < now()` and not completed/cancelled |
| Task chat channels | `channel_type` family/internal/interagency | Map shared=interagency; internal=internal; family cannot read internal |
| Mentions / attachments | Missing | Phase 2: mention via `notifications` + metadata; attachments deferred or Storage+minimal table migration |
| Family service requests | Missing | Map to `tasks` with `metadata.family_visible` + public status mapping; optional later table |
| Activity candidates / response enums | Partial (`event_registrations.status`) | Extend via additive migration when Phase 3 needs it |
| Rehab domains/templates | Plans/milestones/activities | Present plan as domain; milestones collapsible |
| Interaction participants N | Single `conducted_by` + metadata | Store participant IDs in `metadata` until junction migration |
| Stitch pixels | Absent | Functional RTL shell aligned to product IA; swap when Stitch assets arrive |

## 5. Architecture decision

Build **פורטל המנהלת** as a **separate Flutter entrypoint** inside this repo:

- `lib/main_manhelet.dart` + `lib/manhelet_portal/**`
- Own Supabase config → `qdwuwxqouazqwvsjhobo` + **publishable** key only
- Domain services (no raw queries in widgets)
- Salesforce-swappable service interfaces mirrored from TS stub
- **Do not** modify Life App tabs/shell/Nir_DB config

Rationale: same approved Flutter stack; hard isolation from personal Life App; uses real Minhelet schema.

## 6. Environment

| Item | Value |
|------|--------|
| Minhelet URL | `https://qdwuwxqouazqwvsjhobo.supabase.co` |
| Client key | publishable from Project `internal/supabase-minhelet.env` (copied to Dart config; not service_role) |
| Demo passwords | Project `internal/manhelet-demo-auth-credentials.md` → gitignored `demo_credentials.local.dart` |

## 7. Recommended immediate work

1. Phase 1 foundation (auth, roles, shell, services).  
2. Phase 2 core ops (dashboard, tasks, hierarchy).  
3. Additive DB only when a Phase 3+ workflow cannot map onto existing tables.
