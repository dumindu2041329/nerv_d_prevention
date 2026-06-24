-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20260625_landslide_zones_table
-- Purpose:   Create landslide_zones table and seed with NBRO-inspired
--            hazard polygons. The map screen reads from this table
--            instead of the legacy OSM Overpass + bundled polygons.
-- ═══════════════════════════════════════════════════════════════════

-- 1) Create the table
-- ─────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.landslide_zones (
  id            text PRIMARY KEY,
  name          text NOT NULL,
  severity      text NOT NULL
    CHECK (severity IN ('advisory','caution','danger','emergency')),
  source        text NOT NULL,
  latitude      double precision,
  longitude     double precision,
  district      text REFERENCES public.districts(slug) ON DELETE SET NULL,
  polygon_rings jsonb,
  metadata      jsonb,
  is_active     boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE  public.landslide_zones IS
  'Landslide hazard zones and feature points for Sri Lanka. '
  'polygon_rings stores the closed ring as [[lat,lon],...] for polygon zones; '
  'point features use lat/lon with polygon_rings = null.';

COMMENT ON COLUMN public.landslide_zones.polygon_rings IS
  'Closed ring expressed as [[lat, lon], ...]. The first and last element '
  'must be identical. NULL for point features.';

-- Index spatial queries
CREATE INDEX IF NOT EXISTS idx_landslide_zones_severity
  ON public.landslide_zones (severity);
CREATE INDEX IF NOT EXISTS idx_landslide_zones_active
  ON public.landslide_zones (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_landslide_zones_district
  ON public.landslide_zones (district);

ALTER TABLE public.landslide_zones ENABLE ROW LEVEL SECURITY;

-- Anyone can read landslide zones (public safety data)
DROP POLICY IF EXISTS landslide_zones_read ON public.landslide_zones;
CREATE POLICY landslide_zones_read ON public.landslide_zones
  FOR SELECT TO anon, authenticated
  USING (true);

-- 2) Seed NBRO-inspired high-risk polygons
--    (mirrors lib/data/remote/landslides/landslide_polygon_client.dart)
-- ─────────────────────────────────────────────────────────────────

INSERT INTO public.landslide_zones
  (id, name, severity, source, latitude, longitude, district, polygon_rings)
VALUES
  ('nbro-badulla-highlands',
   'Badulla Highlands', 'emergency', 'NBRO',
   6.984, 80.966, 'badulla',
   '[[6.85,80.92],[6.96,81.08],[7.10,81.14],[7.08,80.96],[6.93,80.83],[6.85,80.92]]'::jsonb),

  ('nbro-nuwaraeliya-massif',
   'Nuwara Eliya Massif', 'emergency', 'NBRO',
   6.955, 80.645, 'nuwara_eliya',
   '[[6.85,80.62],[6.99,80.78],[7.06,80.66],[6.92,80.52],[6.85,80.62]]'::jsonb),

  ('nbro-matale-knuckles',
   'Matale Knuckles', 'danger', 'NBRO',
   7.533, 80.575, 'matale',
   '[[7.40,80.55],[7.55,80.70],[7.66,80.60],[7.52,80.45],[7.40,80.55]]'::jsonb),

  ('nbro-ratnapura-escarpment',
   'Ratnapura Escarpment', 'danger', 'NBRO',
   6.730, 80.360, 'ratnapura',
   '[[6.60,80.30],[6.74,80.50],[6.86,80.42],[6.72,80.22],[6.60,80.30]]'::jsonb),

  ('nbro-kegalle-hills',
   'Kegalle Hills', 'danger', 'NBRO',
   7.175, 80.303, 'kegalle',
   '[[7.08,80.28],[7.20,80.45],[7.26,80.30],[7.16,80.18],[7.08,80.28]]'::jsonb),

  ('nbro-kandy-foothills',
   'Kandy Foothills', 'caution', 'NBRO',
   7.258, 80.593, 'kandy',
   '[[7.15,80.55],[7.30,80.70],[7.36,80.55],[7.22,80.44],[7.15,80.55]]'::jsonb),

  ('nbro-kalutara-western-slopes',
   'Kalutara Western Slopes', 'caution', 'NBRO',
   6.620, 80.150, 'kalutara',
   '[[6.50,80.10],[6.64,80.30],[6.74,80.20],[6.60,80.00],[6.50,80.10]]'::jsonb),

  ('nbro-matara-highlands',
   'Matara Highlands', 'caution', 'NBRO',
   6.050, 80.535, 'matara',
   '[[5.94,80.50],[6.06,80.66],[6.16,80.56],[6.04,80.42],[5.94,80.50]]'::jsonb)
ON CONFLICT (id) DO UPDATE
  SET name          = EXCLUDED.name,
      severity      = EXCLUDED.severity,
      source        = EXCLUDED.source,
      latitude      = EXCLUDED.latitude,
      longitude     = EXCLUDED.longitude,
      district      = EXCLUDED.district,
      polygon_rings = EXCLUDED.polygon_rings,
      updated_at    = now();

-- 3) updated_at trigger
-- ─────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS trg_landslide_zones_updated_at ON public.landslide_zones;
CREATE TRIGGER trg_landslide_zones_updated_at
  BEFORE UPDATE ON public.landslide_zones
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ANALYZE public.landslide_zones;
