-- ============================================================================
-- NERV Disaster Prevention — Initial Supabase Schema
-- Date: 2026-06-24
-- ============================================================================
--
-- Tables created:
--   1. alerts             — disaster alerts (Critical → Calm severity scale)
--   2. timeline_events    — 72h event log for the Timeline screen
--   3. crisis_pins        — community-reported shelter/water/road pins
--   4. sos_alerts         — cache of upstream (GDACS) + user-submitted SOS
--   5. contact_messages   — Contact-Us form submissions (no longer mailto:)
--
-- Auth: Clerk handles user identity. Supabase Auth is disabled (see config.toml).
-- Therefore all RLS policies below use `USING (true)` / `WITH CHECK (true)` —
-- write access is gated by the Edge Function (which can rate-limit, validate,
-- and (later) verify Clerk JWTs if needed). For production, tighten RLS by
-- adding Clerk JWT verification in Edge Functions before inserts.
--
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1. alerts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.alerts (
    id           TEXT PRIMARY KEY,
    type         TEXT NOT NULL,                     -- flood, cyclone, tsunami, ...
    headline     TEXT NOT NULL,
    description  TEXT NOT NULL,
    severity     TEXT NOT NULL CHECK (severity IN (
        'critical','emergency','warning','advisory','info','calm'
    )),
    issued_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    expiry_at    TIMESTAMPTZ,
    location     TEXT NOT NULL,
    district     TEXT,                               -- SLDistrict.name (nullable)
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    source       TEXT NOT NULL DEFAULT 'manual',     -- dmc, gdacs, derived, manual
    metadata     JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_alerts_severity  ON public.alerts (severity);
CREATE INDEX IF NOT EXISTS idx_alerts_issued_at ON public.alerts (issued_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_district  ON public.alerts (district);

ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "alerts_public_read"    ON public.alerts;
DROP POLICY IF EXISTS "alerts_service_insert" ON public.alerts;
CREATE POLICY "alerts_public_read"
    ON public.alerts FOR SELECT USING (true);
CREATE POLICY "alerts_service_insert"
    ON public.alerts FOR INSERT WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- 2. timeline_events
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.timeline_events (
    id           TEXT PRIMARY KEY,
    alert_id     TEXT REFERENCES public.alerts(id) ON DELETE CASCADE,
    title        TEXT NOT NULL,
    description  TEXT,
    event_type   TEXT NOT NULL,                      -- same vocabulary as alerts.type
    severity     TEXT NOT NULL CHECK (severity IN (
        'critical','emergency','warning','advisory','info','calm'
    )),
    occurred_at  TIMESTAMPTZ NOT NULL,
    district     TEXT,
    latitude     DOUBLE PRECISION,
    longitude    DOUBLE PRECISION,
    metadata     JSONB,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_timeline_occurred_at
    ON public.timeline_events (occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_timeline_alert_id
    ON public.timeline_events (alert_id);

ALTER TABLE public.timeline_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "timeline_public_read"    ON public.timeline_events;
DROP POLICY IF EXISTS "timeline_service_insert" ON public.timeline_events;
CREATE POLICY "timeline_public_read"
    ON public.timeline_events FOR SELECT USING (true);
CREATE POLICY "timeline_service_insert"
    ON public.timeline_events FOR INSERT WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- 3. crisis_pins
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.crisis_pins (
    id           TEXT PRIMARY KEY,
    type         TEXT NOT NULL CHECK (type IN (
        'shelter','water','toilet','road','waste','relief_supply'
    )),
    name         TEXT NOT NULL,
    description  TEXT,
    latitude     DOUBLE PRECISION NOT NULL,
    longitude    DOUBLE PRECISION NOT NULL,
    address      TEXT,
    capacity     INTEGER,
    is_open      BOOLEAN NOT NULL DEFAULT true,
    posted_by    TEXT,                               -- Clerk user_id (no FK)
    is_verified  BOOLEAN NOT NULL DEFAULT false,
    watch_count  INTEGER NOT NULL DEFAULT 0,
    posted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ,
    expires_at   TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_crisis_pins_location
    ON public.crisis_pins USING gist (
        ll_to_earth(latitude, longitude)
    );
CREATE INDEX IF NOT EXISTS idx_crisis_pins_type
    ON public.crisis_pins (type);

ALTER TABLE public.crisis_pins ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "crisis_pins_public_read"   ON public.crisis_pins;
DROP POLICY IF EXISTS "crisis_pins_public_insert" ON public.crisis_pins;
CREATE POLICY "crisis_pins_public_read"
    ON public.crisis_pins FOR SELECT USING (true);
-- Public writes allowed via Edge Function (rate-limited). Tighten later by
-- adding Clerk JWT verification before this policy is exercised.
CREATE POLICY "crisis_pins_public_insert"
    ON public.crisis_pins FOR INSERT WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- 4. sos_alerts (cache + user submissions)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.sos_alerts (
    id            TEXT PRIMARY KEY,
    source        TEXT NOT NULL CHECK (source IN ('gdacs','user','system')),
    event_type    TEXT NOT NULL,                     -- TC, EQ, FL, TS, VO, ...
    headline      TEXT NOT NULL,
    description   TEXT NOT NULL,
    severity      TEXT NOT NULL CHECK (severity IN (
        'critical','emergency','warning','advisory','info','calm'
    )),
    latitude      DOUBLE PRECISION,
    longitude     DOUBLE PRECISION,
    radius_km     DOUBLE PRECISION,
    district      TEXT,
    reporter_id   TEXT,                               -- Clerk user_id (user submissions)
    reporter_name TEXT,
    contact       TEXT,
    status        TEXT NOT NULL DEFAULT 'active' CHECK (status IN (
        'active','resolved','expired'
    )),
    issued_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at    TIMESTAMPTZ,
    metadata      JSONB,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sos_alerts_severity ON public.sos_alerts (severity);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_status   ON public.sos_alerts (status);
CREATE INDEX IF NOT EXISTS idx_sos_alerts_issued   ON public.sos_alerts (issued_at DESC);

ALTER TABLE public.sos_alerts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "sos_alerts_public_read"    ON public.sos_alerts;
DROP POLICY IF EXISTS "sos_alerts_public_insert"  ON public.sos_alerts;
CREATE POLICY "sos_alerts_public_read"
    ON public.sos_alerts FOR SELECT USING (true);
CREATE POLICY "sos_alerts_public_insert"
    ON public.sos_alerts FOR INSERT WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- 5. contact_messages
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.contact_messages (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    email       TEXT NOT NULL,
    subject     TEXT NOT NULL,
    message     TEXT NOT NULL,
    user_id     TEXT,                                -- Clerk user_id (nullable)
    user_agent  TEXT,
    ip_hash     TEXT,                                -- hashed IP for abuse prevention
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT
);

CREATE INDEX IF NOT EXISTS idx_contact_messages_created_at
    ON public.contact_messages (created_at DESC);

ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "contact_messages_service_insert" ON public.contact_messages;
-- Only Edge Functions can insert (no public read policy).
CREATE POLICY "contact_messages_service_insert"
    ON public.contact_messages FOR INSERT WITH CHECK (true);

-- ---------------------------------------------------------------------------
-- Realtime publication — enables live alert updates on the Home screen.
-- ---------------------------------------------------------------------------
ALTER PUBLICATION supabase_realtime ADD TABLE public.alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sos_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.crisis_pins;

-- ---------------------------------------------------------------------------
-- updated_at trigger for alerts
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_alerts_updated_at ON public.alerts;
CREATE TRIGGER trg_alerts_updated_at
    BEFORE UPDATE ON public.alerts
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();