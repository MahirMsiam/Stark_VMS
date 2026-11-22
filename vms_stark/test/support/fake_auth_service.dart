import 'package:material_ui/material_ui.dart';
import 'package:vms_stark/auth/auth_service.dart';
import 'package:vms_stark/auth/session.dart';

/// In-memory [AuthService] for widget tests. Accepts only [validEmail] / [validPassword].
class FakeAuthService extends ChangeNotifier implements AuthService {
  FakeAuthService({bool signedIn = false}) {
    if (signedIn) _session = _newSession();
  }

  static const validEmail = 'admin@starkgroup.com';
  static const validPassword = 'correct-password';

  Session? _session;
  bool _expired = false;

  Session _newSession() => Session(
      token: 'test-token', email: validEmail, expiresAt: DateTime.now().add(const Duration(hours: 1)));

  @override
  Session? get session => _session;

  @override
  bool get sessionExpired => _expired;

  @override
  Future<Session> signIn(String email, String password) async {
    if (email != validEmail || password != validPassword) throw const InvalidCredentialsException();
    _session = _newSession();
    _expired = false;
    notifyListeners();
    return _session!;
  }

  @override
  Future<void> signOut({bool expired = false}) async {
    _session = null;
    _expired = expired;
    notifyListeners();
  }
}
