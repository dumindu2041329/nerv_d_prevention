-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20260624_03_rpcs_and_views
-- Purpose:   RPCs the Flutter client calls via supabase_flutter.rpc(),
--            plus convenience views joining reference data.
--            All RPCs are SECURITY INVOKER (use the caller's RLS).
-- Applied:   2026-06-24 via Supabase MCP (project ebccdpydoptajlkmqefx)
-- ═══════════════════════════════════════════════════════════════════

-- 1) get_active_alerts — current (unexpired) alerts, sorted by severity
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_active_alerts(
  p_district text DEFAULT NULL
)
RETURNS TABLE (
  id            text,
  type          text,
  headline      text,
  description   text,
  severity      text,
  issued_at     timestamptz,
  expiry_at     timestamptz,
  location      text,
  district_slug text,
  district_name text,
  latitude      double precision,
  longitude     double precision,
  source        text,
  metadata      jsonb,
  type_label    text,
  type_color    text,
  type_icon     text
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  WITH sev_rank AS (
    SELECT severity, row_number() OVER (ORDER BY
      CASE severity
        WHEN 'critical' THEN 1
        WHEN 'emergency' THEN 2
        WHEN 'warning' THEN 3
        WHEN 'advisory' THEN 4
        WHEN 'info' THEN 5
        WHEN 'calm' THEN 6
      END
    ) AS rnk
    FROM (VALUES
      ('critical'),('emergency'),('warning'),('advisory'),('info'),('calm')
    ) AS s(severity)
  )
  SELECT
    a.id,
    a.type,
    a.headline,
    a.description,
    a.severity,
    a.issued_at,
    a.expiry_at,
    a.location,
    a.district,
    d.display_name,
    a.latitude,
    a.longitude,
    a.source,
    a.metadata,
    at.label,
    at.hex_color,
    at.material_icon
  FROM public.alerts a
  LEFT JOIN public.districts d ON d.slug = a.district
  LEFT JOIN public.alert_types at ON at.slug = a.type
  WHERE (a.expiry_at IS NULL OR a.expiry_at > now())
    AND (p_district IS NULL OR a.district = p_district)
  ORDER BY
    (SELECT rnk FROM sev_rank WHERE sev_rank.severity = a.severity),
    a.issued_at DESC;
$$;

-- 2) get_timeline_events — rolling N-hour window
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_timeline_events(
  p_district  text DEFAULT NULL,
  p_event_type text DEFAULT NULL,
  p_hours     int  DEFAULT 72
)
RETURNS TABLE (
  id              text,
  alert_id        text,
  title           text,
  description     text,
  event_type      text,
  severity        text,
  occurred_at     timestamptz,
  is_lifted       boolean,
  location        text,
  district_slug   text,
  district_name   text,
  latitude        double precision,
  longitude       double precision,
  max_intensity   integer,
  magnitude       double precision,
  magnitude_label text,
  depth_km        double precision,
  depth_label     text,
  tsunami_flag    boolean,
  metadata        jsonb
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    t.id,
    t.alert_id,
    t.title,
    t.description,
    t.event_type,
    t.severity,
    t.occurred_at,
    t.is_lifted,
    coalesce(t.location, t.district),
    t.district,
    d.display_name,
    t.latitude,
    t.longitude,
    t.max_intensity,
    t.magnitude,
    t.magnitude_label,
    t.depth_km,
    t.depth_label,
    t.tsunami_flag,
    t.metadata
  FROM public.timeline_events t
  LEFT JOIN public.districts d ON d.slug = t.district
  WHERE t.occurred_at >= now() - make_interval(hours => p_hours)
    AND (p_district   IS NULL OR t.district   = p_district)
    AND (p_event_type IS NULL OR t.event_type = p_event_type)
  ORDER BY t.occurred_at DESC;
$$;

-- 3) get_nearby_pins — Haversine within radius_km, optionally filtered by type
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_nearby_pins(
  p_lat       double precision,
  p_lng       double precision,
  p_radius_km int DEFAULT 25,
  p_type      text DEFAULT NULL
)
RETURNS TABLE (
  id           text,
  type         text,
  name         text,
  description  text,
  latitude     double precision,
  longitude    double precision,
  address      text,
  capacity     integer,
  is_open      boolean,
  is_verified  boolean,
  watch_count  integer,
  posted_at    timestamptz,
  distance_km  double precision
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    p.id,
    p.type,
    p.name,
    p.description,
    p.latitude,
    p.longitude,
    p.address,
    p.capacity,
    p.is_open,
    p.is_verified,
    p.watch_count,
    p.posted_at,
    (
      6371 * acos(
        least(1.0, greatest(-1.0,
          cos(radians(p_lat)) * cos(radians(p.latitude))
          * cos(radians(p.longitude) - radians(p_lng))
          + sin(radians(p_lat)) * sin(radians(p.latitude))
        ))
      )
    ) AS distance_km
  FROM public.crisis_pins p
  WHERE (p.expires_at IS NULL OR p.expires_at > now())
    AND (p_type IS NULL OR p.type = p_type)
    AND (
      6371 * acos(
        least(1.0, greatest(-1.0,
          cos(radians(p_lat)) * cos(radians(p.latitude))
          * cos(radians(p.longitude) - radians(p_lng))
          + sin(radians(p_lat)) * sin(radians(p.latitude))
        ))
      )
    ) <= p_radius_km
  ORDER BY distance_km ASC;
$$;

-- 4) toggle_pin_watch — atomic watch/unwatch, bumps watch_count
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.toggle_pin_watch(
  p_pin_id       text,
  p_clerk_user_id text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  v_existed boolean;
BEGIN
  IF p_pin_id IS NULL OR p_clerk_user_id IS NULL THEN
    RAISE EXCEPTION 'pin_id and clerk_user_id are required';
  END IF;

  DELETE FROM public.pin_watches w
   WHERE w.pin_id = w.pin_id
     AND w.pin_id = p_pin_id
     AND w.clerk_user_id = p_clerk_user_id
  RETURNING true INTO v_existed;

  IF v_existed IS NULL THEN
    INSERT INTO public.pin_watches (pin_id, clerk_user_id)
      VALUES (p_pin_id, p_clerk_user_id)
      ON CONFLICT DO NOTHING;
    UPDATE public.crisis_pins
       SET watch_count = watch_count + 1
     WHERE id = p_pin_id;
    RETURN true;
  ELSE
    UPDATE public.crisis_pins
       SET watch_count = greatest(0, watch_count - 1)
     WHERE id = p_pin_id;
    RETURN false;
  END IF;
END;
$$;

-- 5) get_alert_subscriptions — a user's preferences
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_alert_subscriptions(
  p_clerk_user_id text
)
RETURNS TABLE (
  district_slug   text,
  district_name   text,
  alert_type_slug text,
  alert_type_label text,
  push_enabled    boolean,
  created_at      timestamptz
)
LANGUAGE sql
STABLE
SECURITY INVOKER
AS $$
  SELECT
    s.district_slug,
    d.display_name,
    s.alert_type_slug,
    at.label,
    s.push_enabled,
    s.created_at
  FROM public.alert_subscriptions s
  JOIN public.districts d   ON d.slug = s.district_slug
  JOIN public.alert_types at ON at.slug = s.alert_type_slug
  WHERE s.clerk_user_id = p_clerk_user_id
  ORDER BY d.sort_order, at.sort_order;
$$;

-- 6) Convenience view for the Flutter client (used by realtime subscription)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW public.v_active_alerts AS
  SELECT * FROM public.get_active_alerts(NULL);

GRANT SELECT ON public.v_active_alerts TO anon, authenticated;

-- 7) Cleanup RPC — soft-expire stale alerts (callable by cron edge function)
-- ─────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.expire_stale_alerts()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
AS $$
  WITH expired AS (
    DELETE FROM public.alerts
     WHERE expiry_at IS NOT NULL
       AND expiry_at < now()
    RETURNING 1
  )
  SELECT count(*)::integer FROM expired;
$$;

REVOKE ALL ON FUNCTION public.expire_stale_alerts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.expire_stale_alerts() TO service_role;
