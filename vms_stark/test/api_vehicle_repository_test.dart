import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vms_stark/data/api_client.dart';
import 'package:vms_stark/data/api_vehicle_repository.dart';
import 'package:vms_stark/data/vehicle_repository.dart';
import 'package:vms_stark/models/vehicle.dart';

/// Contract tests: requests and responses exactly as in vms-backend/API.md.
void main() {
  const truckJson = {
    'id': 7,
    'vehicleNumber': 'DHAKA METRO-GA-11-2345',
    'company': 'Stark Logistics',
    'type': 'TRUCK',
    'brand': 'Tata',
    'model': 'LPT 1613',
    'status': 'IN_USE',
  };
  const draft = Vehicle(
      vehicleNumber: 'DHAKA METRO-GA-11-2345', company: 'Stark Logistics', type: VehicleType.truck,
      brand: 'Tata', model: 'LPT 1613', status: VehicleStatus.inUse);

  ApiVehicleRepository repo(MockClientHandler handler) => ApiVehicleRepository(
      ApiClient(baseUrl: 'http://api.test/', httpClient: MockClient(handler)));

  http.Response json(Object body, int status) => http.Response(jsonEncode(body), status,
      headers: {'content-type': 'application/json'});

  test('getAll reads the list and maps API enums', () async {
    final vehicles = await repo((req) async {
      expect(req.method, 'GET');
      expect(req.url.toString(), 'http://api.test/api/vehicles');
      return json([truckJson], 200);
    }).getAll();

    expect(vehicles.single.id, 7);
    expect(vehicles.single.type, VehicleType.truck);
    expect(vehicles.single.status, VehicleStatus.inUse);
  });

  test('create posts the contract body and returns the saved vehicle', () async {
    final saved = await repo((req) async {
      expect(req.method, 'POST');
      expect(jsonDecode(req.body), {
        'vehicleNumber': 'DHAKA METRO-GA-11-2345',
        'company': 'Stark Logistics',
        'type': 'TRUCK',
        'brand': 'Tata',
        'model': 'LPT 1613',
        'status': 'IN_USE',
      });
      expect(req.headers['Content-Type'], startsWith('application/json'));
      return json(truckJson, 201);
    }).create(draft);

    expect(saved.id, 7);
  });

  test('update puts to /api/vehicles/{id}; delete sends DELETE', () async {
    final calls = <String>[];
    final r = repo((req) async {
      calls.add('${req.method} ${req.url.path}');
      return req.method == 'DELETE' ? http.Response('', 204) : json(truckJson, 200);
    });

    await r.update(draft.copyWith(id: 7));
    await r.delete(7);
    expect(calls, ['PUT /api/vehicles/7', 'DELETE /api/vehicles/7']);
  });

  test('409 becomes DuplicateVehicleNumberException', () async {
    final r = repo((_) async => json(
        {'status': 409, 'title': 'Conflict', 'detail': 'Vehicle number X is already registered'}, 409));

    expect(() => r.create(draft), throwsA(isA<DuplicateVehicleNumberException>()));
  });

  test('400 field errors on save become VehicleValidationException with the field map', () async {
    final r = repo((_) async => json({
          'status': 400,
          'detail': 'Validation failed',
          'errors': {'brand': 'Brand must be 40 characters or fewer'},
        }, 400));

    await expectLater(
        r.update(draft.copyWith(id: 7)),
        throwsA(isA<VehicleValidationException>().having(
            (e) => e.fieldErrors, 'fieldErrors', {'brand': 'Brand must be 40 characters or fewer'})));
  });

  test('400 field errors become a readable message', () async {
    final r = repo((_) async => json({
          'status': 400,
          'detail': 'Validation failed',
          'errors': {'type': 'Type is required', 'brand': 'Brand is required'},
        }, 400));

    await expectLater(
        r.create(draft),
        throwsA(isA<VehicleValidationException>()
            .having((e) => e.message, 'message', 'Type is required\nBrand is required')
            .having((e) => e.fieldErrors['brand'], 'brand error', 'Brand is required')));
  });

  test('404 shows the backend detail; non-JSON errors get a generic message', () async {
    await expectLater(repo((_) async => json({'detail': 'Vehicle 9 not found'}, 404)).delete(9),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Vehicle 9 not found')));
    await expectLater(repo((_) async => http.Response('<html>Bad Gateway</html>', 502)).getAll(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('error 502'))));
  });

  test('unreachable server becomes a friendly ApiException', () async {
    final r = repo((_) async => throw http.ClientException('XMLHttpRequest error'));

    await expectLater(
        r.getAll(),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)
            .having((e) => e.message, 'message', startsWith('Cannot reach the server'))));
  });
}
