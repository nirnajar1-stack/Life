-- Phase 1 Skill 3: optional communication_channel dimension on events

create type pd_communication_channel as enum (
  'face_to_face',
  'meeting',
  'phone',
  'video_call',
  'chat',
  'email',
  'presentation'
);

alter table pd_events
  add column communication_channel pd_communication_channel;

insert into pd_skill_progress (skill_id, current_stage_id, events_in_stage)
values ('clear_communication', 'awareness', 0)
on conflict (skill_id) do nothing;

update pd_focus_cycles
set notes = 'Phase 1 — Skills: Self Regulation, Assertiveness, Clear Communication'
where cycle_end is null;
