import 'package:flutter/material.dart';

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
    theme: betSafeTheme(),
    home: HomeScreen(api: api),
  );
}
