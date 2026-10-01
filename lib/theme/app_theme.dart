import 'package:flutter/material.dart';

import 'washi.dart';

ThemeData buildAppTheme() {
  const square = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  );
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: Washi.shu,
        dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      ).copyWith(
        primary: Washi.shu,
        onPrimary: Colors.white,
        surface: Washi.paper,
        onSurface: Washi.ink,
        onSurfaceVariant: Washi.inkSoft,
        outline: Washi.inkSoft,
        outlineVariant: Washi.line,
        surfaceContainerLowest: Washi.page,
        surfaceContainerLow: Washi.page,
        surfaceContainer: Washi.page,
        surfaceContainerHigh: Washi.page,
        surfaceContainerHighest: Washi.desk,
        secondaryContainer: Washi.page,
        onSecondaryContainer: Washi.ink,
      );
  return ThemeData(
    colorScheme: colorScheme,
    fontFamily: Washi.mincho,
    scaffoldBackgroundColor: Washi.paper,
    appBarTheme: const AppBarTheme(
      backgroundColor: Washi.paper,
      foregroundColor: Washi.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: Washi.brush,
        fontSize: 24,
        color: Washi.ink,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Washi.page,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Washi.line),
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: square),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: square,
        foregroundColor: Washi.ink,
        side: const BorderSide(color: Washi.ink),
      ),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: Washi.page,
      side: BorderSide(color: Washi.line),
      shape: square,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Washi.shu,
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Washi.paper,
      indicatorColor: Washi.shu.withValues(alpha: 0.12),
      indicatorShape: square,
    ),
    dividerTheme: const DividerThemeData(color: Washi.line),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Washi.ink,
      contentTextStyle: TextStyle(fontFamily: Washi.mincho, color: Washi.paper),
    ),
  );
}
