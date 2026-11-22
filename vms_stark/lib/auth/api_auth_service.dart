import 'package:material_ui/material_ui.dart';

import '../data/api_client.dart';
import 'auth_service.dart';
import 'session.dart';
import 'session_store.dart';

/// [AuthService] backed by POST /api/auth/login (contract: vms-backend/API.md).
class ApiAuthService extends ChangeNotifier implements AuthService {
  ApiAuthService(this._api, this._store) : _session = Session.tryDecode(_store.read());

  final ApiClient _api;
  final SessionStore _store;
  Session? _session;
  bool _expired = false;

  @override
  Session? get session => _session?.isExpired == false ? _session : null;

  @override
  bool get sessionExpired => _expired;

  @override
  Future<Session> signIn(String email, String password) async {
    final Map<String, dynamic> json;
    try {
      json = await _api.post('/api/auth/login', {'email': email, 'password': password})
          as Map<String, dynamic>;
    } on ApiException catch (e) {
      if (e.statusCode == 401) throw const InvalidCredentialsException();
      rethrow;
    }
    final session = Session(
      token: json['accessToken'] as String,
      email: json['email'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
    _session = session;
    _expired = false;
    _store.write(session.encode()); // token + email + expiry only, never the password
    notifyListeners();
    return session;
  }

  @override
  Future<void> signOut({bool expired = false}) async {
    _session = null;
    _expired = expired;
    _store.clear();
    notifyListeners();
  }
}
