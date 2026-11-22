import 'package:vms_stark/data/vehicle_repository.dart';
import 'package:vms_stark/models/vehicle.dart';

/// In-memory [VehicleRepository] for widget tests (test code only: the app uses the API).
/// Behaves like the backend: assigns ids, rejects duplicate numbers.
/// Each instance has its own data, so tests never affect each other.
class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository({List<Vehicle>? seed}) : _vehicles = [...(seed ?? sampleVehicles)] {
    _nextId = _vehicles.fold(0, (max, v) => v.id! > max ? v.id! : max) + 1;
  }

  final List<Vehicle> _vehicles;
  late int _nextId;

  @override
  Future<List<Vehicle>> getAll() async => List.unmodifiable(_vehicles);

  @override
  Future<Vehicle> create(Vehicle vehicle) async {
    _rejectDuplicate(vehicle);
    final saved = vehicle.copyWith(id: _nextId++);
    _vehicles.add(saved);
    return saved;
  }

  @override
  Future<Vehicle> update(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index == -1) throw StateError('Vehicle ${vehicle.id} not found');
    _rejectDuplicate(vehicle);
    return _vehicles[index] = vehicle;
  }

  @override
  Future<void> delete(int id) async => _vehicles.removeWhere((v) => v.id == id);

  void _rejectDuplicate(Vehicle vehicle) {
    if (_vehicles.any((v) => v.id != vehicle.id && v.vehicleNumber == vehicle.vehicleNumber)) {
      throw DuplicateVehicleNumberException(vehicle.vehicleNumber);
    }
  }
}

/// Test data.
final sampleVehicles = [
  _v(1, 'DHAKA METRO-GA-11-2345', 'Stark Logistics', VehicleType.truck, 'Tata', 'LPT 1613', VehicleStatus.available),
  _v(2, 'DHAKA METRO-KHA-12-8890', 'Stark Motors', VehicleType.car, 'Toyota', 'Premio', VehicleStatus.inUse),
  _v(3, 'CHATTA METRO-GA-14-1022', 'Stark Construction', VehicleType.pickup, 'Mitsubishi', 'L200', VehicleStatus.maintenance),
  _v(4, 'DHAKA METRO-CHA-15-4471', 'Stark Energy', VehicleType.microbus, 'Toyota', 'HiAce', VehicleStatus.available),
  _v(5, 'DHAKA METRO-BA-11-0921', 'Stark Logistics', VehicleType.bus, 'Ashok Leyland', 'Viking', VehicleStatus.inUse),
  _v(6, 'DHAKA METRO-GHA-13-3310', 'Stark Motors', VehicleType.suv, 'Mitsubishi', 'Pajero Sport', VehicleStatus.available),
  _v(7, 'SYLHET-HA-12-5508', 'Stark Energy', VehicleType.motorcycle, 'Honda', 'CB Hornet', VehicleStatus.inactive),
  _v(8, 'DHAKA METRO-THA-16-7765', 'Stark Construction', VehicleType.truck, 'Hino', '500 Series', VehicleStatus.inUse),
  _v(9, 'CHATTA METRO-CHA-11-2219', 'Stark Logistics', VehicleType.van, 'Nissan', 'Urvan', VehicleStatus.maintenance),
  _v(10, 'DHAKA METRO-GA-17-6604', 'Stark Motors', VehicleType.car, 'Honda', 'Civic', VehicleStatus.available),
];

Vehicle _v(int id, String number, String company, VehicleType type, String brand,
        String model, VehicleStatus status) =>
    Vehicle(id: id, vehicleNumber: number, company: company, type: type,
        brand: brand, model: model, status: status);
