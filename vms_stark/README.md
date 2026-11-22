# Stark Group VMS – Frontend (Flutter Web)

Admin UI for the Vehicle Management System. All data comes from the Spring Boot API in `../vms-backend`
(contract: `../vms-backend/API.md`). This project contains no backend code.

## Run locally
1. Start the backend (MySQL running): in `../vms-backend` run `./mvnw spring-boot:run`
2. Start the app: `flutter run -d chrome`
3. Sign in with the admin account from `../vms-backend/.env` (`ADMIN_EMAIL` / `ADMIN_PASSWORD`).

The session (access token, email, expiry — never the password) is kept in the browser tab's
`sessionStorage`: it survives a refresh and is removed when the tab closes or you log out.
If the server rejects the token (e.g. after 8 hours), the app returns to the login screen.

The app calls `http://localhost:9001` by default. Use another backend with:
```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9001
flutter build web --dart-define=API_BASE_URL=https://your-api.onrender.com
```
The URL is public (it ships inside the web app) — never put secrets in a `--dart-define`.
The backend must allow the app's origin in `CORS_ALLOWED_ORIGINS` (any `localhost` port is allowed by default).

## Structure (`lib/`)
| Folder | Responsibility |
|---|---|
| `main.dart` | Composition root: builds `ApiClient`, `ApiAuthService` and `ApiVehicleRepository` and injects them. |
| `auth/` | `AuthService` (abstraction), `ApiAuthService` (login API), `Session`, `SessionStore` (browser `sessionStorage` / memory). |
| `data/` | `VehicleRepository` (abstraction the screens use), `ApiVehicleRepository` (JSON mapping), `ApiClient` (the only HTTP code), `DataException` (user-safe errors). |
| `models/` | `Vehicle`, `VehicleType`, `VehicleStatus`. |
| `screens/` | Login, vehicle list, register/edit form. No HTTP code. |
| `widgets/`, `theme/` | Reusable UI pieces and the Stark Group theme. |

## Tests
```bash
flutter test                      # widget tests (in-memory fake repo) + API contract tests (fake HTTP)
# Optional, against a running backend (credentials from ../vms-backend/.env, never hard-coded):
VMS_LIVE_API=http://localhost:9001 VMS_LIVE_EMAIL=... VMS_LIVE_PASSWORD=... flutter test test/live/backend_live_test.dart
# Full UI journey through the real screens, one phase at a time (register → update → delete):
VMS_LIVE_API=... VMS_LIVE_EMAIL=... VMS_LIVE_PASSWORD=... VMS_LIVE_PHASE=register flutter test test/live/ui_journey_live_test.dart
```
