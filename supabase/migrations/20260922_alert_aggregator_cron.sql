-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20260922_alert_aggregator_cron
-- Purpose:   Schedule the `alert-aggregator` Edge Function every 10 min
--            so public.alerts / public.timeline_events stay populated.
--            Previously nothing invoked the function, so the alerts
--            table was always empty and the app showed no real alerts.
--
-- Mechanism: pg_cron fires a pg_net HTTP POST to the Edge Function.
--            The function has verify_jwt=false (see config.toml), so no
--            Authorization header is required.
--
-- NOTE: The URL embeds the project ref (muoaodsgpgbtbdhrmnfj). If this
--       migration is replayed against a different project, update it.
-- ═══════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Idempotent: drop any prior job with this name before re-registering.
DO $$
BEGIN
  PERFORM cron.unschedule('alert_aggregator_every_10min');
EXCEPTION WHEN OTHERS THEN
  -- Job did not exist yet; nothing to unschedule.
  RAISE NOTICE 'alert_aggregator_every_10min not scheduled yet: %', SQLERRM;
END $$;

SELECT cron.schedule(
  'alert_aggregator_every_10min',
  '*/10 * * * *',
  $$
    SELECT net.http_post(
      url := 'https://muoaodsgpgbtbdhrmnfj.supabase.co/functions/v1/alert-aggregator',
      headers := '{"Content-Type": "application/json", "Accept": "application/json"}'::jsonb,
      body := '{}'::jsonb
    );
  $$
);
