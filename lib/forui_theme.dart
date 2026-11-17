import 'package:flutter/services.dart';
import 'package:forui/forui.dart';

import 'theme.dart';

/// Forui's dark touch theme in BetSafe's glass colors: BetSafe yellow for
/// primary actions and chosen options, project05 purple for the rest, and
/// see-through cards that sit on the glass.
///
/// Forui's outline and ghost buttons take their text color from secondary, so
/// secondary must carry light text on this dark theme.
final FThemeData betSafeForuiTheme = () {
  final colors = FColors(
    brightness: Brightness.dark,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    barrier: const Color(0x99120A24),
    background: BetSafeColors.night,
    foreground: BetSafeColors.ink,
    primary: BetSafeColors.yellow,
    primaryForeground: BetSafeColors.onAccent,
    secondary: BetSafeColors.purpleStrong,
    secondaryForeground: BetSafeColors.ink,
    muted: const Color(0xFF2E2050),
    mutedForeground: BetSafeColors.muted,
    destructive: const Color(0xFFC4323A),
    destructiveForeground: BetSafeColors.ink,
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
