import 'package:material_ui/material_ui.dart';

import 'auth/auth_service.dart';
import 'data/vehicle_repository.dart';
import 'models/vehicle.dart';
import 'screens/login_screen.dart';
import 'screens/vehicle_form_screen.dart';
import 'screens/vehicle_list_screen.dart';
import 'theme/app_theme.dart';

/// All route names live here so screens never hard-code strings.
class AppRoutes {
  static const login = '/';
  static const vehicles = '/vehicles';
  static const newVehicle = '/vehicles/new';
  static const editVehicle = '/vehicles/edit'; // expects a Vehicle argument
}

class VmsApp extends StatefulWidget {
  const VmsApp({super.key, required this.auth, required this.vehicles});

  /// Injected by main() (or a test), then handed to the screens that need them.
  final AuthService auth;
  final VehicleRepository vehicles;

  @override
  State<VmsApp> createState() => _VmsAppState();
}

class _VmsAppState extends State<VmsApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late bool _signedIn = widget.auth.session != null;

  @override
  void initState() {
    super.initState();
    widget.auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// Signed out (logout button or expired token): go to login and drop the history.
  void _onAuthChanged() {
    final signedIn = widget.auth.session != null;
    if (_signedIn && !signedIn) {
      _navigator.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
    _signedIn = signedIn;
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: widget.auth,
      child: MaterialApp(
        title: 'Stark Group VMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: _navigator,
        initialRoute: _signedIn ? AppRoutes.vehicles : AppRoutes.login,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<void> _onGenerateRoute(RouteSettings settings) {
    final vehicles = widget.vehicles;
    final login = LoginScreen(auth: widget.auth);
    // Route guard: every page except login needs a session.
    final Widget page = widget.auth.session == null
        ? login
        : switch (settings.name) {
            AppRoutes.vehicles => VehicleListScreen(vehicles: vehicles),
            AppRoutes.newVehicle => VehicleFormScreen(vehicles: vehicles),
            // shortcut: edit needs the Vehicle passed in memory, so a browser refresh
            // on this URL falls back to the list; load by id from the API if that matters.
            AppRoutes.editVehicle when settings.arguments is Vehicle =>
              VehicleFormScreen(vehicles: vehicles, vehicle: settings.arguments as Vehicle),
            AppRoutes.editVehicle => VehicleListScreen(vehicles: vehicles),
            _ => login,
          };
    // No slide animation: feels more like a desktop web app.
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
    );
  }
}
