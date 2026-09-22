# NERV Disaster Prevention — Supabase Backend

This directory contains the Supabase backend for the NERV disaster
prevention app. Auth uses **Supabase Auth** (email/password — see
`lib/data/repositories/auth_repository_impl.dart`). The `clerk_user_id`
column names in the user-scoped tables are a leftover from the pre-Supabase
auth provider; they now store the Supabase Auth user id.

---

## Project

| Item            | Value                                         |
|-----------------|-----------------------------------------------|
| Project ref     | `muoaodsgpgbtbdhrmnfj`                        |
| Project URL     | `https://muoaodsgpgbtbdhrmnfj.supabase.co`    |
| Region          | `ap-south-1` (Mumbai)                         |
| Postgres        | 17.6 (GA)                                     |
| PostgREST       | enabled (default)                             |
| Realtime        | `alerts`, `timeline_events`, `crisis_pins`, `sos_alerts` |

---

## Directory layout

```
supabase/
├── functions/
│   ├── weather/            # WeatherAPI.com proxy (current + 5-day forecast)
│   ├── geocode/            # MapTiler forward + reverse geocoding proxy
│   ├── tiles/              # MapTiler basemap + OWM overlay tile proxy
│   ├── contact/            # Contact-Us form → contact_messages
│   ├── crisis-pins/        # Community pins: GET list / POST create
│   ├── alert-aggregator/   # Open-Meteo + GDACS RSS → alerts + timeline_events
│   │   └── deno.json       # Deno import map
│   └── globals.d.ts        # Deno ambient type declarations
├── migrations/
│   ├── 20260624_initial_schema.sql
│   ├── 20260624_01_reference_data_and_constraints.sql
│   ├── 20260624_02_user_scoped_and_realtime.sql
│   ├── 20260624_03_rpcs_and_views.sql
│   ├── 20260625_landslide_zones_table.sql
│   ├── 20260922_fix_crisis_pin_type_constraint.sql
│   ├── 20260922_tighten_user_scoped_rls.sql
│   └── 20260922_lock_service_only_writes.sql
└── README.md              # ← you are here
```

All eight migrations are **applied** to the live project above
(`select name from supabase_migrations.schema_migrations order by version;`).

Note: `20260625_landslide_zones_table.sql` creates a GiST index using
`ll_to_earth()`, which needs the `earthdistance` + `cube` extensions in the
`extensions` schema. They are not created by any migration — enable them
before applying that file to a fresh project.

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
| `landslide_zones`     |    ✗     |     ✓       |      ✗       | 8 seeded polygons, read by the hazard map |

### User-scoped tables (`clerk_user_id` holds the Supabase Auth uid)

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

`districts` / `alert_types` / `alerts` / `timeline_events` /
`contact_messages` also have their INSERT/UPDATE/DELETE **grants revoked** from
`anon` and `authenticated`, so those ✗ marks hold at the ACL layer as well as
under RLS. Before `20260922_lock_service_only_writes.sql` the three
`*_service_insert` policies carried no `to <role>` clause (so they applied to
PUBLIC) and `POST /rest/v1/alerts` with only the anon key returned **201** —
i.e. any client could publish a fake alert that every device received over
realtime. Re-checked after the fix: anon alert insert → 401, anon district
update → 401, anon district read → 200, aggregator (service role) → 200.

"Own only" policies compare `clerk_user_id` (the column name is kept for
history) against the request JWT `sub` claim — `auth.jwt() ->> 'sub'` — and
are restricted `to authenticated`, so an anon request matches nothing.
`20260922_tighten_user_scoped_rls.sql` replaced the earlier
`coalesce(claims ->> 'sub', clerk_user_id)` form, which degenerated to
`clerk_user_id = clerk_user_id` whenever the caller had no `sub` claim and
therefore exposed every row to the anon key.

---

## CHECK constraints (data integrity)

| Table             | Constraint                                |
|-------------------|-------------------------------------------|
| `alerts`          | `severity IN ('critical'..'calm')`        |
| `alerts`          | `source IN ('manual','open_meteo','gdacs','reliefweb','derived')` |
| `alerts`          | `latitude ∈ [-90, 90]`, `longitude ∈ [-180, 180]` |
| `timeline_events` | `event_type IN ('flood','landslide','cyclone','lightning','coastalWarning','tsunami','earthquake','info','weather')` |
| `timeline_events` | lat/lng ranges                            |
| `crisis_pins`     | `type IN ('shelter','water','toilet','road','waste','relief_supply')` |
| `crisis_pins`     | `capacity >= 0`, `watch_count >= 0`       |
| `sos_alerts`      | `status IN ('active','acknowledged','resolved','cancelled')` |

---

## Edge function inventory

All six are deployed and ACTIVE on `muoaodsgpgbtbdhrmnfj`.

| Function            | verify_jwt | Called by (Flutter)                                        | Secrets required        |
|---------------------|:----------:|------------------------------------------------------------|-------------------------|
| `weather`           |    ✓       | `WeatherApiClient` → `functions.invoke('weather')`          | `WEATHERAPI_KEY`        |
| `geocode`           |    ✓       | `MaptilerGeocodingClient` (search + reverse geocode)        | `MAPTILER_API_KEY`      |
| `tiles`             |    ✗       | `flutter_map` `TileLayer` (basemap + OWM overlays)          | `MAPTILER_API_KEY`, `OWM_API_KEY` |
| `contact`           |    ✓       | `ContactApiClient` → `contact_messages`                     | – (service role is auto-injected) |
| `crisis-pins`       |    ✓       | pins list/create (repository not wired yet)                 | –                       |
| `alert-aggregator`  |    ✗       | cron / manual invoke, never the client                      | –                       |

