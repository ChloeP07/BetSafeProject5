import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

/// BetSafe on project05's glass style: a warm cream gradient with frosted
/// glass panels, and BetSafe's yellow kept as the accent for picks and stakes.
abstract final class BetSafeColors {
  /// Top of the page gradient.
  static const dusk = Color(0xFFFFF8ED);

  /// Bottom of the page gradient.
  static const night = Color(0xFFEFEDE8);

  /// A solid cream panel, for surfaces that must not show through, such as
  /// the confirmation sheet.
  static const paper = Color(0xFFFFFBF5);

  /// A glass panel over the page, as one opaque color. Contrast checks use it,
  /// since glass itself is see-through.
  static const glass = Color(0xFFE9D8C6);

  /// Main text and icons on glass.
  static const ink = Color(0xFF302016);

  /// Dark text for the yellow accent.
  static const onAccent = Color(0xFF302016);

  static const yellow = Color(0xFFF7C948);
  static const copper = Color(0xFFC9874E);
  static const sand = Color(0xFF694431);

  /// Filled brown buttons.
  static const brownStrong = Color(0xFF694431);

  /// A faint white fill, for neutral pills and placeholders.
  static const soft = Color(0x14694431);

  /// Hairline borders on glass.
  static const line = Color(0x33694431);

  /// Wins and open games: text, and a see-through tint behind it.
  static const green = Color(0xFF245B43);
  static const mint = Color(0x33245B43);

  /// Losses and paused games: text, and a see-through tint behind it.
  static const lossInk = Color(0xFF743A33);
  static const loss = Color(0x33FF8A7A);

  /// Secondary text. Light enough for 4.5:1 on glass.
  static const muted = Color(0xFF665144);
}

ThemeData betSafeTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: BetSafeColors.copper,
    brightness: Brightness.light,
    primary: BetSafeColors.yellow,
    onPrimary: BetSafeColors.onAccent,
    secondary: BetSafeColors.sand,
    onSecondary: Colors.white,
    surface: BetSafeColors.night,
    onSurface: BetSafeColors.ink,
    onSurfaceVariant: BetSafeColors.muted,
    outlineVariant: BetSafeColors.line,
  );
  // Pushed pages slide along a shared axis, from the animations package.
  const transition = SharedAxisPageTransitionsBuilder(
    transitionType: SharedAxisTransitionType.horizontal,
    fillColor: BetSafeColors.night,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: BetSafeColors.night,
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        for (final platform in TargetPlatform.values) platform: transition,
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
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
    dividerTheme: const DividerThemeData(color: BetSafeColors.line, space: 32),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: BetSafeColors.yellow,
      selectedIconTheme: IconThemeData(color: BetSafeColors.onAccent),
      unselectedIconTheme: IconThemeData(color: BetSafeColors.muted),
      selectedLabelTextStyle: TextStyle(
        color: BetSafeColors.ink,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: BetSafeColors.muted),
    ),
  );
}
