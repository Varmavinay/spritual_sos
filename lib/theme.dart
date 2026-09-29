import 'package:flutter/material.dart';

const _seed = Color(0xFF6750A4);

/// Material 3 palette carried over from the original PWA stylesheet.
final _light = ColorScheme.fromSeed(
  seedColor: _seed,
  primary: const Color(0xFF6750A4),
  onPrimary: const Color(0xFFFFFFFF),
  primaryContainer: const Color(0xFFEADDFF),
  onPrimaryContainer: const Color(0xFF21005D),
  secondary: const Color(0xFF625B71),
  secondaryContainer: const Color(0xFFE8DEF8),
  onSecondaryContainer: const Color(0xFF1D192B),
  surface: const Color(0xFFFEF7FF),
  onSurface: const Color(0xFF1D1B20),
  onSurfaceVariant: const Color(0xFF49454F),
  surfaceContainer: const Color(0xFFF3EDF7),
  surfaceContainerHigh: const Color(0xFFECE6F0),
  outline: const Color(0xFF79747E),
  outlineVariant: const Color(0xFFCAC4D0),
);

final _dark = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.dark,
  primary: const Color(0xFFD0BCFF),
  onPrimary: const Color(0xFF381E72),
  primaryContainer: const Color(0xFF4F378B),
  onPrimaryContainer: const Color(0xFFEADDFF),
  secondary: const Color(0xFFCCC2DC),
  secondaryContainer: const Color(0xFF4A4458),
  onSecondaryContainer: const Color(0xFFE8DEF8),
  surface: const Color(0xFF141218),
  onSurface: const Color(0xFFE6E0E9),
  onSurfaceVariant: const Color(0xFFCAC4D0),
  surfaceContainer: const Color(0xFF211F26),
  surfaceContainerHigh: const Color(0xFF2B2930),
  outline: const Color(0xFF938F99),
  outlineVariant: const Color(0xFF49454F),
);

ThemeData _build(ColorScheme scheme) => ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: StadiumBorder(),
      ),
    );

final lightTheme = _build(_light);
final darkTheme = _build(_dark);
