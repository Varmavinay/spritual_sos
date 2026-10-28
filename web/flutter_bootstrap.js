{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings on purpose: web/push_sw.js (registered in
// index.html) handles push notifications and offline caching. Flutter's
// legacy service worker would replace it, unregister itself (deleting the
// push subscription) and reload the page, slowing every first visit.
_flutter.loader.load();
