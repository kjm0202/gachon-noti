import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';
import { initializeApp, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { runCrawler } from './src/crawler.js';

async function main() {
  for (const key of ['SUPABASE_URL', 'SUPABASE_SERVICE_KEY', 'FIREBASE_PROJECT_ID', 'FIREBASE_CLIENT_EMAIL', 'FIREBASE_PRIVATE_KEY']) {
    if (!process.env[key]) throw new Error(`Missing environment variable: ${key}`);
  }
  initializeApp({ credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  }) });
  const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { fetch: (url, options = {}) => fetch(url, { ...options, signal: AbortSignal.timeout(30_000) }) },
  });
  // Die before the database lease expires, even if a network operation hangs.
  const deadline = setTimeout(() => { console.error('Crawler exceeded 9 minutes'); process.exit(1); }, 9 * 60_000);
  const owner = randomUUID();
  try {
    const { data, error } = await supabase.rpc('acquire_crawler_lease', { p_owner: owner });
    if (error) throw error;
    if (!data) { console.log('Another crawler holds the lease'); return; }
    try { await runCrawler(supabase, getMessaging()); }
    finally {
      const { error } = await supabase.from('crawler_leases').delete().eq('owner', owner);
      if (error) throw error;
    }
  } finally { clearTimeout(deadline); }
}
main().catch(error => { console.error('Crawler failed:', error.message); process.exitCode = 1; });
