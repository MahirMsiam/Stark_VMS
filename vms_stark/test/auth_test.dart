import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_stark/auth/api_auth_service.dart';
import 'package:vms_stark/auth/auth_service.dart';
import 'package:vms_stark/auth/session.dart';
import 'package:vms_stark/auth/session_store.dart';
import 'package:vms_stark/data/api_client.dart';

/// Login contract (vms-backend/API.md) and token handling, with a fake HTTP server.
void main() {
  const password = 'S3cret-Pa55word';
  final future = DateTime.now().toUtc().add(const Duration(hours: 8));

  http.Response json(Object body, int status) => http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});

  test('signIn posts the contract body and stores the session without the password', () async {
    final store = MemorySessionStore();
    final auth = ApiAuthService(
        ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((req) async {
          expect(req.url.path, '/api/auth/login');
          expect(jsonDecode(req.body), {'email': 'admin@starkgroup.com', 'password': password});
          expect(req.headers.containsKey('Authorization'), isFalse);
          return json({
            'accessToken': 'jwt-abc',
            'tokenType': 'Bearer',
            'expiresAt': future.toIso8601String(),
            'email': 'admin@starkgroup.com',
          }, 200);
        })),
        store);

    final session = await auth.signIn('admin@starkgroup.com', password);

    expect(session.token, 'jwt-abc');
    expect(auth.session?.email, 'admin@starkgroup.com');
    expect(store.read(), isNot(contains(password)));
    expect(Session.tryDecode(store.read())?.token, 'jwt-abc');
  });

  test('401 from login becomes InvalidCredentialsException, nothing stored', () async {
    final store = MemorySessionStore();
    final auth = ApiAuthService(
        ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((_) async =>
            json({'status': 401, 'detail': 'Invalid email or password'}, 401))),
        store);

    await expectLater(auth.signIn('admin@starkgroup.com', 'nope'),
        throwsA(isA<InvalidCredentialsException>()));
    expect(auth.session, isNull);
    expect(store.read(), isNull);
  });

  test('a stored session survives a reload; an expired one is ignored', () async {
    final client = ApiClient(baseUrl: 'http://api.test', httpClient: MockClient((_) async => json({}, 200)));
    final store = MemorySessionStore()
      ..write(Session(token: 't', email: 'a@b.c', expiresAt: future).encode());
    expect(ApiAuthService(client, store).session?.token, 't');

    store.write(Session(token: 't', email: 'a@b.c',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1))).encode());
    expect(ApiAuthService(client, store).session, isNull);

    store.write('not json');
    expect(ApiAuthService(client, store).session, isNull);
  });

  test('ApiClient sends the bearer token and reports a rejected token', () async {
    var unauthorizedCalls = 0;
    final client = ApiClient(
      baseUrl: 'http://api.test',
      authToken: () => 'jwt-abc',
      onUnauthorized: () => unauthorizedCalls++,
      httpClient: MockClient((req) async {
        expect(req.headers['Authorization'], 'Bearer jwt-abc');
        return json({'status': 401, 'detail': 'Please sign in to continue'}, 401);
      }),
    );

    await expectLater(client.get('/api/vehicles'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('session has expired'))));
    expect(unauthorizedCalls, 1);
  });

  test('a 401 without a token (the login call) does not trigger sign-out', () async {
    var unauthorizedCalls = 0;
    final client = ApiClient(
      baseUrl: 'http://api.test',
      authToken: () => null,
      onUnauthorized: () => unauthorizedCalls++,
      httpClient: MockClient((_) async => json({'detail': 'Invalid email or password'}, 401)),
    );

    await expectLater(client.post('/api/auth/login', {}), throwsA(isA<ApiException>()));
    expect(unauthorizedCalls, 0);
  });
}
