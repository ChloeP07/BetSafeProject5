import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

/// Forui's light touch theme in BetSafe's glass colors: BetSafe yellow for
/// primary actions and chosen options, warm brown for the rest, and
/// see-through cards that sit on the glass.
///
/// Forui's outline and ghost buttons take their text color from secondary, so
/// the secondary brown must stay readable on cream.
final FThemeData betSafeForuiTheme = () {
  final colors = FColors(
    brightness: Brightness.light,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    barrier: const Color(0x9921150F),
    background: BetSafeColors.night,
    foreground: BetSafeColors.ink,
    primary: BetSafeColors.yellow,
    primaryForeground: BetSafeColors.onAccent,
    secondary: const Color(0xFFE9D8C6),
    secondaryForeground: BetSafeColors.ink,
    muted: const Color(0xFFF3E9DC),
    mutedForeground: BetSafeColors.muted,
    destructive: const Color(0xFFC4323A),
    destructiveForeground: Colors.white,
    error: BetSafeColors.lossInk,
    errorForeground: BetSafeColors.onAccent,
    card: const Color(0x14FFFFFF),
    border: BetSafeColors.line,
  );
  final typeface = FTypeface.inherit(
    colors: colors,
    touch: true,
    fontFamily: 'Inter',
  );
  return FThemeData(
    touch: true,
    debugLabel: 'BetSafe glass',
    colors: colors,
    typography: FTypography(display: typeface, body: typeface),
  );
}();
