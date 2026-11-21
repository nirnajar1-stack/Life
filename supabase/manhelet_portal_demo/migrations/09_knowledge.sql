-- Manhelet Portal Demo — 09 knowledge base

CREATE TABLE IF NOT EXISTS public.knowledge_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id uuid REFERENCES public.knowledge_categories(id),
  slug text NOT NULL UNIQUE,
  name_he text NOT NULL,
  sort_order int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE TRIGGER trg_knowledge_categories_updated
  BEFORE UPDATE ON public.knowledge_categories
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS public.knowledge_articles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES public.knowledge_categories(id),
  slug text NOT NULL UNIQUE,
  title_he text NOT NULL,
  summary_he text,
  body_he text NOT NULL,
  audience text NOT NULL DEFAULT 'staff'
    CHECK (audience IN ('staff','families','gov','mixed')),
  is_published boolean NOT NULL DEFAULT false,
  author_id uuid REFERENCES public.profiles(id),
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_knowledge_articles_cat ON public.knowledge_articles(category_id)
  WHERE deleted_at IS NULL AND is_published;
CREATE INDEX IF NOT EXISTS idx_knowledge_articles_title_trgm ON public.knowledge_articles
  USING gin (title_he gin_trgm_ops);

CREATE TRIGGER trg_knowledge_articles_updated
  BEFORE UPDATE ON public.knowledge_articles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
