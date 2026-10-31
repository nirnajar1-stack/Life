-- Personal Development OS — Foundation Phase 0 (additive, single-user)

create type pd_event_type as enum ('real_world', 'practice', 'drill');
create type pd_context_level as enum ('low', 'medium', 'high');
create type pd_safety_level as enum ('safe', 'uncertain', 'unsafe');

create table pd_focus_cycles (
  id uuid primary key default gen_random_uuid(),
  primary_skill_id text not null,
  secondary_skill_id text,
  trait_focus text,
  cycle_start date not null default current_date,
  cycle_end date,
  notes text,
  created_at timestamptz not null default now()
);

create table pd_skill_progress (
  skill_id text primary key,
  current_stage_id text not null,
  events_in_stage int not null default 0,
  updated_at timestamptz not null default now()
);

create table pd_events (
  id uuid primary key default gen_random_uuid(),
  skill_id text not null,
  event_type pd_event_type not null default 'real_world',
  occurred_at timestamptz not null default now(),
  relationship_type text,
  power_gap pd_context_level,
  relationship_safety pd_safety_level,
  outcome_importance pd_context_level,
  difficulty pd_context_level,
  emotional_activation pd_context_level,
  situation_id text,
  notes text,
  created_at timestamptz not null default now()
);

create table pd_event_skills (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references pd_events(id) on delete cascade,
  skill_id text not null,
  micro_behaviors jsonb not null default '[]'::jsonb,
  performance_score smallint check (performance_score between 1 and 5),
  stage_at_event text,
  created_at timestamptz not null default now()
);

create index pd_events_skill_id_idx on pd_events (skill_id);
create index pd_events_occurred_at_idx on pd_events (occurred_at desc);
create index pd_event_skills_event_id_idx on pd_event_skills (event_id);
create index pd_focus_cycles_cycle_start_idx on pd_focus_cycles (cycle_start desc);

-- Seed default focus cycle for Self Regulation
insert into pd_focus_cycles (primary_skill_id, notes)
values ('self_regulation', 'Foundation Phase 0 — primary focus');

insert into pd_skill_progress (skill_id, current_stage_id, events_in_stage)
values ('self_regulation', 'awareness', 0);
