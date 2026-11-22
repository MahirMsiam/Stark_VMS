import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:vms_stark/app.dart';
import 'package:vms_stark/auth/auth_service.dart';
import 'package:vms_stark/data/vehicle_repository.dart';
import 'package:vms_stark/models/vehicle.dart';

import 'support/fake_auth_service.dart';
import 'support/fake_vehicle_repository.dart';

/// Each test gets its own fresh repository and auth, so tests never depend on each other.
/// Signed in by default (most tests are about vehicle screens).
Future<VehicleRepository> _pumpApp(WidgetTester tester,
    {String? route,
    Object? arguments,
    Size size = const Size(1400, 900),
    VehicleRepository? repository,
    AuthService? auth}) async {
  tester.view.physicalSize = size; // desktop-sized window by default
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final vehicles = repository ?? FakeVehicleRepository();
  await tester.pumpWidget(VmsApp(auth: auth ?? FakeAuthService(signedIn: true), vehicles: vehicles));
  await tester.pumpAndSettle();
  if (route != null) {
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushReplacementNamed(route, arguments: arguments);
    await tester.pumpAndSettle();
  }
  return vehicles;
}

/// Reads work; saves fail with a backend field error and deletes with "not found".
class _RejectingRepository extends FakeVehicleRepository {
  @override
  Future<Vehicle> update(Vehicle vehicle) async => throw const VehicleValidationException(
      'Validation failed', {'brand': 'Brand must be 40 characters or fewer'});

  @override
  Future<void> delete(int id) async => throw DataException('Vehicle $id not found');
}

/// A repository whose every call fails, to test error states.
class _FailingRepository implements VehicleRepository {
  @override
  Future<List<Vehicle>> getAll() => Future.error(Exception('offline'));
  @override
  Future<Vehicle> create(Vehicle vehicle) => Future.error(Exception('offline'));
  @override
  Future<Vehicle> update(Vehicle vehicle) => Future.error(Exception('offline'));
  @override
  Future<void> delete(int id) => Future.error(Exception('offline'));
}

