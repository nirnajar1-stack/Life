-- Character Layer Phase 2 — behavioral evidence (separate from Skill engine)

create type pd_character_evidence_source as enum (
  'event',
  'manual_reflection',
  'weekly_review',
  'mission'
);

create table pd_character_evidence (
  id uuid primary key default gen_random_uuid(),
  trait_id text not null,
  indicator_id text not null,
  occurred_at timestamptz not null default now(),
  event_id uuid references pd_events(id) on delete set null,
  context jsonb,
  opportunity_detected boolean not null default true,
  demonstrated boolean not null,
  note text,
  source pd_character_evidence_source not null default 'manual_reflection',
  created_at timestamptz not null default now()
);

create index pd_character_evidence_trait_id_idx on pd_character_evidence (trait_id);
create index pd_character_evidence_occurred_at_idx on pd_character_evidence (occurred_at desc);
create index pd_character_evidence_event_id_idx on pd_character_evidence (event_id);

update pd_focus_cycles
set trait_focus = 'curiosity'
where cycle_end is null and trait_focus is null;
