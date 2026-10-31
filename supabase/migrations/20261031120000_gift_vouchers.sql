-- Gift vouchers (שוברי מתנה) tracked under Income.

create table if not exists public.gift_vouchers (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  store_name text,
  original_amount numeric not null check (original_amount > 0),
  remaining_amount numeric not null check (remaining_amount >= 0),
  voucher_link text,
  barcode_image_url text,
  notes text,
  received_at date not null default (timezone('utc'::text, now()))::date,
  expires_at date,
  is_archived boolean not null default false,
  created_at timestamptz not null default timezone('utc'::text, now()),
  updated_at timestamptz not null default timezone('utc'::text, now()),
  constraint gift_vouchers_remaining_lte_original
    check (remaining_amount <= original_amount)
);

create index if not exists gift_vouchers_active_idx
  on public.gift_vouchers (is_archived, remaining_amount desc, received_at desc);

create index if not exists gift_vouchers_received_at_idx
  on public.gift_vouchers (received_at desc);

grant select, insert, update, delete on table public.gift_vouchers
  to anon, authenticated, service_role;

-- Public storage for barcode / voucher images (single-user app).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'gift-vouchers',
  'gift-vouchers',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "gift_vouchers_public_read" on storage.objects;
drop policy if exists "gift_vouchers_anon_insert" on storage.objects;
drop policy if exists "gift_vouchers_anon_update" on storage.objects;
drop policy if exists "gift_vouchers_anon_delete" on storage.objects;

create policy "gift_vouchers_public_read"
  on storage.objects for select
  using (bucket_id = 'gift-vouchers');

create policy "gift_vouchers_anon_insert"
  on storage.objects for insert
  with check (bucket_id = 'gift-vouchers');

create policy "gift_vouchers_anon_update"
  on storage.objects for update
  using (bucket_id = 'gift-vouchers')
  with check (bucket_id = 'gift-vouchers');

create policy "gift_vouchers_anon_delete"
  on storage.objects for delete
  using (bucket_id = 'gift-vouchers');
