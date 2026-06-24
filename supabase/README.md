# NERV Disaster Prevention — Supabase Backend

This directory contains the Supabase backend for the NERV disaster
prevention app. Auth still uses **Clerk**; Supabase is used purely for
**data** (DMC alerts, timeline events, crisis pins, user subscriptions).

---

## Project

| Item            | Value                                         |
|-----------------|-----------------------------------------------|
| Project ref     | `ebccdpydoptajlkmqefx`                        |
| Project URL     | `https://ebccdpydoptajlkmqefx.supabase.co`    |
| Region          | `ap-south-1` (Mumbai)                         |
| Postgres        | 17.6 (GA)                                     |
| PostgREST       | enabled (default)                             |
| Realtime        | `alerts`, `timeline_events`, `crisis_pins`, `sos_alerts` |

---

## Directory layout

```
supabase/
├── functions/
│   └── alert-aggregator/
│       ├── index.ts       # Edge function (Open-Meteo + GDACS → alerts)
│       └── deno.json      # Deno import map
├── migrations/
│   ├── 20260624_01_reference_data_and_constraints.sql
│   ├── 20260624_02_user_scoped_and_realtime.sql
│   ├── 20260624_03_rpcs_and_views.sql
│   └── 20260624_04_toggle_pin_watch_cleanup.sql
└── README.md              # ← you are here
```

All three migrations are **already applied** to the live project.

---

## Schema overview

### Reference data

| Table          | Rows | Notes                                              |
|----------------|-----:|----------------------------------------------------|
| `districts`    |   25 | All 25 SL districts with `is_highland` / `is_coastal` flags |
| `alert_types`  |    8 | Mirrors `SLAlertType` enum from Flutter            |

### Operational tables

| Table                 | Realtime | Public read | Public write | Notes                                    |
|-----------------------|:--------:|:-----------:|:------------:|------------------------------------------|
| `alerts`              |    ✓     |     ✓       |      ✗       | Service-role writes only                 |
| `timeline_events`     |    ✓     |     ✓       |      ✗       | Service-role writes only                 |
| `crisis_pins`         |    ✓     |     ✓       |      ✓       | Community contribution (any anon insert) |
| `sos_alerts`          |    ✓     |     ✓       |      ✓       | Public SOS submission                    |
| `contact_messages`    |    ✗     |     ✗       |      ✗       | Service-role writes only                 |

### User-scoped tables (Clerk user_id as text)

| Table                 | Realtime | Own-row RLS | Notes                                  |
|-----------------------|:--------:|:-----------:|----------------------------------------|
| `pin_watches`         |    ✗     |      ✓      | One row per (pin, clerk user)          |
| `alert_subscriptions` |    ✗     |      ✓      | Per (clerk user, district, type)       |

### RPCs (callable from `supabase_flutter.rpc()`)

| Function                            | Purpose                                                |
|-------------------------------------|--------------------------------------------------------|
| `get_active_alerts(p_district)`     | All unexpired alerts, joined with district + type, sorted by severity |
| `get_timeline_events(p_district, p_event_type, p_hours)` | Rolling 72h event feed (default), joins district |
| `get_nearby_pins(p_lat, p_lng, p_radius_km, p_type)` | Haversine geo-search for crisis pins |
| `toggle_pin_watch(p_pin_id, p_clerk_user_id)` | Atomic watch/unwatch; bumps `crisis_pins.watch_count` |
| `get_alert_subscriptions(p_clerk_user_id)` | List a user's (district, type) subscriptions |
| `expire_stale_alerts()`             | Service-role cron helper: deletes expired alerts      |

### Views

- `v_active_alerts` — select * from `get_active_alerts(NULL)`,
  used by the Flutter client for realtime subscription.

---

## Row-level security (RLS)

| Table                 | Anon SELECT | Anon INSERT | Anon UPDATE | Anon DELETE |
|-----------------------|:-----------:|:-----------:|:-----------:|:-----------:|
| `alerts`              |      ✓      |      ✗      |      ✗      |      ✗      |
| `timeline_events`     |      ✓      |      ✗      |      ✗      |      ✗      |
| `crisis_pins`         |      ✓      |      ✓      |      ✗      |      ✗      |
| `sos_alerts`          |      ✓      |      ✓      |      ✗      |      ✗      |
| `contact_messages`    |      ✗      |      ✗      |      ✗      |      ✗      |
| `pin_watches`         | own only    |      ✗      |      ✗      |      ✗      |
| `alert_subscriptions` | own only    | own only    | own only    | own only    |
| `districts`           |      ✓      |      ✗      |      ✗      |      ✗      |
| `alert_types`         |      ✓      |      ✗      |      ✗      |      ✗      |

