# Stark VMS — Vehicle Management System

A web-based admin application for registering and managing the vehicle fleet of Stark Group.
Signed-in staff can **register, view, search, update and delete vehicles**. The backend owns all
business rules, for example that a **Vehicle Number can only be registered once**.

The repository contains two independent applications:

| Folder | Application | Technology |
|---|---|---|
| [`vms-backend/`](vms-backend) | REST API, business rules, database access | Java 21, Spring Boot 4.2, MySQL 8 |
| [`vms_stark/`](vms_stark) | Admin web interface | Flutter Web (Dart 3.14), Material 3 |

```
Browser (Flutter Web) ──HTTPS/JSON + Bearer token──▶ Spring Boot API ──JPA──▶ MySQL
```

## Features
- Sign in with email and password; every vehicle operation requires a valid session.
- Vehicle list with live search, status filters, summary cards, and loading / empty / error states.
- Register and edit vehicles: **Vehicle Number, Company, Type, Brand, Model, Status**.
- Validation on both sides; server errors (e.g. duplicate number) are shown under the matching field.
- Delete with confirmation; the UI changes only after the server confirms.
- Responsive desktop/tablet layout, accessible labels.

## Technologies

**Backend (`vms-backend`)**
- Spring Boot 4.2 (Web MVC, Data JPA / Hibernate, Bean Validation, Actuator)
- Spring Security with OAuth2 Resource Server — stateless **JWT** bearer tokens (HS256), BCrypt password hashes
- MySQL 8.4 with **Flyway** migrations (explicit schema, Hibernate only validates)
- Error responses in the standard **ProblemDetail** (RFC 9457) JSON format
- Maven (wrapper included), JUnit 5, Mockito, H2 for tests

**Frontend (`vms_stark`)**
- Flutter Web 3.50 / Dart 3.14, Material 3
- `http` for API calls, `web` for browser `sessionStorage`
- Layered design: screens → repository / auth service abstractions → API client

## Prerequisites
- **JDK 21+** (`JAVA_HOME` set) — Maven is not needed, the wrapper (`mvnw`) downloads it
- **MySQL 8** running on `localhost:3306`
- **Flutter SDK 3.50+** with Chrome

## Setup and run (local)

### 1. Database (once)
Run as MySQL `root`, choosing your own password:
```sql
CREATE DATABASE stark_vms CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'vms_app'@'localhost' IDENTIFIED BY '<db password>';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, REFERENCES
  ON stark_vms.* TO 'vms_app'@'localhost';
```
Tables are created automatically on first start by Flyway (`vms-backend/src/main/resources/db/migration`).

### 2. Backend configuration
```bash
cd vms-backend
cp .env.example .env      # then edit .env — it is git-ignored, never commit it
```

| Variable | Required | Purpose |
|---|---|---|
| `DB_URL` | no | JDBC URL (default `jdbc:mysql://localhost:3306/stark_vms`) |
| `DB_USERNAME` / `DB_PASSWORD` | yes | Database login (`vms_app` and the password above) |
| `JWT_SECRET` | yes | Token signing key, **at least 32 random characters**: `python -c "import secrets; print(secrets.token_urlsafe(48))"` |
| `JWT_TTL` | no | Session length (default `8h`) |
| `ADMIN_EMAIL` / `ADMIN_PASSWORD` | yes (first run) | First login account, created on startup if missing (password 12+ characters) |
| `CORS_ALLOWED_ORIGINS` | no | Web origins allowed to call the API (default: any `localhost` port) |

Real environment variables override `.env`.

### 3. Start the backend
```bash
cd vms-backend
./mvnw spring-boot:run          # Windows: mvnw.cmd spring-boot:run
```
API: `http://localhost:9001` · Health check: `http://localhost:9001/actuator/health` → `{"status":"UP",...}`

### 4. Start the frontend
```bash
cd vms_stark
flutter pub get
flutter run -d chrome           # uses http://localhost:9001 by default
```
Sign in with `ADMIN_EMAIL` / `ADMIN_PASSWORD` from `vms-backend/.env`.

