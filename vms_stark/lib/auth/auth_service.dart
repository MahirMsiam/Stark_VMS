import 'package:material_ui/material_ui.dart';

import '../data/data_exception.dart';
import 'session.dart';

/// Sign-in state for the whole app. Screens depend on this abstraction, not on HTTP.
/// It is a [Listenable]: the app redirects to the login screen when the session ends.
abstract interface class AuthService implements Listenable {
  /// The current session, or null when signed out (or the token has expired).
  Session? get session;

  /// True if the last sign-out happened because the server rejected the token.
  bool get sessionExpired;

  /// Throws [InvalidCredentialsException] for a wrong email/password, [DataException] otherwise.
  Future<Session> signIn(String email, String password);

  Future<void> signOut({bool expired = false});
}

class InvalidCredentialsException extends DataException {
  const InvalidCredentialsException() : super('Incorrect email or password.');
}

/// Makes the [AuthService] available to shared widgets (e.g. the top bar) and rebuilds them on change.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService auth, required super.child}) : super(notifier: auth);

  static AuthService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
}
