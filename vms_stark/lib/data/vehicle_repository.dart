import '../models/vehicle.dart';
import 'data_exception.dart';

export 'data_exception.dart';

/// Everything the screens need from vehicle storage — screens depend on this
/// abstraction, never on a concrete class (Dependency Inversion).
///
/// Production: [ApiVehicleRepository] (Spring Boot API). Tests: an in-memory fake.
/// Swapping implementations changes no screen (Open/Closed).
/// Failures are thrown as [DataException], whose message is safe to show users.
abstract interface class VehicleRepository {
  /// All vehicles, oldest first.
  Future<List<Vehicle>> getAll();

  /// Saves a new vehicle (its id is ignored) and returns it with the id the store assigned.
  /// Throws [DuplicateVehicleNumberException] if the number is taken,
  /// [VehicleValidationException] if the store rejects a field.
  Future<Vehicle> create(Vehicle vehicle);

  /// Replaces all details of an existing vehicle.
  /// Throws [DuplicateVehicleNumberException] if another vehicle has the number,
  /// [VehicleValidationException] if the store rejects a field.
  Future<Vehicle> update(Vehicle vehicle);

  Future<void> delete(int id);
}

/// The store rejected some fields (the backend answers HTTP 400 with per-field messages).
/// Keys are the API field names: vehicleNumber, company, type, brand, model, status.
class VehicleValidationException extends DataException {
  const VehicleValidationException(super.message, this.fieldErrors);

  final Map<String, String> fieldErrors;
}

/// The vehicle number is already registered (the backend answers HTTP 409).
class DuplicateVehicleNumberException extends DataException {
  DuplicateVehicleNumberException(this.vehicleNumber)
      : super('$vehicleNumber is already registered');

  final String vehicleNumber;
}
