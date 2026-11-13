import 'dart:convert';

import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/widgets/pick_confirmation_sheet.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'support/fixtures.dart';

/// Opens the pick screen with the Bills chosen and 250 coins staked.
Future<void> choosePick(
  WidgetTester tester,
  Map<String, dynamic> json,
  List<http.Request> requests,
) async {
  await pumpPick(tester, json, onRequest: requests.add);
  await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
  await tester.tap(find.text('250 coins'));
  await tester.pumpAndSettle();
}

int posts(List<http.Request> requests) =>
    requests.where((request) => request.method == 'POST').length;

void main() {
  testWidgets('shows the team, stake and balance before sending', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await choosePick(tester, stateJson(), requests);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    final sheet = find.byType(PickConfirmationSheet);
    expect(sheet, findsOneWidget);
    Finder inSheet(String text) =>
        find.descendant(of: sheet, matching: find.text(text));
    expect(inSheet('Buffalo Bills'), findsOneWidget);
    expect(inSheet('250 coins'), findsOneWidget);
    expect(inSheet('1000 coins'), findsOneWidget);
    expect(inSheet('750 coins'), findsOneWidget);
    expect(inSheet('500 coins returned'), findsOneWidget);
    expect(posts(requests), 0);
  });

  testWidgets('Go back sends nothing and keeps the choices', (tester) async {
    final requests = <http.Request>[];
    await choosePick(tester, stateJson(), requests);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(PickConfirmationSheet), findsNothing);
    expect(find.byType(PickScreen), findsOneWidget);
    expect(posts(requests), 0);
    final bills = tester.widget<TeamOptionCard>(
      find.widgetWithText(TeamOptionCard, 'Buffalo Bills'),
    );
    expect(bills.selected, isTrue);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lock in pick'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Confirm pick sends the chosen team and stake once', (
    tester,
  ) async {
    final requests = <http.Request>[];
    await choosePick(tester, stateJson(), requests);
    await lockInPick(tester);
    final post = requests.singleWhere((request) => request.method == 'POST');
    expect(jsonDecode(post.body), {
      'gameId': 'demo-1',
      'team': 'Buffalo Bills',
      'stake': 250,
    });
  });

  testWidgets('a pick arriving while the sheet is open opens one game view', (
    tester,
  ) async {
    final json = stateJson();
    final requests = <http.Request>[];
    await choosePick(tester, json, requests);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    json['picks'] = [pickJson()];
    final api = tester
        .widget<PickScreen>(find.byType(PickScreen, skipOffstage: false))
        .api;
    await api.refresh();
    await tester.pumpAndSettle();
    // The sheet stays put while it is open.
    expect(find.byType(PickConfirmationSheet), findsOneWidget);
    await tester.tap(find.text('Go back'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsNothing);
    expect(find.byType(GameScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('More this week'), findsOneWidget);
    expect(posts(requests), 0);
  });
}