void main() {
  testWidgets('login validates, then valid credentials open the vehicle list', (tester) async {
    await _pumpApp(tester, auth: FakeAuthService());

    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), ' ${FakeAuthService.validEmail} ');
    await tester.enterText(find.byType(TextFormField).at(1), FakeAuthService.validPassword);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('DHAKA METRO-GA-11-2345'), findsOneWidget);
    expect(find.text(FakeAuthService.validEmail), findsOneWidget); // top bar shows the user
  });

  testWidgets('invalid credentials show a clear error and clear the password', (tester) async {
    await _pumpApp(tester, auth: FakeAuthService());

    await tester.enterText(find.byType(TextFormField).at(0), FakeAuthService.validEmail);
    await tester.enterText(find.byType(TextFormField).at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
    expect(find.text('wrong-password'), findsNothing);
    expect(find.text('Sign in'), findsWidgets); // still on login
  });

  testWidgets('signed-out users cannot open vehicle pages', (tester) async {
    await _pumpApp(tester, auth: FakeAuthService(), route: AppRoutes.vehicles);

    expect(find.text('DHAKA METRO-GA-11-2345'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('log out returns to login; expired session explains why', (tester) async {
    final auth = FakeAuthService(signedIn: true);
    await _pumpApp(tester, auth: auth, route: AppRoutes.vehicles);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();
    expect(auth.session, isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);

    // Sign in again, then the server rejects the token (what ApiClient triggers on 401).
    await auth.signIn(FakeAuthService.validEmail, FakeAuthService.validPassword);
    await _pumpApp(tester, auth: auth, route: AppRoutes.vehicles);
    await auth.signOut(expired: true);
    await tester.pumpAndSettle();
    expect(find.text('Your session has expired. Please sign in again.'), findsOneWidget);
  });

  testWidgets('register form validates only after first save', (tester) async {
    await _pumpApp(tester, route: AppRoutes.newVehicle);
    expect(find.text('Enter the vehicle number'), findsNothing); // no errors before saving

    await tester.tap(find.text('Register vehicle'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Some details need attention'), findsOneWidget);
    expect(find.text('Enter the vehicle number'), findsOneWidget);
    expect(find.text('Choose the company that owns this vehicle'), findsOneWidget);
    expect(find.text('Choose a vehicle type'), findsOneWidget);
    expect(find.text('Enter the brand'), findsOneWidget);
    expect(find.text('Enter the model'), findsOneWidget);
  });

  testWidgets('duplicate number rejected by the repository shows on the field', (tester) async {
    final second = sampleVehicles[1]; // edit vehicle 2, try to take vehicle 1's number
    await _pumpApp(tester, route: AppRoutes.editVehicle, arguments: second);

    // Typed in lower case with extra spaces: normalized before saving, still a duplicate.
    await tester.enterText(find.byType(TextFormField).first, ' dhaka metro-ga-11-2345 ');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('DHAKA METRO-GA-11-2345 is already registered'), findsOneWidget);
    expect(find.text('Edit Vehicle'), findsOneWidget); // stayed on the form

    // Editing the number clears the message.
    await tester.enterText(find.byType(TextFormField).first, 'NEW-9999');
    await tester.pumpAndSettle();
    expect(find.textContaining('already registered'), findsNothing);
  });

  testWidgets('backend validation messages appear under the matching field', (tester) async {
    await _pumpApp(tester,
        repository: _RejectingRepository(), route: AppRoutes.editVehicle, arguments: sampleVehicles[0]);

    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Brand must be 40 characters or fewer'), findsOneWidget);
    expect(find.text('Edit Vehicle'), findsOneWidget); // stayed on the form, values kept

    await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), 'Tata Motors');
    await tester.pumpAndSettle();
    expect(find.text('Brand must be 40 characters or fewer'), findsNothing);
  });

  testWidgets('failed delete keeps the row and explains why', (tester) async {
    await _pumpApp(tester, repository: _RejectingRepository(), route: AppRoutes.vehicles);

    final deleteButton = find.widgetWithText(TextButton, 'Delete').first;
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Could not delete DHAKA METRO-GA-11-2345. Vehicle 1 not found'), findsOneWidget);
    expect(find.text('Showing 10 of 10 vehicles'), findsOneWidget);
  });

  testWidgets('list shows a retry option when loading fails', (tester) async {
    await _pumpApp(tester, route: AppRoutes.vehicles, repository: _FailingRepository());

    expect(find.text('Could not load vehicles'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsOneWidget);
  });

  test('fake repository assigns ids and enforces unique numbers', () async {
    final repo = FakeVehicleRepository(seed: []);
    const draft = Vehicle(vehicleNumber: 'KA-01', company: 'Stark Motors', type: VehicleType.car,
        brand: 'Toyota', model: 'Premio', status: VehicleStatus.available);

    final saved = await repo.create(draft);
    expect(saved.id, 1);
    expect(() => repo.create(draft), throwsA(isA<DuplicateVehicleNumberException>()));
    expect(await repo.update(saved), same(saved)); // keeping its own number is fine
  });

  testWidgets('cancel with unsaved changes asks before discarding', (tester) async {
    await _pumpApp(tester, route: AppRoutes.newVehicle);

    await tester.enterText(find.byType(TextFormField).first, 'TEST-1234');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.text('Keep editing'));
    await tester.pumpAndSettle();
    expect(find.text('Register Vehicle'), findsWidgets); // still on the form

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Showing'), findsOneWidget); // back on the list
  });

  testWidgets('status filter narrows the list', (tester) async {
    await _pumpApp(tester, route: AppRoutes.vehicles);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Inactive'));
    await tester.pumpAndSettle();
    expect(find.text('SYLHET-HA-12-5508'), findsOneWidget);
    expect(find.text('DHAKA METRO-GA-11-2345'), findsNothing);
  });

  testWidgets('tablet width renders list and form without overflow', (tester) async {
    for (final route in [AppRoutes.login, AppRoutes.vehicles, AppRoutes.newVehicle]) {
      await _pumpApp(tester, route: route, size: const Size(800, 1000));
      expect(tester.takeException(), isNull, reason: route);
    }
  });

  testWidgets('no-match empty state explains filters and clears them', (tester) async {
    await _pumpApp(tester, route: AppRoutes.vehicles);

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching vehicles'), findsOneWidget);
    expect(find.textContaining('"zzz"'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 10 of 10 vehicles'), findsOneWidget);
  });

  testWidgets('delete asks for confirmation, then removes the row', (tester) async {
    await _pumpApp(tester, route: AppRoutes.vehicles);

    final deleteButton = find.widgetWithText(TextButton, 'Delete').first;
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Showing 9 of 9 vehicles'), findsOneWidget);
  });
}
