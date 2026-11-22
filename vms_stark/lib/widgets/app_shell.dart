import 'package:material_ui/material_ui.dart';

import '../app.dart';
import '../auth/auth_service.dart';
import '../theme/app_theme.dart';
import 'brand_mark.dart';

/// The layout every logged-in screen sits inside: dark sidebar, top bar, page area.
/// Each screen wraps its content in `AppShell(selectedIndex: ..., child: ...)`.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.selectedIndex, required this.child});

  /// Which nav item is highlighted. Use null for pages not in the nav (e.g. Edit).
  final int? selectedIndex;
  final Widget child;

  static const _destinations = [
    (icon: Icons.directions_car_outlined, selected: Icons.directions_car, label: 'Vehicles', route: AppRoutes.vehicles),
    (icon: Icons.add_circle_outline, selected: Icons.add_circle, label: 'Register Vehicle', route: AppRoutes.newVehicle),
  ];

  @override
  Widget build(BuildContext context) {
    // Desktop: sidebar with labels. Tablet: icons only (labels stay as tooltips/semantics).
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            extended: isDesktop,
            minExtendedWidth: 240,
            selectedIndex: selectedIndex,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              // Width matches the extended rail minus its padding.
              child: isDesktop
                  ? const SizedBox(width: 208, child: BrandMark())
                  : const BrandMark(showName: false),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Tooltip(message: d.label, child: Icon(d.icon)),
                  selectedIcon: Icon(d.selected),
                  label: Text(d.label),
                ),
            ],
            onDestinationSelected: (i) =>
                Navigator.pushReplacementNamed(context, _destinations[i].route),
          ),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1400),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final auth = AuthScope.of(context);
    final email = auth.session?.email ?? '';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          const Spacer(),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.navy,
            child: Text(email.isEmpty ? '?' : email[0].toUpperCase(),
                style: text.labelLarge?.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(email, style: text.titleSmall),
          const SizedBox(width: AppSpacing.md),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut, // the app then returns to the login screen
          ),
        ],
      ),
    );
  }
}
