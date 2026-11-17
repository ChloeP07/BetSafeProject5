import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

/// A mix of NFL games: open soon, live, postponed and final, with one pick.
Map<String, dynamic> busyState() => stateJson(
  nfl: nflOk(),
  coins: 120,
  dailyStaked: 400,
  games: [
    nflGameJson(
      id: 'bdl-1',
      kickoff: DateTime.now().add(const Duration(hours: 3)),
    ),
    nflGameJson(
      id: 'bdl-2',
      away: 'Jacksonville Jaguars',
      home: 'San Francisco 49ers',
      status: 'live',
      awayScore: 14,
      homeScore: 10,
    ),
    nflGameJson(
      id: 'bdl-3',
      away: 'Tampa Bay Buccaneers',
      home: 'New England Patriots',
      status: 'postponed',
    ),
    nflGameJson(
      id: 'bdl-4',
      away: 'Los Angeles Chargers',
      home: 'Washington Commanders',
      status: 'final',
      awayScore: 27,
      homeScore: 24,
    ),
    demoGameJson(),
  ],
  picks: [pickJson(gameId: 'bdl-2', team: 'San Francisco 49ers')],
);

/// Pumps the app on a 390×844 phone with text at twice its normal size.
Future<void> pumpLargeText(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final json = busyState();
  final api = BetSafeApi(
    client: MockClient((_) async => http.Response(jsonEncode(json), 200)),
  );
  addTearDown(api.dispose);
  await tester.pumpWidget(BetSafeApp(api: api));
  await tester.pumpAndSettle();
}

/// Scrolls [scrollable] from top to bottom a little at a time, checking for
/// overflow and small tap targets at every stop.
Future<void> checkWholePage(WidgetTester tester, Finder scrollable) async {
  final handle = tester.ensureSemantics();
  for (var step = 0; step < 80; step++) {
    expect(tester.takeException(), isNull, reason: 'overflow at step $step');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    final position = tester.state<ScrollableState>(scrollable).position;
    if (position.pixels >= position.maxScrollExtent) break;
    await tester.drag(scrollable, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.pixels, position.maxScrollExtent);
  handle.dispose();
}

/// Scrolls [target] fully into view, then taps it.
Future<void> tapVisible(
  WidgetTester tester,
  Finder target,
  Finder scrollable,
) async {
  await tester.scrollUntilVisible(target, 300, scrollable: scrollable);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
}

void main() {
  testWidgets('Games fits at 2× text with 48-pixel targets', (tester) async {
    await pumpLargeText(tester);
    final finished = find.textContaining('Show 1 game');
    await tapVisible(tester, finished, find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
    await tester.pumpAndSettle();
    await checkWholePage(tester, find.byType(Scrollable).first);
  });

  testWidgets('Pick fits at 2× text with 48-pixel targets', (tester) async {
    await pumpLargeText(tester);
    await tapVisible(tester, gameCard().first, find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final page = find.byType(Scrollable).last;
    await tapVisible(
      tester,
      find.widgetWithText(TeamOptionCard, 'Buffalo Bills'),
      page,
    );
    await tester.pumpAndSettle();
    await tester.drag(page, const Offset(0, 10000));
    await tester.pumpAndSettle();
    await checkWholePage(tester, page);
  });

  testWidgets('the confirmation sheet fits at 2× text', (tester) async {
    await pumpLargeText(tester);
    await tapVisible(tester, gameCard().first, find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    final page = find.byType(Scrollable).last;
    await tapVisible(
      tester,
      find.widgetWithText(TeamOptionCard, 'Buffalo Bills'),
      page,
    );
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Lock in pick'), page);
    await tester.pumpAndSettle();
    final sheet = find.byType(Scrollable).last;
    await checkWholePage(tester, sheet);
    expect(find.text('Confirm pick'), findsOneWidget);
  });
}
