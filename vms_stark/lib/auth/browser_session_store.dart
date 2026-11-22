import 'package:web/web.dart' as web;

import 'session_store.dart';

/// Keeps the session in the browser's sessionStorage: survives a page refresh,
/// is not shared with other tabs, and is deleted when the tab closes.
// shortcut: readable by page scripts (XSS risk like localStorage); move to an HttpOnly cookie if the app ever renders untrusted HTML.
class BrowserSessionStore implements SessionStore {
  static const _key = 'vms.session';

  @override
  String? read() => web.window.sessionStorage.getItem(_key);

  @override
  void write(String value) => web.window.sessionStorage.setItem(_key, value);

  @override
  void clear() => web.window.sessionStorage.removeItem(_key);
}
