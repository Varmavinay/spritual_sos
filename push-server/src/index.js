// Spiritual SOS push server (Cloudflare Worker).
//
//   GET  /vapid-public-key   -> { publicKey }
//   POST /subscribe          { subscription, hour, minute, timeZone, source? }
//                            source: "all" (default), "bible", "gita" or "quran"
//   POST /unsubscribe        { endpoint }
//   cron (every minute)      sends a quote to every subscription that is due
import quotes from './quotes.json';
import { BOOKS, pickQuote } from './quotes.js';
import { isValidTimeZone, nextSendAt } from './time.js';
import { sendPush } from './webpush.js';

// Free Workers allow 50 outbound requests per invocation; anything left
// over is picked up by the next minute's run.
const SENDS_PER_RUN = 45;

// Only real browser push services may be stored, so this server cannot be
// used to send requests to arbitrary URLs.
const PUSH_SERVICE_HOSTS = [
  /(^|\.)push\.apple\.com$/,
  /^fcm\.googleapis\.com$/,
  /(^|\.)push\.services\.mozilla\.com$/,
  /(^|\.)notify\.windows\.com$/,
];

function isAllowedEndpoint(endpoint, env) {
  let url;
  try {
    url = new URL(endpoint);
  } catch {
    return false;
  }
  if (env.ALLOW_LOCAL_ENDPOINTS === 'true' && url.hostname === '127.0.0.1') return true;
  return url.protocol === 'https:' && PUSH_SERVICE_HOSTS.some((re) => re.test(url.hostname));
}

function corsHeaders(request, env) {
  const origin = request.headers.get('Origin') ?? '';
  const allowed = (env.ALLOWED_ORIGINS ?? '').split(',').map((o) => o.trim());
  const isLocal = /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
  return {
    'Access-Control-Allow-Origin': allowed.includes(origin) || isLocal ? origin : allowed[0] ?? '',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function json(data, status, headers) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...headers },
  });
}

function vapidConfig(env) {
  return {
    publicKey: env.VAPID_PUBLIC_KEY,
    privateKeyJwk: JSON.parse(env.VAPID_PRIVATE_KEY),
    subject: env.VAPID_SUBJECT,
  };
}

async function handleSubscribe(request, env) {
  const body = await request.json().catch(() => null);
  const sub = body?.subscription;
  const { hour, minute, timeZone, source = 'all' } = body ?? {};
  if (
    !sub || typeof sub.endpoint !== 'string' ||
    typeof sub.keys?.p256dh !== 'string' || typeof sub.keys?.auth !== 'string' ||
    !Number.isInteger(hour) || hour < 0 || hour > 23 ||
    !Number.isInteger(minute) || minute < 0 || minute > 59 ||
    typeof timeZone !== 'string' || !isValidTimeZone(timeZone) ||
    !BOOKS.includes(source)
  ) {
    return { status: 400, data: { error: 'Invalid subscription, time, time zone or source' } };
  }
  if (!isAllowedEndpoint(sub.endpoint, env)) {
    return { status: 400, data: { error: 'Unsupported push service' } };
  }

  const now = Date.now();
  const next = nextSendAt(hour, minute, timeZone, now);
  await env.DB.prepare(
    `INSERT INTO subscriptions (endpoint, p256dh, auth, hour, minute, timezone, next_send_at, updated_at, book)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)
     ON CONFLICT (endpoint) DO UPDATE SET
       p256dh = ?2, auth = ?3, hour = ?4, minute = ?5, timezone = ?6,
       next_send_at = ?7, updated_at = ?8, book = ?9`,
  ).bind(sub.endpoint, sub.keys.p256dh, sub.keys.auth, hour, minute, timeZone, next, now, source).run();
  return { status: 200, data: { ok: true, nextSendAt: next } };
}

async function handleUnsubscribe(request, env) {
  const body = await request.json().catch(() => null);
  if (typeof body?.endpoint !== 'string') {
    return { status: 400, data: { error: 'Missing endpoint' } };
  }
  await env.DB.prepare('DELETE FROM subscriptions WHERE endpoint = ?1').bind(body.endpoint).run();
  return { status: 200, data: { ok: true } };
}

/** Sends every reminder that is due. Exported for tests. */
export async function sendDueReminders(env, now = Date.now()) {
  const { results } = await env.DB.prepare(
    'SELECT * FROM subscriptions WHERE next_send_at <= ?1 ORDER BY next_send_at LIMIT ?2',
  ).bind(now, SENDS_PER_RUN).all();
  if (results.length === 0) return { sent: 0, removed: 0, failed: 0 };

  const vapid = vapidConfig(env);
  let sent = 0;
  let removed = 0;
  let failed = 0;

  await Promise.all(results.map(async (row) => {
    const quote = pickQuote(quotes, row.book);
    let status;
    try {
      status = await sendPush(
        { endpoint: row.endpoint, p256dh: row.p256dh, auth: row.auth },
        {
          id: quote.id,
          title: `From ${quote.from}`,
          body: `“${quote.text}”\n— ${quote.citation}`,
          // Opens the message in the app (see takeLaunchQuoteId in the app).
          url: `${env.APP_URL}?quote=${quote.id}`,
        },
        vapid,
      );
    } catch (error) {
      console.error('Push failed', row.endpoint, error);
      status = 0;
    }

    if (status === 404 || status === 410) {
      // The browser unsubscribed or the app was removed.
      await env.DB.prepare('DELETE FROM subscriptions WHERE endpoint = ?1').bind(row.endpoint).run();
      removed++;
      return;
    }
    if (status >= 200 && status < 300) sent++;
    else {
      failed++;
      console.error('Push service rejected message', status, row.endpoint);
    }
    // Move on to tomorrow either way, so one bad subscription never blocks the queue.
    const next = nextSendAt(row.hour, row.minute, row.timezone, now);
    await env.DB.prepare('UPDATE subscriptions SET next_send_at = ?1 WHERE endpoint = ?2')
      .bind(next, row.endpoint).run();
  }));

  return { sent, removed, failed };
}

export default {
  async fetch(request, env) {
    const cors = corsHeaders(request, env);
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: cors });

    const { pathname } = new URL(request.url);
    try {
      if (request.method === 'GET' && pathname === '/vapid-public-key') {
        return json({ publicKey: env.VAPID_PUBLIC_KEY }, 200, cors);
      }
      if (request.method === 'POST' && pathname === '/subscribe') {
        const { status, data } = await handleSubscribe(request, env);
        return json(data, status, cors);
      }
      if (request.method === 'POST' && pathname === '/unsubscribe') {
        const { status, data } = await handleUnsubscribe(request, env);
        return json(data, status, cors);
      }
      if (request.method === 'GET' && pathname === '/') {
        return json({ ok: true, service: 'spiritual-sos-push' }, 200, cors);
      }
      return json({ error: 'Not found' }, 404, cors);
    } catch (error) {
      console.error(error);
      return json({ error: 'Server error' }, 500, cors);
    }
  },

  async scheduled(_event, env, ctx) {
    ctx.waitUntil(sendDueReminders(env).then((r) => console.log('Reminders', r)));
  },
};
