// Drives the REAL screens against a running backend (skipped by default).
// Run one phase at a time and check the database in between:
//   VMS_LIVE_API=http://localhost:9001 VMS_LIVE_EMAIL=... VMS_LIVE_PASSWORD=... VMS_LIVE_PHASE=register flutter test test/live/ui_journey_live_test.dart
//   ... VMS_LIVE_PHASE=update ...   then   ... VMS_LIVE_PHASE=delete ...
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_stark/app.dart';
import 'package:vms_stark/auth/api_auth_service.dart';
import 'package:vms_stark/auth/session_store.dart';
import 'package:vms_stark/data/api_client.dart';
import 'package:vms_stark/data/api_vehicle_repository.dart';
import 'package:vms_stark/models/vehicle.dart';

const number = 'LIVE-UI-0001';

/// The vehicle number inside the list table (not the same text typed into a form field).
Finder inList(String text) => find.descendant(of: find.byType(DataTable), matching: find.text(text));

void main() {
  final env = Platform.environment;
  final baseUrl = env['VMS_LIVE_API'];
  final phase = env['VMS_LIVE_PHASE'] ?? 'register';

  testWidgets('UI journey against the real backend: $phase', (tester) async {
    HttpOverrides.global = null; // flutter_test fakes all HTTP by default; this test needs the real network
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Wired exactly like main.dart (only the session store differs: no browser here).
    late final ApiAuthService auth;
    final api = ApiClient(
        baseUrl: baseUrl!,
        authToken: () => auth.session?.token,
        onUnauthorized: () => auth.signOut(expired: true));
    auth = ApiAuthService(api, MemorySessionStore());
    await tester.pumpWidget(VmsApp(auth: auth, vehicles: ApiVehicleRepository(api)));

    // ---- Login (through the login screen)
    await tester.enterText(find.byType(TextFormField).at(0), env['VMS_LIVE_EMAIL']!);
    await tester.enterText(find.byType(TextFormField).at(1), env['VMS_LIVE_PASSWORD']!);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await waitFor(tester, find.text('Total vehicles')); // list loaded from the API

    switch (phase) {
      case 'register':
        await registerVehicle(tester, number);
        await waitFor(tester, inList(number));
        report(tester, 'after register');

        // Same plate again, typed differently: the backend must reject it, the form must say so.
        await registerVehicle(tester, 'live-ui-0001');
        await waitFor(tester, find.text('$number is already registered'));
        expect(find.text('Register Vehicle'), findsWidgets); // still on the form
        // ignore: avoid_print
        print('UI duplicate message: "$number is already registered"');

      case 'update':
        await waitFor(tester, inList(number));
        await tap(tester, find.byTooltip('Edit $number'));
        await waitFor(tester, find.text('Edit Vehicle'));
        await tap(tester, find.widgetWithText(ChoiceChip, 'Maintenance'));
        await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'Urvan NV350');
        await tap(tester, find.text('Save changes'));
        await waitFor(tester, inList('Urvan NV350')); // back on the list, re-read from the API
        report(tester, 'after update');

      case 'delete':
        await waitFor(tester, inList(number));
        await tap(tester, find.byTooltip('Delete $number'));
        await tap(tester, find.widgetWithText(FilledButton, 'Delete')); // confirmation dialog
        await waitFor(tester, inList(number), present: false);
        report(tester, 'after delete');
    }
    api.close(); // drop the kept-alive connection (its idle timer would outlive the test)
    await tester.pump(const Duration(seconds: 10)); // let snackbars time out before the test ends
  }, skip: baseUrl == null); // needs VMS_LIVE_API, VMS_LIVE_EMAIL, VMS_LIVE_PASSWORD
}

/// Opens the Register form, fills every field through the real widgets and submits.
Future<void> registerVehicle(WidgetTester tester, String vehicleNumber) async {
  await tap(tester, find.widgetWithText(FilledButton, 'Register vehicle'));
  await waitFor(tester, find.text('Vehicle details'));
  await tester.enterText(find.byType(TextFormField).first, vehicleNumber);
  await tap(tester, find.byType(DropdownButtonFormField<String>));
  await tap(tester, find.text('Stark Motors').last);
  await tap(tester, find.byType(DropdownButtonFormField<VehicleType>));
  await tap(tester, find.text('Van').last);
  await tester.enterText(find.widgetWithText(TextFormField, 'Brand'), 'Nissan');
  await tester.enterText(find.widgetWithText(TextFormField, 'Model'), 'Urvan');
  await tap(tester, find.widgetWithText(FilledButton, 'Register vehicle'));
}

/// Prints what the UI shows so it can be compared with the database.
void report(WidgetTester tester, String step) {
  final footer = find.textContaining(RegExp(r'^Showing \d+ of \d+ vehicles$'));
  final rows = tester.widgetList<DataTable>(find.byType(DataTable)).expand((t) => t.rows).map((r) =>
      r.cells.take(6).map((c) => switch (c.child) {
            Text(:final data) => data,
            _ => '',
          }).where((s) => s != null && s.isNotEmpty).join(' | '));
  // ignore: avoid_print
  print('UI $step: ${footer.evaluate().isEmpty ? 'empty list' : (footer.evaluate().first.widget as Text).data}'
      '${rows.isEmpty ? '' : '\n    ${rows.join('\n    ')}'}');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await settle(tester);
}

/// Lets real network I/O complete between frames, until [finder] is (or is no longer) on screen.
Future<void> waitFor(WidgetTester tester, Finder finder, {bool present = true}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await settle(tester);
    if (finder.evaluate().isNotEmpty == present) return;
  }
  throw TestFailure('Timed out waiting for $finder to be ${present ? 'shown' : 'gone'}');
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
  await tester.pump(const Duration(milliseconds: 300)); // also finishes dialog/dropdown animations
}
