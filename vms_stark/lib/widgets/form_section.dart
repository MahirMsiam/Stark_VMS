import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// A titled group of form fields.
/// Wide: title/description on the left, fields on the right. Narrow: stacked.
class FormSection extends StatelessWidget {
  const FormSection({
    super.key,
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: text.titleSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(description, style: text.bodySmall?.copyWith(color: AppTheme.slate)),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 720) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [heading, const SizedBox(height: AppSpacing.md), child],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 220, child: heading),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: child),
        ],
      );
    });
  }
}
