// Read-only export of alerts, timeline_events and sos_alerts rows from the
// Supabase project (the same DB the MCP connects to) into JSON files, ready to
// be uploaded to a Supabase Storage bucket. Uses the public anon key; these
// tables expose a public-read RLS policy (SELECT USING true).
//
// Run:  node supabase/export_table_data_to_storage.js
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const SUPABASE_URL = 'https://muoaodsgpgbtbdhrmnfj.supabase.co';
const ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11b2FvZHNncGdidGJkaHJtbmZqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwNzIxMDIsImV4cCI6MjEwNTY0ODEwMn0.8NLe8oHXuS1f8Lp_P4471PQMy2O8-1QcPDsh43JtoOY';

const TABLES = ['alerts', 'timeline_events', 'sos_alerts'];
const OUT_DIR = dirname(fileURLToPath(import.meta.url));
const PAGE = 1000;

async function fetchTable(table) {
  const rows = [];
  let start = 0;
  while (true) {
    const end = start + PAGE - 1;
    const res = await fetch(
      `${SUPABASE_URL}/rest/v1/${table}?select=*&order=id.asc`,
      {
        headers: {
          apikey: ANON_KEY,
          Authorization: `Bearer ${ANON_KEY}`,
          Range: `${start}-${end}`,
          'Range-Unit': 'items',
          Prefer: 'count=exact',
        },
      },
    );
    if (!res.ok) {
      throw new Error(`${table}: HTTP ${res.status} ${await res.text()}`);
    }
    const page = await res.json();
    rows.push(...page);
    if (page.length < PAGE) break;
    start += PAGE;
  }
  return rows;
}

for (const table of TABLES) {
  const rows = await fetchTable(table);
  const file = join(OUT_DIR, `${table}.json`);
  writeFileSync(file, JSON.stringify(rows, null, 2), 'utf8');
  console.log(`${table}: ${rows.length} rows -> ${file}`);
}
