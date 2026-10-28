import 'package:flutter/material.dart';

abstract final class BetSafeColors {
  static const brown = Color(0xFF57321F);
  static const darkBrown = Color(0xFF302016);
  static const cream = Color(0xFFF7F2E9);
  static const ink = Color(0xFF302419);
  static const green = Color(0xFF245B43);
  static const mint = Color(0xFFDCEACD);
  static const clay = Color(0xFFF0DCC9);
  static const muted = Color(0xFF6B6055);
}

ThemeData betSafeTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BetSafeColors.brown,
    brightness: brightness,
    primary: dark ? BetSafeColors.mint : BetSafeColors.green,
    onPrimary: dark ? BetSafeColors.ink : Colors.white,
    secondary: dark ? const Color(0xFFE3B996) : BetSafeColors.brown,
    surface: dark ? const Color(0xFF241B16) : BetSafeColors.cream,
    onSurface: dark ? BetSafeColors.cream : BetSafeColors.ink,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
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
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: BetSafeColors.darkBrown,
      indicatorColor: BetSafeColors.mint,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          color: BetSafeColors.cream,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? BetSafeColors.green
              : BetSafeColors.cream,
        ),
      ),
    ),
  );
}
