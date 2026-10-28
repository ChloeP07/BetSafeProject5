import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> fixture() => {
  'account': {'coins': 1000, 'dailyLimit': 500, 'dailyStaked': 0},
  'games': [
    {
      'id': 'demo-1',
      'away': 'Kansas City Chiefs',
      'home': 'Buffalo Bills',
      'status': 'scheduled',
      'label': 'Demo matchup',
      'homeScore': 0,
      'awayScore': 0,
    },
  ],
  'picks': [],
  'collection': [],
};

void main() {
  testWidgets('loads server data, navigates, and submits a selected pick', (
    tester,
  ) async {
    final state = fixture();
    final requests = <http.Request>[];
    final api = BetSafeApi(
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {
            'gameId': 'demo-1',
            'team': 'Buffalo Bills',
            'stake': 100,
          });
          state['picks'] = [
            {
              'gameId': 'demo-1',
              'team': 'Buffalo Bills',
              'stake': 100,
              'status': 'pending',
              'payout': 0,
            },
          ];
          state['account'] = {
            'coins': 900,
            'dailyLimit': 500,
            'dailyStaked': 100,
          };
        }
        return http.Response(jsonEncode(state), 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('1000 virtual coins'), findsOneWidget);
    await tester.tap(find.text('Collection'));
    await tester.pumpAndSettle();
    expect(find.text('Make your first winning call.'), findsOneWidget);
    await tester.tap(find.text('Games'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Make a pick'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Make a pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make a pick'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lock in pick'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lock in pick'),
          )
          .onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Buffalo Bills'),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lock in pick'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    expect(find.text('Your pick: Buffalo Bills'), findsOneWidget);
    expect(requests.where((request) => request.method == 'POST'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('network failure displays recovery rather than fictional data', (
    tester,
  ) async {
    final api = BetSafeApi(
      client: MockClient((_) async => throw Exception('offline')),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('Start your demo server'), findsOneWidget);
    expect(find.text('1000 virtual coins'), findsNothing);
  });

  testWidgets('compact layout supports large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = BetSafeApi(
      client: MockClient(
        (_) async => http.Response(jsonEncode(fixture()), 200),
      ),
    );
    addTearDown(api.dispose);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('NFL matchups'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NFL matchups'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
