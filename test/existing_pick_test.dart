import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('a pick that arrives by refresh moves on to the game view', (
    tester,
  ) async {
    final json = stateJson();
    final api = await pumpPick(tester, json);
    expect(find.byType(PickScreen), findsOneWidget);
    json['picks'] = [pickJson(gameId: 'demo-1', team: 'Kansas City Chiefs')];
    await api.refresh();
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsNothing);
    expect(find.text('Your pick: Kansas City Chiefs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving on replaces the form, so Back reaches the list', (
    tester,
  ) async {
    final json = stateJson();
    final api = await pumpPick(tester, json);
    json['picks'] = [pickJson(gameId: 'demo-1')];
    await api.refresh();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(PickScreen), findsNothing);
    expect(find.text('NFL matchups'), findsOneWidget);
  });

  testWidgets('locking in opens the game view exactly once', (tester) async {
    final json = stateJson();
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = BetSafeApi(
      client: MockClient((request) async {
        if (request.method == 'POST') json['picks'] = [pickJson()];
        return http.Response(jsonEncode(json), 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    await lockInPick(tester);
    expect(find.text('Your pick: Buffalo Bills'), findsOneWidget);
    // One Back reaches the list. A second game view would still be in the way.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('NFL matchups'), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
  });

  testWidgets('a duplicate rejected by the server recovers on retry', (
    tester,
  ) async {
    final json = stateJson();
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = BetSafeApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(
            jsonEncode({'error': 'You already picked this game.'}),
            409,
          );
        }
        return http.Response(jsonEncode(json), 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    await lockInPick(tester);
    // The form stays, and shows the server's own message.
    expect(find.byType(PickScreen), findsOneWidget);
    expect(find.text('You already picked this game.'), findsOneWidget);

    json['picks'] = [pickJson()];
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsNothing);
    expect(find.text('Your pick: Buffalo Bills'), findsOneWidget);
  });
}
