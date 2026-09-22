-- ============================================================================
-- Fix: "service" write policies were open to everyone, reference data was writable
-- ----------------------------------------------------------------------------
-- Verified against this project before the change:
--   POST /rest/v1/alerts  (anon key only) -> 201  ← anyone could publish a
--   fake "Critical Flood Warning" and every client received it over realtime.
--
-- Causes found:
--   * alerts_service_insert / timeline_service_insert / contact_messages_service_insert
--     were created without a `to <role>` clause, so they apply to PUBLIC — i.e.
--     every role including `anon`. The names said service, the policy said open.
--   * districts / alert_types had RLS disabled *and* full INSERT/UPDATE/DELETE
--     grants for anon, so the reference data the aggregator and hazard map read
--     could be rewritten by any anon-key holder.
--   * expire_stale_alerts() is SECURITY DEFINER and documented "service-role
--     only", but was executable by anon/authenticated via /rpc.
--
-- The Flutter client only ever reads these tables (see realtime_alerts_service.dart
-- and landslide_repository_impl.dart); every write goes through an Edge Function
-- using the service role. sos_alerts / crisis_pins keep their public INSERT
-- policies on purpose — those are genuine community submissions.
--
-- Re-verified after applying: anon INSERT alerts -> 401, anon PATCH districts
-- -> 401 (permission denied), anon SELECT districts -> 200, alert-aggregator
-- (service role) -> 5 alerts upserted, contact function -> 200.
-- ============================================================================

-- 1) Alert / timeline / contact writes: service role only -------------------
--    (service_role has BYPASSRLS, so these policies are kept for the case where
--     FORCE ROW LEVEL SECURITY is applied later; anon now matches nothing.)

drop policy if exists alerts_service_insert on public.alerts;
create policy alerts_service_insert on public.alerts
  for insert to service_role with check (true);

drop policy if exists timeline_service_insert on public.timeline_events;
create policy timeline_service_insert on public.timeline_events
  for insert to service_role with check (true);

drop policy if exists contact_messages_service_insert on public.contact_messages;
create policy contact_messages_service_insert on public.contact_messages
  for insert to service_role with check (true);

revoke insert, update, delete, truncate, references, trigger
  on public.alerts, public.timeline_events, public.contact_messages
  from anon, authenticated;

-- 2) Reference data: read-only for clients ---------------------------------

alter table public.districts enable row level security;
alter table public.alert_types enable row level security;

drop policy if exists districts_public_read on public.districts;
create policy districts_public_read on public.districts
  for select to anon, authenticated using (true);

drop policy if exists alert_types_public_read on public.alert_types;
create policy alert_types_public_read on public.alert_types
  for select to anon, authenticated using (true);

revoke insert, update, delete, truncate, references, trigger
  on public.districts, public.alert_types
  from anon, authenticated;

-- 3) expire_stale_alerts(): service role only ------------------------------

revoke execute on function public.expire_stale_alerts() from public, anon, authenticated;
grant execute on function public.expire_stale_alerts() to service_role;

-- 4) Pin search_path on the exposed functions (clears 7 linter WARNs) ------

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.proname in (
        'expire_stale_alerts', 'set_updated_at', 'get_active_alerts',
        'get_timeline_events', 'get_nearby_pins', 'toggle_pin_watch',
        'get_alert_subscriptions')
  loop
    execute format('alter function %s set search_path = public, extensions', r.sig);
  end loop;
end $$;
