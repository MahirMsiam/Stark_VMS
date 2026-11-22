import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// The Stark Group logo square, optionally with the name beside it.
/// Designed for dark (navy) backgrounds: the sidebar and the login panel.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.showName = true});

  final bool showName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final logo = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      // shortcut: letter placeholder, swap for the real logo asset when available.
      child: Text('S',
          style: text.titleLarge?.copyWith(color: AppTheme.navy, fontWeight: FontWeight.w800)),
    );

    return Semantics(
      label: 'Stark Group Vehicle Management',
      excludeSemantics: true,
      child: !showName
          ? logo
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                logo,
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STARK GROUP',
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall?.copyWith(
                              color: Colors.white, letterSpacing: 1.2)),
                      Text('Vehicle Management',
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: AppTheme.sidebarText)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