`verify_jwt = false` on `tiles` is deliberate: `TileLayer` issues plain image
GETs and cannot attach an `Authorization` header. The other five are reached
through `supabase.functions.invoke`, which always sends the session (or anon)
JWT, so requiring one costs nothing.

### Secrets

Provider keys live **only** in Supabase Secrets — never in `.env`, never in
the APK. Until they are set, `weather` / `geocode` / `tiles` answer
`500 "Server misconfigured"` and the map renders blank overlays.

```powershell
npx supabase secrets set `
  WEATHERAPI_KEY=... MAPTILER_API_KEY=... OWM_API_KEY=... `
  --project-ref muoaodsgpgbtbdhrmnfj
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected by the platform —
do not set them.

### Deploy

Either from the repo script (reads the project ref from `.env`, deploys all
six, honours `verify_jwt` from `config.toml`):

```powershell
$env:SUPABASE_ACCESS_TOKEN = "sbp_..."   # dashboard → Account → Tokens
pwsh scripts/deploy_edge_functions.ps1
```

Or per function with the CLI:

```bash
supabase functions deploy alert-aggregator --project-ref muoaodsgpgbtbdhrmnfj
```

Or paste the file contents into the Supabase Dashboard → Edge Functions →
"Deploy from editor".

## Edge function detail: `alert-aggregator`

Polls Open-Meteo and GDACS RSS, derives alerts via thresholds, and
upserts into `alerts` + mirrors into `timeline_events`.

### Redeploy caveat (`alert-aggregator` only)

This function ships a `deno.json` import map. Once a function is deployed
**with** an import map through the Supabase MCP tool, the stored
`import_map_path` is an absolute `file:///tmp/...` URI and every later MCP
deploy of that function fails with `import map path does not exist`. Use the
CLI or the Dashboard for subsequent `alert-aggregator` deploys.

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

**Not scheduled yet** on `muoaodsgpgbtbdhrmnfj` — `pg_cron` and `pg_net` are
not enabled there, so `alerts` only changes when someone invokes the function
manually. Either add the schedule from Dashboard → Edge Functions →
`alert-aggregator` → *Schedule* (the dashboard enables the extensions for
you), or run the SQL below after enabling `pg_cron` + `pg_net` and storing the
service-role key in `vault`:

```sql
select cron.schedule(
  'alert-aggregator-10m',
  '*/10 * * * *',
  $$
  select net.http_post(
    url     := 'https://muoaodsgpgbtbdhrmnfj.supabase.co/functions/v1/alert-aggregator',
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key'),
      'Content-Type',  'application/json'
    ),
    body    := '{}'::jsonb
  );
  $$
);
```

A second schedule running `select public.expire_stale_alerts();` every 10
minutes keeps expired alerts out of the app. That RPC is `SECURITY DEFINER`
and EXECUTE is now restricted to `service_role`
(`20260922_lock_service_only_writes.sql`), so it must be called from the cron
job's service-role context or the dashboard, never from the client.

Or call the aggregator manually:

```powershell
curl.exe https://muoaodsgpgbtbdhrmnfj.supabase.co/functions/v1/alert-aggregator
```

---

## Flutter client wiring (done)

`.env` needs only two values — provider keys are never client-side:

```env
SUPABASE_URL=https://muoaodsgpgbtbdhrmnfj.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOi...   # from Supabase dashboard → Settings → API
```

`SupabaseService.init()` (`lib/data/remote/supabase/supabase_service.dart`)
reads both through `flutter_dotenv`; `main.dart` loads `.env` and then awaits
`initDependencies()`, which initialises Supabase as its very first step.
Tile URLs are built in `AppConstants` as
`{SUPABASE_URL}/functions/v1/tiles/...`, so no key ever reaches the device.

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
| `20260624_initial_schema`                      | `alerts`, `timeline_events`, `crisis_pins`, `sos_alerts`, `contact_messages`, base RLS + realtime |
| `20260624_01_reference_data_and_constraints`   | CHECK constraints, `districts`, `alert_types`, timeline detail fields |
| `20260624_02_user_scoped_and_realtime`         | `pin_watches`, `alert_subscriptions`, realtime for `timeline_events`, `updated_at` triggers |
| `20260624_03_rpcs_and_views`                   | 5 RPCs + `v_active_alerts` view + `expire_stale_alerts` |
| `20260625_landslide_zones_table`               | `landslide_zones` + 8 seeded NBRO-inspired polygons |
| `20260922_fix_crisis_pin_type_constraint`      | Reconciles the two competing `crisis_pins.type` CHECKs on `relief_supply` |
| `20260922_tighten_user_scoped_rls`             | `pin_watches` / `alert_subscriptions` policies keyed on `auth.jwt()`, `authenticated` only, + missing insert/delete |
| `20260922_lock_service_only_writes`            | Alert/timeline/contact writes restricted to `service_role`, reference data read-only, `expire_stale_alerts` EXECUTE locked, `search_path` pinned on 7 functions |

`20260624_04_toggle_pin_watch_cleanup` is referenced by older revisions of
this README but was never committed and never needed: the
`WHERE w.pin_id = w.pin_id` line in `toggle_pin_watch` is a harmless tautology
(the real predicate `w.pin_id = p_pin_id` follows it).
