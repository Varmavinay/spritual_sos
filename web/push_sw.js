// Service worker for the Divine Quotes website.
//  - Shows the daily quote pushed by the push server (push-server/).
//  - Opens / focuses the app when a notification is tapped.
//  - Keeps a network-first cache so the app still opens offline.

const CACHE = 'divine-quotes-v1';

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

// Network first, falling back to the cache when offline. Covers the app's own
// files and Flutter's CanvasKit / fonts from gstatic.
self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  const cacheable =
    url.href.startsWith(self.registration.scope) ||
    url.hostname === 'www.gstatic.com' ||
    url.hostname === 'fonts.gstatic.com' ||
    url.hostname === 'fonts.googleapis.com';
  if (!cacheable) return;

  event.respondWith((async () => {
    try {
      const response = await fetch(request);
      if (response.ok || response.type === 'opaque') {
        const cache = await caches.open(CACHE);
        cache.put(request, response.clone());
      }
      return response;
    } catch (error) {
      const cached = await caches.match(request, { ignoreSearch: true });
      if (cached) return cached;
      throw error;
    }
  })());
});
