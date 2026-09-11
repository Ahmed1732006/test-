-- IN THE VOID — Platform link buttons
-- Run this once in Supabase SQL Editor.

create table if not exists public.platform_buttons (
  id bigint generated always as identity primary key,
  button_key text not null unique,
  label text not null default 'رابط',
  color text not null default '#2563eb',
  icon text null,
  url text not null default '',
  image_url text null,
  image_path text null,
  is_enabled boolean not null default true,
  audience_mode text not null default 'all'
    check (audience_mode in ('all','members','moderators','admins')),
  start_at timestamptz null,
  end_at timestamptz null,
  sort_order integer not null default 10,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  updated_by uuid null references auth.users(id) on delete set null
);

alter table public.platform_buttons enable row level security;

drop policy if exists "platform_buttons_select_authenticated" on public.platform_buttons;
create policy "platform_buttons_select_authenticated"
on public.platform_buttons
for select
to authenticated
using (true);

drop policy if exists "platform_buttons_admin_insert" on public.platform_buttons;
create policy "platform_buttons_admin_insert"
on public.platform_buttons
for insert
to authenticated
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

drop policy if exists "platform_buttons_admin_update" on public.platform_buttons;
create policy "platform_buttons_admin_update"
on public.platform_buttons
for update
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
)
with check (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

drop policy if exists "platform_buttons_admin_delete" on public.platform_buttons;
create policy "platform_buttons_admin_delete"
on public.platform_buttons
for delete
to authenticated
using (
  exists (
    select 1 from public.profiles p
    where p.id = auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

-- Public images are stored separately so GIF/WebP/etc. can display directly.
insert into storage.buckets (id, name, public)
values ('platform-buttons','platform-buttons',true)
on conflict (id) do update set public=true;

drop policy if exists "platform_buttons_images_public_read" on storage.objects;
create policy "platform_buttons_images_public_read"
on storage.objects
for select
to public
using (bucket_id='platform-buttons');

drop policy if exists "platform_buttons_images_admin_insert" on storage.objects;
create policy "platform_buttons_images_admin_insert"
on storage.objects
for insert
to authenticated
with check (
  bucket_id='platform-buttons'
  and exists (
    select 1 from public.profiles p
    where p.id=auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

drop policy if exists "platform_buttons_images_admin_update" on storage.objects;
create policy "platform_buttons_images_admin_update"
on storage.objects
for update
to authenticated
using (
  bucket_id='platform-buttons'
  and exists (
    select 1 from public.profiles p
    where p.id=auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
)
with check (
  bucket_id='platform-buttons'
  and exists (
    select 1 from public.profiles p
    where p.id=auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

drop policy if exists "platform_buttons_images_admin_delete" on storage.objects;
create policy "platform_buttons_images_admin_delete"
on storage.objects
for delete
to authenticated
using (
  bucket_id='platform-buttons'
  and exists (
    select 1 from public.profiles p
    where p.id=auth.uid()
      and p.role in ('admin','super_admin')
      and coalesce(p.status,'active') not in ('pending','revoked')
  )
);

insert into public.platform_buttons
(button_key,label,color,icon,url,is_enabled,audience_mode,sort_order)
values
('whatsapp','واتساب','#25D366','fa-brands fa-whatsapp','',true,'all',1),
('telegram','تليجرام','#229ED9','fa-brands fa-telegram','',true,'all',2)
on conflict (button_key) do nothing;

notify pgrst, 'reload schema';
