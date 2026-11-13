import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/pick_confirmation_sheet.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

/// A small stand-in for the server: it takes a pick, debits the stake and
/// records it, the way server/src/store.js does. The app never does this math.
BetSafeApi fakeServer(Map<String, dynamic> json, List<http.Request> posts) =>
    BetSafeApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          posts.add(request);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final stake = body['stake'] as int;
          final account = json['account'] as Map<String, dynamic>;
          account['coins'] = (account['coins'] as int) - stake;
          account['dailyStaked'] = (account['dailyStaked'] as int) + stake;
          json['picks'] = [
            ...json['picks'] as List,
            pickJson(
              gameId: body['gameId'] as String,
              team: body['team'] as String,
              stake: stake,
            ),
          ];
        }
        return http.Response(jsonEncode(json), 200);
      }),
    );

void main() {
  testWidgets('a full pick from the Games list to the locked pick', (
    tester,
  ) async {
    final json = stateJson();
    final posts = <http.Request>[];
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = fakeServer(json, posts);
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();

    // Games: the wallet and the open game.
    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('500 left today'), findsOneWidget);
    await openGame(tester);
    await tester.pumpAndSettle();
    expect(find.byType(PickScreen), findsOneWidget);

    // Pick: nothing can be sent until a team is chosen.
    expect(find.text('Choose a team to continue.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(find.text('You’re backing the Bills'), findsOneWidget);
    expect(find.text('Choose a team to continue.'), findsNothing);

    // The stake updates the payout and the balance preview.
    await tester.tap(find.text('250 coins'));
    await tester.pumpAndSettle();
    expect(find.text('500 coins returned'), findsOneWidget);
    expect(find.text('750 coins'), findsOneWidget);

    // Lock in asks first, and sends only on Confirm pick.
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    expect(find.byType(PickConfirmationSheet), findsOneWidget);
    expect(posts, isEmpty);
    await tester.tap(find.text('Confirm pick'));
    await tester.pumpAndSettle();
    expect(posts, hasLength(1));
    expect(jsonDecode(posts.single.body), {
      'gameId': 'demo-1',
      'team': 'Buffalo Bills',
      'stake': 250,
    });

    // The game view takes over, with the confirmation.
    expect(find.byType(PickScreen), findsNothing);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.text('Pick locked: Bills · 250 coins'), findsOneWidget);

    // Back on Games, the server's new figures and the pick show.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('750'), findsOneWidget);
    expect(find.text('250 left today'), findsOneWidget);
    expect(find.text('BUF picked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a second pick is limited by what the first one used', (
    tester,
  ) async {
    final json = stateJson(
      games: [
        demoGameJson(id: 'demo-1'),
        demoGameJson(
          id: 'demo-2',
          away: 'Dallas Cowboys',
          home: 'Green Bay Packers',
        ),
      ],
      dailyStaked: 400,
    );
    final posts = <http.Request>[];
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = fakeServer(json, posts);
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();

    await openGame(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
    // 100 left today: 250 is off and 100 stays the default.
    expect(
      find.text(
        'Stakes over the 100 coins left in today’s limit are unavailable.',
      ),
      findsOneWidget,
    );
    await lockInPick(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // The limit is now used up, and Games says so.
    expect(find.textContaining('You’ve used all of today’s'), findsOneWidget);
    await openGame(tester, away: 'Dallas Cowboys', home: 'Green Bay Packers');
    await tester.pumpAndSettle();
    expect(find.text('No stake fits right now.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lock in pick'),
          )
          .onPressed,
      isNull,
    );
    expect(posts, hasLength(1));
  });
}
