import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'auth/api_auth_service.dart';
import 'auth/browser_session_store.dart';
import 'data/api_client.dart';
import 'data/api_vehicle_repository.dart';

/// Backend URL. Default = local Spring Boot. Override per environment at build time:
///   flutter build web --dart-define=API_BASE_URL=https://your-api.onrender.com
/// (Public by nature: anything in a web app is visible to users, so never put secrets here.)
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:9001');

/// Composition root: the one place that decides which implementations the app uses.
void main() {
  late final ApiAuthService auth; // the client needs the token, the auth service needs the client
  final api = ApiClient(
    baseUrl: apiBaseUrl,
    authToken: () => auth.session?.token,
    onUnauthorized: () => auth.signOut(expired: true),
  );
  auth = ApiAuthService(api, BrowserSessionStore());
  runApp(VmsApp(auth: auth, vehicles: ApiVehicleRepository(api)));
}
