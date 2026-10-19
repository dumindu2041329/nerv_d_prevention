-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20261020_table_exports_bucket
-- Purpose:   Declaratively provision the `table-exports` Storage bucket
--            the app now depends on (SosAlertApiClient downloads
--            alerts.json from it). Previously the bucket existed only by
--            manual dashboard state, so a fresh/review-environment could
--            not reproduce the app, and its public-read policy was
--            unreviewed.
--
-- Policy:    Anonymous/authenticated clients may READ only alerts.json.
--            Writes go through the alert-aggregator Edge Function using
--            the service-role key (bypasses RLS), so no public write
--            policy is granted here.
-- ═══════════════════════════════════════════════════════════════════

-- 1) Ensure the bucket exists (public=false — access is via the read
--    policy below, not a fully public bucket).
INSERT INTO storage.buckets (id, name, public)
VALUES ('table-exports', 'table-exports', false)
ON CONFLICT (id) DO NOTHING;

-- 2) Lock down: drop any prior blanket read policy on the bucket so the
--    object-scoped policy below is the only public surface.
DROP POLICY IF EXISTS "table_exports_public_read" ON storage.objects;
DROP POLICY IF EXISTS "table_exports_read_alerts" ON storage.objects;

-- 3) Public SELECT limited to the single alerts.json object.
CREATE POLICY "table_exports_read_alerts"
ON storage.objects FOR SELECT
TO public
USING (
  bucket_id = 'table-exports'
  AND (storage.foldername(name))[1] = 'alerts.json'
);

-- NOTE on writes: the alert-aggregator Edge Function uploads alerts.json
-- with the service-role client (bypasses RLS). If a future migration adds
-- a DB-triggered export path, scope its INSERT policy to this bucket and
-- service_role only — never to_anon/authenticated.
