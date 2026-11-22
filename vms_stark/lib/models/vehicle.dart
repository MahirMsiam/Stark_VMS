/// Values match the vms-backend enums (CAR, IN_USE, ...) so JSON mapping is direct.
enum VehicleType {
  car('Car'),
  suv('SUV'),
  van('Van'),
  microbus('Microbus'),
  bus('Bus'),
  truck('Truck'),
  pickup('Pickup'),
  motorcycle('Motorcycle');

  const VehicleType(this.label);
  final String label;
}

enum VehicleStatus {
  available('Available'),
  inUse('In Use'),
  maintenance('Maintenance'),
  inactive('Inactive');

  const VehicleStatus(this.label);
  final String label;
}

class Vehicle {
  const Vehicle({
    this.id,
    required this.vehicleNumber,
    required this.company,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
  });

  /// Assigned by the repository when saved; null for a vehicle not saved yet.
  final int? id;
  final String vehicleNumber;
  final String company;
  final VehicleType type;
  final String brand;
  final String model;
  final VehicleStatus status;

  /// Factory for the saved copy (same details, new id) — the model stays immutable.
  Vehicle copyWith({int? id}) => Vehicle(
        id: id ?? this.id,
        vehicleNumber: vehicleNumber,
        company: company,
        type: type,
        brand: brand,
        model: model,
        status: status,
      );
}
