-- Manhelet Portal Demo — 10 notifications + audit_logs

CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  channel public.notification_channel NOT NULL DEFAULT 'in_app',
  title_he text NOT NULL,
  body_he text,
  link_path text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread
  ON public.notifications(recipient_id, created_at DESC)
  WHERE read_at IS NULL;

CREATE TABLE IF NOT EXISTS public.audit_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid REFERENCES public.profiles(id),
  action text NOT NULL,
  entity_table text NOT NULL,
  entity_id uuid,
  family_id uuid,
  treatment_unit_id uuid,
  before_data jsonb,
  after_data jsonb,
  ip inet,
  user_agent text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON public.audit_logs(entity_table, entity_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor ON public.audit_logs(actor_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_family ON public.audit_logs(family_id, created_at DESC);
