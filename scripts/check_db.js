/**
 * Manual debug script: list rows in `settings` table.
 *
 * Usage (run from repo root, NOT from this directory):
 *   node scripts/check_db.js
 *
 * Requires .env with VITE_SUPABASE_URL and SUPABASE_SERVICE_KEY.
 * Not referenced by any application code or npm script.
 */
const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

async function check() {
  const { data, error } = await supabase.from('settings').select('*');
  if (error) {
    console.error('Query failed:', error);
    process.exit(1);
  }
  console.log(data);
}

check();
