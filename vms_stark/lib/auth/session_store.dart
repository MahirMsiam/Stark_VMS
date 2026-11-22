/// Where the current session is kept between page loads.
/// Browser: [BrowserSessionStore] (main.dart). Tests: [MemorySessionStore].
abstract interface class SessionStore {
  String? read();
  void write(String value);
  void clear();
}

class MemorySessionStore implements SessionStore {
  String? _value;

  @override
  String? read() => _value;

  @override
  void write(String value) => _value = value;

  @override
  void clear() => _value = null;
}
