-- Phase 1: Assertiveness skill seed + focus cycle secondary skill

insert into pd_skill_progress (skill_id, current_stage_id, events_in_stage)
values ('assertiveness', 'awareness', 0)
on conflict (skill_id) do nothing;

update pd_focus_cycles
set
  secondary_skill_id = 'assertiveness',
  notes = 'Phase 1 — Self Regulation primary, Assertiveness secondary'
where cycle_end is null
  and primary_skill_id = 'self_regulation';
