import 'dart:convert';

import 'package:betsafeproject5/forui_theme.dart';
import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/models/demo_state.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A real-feed game in the shape the server sends.
Map<String, dynamic> nflGameJson({
  String id = 'bdl-1',
  String away = 'Kansas City Chiefs',
  String home = 'Buffalo Bills',
  String status = 'scheduled',
  DateTime? kickoff,
  int? awayScore,
  int? homeScore,
}) => {
  'id': id,
  'source': 'balldontlie',
  'away': away,
  'home': home,
  'status': status,
  'label': 'NFL · $status',
  'kickoff': (kickoff ?? DateTime.now().add(const Duration(days: 2)))
      .toUtc()
      .toIso8601String(),
  'awayScore': awayScore,
  'homeScore': homeScore,
};

/// A simulation game in the shape the server sends.
Map<String, dynamic> demoGameJson({
  String id = 'demo-1',
  String away = 'Kansas City Chiefs',
  String home = 'Buffalo Bills',
  String status = 'scheduled',
  int awayScore = 0,
  int homeScore = 0,
}) => {
  'id': id,
  'away': away,
  'home': home,
  'status': status,
  'label': 'Demo matchup',
  'awayScore': awayScore,
  'homeScore': homeScore,
};

Map<String, dynamic> pickJson({
  String gameId = 'demo-1',
  String team = 'Buffalo Bills',
  int stake = 100,
  String status = 'pending',
  int payout = 0,
}) => {
  'gameId': gameId,
  'team': team,
  'stake': stake,
  'status': status,
  'payout': payout,
};

/// A full `/api/state` snapshot.
Map<String, dynamic> stateJson({
  List<Map<String, dynamic>>? games,
  List<Map<String, dynamic>> picks = const [],
  String name = 'Demo player',
  int coins = 1000,
  int dailyLimit = 500,
  int dailyStaked = 0,
  Map<String, dynamic>? nfl,
}) => {
  'account': {
    'name': name,
    'coins': coins,
    'dailyLimit': dailyLimit,
    'dailyStaked': dailyStaked,
  },
  'games': games ?? [demoGameJson()],
  'picks': picks,
  'collection': <Map<String, dynamic>>[],
  'nfl': ?nfl,
};

/// `nfl` block for a working feed.
Map<String, dynamic> nflOk() => {
  'configured': true,
  'source': 'BALLDONTLIE',
  'fetchedAt': DateTime.now().toUtc().toIso8601String(),
  'stale': false,
  'error': null,
  'refreshSeconds': 60,
};

DemoState demoState(Map<String, dynamic> json) => DemoState.fromJson(json);

Game gameFrom(Map<String, dynamic> json) => Game.fromJson(json);

/// An API client that always answers with [json], counting requests in [onRequest].
BetSafeApi apiWith(
  Map<String, dynamic> json, {
  void Function(http.Request request)? onRequest,
}) => BetSafeApi(
  client: MockClient((request) async {
    onRequest?.call(request);
    return http.Response(jsonEncode(json), 200);
  }),
);

/// Pumps the whole app on a tall phone-width screen, so every card is built.
Future<BetSafeApi> pumpApp(
  WidgetTester tester,
  Map<String, dynamic> json, {
  void Function(http.Request request)? onRequest,
}) async {
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = apiWith(json, onRequest: onRequest);
  addTearDown(api.dispose);
  await tester.pumpWidget(BetSafeApp(api: api));
  await tester.pumpAndSettle();
  return api;
}

/// A game card on the Games list, found by its screen-reader description,
/// which starts "Away at Home.". With no teams given, the first card.
Finder gameCard({String? away, String? home}) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      (widget.properties.label?.startsWith(
            away == null ? '' : '$away at $home.',
          ) ??
          false) &&
      (widget.properties.label?.contains(' at ') ?? false),
);

/// Taps a game card on the Games list, as a player would, to open that game.
Future<void> openGame(WidgetTester tester, {String? away, String? home}) async {
  final card = gameCard(away: away, home: home).first;
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

/// Pumps the whole app and opens the pick screen for its first open game.
Future<BetSafeApi> pumpPick(
  WidgetTester tester,
  Map<String, dynamic> json, {
  void Function(http.Request request)? onRequest,
}) async {
  final api = await pumpApp(tester, json, onRequest: onRequest);
  await openGame(tester);
  return api;
}

/// Taps Lock in pick and confirms on the sheet that follows.
Future<void> lockInPick(WidgetTester tester) async {
  await tester.tap(find.text('Lock in pick'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm pick'));
  await tester.pumpAndSettle();
}

/// Pumps one matchup card on its own.
Future<void> pumpTicket(WidgetTester tester, Map<String, dynamic> json) =>
    tester.pumpWidget(
      ForuiTestApp(
        home: Scaffold(body: MatchTicket(game: gameFrom(json))),
      ),
    );

/// A MaterialApp with the app's themes, Forui's included, for pumping single
/// widgets the way the app shows them.
class ForuiTestApp extends StatelessWidget {
  const ForuiTestApp({super.key, required this.home, this.theme});
  final Widget home;
  final ThemeData? theme;
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: theme ?? betSafeTheme(),
    localizationsDelegates: FLocalizations.localizationsDelegates,
    supportedLocales: FLocalizations.supportedLocales,
    builder: (context, child) => FTheme(
      data: betSafeForuiTheme,
      child: FToaster(child: child!),
    ),
    home: home,
  );
}

/// Taps the Forui header's back button, the way a player leaves a page.
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byType(FHeaderAction).first);
  await tester.pumpAndSettle();
}

/// The text in the Games search box.
String searchText(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).controller.text;

/// The Forui search box's clear button.
Finder clearSearchButton() => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.semanticLabel == 'Clear',
);
