-- Additive schema for the topic sender. Existing posts are never backfilled.
create table public.notification_outbox (
  post_id bigint primary key references public.posts(id) on delete cascade,
  attempts integer not null default 0,
  next_attempt_at timestamptz not null default now(),
  sent_at timestamptz,
  last_error text
);
create index notification_outbox_pending_idx on public.notification_outbox(next_attempt_at, post_id) where sent_at is null;

-- Keep a snapshot even after a device is removed, so its topics can be removed.
create table public.fcm_topic_memberships (
  fcm_token text not null,
  board_id text not null,
  primary key (fcm_token, board_id)
);
create table public.crawler_leases (
  name text primary key,
  owner uuid not null,
  expires_at timestamptz not null
);
alter table public.notification_outbox enable row level security;
alter table public.fcm_topic_memberships enable row level security;
alter table public.crawler_leases enable row level security;
revoke all on public.notification_outbox, public.fcm_topic_memberships, public.crawler_leases from public, anon, authenticated;
grant all on public.notification_outbox, public.fcm_topic_memberships, public.crawler_leases to service_role;
create policy server_only on public.notification_outbox to service_role using (true) with check (true);
create policy server_only on public.fcm_topic_memberships to service_role using (true) with check (true);
create policy server_only on public.crawler_leases to service_role using (true) with check (true);

create function public.acquire_crawler_lease(p_owner uuid) returns boolean
language sql security invoker set search_path = '' as $$
  with acquired as (
    insert into public.crawler_leases(name, owner, expires_at)
    values ('rss', p_owner, now() + interval '20 minutes')
    on conflict (name) do update set owner = excluded.owner, expires_at = excluded.expires_at
      where public.crawler_leases.expires_at < now()
    returning name
  ) select exists(select 1 from acquired);
$$;

-- Inserting a post and scheduling its notification commit together.
create function public.enqueue_rss_post(p_post jsonb) returns bigint
language plpgsql security invoker set search_path = '' as $$
declare new_id bigint;
begin
  insert into public.posts(board_id, title, link, description, author, pub_date)
  values (p_post->>'board_id', p_post->>'title', p_post->>'link',
    p_post->>'description', p_post->>'author', (p_post->>'pub_date')::timestamptz)
  on conflict (link) do nothing returning id into new_id;
  if new_id is not null then
    insert into public.notification_outbox(post_id) values (new_id);
  end if;
  return new_id;
end;
$$;
revoke execute on function public.acquire_crawler_lease(uuid), public.enqueue_rss_post(jsonb) from public, anon, authenticated;
grant execute on function public.acquire_crawler_lease(uuid), public.enqueue_rss_post(jsonb) to service_role;
create index if not exists user_devices_user_id_idx on public.user_devices(user_id);
create index if not exists posts_board_pub_date_idx on public.posts(board_id, pub_date desc, id desc);
