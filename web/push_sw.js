// Service worker for the Divine Quotes website.
//  - Shows the daily quote pushed by the push server (push-server/).
//  - Opens / focuses the app when a notification is tapped.
//  - Keeps a network-first cache so the app still opens offline.

const CACHE = 'divine-quotes-v2';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const names = await caches.keys();
    await Promise.all(names.filter((n) => n !== CACHE).map((n) => caches.delete(n)));
    await self.clients.claim();
  })());
});

self.addEventListener('push', (event) => {
  let data = {};
  try {
    data = event.data ? event.data.json() : {};
  } catch {
    data = { body: event.data ? event.data.text() : '' };
  }
  const scope = self.registration.scope;
  event.waitUntil(
    self.registration.showNotification(data.title || 'Divine Quotes', {
      body: data.body || 'Your daily quote is here.',
      icon: `${scope}icons/Icon-192.png`,
      badge: `${scope}icons/Icon-192.png`,
      tag: 'daily-quote',
      data: { url: data.url || scope },
    }),
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || self.registration.scope;
  event.waitUntil((async () => {
    const windows = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of windows) {
      if (client.url.startsWith(self.registration.scope) && 'focus' in client) {
        return client.focus();
      }
    }
    return self.clients.openWindow(url);
  })());
});

// Caching, chosen to make launches fast without serving stale app code:
//  - Flutter's engine (www.gstatic.com/flutter-canvaskit/<engine hash>/...)
//    and Google font files have versioned URLs that never change, so they
//    are served straight from the cache.
//  - The app's own files are fetched from the network first, so a new
//    release shows up right away; if the network is offline or slower than
//    NETWORK_TIMEOUT_MS, the cached copy is used instead.
const NETWORK_TIMEOUT_MS = 3000;

function isImmutable(url) {
  return (url.hostname === 'www.gstatic.com' && url.pathname.startsWith('/flutter-canvaskit/')) ||
    url.hostname === 'fonts.gstatic.com';
}

async function putInCache(request, response) {
  if (response.ok || response.type === 'opaque') {
    const cache = await caches.open(CACHE);
    await cache.put(request, response);
  }
}

async function cacheFirst(request) {
  const cached = await caches.match(request);
  if (cached) return cached;
  const response = await fetch(request);
  putInCache(request, response.clone());
  return response;
}

async function networkFirst(request, event) {
  const network = fetch(request).then((response) => {
    event.waitUntil(putInCache(request, response.clone()));
    return response;
  });
  network.catch(() => {}); // Handled below; avoid an unhandled rejection if the cache answered.
  const cached = caches.match(request, { ignoreSearch: request.mode === 'navigate' });
  const timeout = new Promise((resolve) => setTimeout(resolve, NETWORK_TIMEOUT_MS));
  try {
    // Prefer the network; fall back to the cache only if it fails or is slow.
    const response = await Promise.race([network, timeout.then(() => cached)]);
    if (response) return response;
    return await network;
  } catch (error) {
    const fallback = await cached;
    if (fallback) return fallback;
    throw error;
  }
}

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (isImmutable(url)) {
    event.respondWith(cacheFirst(request));
  } else if (url.href.startsWith(self.registration.scope) || url.hostname === 'fonts.googleapis.com') {
    event.respondWith(networkFirst(request, event));
  }
});
