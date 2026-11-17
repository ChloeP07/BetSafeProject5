import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'forui_theme.dart';
import 'screens/home_screen.dart';
import 'services/betsafe_api.dart';
import 'theme.dart';

void main() => runApp(const BetSafeApp());

class BetSafeApp extends StatelessWidget {
  const BetSafeApp({super.key, this.api});
  final BetSafeApi? api;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BetSafe',
    debugShowCheckedModeBanner: false,
    // The Material theme still styles the few Material widgets left, such as
    // the pull-to-refresh spinner. Forui widgets take FTheme below.
    theme: betSafeTheme(),
    localizationsDelegates: FLocalizations.localizationsDelegates,
    supportedLocales: FLocalizations.supportedLocales,
    builder: (context, child) => FTheme(
      data: betSafeForuiTheme,
      child: FToaster(child: FTooltipGroup(child: child!)),
    ),
    home: HomeScreen(api: api),
  );
}
