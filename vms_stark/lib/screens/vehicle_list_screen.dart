import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../data/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/stat_card.dart';
import '../widgets/vehicle_badges.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key, required this.vehicles});

  final VehicleRepository vehicles;

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  final _searchController = TextEditingController();
  VehicleStatus? _statusFilter; // null = all

  List<Vehicle>? _all; // null until the first load finishes
  String? _loadError; // user-facing message when the last load failed
  final Set<int> _deleting = {}; // rows with a delete request in flight

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final vehicles = await widget.vehicles.getAll();
      if (mounted) setState(() => _all = vehicles);
    } catch (e) {
      if (mounted) setState(() => _loadError = userMessage(e));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasFilters => _searchController.text.isNotEmpty || _statusFilter != null;

  bool _matches(Vehicle v) {
    final q = _searchController.text.trim().toLowerCase();
    final matchesText = [v.vehicleNumber, v.company, v.brand, v.model, v.type.label]
        .any((field) => field.toLowerCase().contains(q));
    return matchesText && (_statusFilter == null || v.status == _statusFilter);
  }

  void _clearFilters() => setState(() {
        _searchController.clear();
        _statusFilter = null;
      });

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final confirmed = await confirmDestructive(
      context,
      title: 'Delete vehicle?',
      message: '${vehicle.vehicleNumber} will be permanently removed.',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deleting.add(vehicle.id!));
    try {
      await widget.vehicles.delete(vehicle.id!);
      messenger.showSnackBar(SnackBar(content: Text('${vehicle.vehicleNumber} deleted')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text('Could not delete ${vehicle.vehicleNumber}. ${userMessage(e)}')));
    }
    // The row disappears only now, from a fresh read of the store (the source of truth).
    await _load();
    if (mounted) setState(() => _deleting.remove(vehicle.id));
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    return AppShell(
      selectedIndex: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Vehicles',
            subtitle: 'Fleet registry and operational status across Stark Group',
            action: _registerButton(),
          ),
          if (all != null)
            ..._buildContent(all)
          else
            Card(child: _loadError != null ? _buildLoadError() : _buildLoading()),
        ],
      ),
    );
  }

  Widget _buildLoading() => const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(
          child: CircularProgressIndicator(semanticsLabel: 'Loading vehicles'),
        ),
      );

  Widget _buildLoadError() => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.cloud_off, size: 32, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Could not load vehicles', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(_loadError ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.slate)),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      );

  List<Widget> _buildContent(List<Vehicle> all) {
    final vehicles = all.where(_matches).toList();
    int count(VehicleStatus s) => all.where((v) => v.status == s).length;

    return [
          ResponsiveGrid(
            minItemWidth: 220,
            children: [
              StatCard(label: 'Total vehicles', value: all.length, icon: Icons.garage_outlined, color: AppTheme.navy),
              for (final s in [VehicleStatus.available, VehicleStatus.inUse, VehicleStatus.maintenance])
                StatCard(
                  label: s.label,
                  value: count(s),
                  icon: switch (s) {
                    VehicleStatus.available => Icons.check_circle_outline,
                    VehicleStatus.inUse => Icons.route_outlined,
                    _ => Icons.build_outlined,
                  },
                  color: StatusBadge.colorsFor(s).$2,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilters(),
                const Divider(),
                if (vehicles.isEmpty)
                  _buildEmptyState(fleetIsEmpty: all.isEmpty)
                else ...[
                  _buildTable(vehicles),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Showing ${vehicles.length} of ${all.length} vehicles',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.slate),
                    ),
                  ),
                ],
              ],
            ),
          ),
    ];
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search vehicles',
                hintText: 'Number, company, brand or model',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ChoiceChip(
            label: const Text('All'),
            selected: _statusFilter == null,
            onSelected: (_) => setState(() => _statusFilter = null),
          ),
          for (final s in VehicleStatus.values)
            ChoiceChip(
              label: Text(s.label),
              selected: _statusFilter == s,
              onSelected: (selected) => setState(() => _statusFilter = selected ? s : null),
            ),
          if (_hasFilters)
            TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close),
              label: const Text('Clear filters'),
            ),
        ],
      ),
    );
  }

  Widget _registerButton() => FilledButton.icon(
        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.newVehicle),
        icon: const Icon(Icons.add),
        label: const Text('Register vehicle'),
      );

  /// Two cases: the fleet is empty, or the filters hide everything.
  Widget _buildEmptyState({required bool fleetIsEmpty}) {
    final text = Theme.of(context).textTheme;
    final filters = [
      if (_searchController.text.trim().isNotEmpty) '"${_searchController.text.trim()}"',
      if (_statusFilter != null) 'status ${_statusFilter!.label}',
    ].join(' with ');

    final (icon, title, message, action) = fleetIsEmpty
        ? (
            Icons.directions_car_outlined,
            'No vehicles registered yet',
            'Register your first vehicle to start the fleet registry.',
            _registerButton(),
          )
        : (
            Icons.search_off,
            'No matching vehicles',
            'Nothing matches $filters. Try a different search or clear the filters.',
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.close),
              label: const Text('Clear filters'),
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: ExcludeSemantics(child: Icon(icon, size: 32, color: AppTheme.navyLight)),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: text.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(message,
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: AppTheme.slate)),
              const SizedBox(height: AppSpacing.lg),
              action,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable(List<Vehicle> vehicles) {
    final error = Theme.of(context).colorScheme.error;
    // Fills the card on desktop; scrolls sideways on narrower tablets.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: DataTable(
            dataRowMinHeight: 56,
            dataRowMaxHeight: 56,
            // The two fields people look for first sit side by side on the left.
            columns: const [
              DataColumn(label: Text('VEHICLE NUMBER')),
              DataColumn(label: Text('STATUS')),
              DataColumn(label: Text('COMPANY')),
              DataColumn(label: Text('TYPE')),
              DataColumn(label: Text('BRAND')),
              DataColumn(label: Text('MODEL')),
              DataColumn(label: Text('ACTIONS')),
            ],
            rows: [
              for (final (i, v) in vehicles.indexed)
                DataRow(
                  // Zebra striping helps the eye follow a row across.
                  color: WidgetStatePropertyAll(
                      i.isOdd ? AppTheme.background : Colors.white),
                  cells: [
                    DataCell(Text(
                      v.vehicleNumber,
                      style: const TextStyle(
                        color: AppTheme.navy,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    )),
                    DataCell(StatusBadge(status: v.status)),
                    DataCell(Text(v.company)),
                    DataCell(VehicleTypeLabel(type: v.type)),
                    DataCell(Text(v.brand)),
                    DataCell(Text(v.model)),
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tooltips name the vehicle so screen readers don't hear "Edit" 10 times.
                        Tooltip(
                          message: 'Edit ${v.vehicleNumber}',
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.editVehicle,
                                arguments: v),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Tooltip(
                          message: 'Delete ${v.vehicleNumber}',
                          child: TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: error),
                            // Disabled while its request runs: no double delete.
                            onPressed: _deleting.contains(v.id) ? null : () => _confirmDelete(v),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(_deleting.contains(v.id) ? 'Deleting…' : 'Delete'),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
