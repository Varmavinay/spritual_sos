// Web Push client. The real implementation only exists on the web; other
// platforms get a stub (they use flutter_local_notifications instead).
export 'web_push_stub.dart' if (dart.library.js_interop) 'web_push_web.dart';
