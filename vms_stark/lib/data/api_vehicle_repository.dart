import '../models/vehicle.dart';
import 'api_client.dart';
import 'vehicle_repository.dart';

/// [VehicleRepository] backed by the Spring Boot API (contract: vms-backend/API.md).
/// Translates between JSON and [Vehicle]; all HTTP details stay inside [ApiClient].
class ApiVehicleRepository implements VehicleRepository {
  ApiVehicleRepository(this._api);

  final ApiClient _api;
  static const _path = '/api/vehicles';

  @override
  Future<List<Vehicle>> getAll() async {
    final json = await _api.get(_path) as List<dynamic>;
    return json.map((item) => _fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<Vehicle> create(Vehicle vehicle) => _mapSaveErrors(vehicle,
      () async => _fromJson(await _api.post(_path, _toJson(vehicle)) as Map<String, dynamic>));

  @override
  Future<Vehicle> update(Vehicle vehicle) => _mapSaveErrors(vehicle,
      () async => _fromJson(await _api.put('$_path/${vehicle.id}', _toJson(vehicle)) as Map<String, dynamic>));

  @override
  Future<void> delete(int id) => _api.delete('$_path/$id');

  /// Turns the backend's save errors into domain errors the form understands:
  /// 409 = duplicate Vehicle Number rule, 400 + "errors" = per-field validation messages.
  static Future<Vehicle> _mapSaveErrors(Vehicle vehicle, Future<Vehicle> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw DuplicateVehicleNumberException(vehicle.vehicleNumber);
      if (e.statusCode == 400 && e.fieldErrors.isNotEmpty) {
        throw VehicleValidationException(e.message, e.fieldErrors);
      }
      rethrow;
    }
  }

  // ---- JSON mapping (field names exactly as in API.md) ----

  static Map<String, Object?> _toJson(Vehicle v) => {
        'vehicleNumber': v.vehicleNumber,
        'company': v.company,
        'type': _apiName(v.type),
        'brand': v.brand,
        'model': v.model,
        'status': _apiName(v.status),
      };

  static Vehicle _fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as int,
        vehicleNumber: json['vehicleNumber'] as String,
        company: json['company'] as String,
        type: _parse(VehicleType.values, json['type']),
        brand: json['brand'] as String,
        model: json['model'] as String,
        status: _parse(VehicleStatus.values, json['status']),
      );

  /// Dart `inUse` <-> API `IN_USE`.
  static String _apiName(Enum value) =>
      value.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static T _parse<T extends Enum>(List<T> values, Object? json) => values.firstWhere(
        (v) => _apiName(v) == json,
        orElse: () => throw FormatException('Unknown value from API: $json'),
      );
}
