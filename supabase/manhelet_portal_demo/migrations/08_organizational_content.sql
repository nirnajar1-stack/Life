-- Manhelet Portal Demo — 08 organizational content

CREATE TABLE IF NOT EXISTS public.content_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  title_he text NOT NULL,
  summary_he text,
  body_he text,
  status public.content_status NOT NULL DEFAULT 'draft',
  audience text NOT NULL DEFAULT 'staff'
    CHECK (audience IN ('staff','families','gov','public_demo')),
  category text NOT NULL DEFAULT 'announcement'
    CHECK (category IN ('announcement','procedure','faq','guide','news','other')),
  author_id uuid REFERENCES public.profiles(id),
  reviewer_id uuid REFERENCES public.profiles(id),
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_content_items_status ON public.content_items(status)
  WHERE deleted_at IS NULL;
CREATE TRIGGER trg_content_items_updated
  BEFORE UPDATE ON public.content_items
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.content_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  content_item_id uuid NOT NULL REFERENCES public.content_items(id) ON DELETE CASCADE,
  version_number int NOT NULL,
  title_he text NOT NULL,
  body_he text,
  edited_by uuid REFERENCES public.profiles(id),
  change_note_he text,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  UNIQUE (content_item_id, version_number)
);
