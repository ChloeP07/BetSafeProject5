import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

Future<void> lockInBills(WidgetTester tester, {required bool accept}) async {
  final json = stateJson();
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = BetSafeApi(
    client: MockClient((request) async {
      if (request.method == 'POST') {
        if (!accept) {
          return http.Response(
            jsonEncode({'error': 'Daily stake limit reached.'}),
            400,
          );
        }
        json['picks'] = [pickJson(stake: 250)];
      }
      return http.Response(jsonEncode(json), 200);
    }),
  );
  addTearDown(api.dispose);
  await tester.pumpWidget(BetSafeApp(api: api));
  await tester.pumpAndSettle();
  await openGame(tester);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
  await tester.tap(find.text('250 coins'));
  await tester.pumpAndSettle();
  await lockInPick(tester);
}

void main() {
  testWidgets('a locked pick is confirmed on the game view', (tester) async {
    await lockInBills(tester, accept: true);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Pick locked: Bills · 250 coins'), findsOneWidget);
  });

  testWidgets('a rejected pick shows no confirmation', (tester) async {
    await lockInBills(tester, accept: false);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.textContaining('Pick locked'), findsNothing);
  });
}
