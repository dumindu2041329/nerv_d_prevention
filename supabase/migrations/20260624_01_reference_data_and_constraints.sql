-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20260624_01_reference_data_and_constraints
-- Purpose:   Add CHECK constraints to existing tables, extend
--            timeline_events with detail fields, and seed the
--            reference data (districts + alert_types) used by the
--            Flutter client and edge functions.
-- Applied:   2026-06-24 via Supabase MCP (project ebccdpydoptajlkmqefx)
-- ═══════════════════════════════════════════════════════════════════

-- 1) CHECK constraints on existing tables
-- ─────────────────────────────────────────────────────────────────

ALTER TABLE public.alerts
  ADD CONSTRAINT alerts_severity_chk
    CHECK (severity IN ('critical','emergency','warning','advisory','info','calm')),
  ADD CONSTRAINT alerts_lat_range_chk
    CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  ADD CONSTRAINT alerts_lng_range_chk
    CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180)),
  ADD CONSTRAINT alerts_source_chk
    CHECK (source IN ('manual','open_meteo','gdacs','reliefweb','derived'));

ALTER TABLE public.timeline_events
  ADD CONSTRAINT timeline_severity_chk
    CHECK (severity IN ('critical','emergency','warning','advisory','info','calm')),
  ADD CONSTRAINT timeline_event_type_chk
    CHECK (event_type IN
      ('flood','landslide','cyclone','lightning','coastalWarning',
       'tsunami','earthquake','info','weather')),
  ADD CONSTRAINT timeline_lat_range_chk
    CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
  ADD CONSTRAINT timeline_lng_range_chk
    CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180));

ALTER TABLE public.crisis_pins
  ADD CONSTRAINT crisis_pins_type_chk
    CHECK (type IN
      ('shelter','water','toilet','road','waste','reliefSupply')),
  ADD CONSTRAINT crisis_pins_lat_range_chk
    CHECK (latitude BETWEEN -90 AND 90),
  ADD CONSTRAINT crisis_pins_lng_range_chk
    CHECK (longitude BETWEEN -180 AND 180),
  ADD CONSTRAINT crisis_pins_capacity_chk
    CHECK (capacity IS NULL OR capacity >= 0),
  ADD CONSTRAINT crisis_pins_watch_count_chk
    CHECK (watch_count >= 0);

ALTER TABLE public.sos_alerts
  ADD CONSTRAINT sos_severity_chk
    CHECK (severity IN ('critical','emergency','warning','advisory','info','calm')),
  ADD CONSTRAINT sos_status_chk
    CHECK (status IN ('active','acknowledged','resolved','cancelled'));

-- 2) Add missing detail fields to timeline_events
--    (matches TimelineEvent entity in Flutter)
-- ─────────────────────────────────────────────────────────────────

ALTER TABLE public.timeline_events
  ADD COLUMN IF NOT EXISTS is_lifted boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS max_intensity integer,
  ADD COLUMN IF NOT EXISTS magnitude double precision,
  ADD COLUMN IF NOT EXISTS magnitude_label text,
  ADD COLUMN IF NOT EXISTS depth_km double precision,
  ADD COLUMN IF NOT EXISTS depth_label text,
  ADD COLUMN IF NOT EXISTS tsunami_flag boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS location text;

COMMENT ON COLUMN public.timeline_events.occurred_at IS
  'Wall-clock time the event occurred (Flutter TimelineEvent.time)';

