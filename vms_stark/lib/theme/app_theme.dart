import 'package:material_ui/material_ui.dart';

/// Spacing scale. Use these instead of raw numbers so every screen lines up.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Stark Group colors and component styles, all in one place.
class AppTheme {
  static const navy = Color(0xFF0F172A);
  static const navyLight = Color(0xFF334155);
  static const slate = Color(0xFF64748B);
  static const sidebarText = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const background = Color(0xFFF8FAFC);
  static const surfaceMuted = Color(0xFFF1F5F9); // table header, icon circles

  /// Corner radii: [radius] for controls, [cardRadius] for cards and dialogs.
  static const radius = 8.0;
  static const cardRadius = 12.0;

  static final _radius = BorderRadius.circular(radius);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      primary: navy,
      surface: Colors.white,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: _radius);
    const buttonSize = Size(0, 44);
    final fieldBorder = OutlineInputBorder(
      borderRadius: _radius,
      borderSide: const BorderSide(color: border),
    );

    final base = ThemeData(colorScheme: scheme).textTheme;
    const bold = TextStyle(fontWeight: FontWeight.w700);
    const semiBold = TextStyle(fontWeight: FontWeight.w600);
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: const BorderSide(color: border),
    );

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      // Heading weights live here so screens never set fontWeight themselves.
      textTheme: base.copyWith(
        displaySmall: base.displaySmall?.merge(bold),
        headlineMedium: base.headlineMedium?.merge(bold),
        headlineSmall: base.headlineSmall?.merge(bold),
        titleMedium: base.titleMedium?.merge(semiBold),
        titleSmall: base.titleSmall?.merge(semiBold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
            borderSide: const BorderSide(color: navy, width: 2)),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: cardShape,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(cardRadius)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        width: 420, // a full-width bar looks out of place on desktop
        shape: RoundedRectangleBorder(borderRadius: _radius),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: buttonSize, shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          side: const BorderSide(color: border),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: navy,
        indicatorColor: navyLight,
        selectedIconTheme: IconThemeData(color: Colors.white),
        unselectedIconTheme: IconThemeData(color: sidebarText),
        selectedLabelTextStyle:
            TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: sidebarText),
      ),
      dataTableTheme: const DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(surfaceMuted),
        headingTextStyle: TextStyle(
          color: navyLight,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
      dividerTheme: const DividerThemeData(color: border, space: 1),
    );
  }
}
