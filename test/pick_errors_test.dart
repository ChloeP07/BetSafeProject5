import 'dart:convert';
import 'dart:io';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/models/pick_errors.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

/// The messages placePick in the server can reject a pick with.
const serverMessages = [
  'Game not found.',
  'Picks are closed for this game.',
  'Fresh NFL data is needed before accepting this pick. Try refreshing.',
  'Picks close at kickoff.',
  'Choose a team in this game.',
  'Choose a stake of 50, 100, or 250 coins.',
  'You already picked this game.',
  'Not enough virtual coins.',
  'Daily stake limit reached.',
];

void main() {
  test('every mapped message is one the server really sends', () {
    final store = File('server/src/store.js').readAsStringSync();
    for (final message in serverMessages) {
      expect(store, contains(jsonEncode(message).replaceAll('"', "'")));
    }
  });

  test('each known message gets a friendlier one', () {
    for (final message in serverMessages) {
      expect(friendlyPickError(message), isNot(message));
    }
  });

  test('friendly messages keep a next step', () {
    expect(
      friendlyPickError('You already picked this game.'),
      'You already picked this game. Tap Try again to see your pick.',
    );
    expect(
      friendlyPickError('Not enough virtual coins.'),
      endsWith('Choose a smaller stake.'),
    );
    expect(
      friendlyPickError('Picks close at kickoff.'),
      contains('Go back to the games list'),
    );
  });

  test('unknown errors pass through unchanged', () {
    expect(friendlyPickError('Something new.'), 'Something new.');
    expect(
      friendlyPickError(
        'Cannot reach the demo server. Check that it is running and try again.',
      ),
      'Cannot reach the demo server. Check that it is running and try again.',
    );
  });

  Future<void> rejectWith(WidgetTester tester, String error) async {
    final json = stateJson();
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = BetSafeApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'error': error}), 400);
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
    await tester.pumpAndSettle();
    await lockInPick(tester);
  }

  testWidgets('the pick screen shows the friendly message', (tester) async {
    await rejectWith(tester, 'Daily stake limit reached.');
    expect(find.text('Daily stake limit reached.'), findsNothing);
    expect(
      find.text(friendlyPickError('Daily stake limit reached.')),
      findsOneWidget,
    );
  });

  testWidgets('the pick screen shows an unknown message as sent', (
    tester,
  ) async {
    await rejectWith(tester, 'The server had a new problem.');
    expect(find.text('The server had a new problem.'), findsOneWidget);
  });
}