-- 3) Reference data: districts (25 SL districts)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.districts (
  slug         text PRIMARY KEY,
  display_name text NOT NULL UNIQUE,
  province     text NOT NULL,
  latitude     double precision NOT NULL,
  longitude    double precision NOT NULL,
  is_highland  boolean NOT NULL DEFAULT false,
  is_coastal   boolean NOT NULL DEFAULT false,
  sort_order   integer NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_districts_province
  ON public.districts (province);

-- Seed the 25 Sri Lankan districts (mirrors lib/core/constants/app_sl_constants.dart)
INSERT INTO public.districts (slug, display_name, province, latitude, longitude, is_highland, is_coastal, sort_order) VALUES
  ('colombo',       'Colombo',       'Western',        6.9271, 79.8612, false, true,  1),
  ('gampaha',       'Gampaha',       'Western',        7.0867, 80.0128, false, false, 2),
  ('kalutara',      'Kalutara',      'Western',        6.5854, 79.9607, false, true,  3),
  ('kandy',         'Kandy',         'Central',        7.2906, 80.6337, true,  false, 4),
  ('matale',        'Matale',        'Central',        7.4675, 80.6234, true,  false, 5),
  ('nuwara_eliya',  'Nuwara Eliya',  'Central',        6.9497, 80.7891, true,  false, 6),
  ('galle',         'Galle',         'Southern',       6.0535, 80.2210, false, true,  7),
  ('matara',        'Matara',        'Southern',       5.9485, 80.5353, false, true,  8),
  ('hambantota',    'Hambantota',    'Southern',       6.1241, 81.1185, false, true,  9),
  ('jaffna',        'Jaffna',        'Northern',       9.6683, 80.0074, false, true,  10),
  ('kilinochchi',   'Kilinochchi',   'Northern',       9.3929, 80.4041, false, false, 11),
  ('mannar',        'Mannar',        'Northern',       8.9802, 79.9043, false, true,  12),
  ('vavuniya',      'Vavuniya',      'Northern',       8.7577, 80.4993, false, false, 13),
  ('mullaitivu',    'Mullaitivu',    'Northern',       9.2670, 80.8140, false, true,  14),
  ('batticaloa',    'Batticaloa',    'Eastern',        7.7167, 81.7000, false, true,  15),
  ('ampara',        'Ampara',        'Eastern',        7.2833, 81.6667, false, true,  16),
  ('trincomalee',   'Trincomalee',   'Eastern',        8.5874, 81.2152, false, true,  17),
  ('kurunegala',    'Kurunegala',    'North Western',  7.4875, 80.3647, false, false, 18),
  ('puttalam',      'Puttalam',      'North Western',  8.0362, 79.8287, false, true,  19),
  ('anuradhapura',  'Anuradhapura',  'North Central',  8.3114, 80.4037, false, false, 20),
  ('polonnaruwa',   'Polonnaruwa',   'North Central',  7.9403, 81.0188, false, false, 21),
  ('badulla',       'Badulla',       'Uva',            6.9897, 81.0557, true,  false, 22),
  ('monaragala',    'Monaragala',    'Uva',            6.8728, 81.3507, true,  false, 23),
  ('ratnapura',     'Ratnapura',     'Sabaragamuwa',   6.6828, 80.3994, true,  false, 24),
  ('kegalle',       'Kegalle',       'Sabaragamuwa',   7.2539, 80.3535, true,  false, 25)
ON CONFLICT (slug) DO UPDATE
  SET display_name = EXCLUDED.display_name,
      province     = EXCLUDED.province,
      latitude     = EXCLUDED.latitude,
      longitude    = EXCLUDED.longitude,
      is_highland  = EXCLUDED.is_highland,
      is_coastal   = EXCLUDED.is_coastal,
      sort_order   = EXCLUDED.sort_order;

-- 4) Reference data: alert_types (mirrors SLAlertType enum)
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.alert_types (
  slug             text PRIMARY KEY,
  label            text NOT NULL,
  full_label       text NOT NULL,
  hex_color        text NOT NULL,
  material_icon    text NOT NULL,
  sort_order       integer NOT NULL DEFAULT 0,
  default_severity text NOT NULL DEFAULT 'advisory'
    CHECK (default_severity IN ('critical','emergency','warning','advisory','info','calm'))
);

INSERT INTO public.alert_types (slug, label, full_label, hex_color, material_icon, sort_order, default_severity) VALUES
  ('flood',          'Flood',          'Flood Warning',    '#FF6D00', 'water',         1, 'warning'),
  ('landslide',      'Landslide',      'Landslide Alert', '#FF6D00', 'terrain',       2, 'warning'),
  ('cyclone',        'Cyclone',        'Cyclone Advisory','#FF1744', 'cyclone',       3, 'emergency'),
  ('lightning',      'Lightning',      'Lightning Alert', '#FFC400', 'bolt',          4, 'advisory'),
  ('coastalWarning', 'Coastal Warning','Coastal Warning', '#00E5FF', 'beach_access',  5, 'advisory'),
  ('tsunami',        'Tsunami',        'Tsunami Bulletin','#FF1744', 'waves',         6, 'critical'),
  ('earthquake',     'Earthquake',     'Earthquake Info', '#FF1744', 'public',        7, 'warning'),
  ('info',           'Info',           'Information',     '#69F0AE', 'info',          8, 'info')
ON CONFLICT (slug) DO UPDATE
  SET label            = EXCLUDED.label,
      full_label       = EXCLUDED.full_label,
      hex_color        = EXCLUDED.hex_color,
      material_icon    = EXCLUDED.material_icon,
      sort_order       = EXCLUDED.sort_order,
      default_severity = EXCLUDED.default_severity;

-- 5) Backfill: link existing rows to reference data where missing
-- ─────────────────────────────────────────────────────────────────

UPDATE public.alerts a
   SET district = d.slug
  FROM public.districts d
 WHERE lower(a.district) = d.display_name
   AND a.district IS DISTINCT FROM d.slug;

ANALYZE public.alerts;
ANALYZE public.timeline_events;
ANALYZE public.crisis_pins;
ANALYZE public.districts;
ANALYZE public.alert_types;
