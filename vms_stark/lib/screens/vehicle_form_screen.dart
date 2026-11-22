import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../data/companies.dart';
import '../data/vehicle_repository.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../widgets/app_shell.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/error_banner.dart';
import '../widgets/form_section.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/vehicle_badges.dart';

/// One screen for both Register (vehicle == null) and Edit (vehicle given).
class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, required this.vehicles, this.vehicle});

  final VehicleRepository vehicles;
  final Vehicle? vehicle;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  static const _maxNameLength = 40;

  final _formKey = GlobalKey<FormState>();
  late final _number = TextEditingController(text: widget.vehicle?.vehicleNumber);
  late final _brand = TextEditingController(text: widget.vehicle?.brand);
  late final _model = TextEditingController(text: widget.vehicle?.model);
  late String? _company = widget.vehicle?.company;
  late VehicleType? _type = widget.vehicle?.type;
  late VehicleStatus _status = widget.vehicle?.status ?? VehicleStatus.available;

  /// Errors stay hidden until the first save attempt, then update as the user types.
  bool _submitted = false;
  bool _dirty = false;
  bool _saving = false;

  /// Messages from the store (backend) per API field name, e.g. {'vehicleNumber': '... already registered'}.
  /// Shown under the matching field; a field's message is cleared as soon as the user edits it.
  final Map<String, String> _serverErrors = {};

  void _clearServerError(String field) {
    if (_serverErrors.containsKey(field)) setState(() => _serverErrors.remove(field));
  }

  bool get _isEdit => widget.vehicle != null;

  @override
  void dispose() {
    _number.dispose();
    _brand.dispose();
    _model.dispose();
    super.dispose();
  }

  // ---------- Validation ----------

  /// "dhaka  metro-ga 11" -> "DHAKA METRO-GA 11"
  static String _normalizeNumber(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

  String? _validateNumber(String? v) {
    final number = _normalizeNumber(v ?? '');
    if (number.isEmpty) return 'Enter the vehicle number';
    if (!RegExp(r'^[A-Z0-9 -]+$').hasMatch(number)) {
      return 'Use only letters, numbers, spaces and hyphens';
    }
    if (number.length < 4) return 'Vehicle number is too short (minimum 4 characters)';
    if (number.length > 30) return 'Vehicle number is too long (maximum 30 characters)';
    // Uniqueness and anything else the backend checks are reported after saving.
    return _serverErrors['vehicleNumber'];
  }

  static FormFieldValidator<String> _requiredName(String field) => (v) {
        final value = v?.trim() ?? '';
        if (value.isEmpty) return 'Enter the ${field.toLowerCase()}';
        if (value.length > _maxNameLength) {
          return '$field must be $_maxNameLength characters or fewer';
        }
        return null;
      };

  // ---------- Actions ----------

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      return;
    }
    final vehicle = Vehicle(
      id: widget.vehicle?.id,
      vehicleNumber: _normalizeNumber(_number.text),
      company: _company!,
      type: _type!,
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      status: _status,
    );
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await (_isEdit ? widget.vehicles.update(vehicle) : widget.vehicles.create(vehicle));
    } on DuplicateVehicleNumberException catch (e) {
      _showServerErrors({'vehicleNumber': e.message});
      return;
    } on VehicleValidationException catch (e) {
      _showServerErrors(e.fieldErrors);
      // A field this form has no input for (should not happen) still gets reported.
      final unshown = e.fieldErrors.keys.where((k) => !_formFields.contains(k));
      if (unshown.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(e.fieldErrors[unshown.first]!)));
      }
      return;
    } catch (e) {
      setState(() => _saving = false);
      // Nothing typed is lost: the form stays open with all values.
      messenger.showSnackBar(
          SnackBar(content: Text('Could not save the vehicle. ${userMessage(e)}')));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text('${vehicle.vehicleNumber} ${_isEdit ? 'updated' : 'registered'}'),
    ));
    if (mounted) _backToList();
  }

  static const _formFields = {'vehicleNumber', 'company', 'type', 'brand', 'model'};

  /// Puts the backend's messages under the matching fields and keeps the form open.
  void _showServerErrors(Map<String, String> errors) {
    setState(() {
      _saving = false;
      _submitted = true;
      _serverErrors
        ..clear()
        ..addAll(errors);
    });
    _formKey.currentState!.validate();
  }

  /// Asks before throwing away typed changes.
  Future<void> _cancel() async {
    if (!_dirty) return _backToList();
    final discard = await confirmDestructive(
      context,
      title: 'Discard changes?',
      message: 'The details you entered will not be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
    if (discard && mounted) _backToList();
  }

  void _backToList() => Navigator.pushReplacementNamed(context, AppRoutes.vehicles);

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: _isEdit ? null : 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to vehicles'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PageHeader(
              title: _isEdit ? 'Edit Vehicle' : 'Register Vehicle',
              subtitle: _isEdit
                  ? 'Update the details for ${widget.vehicle!.vehicleNumber}'
                  : 'Add a new vehicle to the Stark Group fleet registry. All fields are required.',
            ),
            Card(
              child: Form(
                key: _formKey,
                autovalidateMode: _submitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
                onChanged: () => _dirty = true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Shown after a failed save, re-checked live as fields are fixed.
                    // The key stops Flutter from reusing the first section's slot for the banner,
                    // which would rebuild that section and wipe its fields' error messages.
                    if (_submitted)
                      const Padding(
                        key: ValueKey('form-error-banner'),
                        padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
                        child: ErrorBanner(
                            message: 'Some details need attention. Check the highlighted fields below.'),
                      ),
                    _section(
                      title: 'Identification',
                      description: 'How the vehicle is identified and who owns it.',
                      child: ResponsiveGrid(minItemWidth: 260, children: [
                        _numberField(),
                        _companyField(),
                      ]),
                    ),
                    const Divider(),
                    _section(
                      title: 'Vehicle details',
                      description: 'What kind of vehicle this is.',
                      child: ResponsiveGrid(minItemWidth: 260, children: [
                        _typeField(),
                        _brandField(),
                        _modelField(),
                      ]),
                    ),
                    const Divider(),
                    _section(
                      title: 'Status',
                      description: 'Current availability. You can change this any time.',
                      child: _statusPicker(),
                    ),
                    const Divider(),
                    _actions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required String description, required Widget child}) =>
      Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FormSection(title: title, description: description, child: child),
      );

  Widget _numberField() => TextFormField(
        controller: _number,
        onChanged: (_) => _clearServerError('vehicleNumber'),
        decoration: const InputDecoration(
          labelText: 'Vehicle number',
          hintText: 'e.g. DHAKA METRO-GA-11-2345',
          helperText: 'As shown on the registration plate',
        ),
        textCapitalization: TextCapitalization.characters,
        textInputAction: TextInputAction.next,
        validator: _validateNumber,
      );

  Widget _companyField() => DropdownButtonFormField<String>(
        initialValue: _company,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Company',
          helperText: 'Group company that owns the vehicle',
        ),
        items: [
          // Include the saved value even if it's not in the list, or the dropdown would crash.
          for (final c in {...companies, ?_company})
            DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)),
        ],
        validator: (v) =>
            v == null ? 'Choose the company that owns this vehicle' : _serverErrors['company'],
        onChanged: (v) {
          _clearServerError('company');
          setState(() => _company = v);
        },
      );

  Widget _typeField() => DropdownButtonFormField<VehicleType>(
        initialValue: _type,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Vehicle type'),
        items: [
          for (final t in VehicleType.values)
            DropdownMenuItem(value: t, child: VehicleTypeLabel(type: t)),
        ],
        validator: (v) => v == null ? 'Choose a vehicle type' : _serverErrors['type'],
        onChanged: (v) {
          _clearServerError('type');
          setState(() => _type = v);
        },
      );

  Widget _brandField() => TextFormField(
        controller: _brand,
        decoration: const InputDecoration(labelText: 'Brand', hintText: 'e.g. Toyota'),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        onChanged: (_) => _clearServerError('brand'),
        validator: (v) => _requiredName('Brand')(v) ?? _serverErrors['brand'],
      );

  Widget _modelField() => TextFormField(
        controller: _model,
        decoration: const InputDecoration(labelText: 'Model', hintText: 'e.g. HiAce'),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _save(),
        onChanged: (_) => _clearServerError('model'),
        validator: (v) => _requiredName('Model')(v) ?? _serverErrors['model'],
      );

  /// One-click choice; every status is visible, unlike a dropdown.
  Widget _statusPicker() => Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final s in VehicleStatus.values)
            ChoiceChip(
              avatar: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: StatusBadge.colorsFor(s).$3,
                  shape: BoxShape.circle,
                ),
              ),
              label: Text(s.label),
              selected: _status == s,
              showCheckmark: false,
              onSelected: (_) => setState(() {
                _status = s;
                _dirty = true;
              }),
            ),
        ],
      );

  /// Secondary (Cancel) left of primary (Save), right-aligned; wraps on narrow widths.
  Widget _actions() => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(onPressed: _cancel, child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: _saving ? null : _save, // disabled while saving: no double submit
              icon: Icon(_isEdit ? Icons.check : Icons.add),
              label: Text(_saving
                  ? 'Saving…'
                  : _isEdit
                      ? 'Save changes'
                      : 'Register vehicle'),
            ),
          ],
        ),
      );
}
