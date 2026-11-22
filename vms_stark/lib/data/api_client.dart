import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'data_exception.dart';

/// A failed API call. [message] is the backend's `detail` (ProblemDetail, see vms-backend/API.md).
class ApiException extends DataException {
  const ApiException(super.message, {this.statusCode, this.fieldErrors = const {}});

  /// Null when the server could not be reached at all.
  final int? statusCode;

  /// Per-field validation messages from a 400 response, e.g. {"type": "Type is required"}.
  final Map<String, String> fieldErrors;
}

/// Small reusable JSON-over-HTTP client. The only class in the app that knows about HTTP.
/// Repositories use it; widgets never do.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? httpClient, // injectable, so tests can use package:http/testing.dart
    this.timeout = const Duration(seconds: 15),
    this.authToken,
    this.onUnauthorized,
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _http;
  final Duration timeout;

  /// Current access token, sent as "Authorization: Bearer ..." when not null.
  final String? Function()? authToken;

  /// Called when the server rejects a token we sent (expired or revoked), so the app can sign out.
  final void Function()? onUnauthorized;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Object body) => _send('POST', path, body);
  Future<dynamic> put(String path, Object body) => _send('PUT', path, body);
  Future<void> delete(String path) => _send('DELETE', path);

  /// Releases kept-alive connections. Call when the client is no longer needed.
  void close() => _http.close();

  Future<dynamic> _send(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers['Accept'] = 'application/json';
    final token = authToken?.call();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _http.send(request)).timeout(timeout);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond. Please try again.');
    } catch (_) {
      // Server down, wrong URL, no network, or blocked by CORS: the browser can't tell us which.
      throw const ApiException('Cannot reach the server. Check your connection and try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isEmpty ? null : jsonDecode(utf8.decode(response.bodyBytes));
    }
    // Only a rejected *token* ends the session; a 401 from the login call itself means wrong password.
    if (response.statusCode == 401 && token != null) {
      onUnauthorized?.call();
      throw const ApiException('Your session has expired. Please sign in again.', statusCode: 401);
    }
    throw _toException(response);
  }

  /// Reads the backend's ProblemDetail JSON; falls back to a generic message.
  static ApiException _toException(http.Response response) {
    String? detail;
    var fieldErrors = const <String, String>{};
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      detail = json['detail'] as String?;
      final errors = json['errors'];
      if (errors is Map) {
        fieldErrors = errors.map((k, v) => MapEntry('$k', '$v'));
      }
    } catch (_) {
      // Not JSON (e.g. a proxy error page): use the generic message below.
    }
    final message = switch ((detail, fieldErrors.isNotEmpty)) {
      // "Validation failed" alone isn't helpful: list what failed instead.
      (_, true) => fieldErrors.values.join('\n'),
      (final String d, _) => d,
      _ => 'Something went wrong (error ${response.statusCode}). Please try again.',
    };
    return ApiException(message, statusCode: response.statusCode, fieldErrors: fieldErrors);
  }
}
