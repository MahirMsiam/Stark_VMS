import 'dart:convert';

/// The minimum kept after login: the access token, who it belongs to, and when it expires.
/// The password is never part of a session.
class Session {
  const Session({required this.token, required this.email, required this.expiresAt});

  final String token;
  final String email;
  final DateTime expiresAt;

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  String encode() => jsonEncode(
      {'token': token, 'email': email, 'expiresAt': expiresAt.toUtc().toIso8601String()});

  /// Null for missing or unreadable data (e.g. edited by hand) instead of crashing.
  static Session? tryDecode(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Session(
        token: json['token'] as String,
        email: json['email'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}
