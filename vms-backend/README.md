# Stark Group VMS – Backend

Spring Boot REST API for the Vehicle Management System. It owns the business rules and database access.
The Flutter frontend (`../vms_stark`) is a separate project and contains no backend code.

## Requirements
- JDK 21 or newer (`JAVA_HOME` must point to it)
- MySQL 8 on `localhost:3306` (not needed for tests or the `h2` profile)

Maven does not need to be installed: use the wrapper (`mvnw` / `mvnw.cmd`).

## Database setup (once per machine)
Run as MySQL root, choosing your own password:
```sql
CREATE DATABASE stark_vms CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'vms_app'@'localhost' IDENTIFIED BY '<your password>';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX, DROP, REFERENCES
  ON stark_vms.* TO 'vms_app'@'localhost';
```
Then copy `.env.example` to `.env` and fill in:
- `DB_PASSWORD` — the password above;
- `JWT_SECRET` — 32+ random characters (`python -c "import secrets; print(secrets.token_urlsafe(48))"`);
- `ADMIN_EMAIL` / `ADMIN_PASSWORD` — the first login account (12+ characters), created on startup.
`.env` is git-ignored — **never commit it**. Real environment variables
(`DB_URL`, `DB_USERNAME`, `DB_PASSWORD`) override the file.

The schema is explicit: Hibernate runs with `ddl-auto=validate`, so it never creates or
changes tables. Tables are created by Flyway migrations in
`src/main/resources/db/migration` (`V1__create_vehicles.sql`, ...), applied automatically on startup.
Never edit a migration that has already run: add a new `V2__...sql` instead.

## Run
```bash
./mvnw spring-boot:run                                   # MySQL, using .env
./mvnw spring-boot:run -Dspring-boot.run.profiles=h2    # in-memory H2, no MySQL needed
```
Run from the `vms-backend` folder so `.env` is found. The API listens on http://localhost:9001.

## API
Endpoints, request/response bodies and error cases: see [API.md](API.md).

## Health check
`GET http://localhost:9001/actuator/health` → `{"status":"UP","components":{"db":{"status":"UP"},...}}`.
`db: DOWN` means MySQL is unreachable or the credentials are wrong.

| Startup error | Cause | Fix |
|---|---|---|
| `Access denied for user '${DB_USERNAME}'` | No `.env` found and no environment variables set | Create `.env` from `.env.example`, run from `vms-backend/` |
| `Access denied for user 'vms_app'@'localhost'` | Wrong password in `.env` | Fix `DB_PASSWORD` |
| `Communications link failure` | MySQL is not running | Start the `MySQL84` service |
| `Unknown database 'stark_vms'` | Database not created | Run the setup SQL above |

## Build and test
```bash
./mvnw verify
```
Tests use the in-memory H2 database.

## Structure (`src/main/java/com/starkgroup/vms`)
| Package | Responsibility |
|---|---|
| `controller` | REST endpoints: HTTP in, DTOs out. No business rules. |
| `service` | Business rules and transactions. |
| `repository` | Spring Data JPA database access. |
| `entity` | JPA entities (database tables). Never returned directly by the API. |
| `dto` | Request/response objects with validation annotations. |
| `exception` | `GlobalExceptionHandler`: every error is returned as JSON ProblemDetail (`status`, `title`, `detail`, plus `errors` per field for validation failures). |

Request flow: `controller → service → repository → database`.
