import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Lays children out in as many equal columns as fit, each at least [minItemWidth] wide.
/// 4 columns on desktop, 2 on tablet, 1 on narrow windows — with no breakpoints to maintain.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.minItemWidth,
    required this.children,
    this.spacing = AppSpacing.md,
  });

  final double minItemWidth;
  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final fit = ((constraints.maxWidth + spacing) / (minItemWidth + spacing)).floor();
      final columns = fit.clamp(1, children.isEmpty ? 1 : children.length);
      // floor avoids a rounding error pushing the last item onto a new row
      final itemWidth =
          ((constraints.maxWidth - spacing * (columns - 1)) / columns).floorToDouble();
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [for (final c in children) SizedBox(width: itemWidth, child: c)],
      );
    });
  }
}