"Own only" policies compare `clerk_user_id` against the request JWT
sub claim (`request.jwt.claims ->> 'sub'`). For full Clerk ↔ Supabase
JWT bridging in production, configure Clerk's native Supabase
integration so it signs Supabase JWTs with the same key.

---

## CHECK constraints (data integrity)

| Table             | Constraint                                |
|-------------------|-------------------------------------------|
| `alerts`          | `severity IN ('critical'..'calm')`        |
| `alerts`          | `source IN ('manual','open_meteo','gdacs','reliefweb','derived')` |
| `alerts`          | `latitude ∈ [-90, 90]`, `longitude ∈ [-180, 180]` |
| `timeline_events` | `event_type IN ('flood','landslide','cyclone','lightning','coastalWarning','tsunami','earthquake','info','weather')` |
| `timeline_events` | lat/lng ranges                            |
| `crisis_pins`     | `type IN ('shelter','water','toilet','road','waste','reliefSupply')` |
| `crisis_pins`     | `capacity >= 0`, `watch_count >= 0`       |
| `sos_alerts`      | `status IN ('active','acknowledged','resolved','cancelled')` |

---

## Edge function: `alert-aggregator`

Polls Open-Meteo and GDACS RSS, derives alerts via thresholds, and
upserts into `alerts` + mirrors into `timeline_events`.

### Deploy

The MCP deploy tool currently has a transport-layer type bug
(`false` and arrays get stringified). Use the Supabase CLI instead:

```bash
# from project root
supabase functions deploy alert-aggregator \
  --project-ref ebccdpydoptajlkmqefx \
  --no-verify-jwt
```

Or paste the file contents into the Supabase Dashboard → Edge
Functions → "Deploy from editor".

### Thresholds

| Type               | Trigger                                                    |
|--------------------|------------------------------------------------------------|
| `flood` (warning)  | 6h precip ≥ 50 mm                                          |
| `flood` (emergency)| 24h precip ≥ 100 mm                                        |
| `flood` (critical) | 24h precip ≥ 150 mm                                        |
| `landslide`        | 24h precip ≥ 100 mm in highland districts                  |
| `lightning`        | WMO code 95–99 within next 6h                              |
| `coastalWarning`   | Coastal district + wind 40–60 km/h                         |
| `cyclone`          | Sustained wind ≥ 60 km/h                                   |
| `cyclone` (GDACS)  | GDACS cyclone within SL bounding box → critical            |
| `tsunami` (GDACS)  | GDACS tsunami in Indian Ocean → critical                   |

### Schedule

Recommended: every 10 minutes via Supabase Cron.

```sql
-- In the SQL editor, then schedule with pg_cron or supabase_cron
select cron.schedule(
  'alert-aggregator-10m',
  '*/10 * * * *',
  $$
  select net.http_post(
    url     := 'https://ebccdpydoptajlkmqefx.supabase.co/functions/v1/alert-aggregator',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
```

Or call it manually from the dashboard's Edge Functions → "Invoke".

---

## Flutter client wiring (next step, not part of this backend PR)

Add the Supabase URL + anon key to `.env`:

```env
SUPABASE_URL=https://ebccdpydoptajlkmqefx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...   # from Supabase dashboard → Settings → API
```

Then in `main.dart`:

```dart
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

`supabase_flutter ^2.8.0` is already in `pubspec.yaml` — no new deps.

---

## Verification queries

```sql
-- Counts
select (select count(*) from public.districts)        as districts,
       (select count(*) from public.alert_types)      as alert_types,
       (select count(*) from public.get_active_alerts()) as active_alerts,
       (select count(*) from public.get_timeline_events()) as timeline_events;

-- Real-time publication
select tablename from pg_publication_tables
 where pubname = 'supabase_realtime' order by tablename;
```

---

## Migration history

| Migration                                      | What it added                                       |
|------------------------------------------------|-----------------------------------------------------|
| `20260624_01_reference_data_and_constraints`   | CHECK constraints, `districts`, `alert_types`, timeline detail fields |
| `20260624_02_user_scoped_and_realtime`         | `pin_watches`, `alert_subscriptions`, realtime for `timeline_events`, `updated_at` triggers |
| `20260624_03_rpcs_and_views`                   | 5 RPCs + `v_active_alerts` view + `expire_stale_alerts` |
| `20260624_04_toggle_pin_watch_cleanup`         | Drop + recreate `toggle_pin_watch` (removed tautology)  |
