// Live check against a running backend (skipped by default). Credentials come from the
// environment, never from code:
//   VMS_LIVE_API=http://localhost:9001 VMS_LIVE_EMAIL=... VMS_LIVE_PASSWORD=... VMS_LIVE_PHASE=create  flutter test test/live
//   (same with VMS_LIVE_PHASE=cleanup)
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vms_stark/auth/api_auth_service.dart';
import 'package:vms_stark/auth/auth_service.dart';
import 'package:vms_stark/auth/session_store.dart';
import 'package:vms_stark/data/api_client.dart';
import 'package:vms_stark/data/api_vehicle_repository.dart';
import 'package:vms_stark/data/vehicle_repository.dart';
import 'package:vms_stark/models/vehicle.dart';

void main() {
  final env = Platform.environment;
  final baseUrl = env['VMS_LIVE_API'];
  final phase = env['VMS_LIVE_PHASE'] ?? 'create';
  const number = 'LIVE-TEST-0001';

  test('real backend round trip ($phase)', () async {
    // Wired exactly like main.dart, but with an in-memory session store.
    late final ApiAuthService auth;
    final api = ApiClient(baseUrl: baseUrl!, authToken: () => auth.session?.token,
        onUnauthorized: () => auth.signOut(expired: true));
    auth = ApiAuthService(api, MemorySessionStore());
    final repo = ApiVehicleRepository(api);

    // Not signed in: vehicle operations are rejected.
    await expectLater(repo.getAll(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    // Wrong password: clear error.
    await expectLater(auth.signIn(env['VMS_LIVE_EMAIL']!, 'definitely-wrong'),
        throwsA(isA<InvalidCredentialsException>()));
    await auth.signIn(env['VMS_LIVE_EMAIL']!, env['VMS_LIVE_PASSWORD']!);

    if (phase == 'create') {
      final saved = await repo.create(const Vehicle(
          vehicleNumber: number, company: 'Stark Motors', type: VehicleType.van,
          brand: 'Nissan', model: 'Urvan', status: VehicleStatus.available));
      expect(saved.id, isNotNull);
      return;
    }

    final vehicle = (await repo.getAll()).firstWhere((v) => v.vehicleNumber == number);
    final updated = await repo.update(Vehicle(
        id: vehicle.id, vehicleNumber: number, company: vehicle.company, type: vehicle.type,
        brand: vehicle.brand, model: vehicle.model, status: VehicleStatus.maintenance));
    expect(updated.status, VehicleStatus.maintenance);
    await expectLater(repo.create(vehicle), throwsA(isA<DuplicateVehicleNumberException>()));
    await repo.delete(vehicle.id!);

    // Signing out drops the token: the API rejects us again.
    await auth.signOut();
    await expectLater(repo.getAll(), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
  }, skip: baseUrl == null ? 'set VMS_LIVE_API (and VMS_LIVE_EMAIL/PASSWORD) to run against a real backend' : false);
}
