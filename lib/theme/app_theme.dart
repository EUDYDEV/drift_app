import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const orange = Color(0xFFFF6A00);
  static const lightBackground = Color(0xFFF5F5F7);
  static const darkBackground = Color(0xFF141416);
  static const darkSurface = Color(0xFF202024);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.light,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBackground,
      cardColor: Colors.white,
      canvasColor: Colors.white,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? orange
              : const Color(0xFF8A8A8E),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: orange,
      brightness: Brightness.dark,
      surface: darkSurface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      canvasColor: darkSurface,
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: darkSurface),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF29292E),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? orange
              : const Color(0xFFB5B5BA),
        ),
      ),
    );
  }
}
