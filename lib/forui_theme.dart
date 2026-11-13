import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

/// Forui's touch theme in BetSafe's colors: ink for primary actions, yellow
/// as the accent, warm paper for the page and white for cards.
final FThemeData betSafeForuiTheme = () {
  final colors = FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: const Color(0x55302016),
    background: BetSafeColors.paper,
    foreground: BetSafeColors.ink,
    primary: BetSafeColors.ink,
    primaryForeground: Colors.white,
    secondary: BetSafeColors.yellow,
    secondaryForeground: BetSafeColors.ink,
    muted: BetSafeColors.soft,
    mutedForeground: BetSafeColors.muted,
    destructive: BetSafeColors.lossInk,
    destructiveForeground: Colors.white,
    error: BetSafeColors.lossInk,
    errorForeground: Colors.white,
    card: Colors.white,
    border: const Color(0xFFE2DCD2),
  );
  final typeface = FTypeface.inherit(
    colors: colors,
    touch: true,
    fontFamily: 'Inter',
  );
  return FThemeData(
    touch: true,
    debugLabel: 'BetSafe',
    colors: colors,
    typography: FTypography(display: typeface, body: typeface),
  );
}();