## API overview
Base URL `http://localhost:9001`. JSON everywhere. Full contract with all request/response
bodies and error cases: **[`vms-backend/API.md`](vms-backend/API.md)**.

| Method | Path | Auth | Success | Errors |
|---|---|---|---|---|
| `POST` | `/api/auth/login` | public | `200` `{accessToken, tokenType, expiresAt, email}` | `400`, `401` |
| `GET` | `/api/vehicles` | Bearer | `200` list of vehicles | `401` |
| `GET` | `/api/vehicles/{id}` | Bearer | `200` vehicle | `401`, `404` |
| `POST` | `/api/vehicles` | Bearer | `201` vehicle + `Location` header | `400`, `401`, `409` |
| `PUT` | `/api/vehicles/{id}` | Bearer | `200` vehicle | `400`, `401`, `404`, `409` |
| `DELETE` | `/api/vehicles/{id}` | Bearer | `204` | `401`, `404` |
| `GET` | `/actuator/health` | public | `200` | `503` if the database is down |

Vehicle JSON:
```json
{
  "id": 1,
  "vehicleNumber": "DHAKA METRO-GA-11-2345",
  "company": "Stark Logistics",
  "type": "TRUCK",
  "brand": "Tata",
  "model": "LPT 1613",
  "status": "AVAILABLE"
}
```
- `type`: `CAR`, `SUV`, `VAN`, `MICROBUS`, `BUS`, `TRUCK`, `PICKUP`, `MOTORCYCLE`
- `status`: `AVAILABLE`, `IN_USE`, `MAINTENANCE`, `INACTIVE`
- `vehicleNumber` is unique, 4–30 characters, stored upper case with single spaces.

Errors always use one shape:
```json
{ "status": 409, "title": "Conflict", "detail": "Vehicle number KA-01 is already registered" }
```
Validation failures (`400`) add `"errors": { "<field>": "<message>" }`.

Example with curl:
```bash
TOKEN=$(curl -s -X POST http://localhost:9001/api/auth/login -H "Content-Type: application/json" \
  -d '{"email":"admin@starkgroup.com","password":"<password>"}' | sed -E 's/.*"accessToken":"([^"]+)".*/\1/')
curl -H "Authorization: Bearer $TOKEN" http://localhost:9001/api/vehicles
```

## Deployment
**Backend** (e.g. Render web service, root directory `vms-backend`)
- Build: `./mvnw -DskipTests package` · Start: `java -jar target/vms-backend-0.0.1-SNAPSHOT.jar`
- Set `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` and
  `CORS_ALLOWED_ORIGINS=https://<your-frontend-url>` as environment variables. Port `9001` is the
  default (`server.port`); set `SERVER_PORT` if the host requires a specific port.

**Frontend** (any static host, root directory `vms_stark`)
```bash
flutter build web --release --dart-define=API_BASE_URL=https://<your-backend-url>
```
Publish the `build/web` folder. The API URL is compiled into the app and is public — never put secrets in a `--dart-define`.

## Tests
```bash
cd vms-backend && ./mvnw verify     # unit + integration tests on an in-memory H2 database
cd vms_stark   && flutter test      # widget, API-contract and auth tests (live tests are skipped by default)
```

## Project structure
```
vms-backend/src/main/java/com/starkgroup/vms/
  controller/   REST endpoints (HTTP only)
  service/      business rules (duplicate Vehicle Number, login, tokens)
  repository/   Spring Data JPA
  entity/       JPA entities (Vehicle, AppUser)
  dto/          request/response records with validation
  exception/    global error handling (ProblemDetail)
  config/       security, CORS, first admin account
vms_stark/lib/
  screens/      login, vehicle list, register/edit form
  widgets/      reusable UI (app shell, badges, banners, dialogs)
  data/         VehicleRepository + API implementation, ApiClient (the only HTTP code)
  auth/         AuthService, session handling
  models/ theme/
```
More detail: [`vms-backend/README.md`](vms-backend/README.md) · [`vms_stark/README.md`](vms_stark/README.md)
