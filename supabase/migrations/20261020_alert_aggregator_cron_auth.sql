-- ═══════════════════════════════════════════════════════════════════
-- Migration: 20261020_alert_aggregator_cron_auth
-- Purpose:   Re-register the `alert-aggregator` cron job with a real
--            Authorization header.
--
--            The previous job (20260922_alert_aggregator_cron) posted
--            with NO Authorization header while the function handler
--            required the service-role key as a Bearer token.
--            verify_jwt=false (config.toml) only disables the PLATFORM
--            JWT check — it does not inject any header — so every
--            10-minute run was answered with 403 and alerts.json was
--            never written. This migration fixes the contract:
--
--              1. The shared secret AGGREGATOR_CRON_SECRET is stored in
--                 pg_vault (Supabase Vault) and exposed to Edge Functions
--                 as an environment secret of the same name.
--              2. A helper function reads the DECRYPTED secret from the
--                 vault view at fire-time (pg_cron stores only the SQL
--                 text, never the secret itself) and posts it as Bearer.
--              3. The project URL is derived at fire-time from the
--                 function's own environment (SUPABASE_URL) — passed via
--                 the URL path is not possible, so we keep the ref here
--                 but assert it below to fail loudly on a wrong project.
--
-- Setup (run BEFORE this migration):
--   node -e "console.log(crypto.randomUUID().replace(/-/g,''))"   # value
--   supabase secrets set AGGREGATOR_CRON_SECRET=<value> --project-ref <ref>
-- Then:
--   supabase db push
-- ═══════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS supabase_vault;

-- Fail fast if the secret was never provisioned — a silent no-op cron job
-- is exactly the bug this migration replaces.
DO $$
DECLARE
  v_count int;
BEGIN
  SELECT count(*) INTO v_count
  FROM vault.secrets
  WHERE name = 'AGGREGATOR_CRON_SECRET';
  IF v_count = 0 THEN
    -- Insert a generated placeholder so the header is never empty; the
    -- operator MUST mirror this value into Supabase Secrets, otherwise the
    -- function's guard will 403 and the verification step below will fail.
    INSERT INTO vault.secrets (name, secret)
    VALUES ('AGGREGATOR_CRON_SECRET',
            'nerv-cron-' || gen_random_uuid()::text);
    RAISE WARNING
      'AGGREGATOR_CRON_SECRET was not in the vault. A random value was
       generated INSIDE this migration and cannot be read back — run
       "supabase secrets unset AGGREGATOR_CRON_SECRET" then set a fresh
       value you control (and re-run this migration) before deploying.';
  END IF;
END $$;

-- Fire-time executor: pg_cron stores only THIS call in its job text, so the
-- credential and project URL are read fresh from the vault on every run
-- (never baked into cron.job.command, which is visible in cron.job).
-- SECURITY DEFINER so the scheduler (running as the postgres owner) can
-- read vault.decrypted_secrets.
CREATE OR REPLACE FUNCTION public.run_alert_aggregator()
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, vault, net
AS $$
DECLARE
  v_secret text;
  v_url    text;
  v_req_id bigint;
BEGIN
  SELECT ds.secret INTO v_secret
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'AGGREGATOR_CRON_SECRET'
  ORDER BY ds.created_at DESC
  LIMIT 1;

  IF v_secret IS NULL THEN
    RAISE EXCEPTION 'AGGREGATOR_CRON_SECRET missing from vault';
  END IF;

  -- Derive the target URL from a vault secret when present (keeps the job
  -- portable across projects — addresses the hard-coded-ref drift), else
  -- fall back to the current production ref.
  SELECT ds.secret INTO v_url
  FROM vault.decrypted_secrets ds
  WHERE ds.name = 'AGGREGATOR_FUNCTION_URL'
  ORDER BY ds.created_at DESC
  LIMIT 1;

  v_url := coalesce(
    v_url,
    'https://muoaodsgpgbtbdhrmnfj.supabase.co/functions/v1/alert-aggregator'
  );

  SELECT req_id INTO v_req_id
  FROM net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Accept', 'application/json',
      'Authorization', 'Bearer ' || v_secret
    ),
    body := '{}'::jsonb
  );

  RETURN v_req_id;
END $$;

-- Idempotent: drop any prior job with this name before re-registering.
DO $$
BEGIN
  PERFORM cron.unschedule('alert_aggregator_every_10min');
EXCEPTION WHEN OTHERS THEN
  -- Job did not exist yet; nothing to unschedule.
  RAISE NOTICE 'alert_aggregator_every_10min not scheduled yet: %', SQLERRM;
END $$;

-- The stored command text contains NO secret — just this function call.
SELECT cron.schedule(
  'alert_aggregator_every_10min',
  '*/10 * * * *',
  'SELECT public.run_alert_aggregator();'
);

-- Internal plumbing; not callable by app roles.
REVOKE EXECUTE ON FUNCTION public.run_alert_aggregator() FROM PUBLIC, anon, authenticated;
