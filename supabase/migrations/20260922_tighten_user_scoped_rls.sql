-- ============================================================================
-- Fix: user-scoped RLS was readable (and writable) by any anon request
-- ----------------------------------------------------------------------------
-- The Clerk-era policies fell back to the row's own value when the JWT had no
-- `sub` claim:
--   clerk_user_id = coalesce(request.jwt.claims ->> 'sub', clerk_user_id)
-- For an anon request the coalesce yields clerk_user_id, so the predicate
-- became `clerk_user_id = clerk_user_id` — always true (the column is NOT
-- NULL). Anyone holding the public anon key could list every user's pin
-- watches and district/type subscriptions.
--
-- The app now authenticates with Supabase Auth, so `auth.jwt() ->> 'sub'` is
-- the caller's real user id; there is no second provider to bridge anymore.
-- pin_watches also had no INSERT/DELETE policy at all, which meant the
-- documented `toggle_pin_watch()` RPC (SECURITY INVOKER) could never insert or
-- delete a watch row. Those are added for `authenticated` only.
-- ============================================================================

drop policy if exists pin_watches_self_read on public.pin_watches;
drop policy if exists subscriptions_self_read on public.alert_subscriptions;
drop policy if exists subscriptions_self_write on public.alert_subscriptions;

create policy pin_watches_self_read on public.pin_watches
  for select to authenticated
  using (clerk_user_id = (auth.jwt() ->> 'sub'));

create policy pin_watches_self_insert on public.pin_watches
  for insert to authenticated
  with check (clerk_user_id = (auth.jwt() ->> 'sub'));

create policy pin_watches_self_delete on public.pin_watches
  for delete to authenticated
  using (clerk_user_id = (auth.jwt() ->> 'sub'));

create policy subscriptions_self_read on public.alert_subscriptions
  for select to authenticated
  using (clerk_user_id = (auth.jwt() ->> 'sub'));

create policy subscriptions_self_write on public.alert_subscriptions
  for all to authenticated
  using (clerk_user_id = (auth.jwt() ->> 'sub'))
  with check (clerk_user_id = (auth.jwt() ->> 'sub'));
