-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20260624_02_user_scoped_and_realtime
-- Purpose:   Add Clerk-user-scoped tables (pin_watches,
--            alert_subscriptions) and add timeline_events to the
--            realtime publication so the Home/Timeline screens
--            receive push updates.
-- Applied:   2026-06-24 via Supabase MCP (project ebccdpydoptajlkmqefx)
-- ═══════════════════════════════════════════════════════════════════

-- 1) pin_watches — atomic watch toggle per (pin, clerk user)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.pin_watches (
  pin_id         text NOT NULL REFERENCES public.crisis_pins(id) ON DELETE CASCADE,
  clerk_user_id  text NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (pin_id, clerk_user_id)
);

CREATE INDEX IF NOT EXISTS idx_pin_watches_user
  ON public.pin_watches (clerk_user_id);

ALTER TABLE public.pin_watches ENABLE ROW LEVEL SECURITY;

-- Users see their own watches; public read kept off for privacy
DROP POLICY IF EXISTS pin_watches_self_read ON public.pin_watches;
CREATE POLICY pin_watches_self_read ON public.pin_watches
  FOR SELECT TO anon, authenticated
  USING (clerk_user_id = coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'sub',
    clerk_user_id
  ));

-- 2) alert_subscriptions — which Clerk user wants which (district, type)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.alert_subscriptions (
  clerk_user_id   text NOT NULL,
  district_slug   text NOT NULL REFERENCES public.districts(slug) ON DELETE CASCADE,
  alert_type_slug text NOT NULL REFERENCES public.alert_types(slug) ON DELETE CASCADE,
  push_enabled    boolean NOT NULL DEFAULT true,
  created_at      timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (clerk_user_id, district_slug, alert_type_slug)
);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user
  ON public.alert_subscriptions (clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_district_type
  ON public.alert_subscriptions (district_slug, alert_type_slug)
  WHERE push_enabled = true;

ALTER TABLE public.alert_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS subscriptions_self_read ON public.alert_subscriptions;
CREATE POLICY subscriptions_self_read ON public.alert_subscriptions
  FOR SELECT TO anon, authenticated
  USING (clerk_user_id = coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'sub',
    clerk_user_id
  ));

DROP POLICY IF EXISTS subscriptions_self_write ON public.alert_subscriptions;
CREATE POLICY subscriptions_self_write ON public.alert_subscriptions
  FOR ALL TO anon, authenticated
  USING (clerk_user_id = coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'sub',
    clerk_user_id
  ))
  WITH CHECK (clerk_user_id = coalesce(
    current_setting('request.jwt.claims', true)::jsonb ->> 'sub',
    clerk_user_id
  ));

-- 3) Realtime: add timeline_events to publication
-- ─────────────────────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
     WHERE pubname = 'supabase_realtime'
       AND schemaname = 'public'
       AND tablename = 'timeline_events'
  ) THEN
    EXECUTE 'ALTER PUBLICATION supabase_realtime ADD TABLE public.timeline_events';
  END IF;
END$$;

-- 4) updated_at maintenance trigger
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_alerts_updated_at ON public.alerts;
CREATE TRIGGER trg_alerts_updated_at
  BEFORE UPDATE ON public.alerts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_crisis_pins_updated_at ON public.crisis_pins;
CREATE TRIGGER trg_crisis_pins_updated_at
  BEFORE UPDATE ON public.crisis_pins
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ANALYZE public.pin_watches;
ANALYZE public.alert_subscriptions;
