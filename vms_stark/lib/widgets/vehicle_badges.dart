import 'package:material_ui/material_ui.dart';

import '../models/vehicle.dart';
import '../theme/app_theme.dart';

/// Pill showing a vehicle's status. Always shows text, so color is never the only cue.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final VehicleStatus status;

  /// (background, text, dot) colors per status.
  static (Color, Color, Color) colorsFor(VehicleStatus status) => switch (status) {
        VehicleStatus.available =>
          (const Color(0xFFECFDF3), const Color(0xFF027A48), const Color(0xFF12B76A)),
        VehicleStatus.inUse =>
          (const Color(0xFFEFF8FF), const Color(0xFF175CD3), const Color(0xFF2E90FA)),
        VehicleStatus.maintenance =>
          (const Color(0xFFFFFAEB), const Color(0xFFB54708), const Color(0xFFF79009)),
        VehicleStatus.inactive =>
          (const Color(0xFFF2F4F7), const Color(0xFF475467), const Color(0xFF667085)),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dot) = colorsFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(status.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }
}

/// Icon + name for a vehicle type.
class VehicleTypeLabel extends StatelessWidget {
  const VehicleTypeLabel({super.key, required this.type});

  final VehicleType type;

  static IconData iconFor(VehicleType type) => switch (type) {
        VehicleType.car || VehicleType.suv => Icons.directions_car_outlined,
        VehicleType.van || VehicleType.microbus => Icons.airport_shuttle_outlined,
        VehicleType.bus => Icons.directions_bus_outlined,
        VehicleType.truck || VehicleType.pickup => Icons.local_shipping_outlined,
        VehicleType.motorcycle => Icons.two_wheeler_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: Icon(iconFor(type), size: 18)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(type.label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
