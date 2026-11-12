import 'package:flutter/material.dart';

abstract final class BetSafeColors {
  static const ink = Color(0xFF302016);
  static const yellow = Color(0xFFF7C948);
  static const paper = Color(0xFFEFEDE8);
  static const soft = Color(0xFFF3F0EA);
  static const green = Color(0xFF245B43);
  static const mint = Color(0xFFDCEACD);
  static const loss = Color(0xFFF0DFD5);
  static const lossInk = Color(0xFF743A33);
  static const muted = Color(0xFF555049);
}

ThemeData betSafeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BetSafeColors.yellow,
    primary: BetSafeColors.ink,
    onPrimary: Colors.white,
    secondary: BetSafeColors.yellow,
    onSecondary: BetSafeColors.ink,
    surface: BetSafeColors.paper,
    onSurface: BetSafeColors.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: BetSafeColors.ink,
      ),
      centerTitle: false,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 32),
    navigationRailTheme: const NavigationRailThemeData(
      indicatorColor: BetSafeColors.yellow,
      selectedIconTheme: IconThemeData(color: BetSafeColors.ink),
    ),
  );
}
