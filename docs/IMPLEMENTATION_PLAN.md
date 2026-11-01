# Manhelet Portal — Implementation Plan & Tracker

**Branch:** `cursor/manhelet-portal-app-133d`  
**Backend:** `qdwuwxqouazqwvsjhobo`  
**Entrypoint:** `lib/main_manhelet.dart`

Status legend: Not Started · In Progress · Implemented · Tested · Blocked

## PHASE 0 — Audit

| Module | Status | Notes |
|--------|--------|-------|
| Codebase + schema audit | Implemented | `docs/IMPLEMENTATION_AUDIT.md` |
| Stitch design import | Blocked | Assets not in repo/store |

## PHASE 1 — Foundation

| Module / Screen | Functionality | DB deps | Status | Tests |
|-----------------|---------------|---------|--------|-------|
| Supabase Minhelet config | Publishable client only | — | Implemented | analyze |
| Auth login/logout/session | Email/password Auth | profiles | Implemented | smoke Auth |
| Role resolution | Multi-role | user_roles | Implemented | smoke |
| Protected routes | go_router redirect | — | Implemented | analyze |
| Demo user switcher | Real sign-in | Auth | Implemented | smoke (after sync) |
| App shell RTL | Nav by role | — | Implemented | web build |
| Domain services | Task/Caseload/Notify/Content/Auth | tables/views | Implemented | smoke reads |
| RLS helper recursion fix | mig 14 DEFINER helpers | helpers | Implemented | smoke OK |

## PHASE 2 — Core operational

| Module / Screen | Functionality | DB deps | Status | Tests |
|-----------------|---------------|---------|--------|-------|
| סביבת העבודה שלי | Live KPIs + filter nav | tasks, notifications, content | Implemented | unit attention rules |
| מרכז המשימות A/B | Dual view + shared filters | tasks, units | Implemented | analyze |
| פרטי משימה | Drawer/page, status, messages | tasks, communications | Implemented | smoke |
| משפחות / יחידות / אדם | Hierarchy read/nav | families, units, persons | Implemented | analyze |
| הנהלה situation | v_executive_situation | view | Implemented | analyze |
| Family home | v_family_portal_home | view | Implemented | RLS smoke (0 internal) |

## PHASE 3 — Operational modules

| Module | Status | Notes |
|--------|--------|-------|
| Interactions + calendar | Not Started | |
| Rehabilitation UI | Not Started | |
| Events / benefits full workflow | Not Started | May need additive columns |

## PHASE 4 — Government portal polish | In Progress | Nav + task/unit access via RLS; dedicated polish TBD |

## PHASE 5 — Family portal | In Progress | Home live; requests/messages TBD |

## PHASE 6 — Org home / knowledge / search | Not Started |

## PHASE 7 — Management / admin | Not Started | Executive view started |

## PHASE 8 — Verification

| Item | Status |
|------|--------|
| `flutter analyze` manhelet | Tested — clean |
| Unit tests domain models | Tested — 5 passed |
| `flutter build web -t lib/main_manhelet.dart` | Tested — OK |
| Auth+RLS smoke script | Tested — case mgr reads; family internal threads=0 |
| E2E Scenario 1–6 full | Not Started |

## Known blockers / gaps

1. No Google Stitch source — functional RTL shell pending assets.  
2. Demo passwords must be synced locally (not in git).  
3. Phases 3–7 largely incomplete.  
4. Migration `14_fix_rls_helper_recursion.sql` applied live (required for queries).
