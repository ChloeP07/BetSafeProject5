import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('greets the player and shows the limit the server sent', (
    tester,
  ) async {
    await pumpApp(
      tester,
      stateJson(name: 'Sam', dailyLimit: 800, dailyStaked: 300),
    );
    expect(find.text('Hey, Sam'), findsOneWidget);
    expect(find.text('500 of 800 coins left to stake today'), findsOneWidget);
  });

  testWidgets(
    'open tickets stay neutral, since green means selection or wins',
    (tester) async {
      await pumpApp(
        tester,
        stateJson(
          games: [
            demoGameJson(id: 'demo-1'),
            demoGameJson(id: 'demo-2'),
            demoGameJson(id: 'demo-3'),
          ],
        ),
      );
      final tickets = tester.widgetList<MatchTicket>(find.byType(MatchTicket));
      expect(tickets, hasLength(3));
      expect(tickets.map((ticket) => ticket.color).toSet(), {Colors.white});
    },
  );

  testWidgets('the list shows a heading for each kind of game', (tester) async {
    final kickoff = DateTime.now().add(const Duration(days: 1));
    await pumpApp(
      tester,
      stateJson(
        nfl: nflOk(),
        games: [
          nflGameJson(id: 'bdl-1', status: 'live', kickoff: kickoff),
          nflGameJson(id: 'bdl-2', kickoff: kickoff),
          nflGameJson(id: 'bdl-3', status: 'postponed', kickoff: kickoff),
          nflGameJson(id: 'bdl-4', status: 'final', kickoff: kickoff),
        ],
      ),
    );
    expect(find.text('Live now'), findsOneWidget);
    expect(find.text('Open for picks'), findsOneWidget);
    expect(find.text('Waiting for an update'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
  });

  group('filter chips', () {
    Map<String, dynamic> mixedState() {
      final kickoff = DateTime.now().add(const Duration(days: 1));
      return stateJson(
        nfl: nflOk(),
        games: [
          nflGameJson(id: 'bdl-1', status: 'live', kickoff: kickoff),
          nflGameJson(id: 'bdl-2', kickoff: kickoff),
          nflGameJson(id: 'bdl-3', kickoff: kickoff),
          nflGameJson(id: 'bdl-4', status: 'postponed', kickoff: kickoff),
          nflGameJson(id: 'bdl-5', status: 'final', kickoff: kickoff),
        ],
      );
    }

    testWidgets('show a count for each filter', (tester) async {
      await pumpApp(tester, mixedState());
      expect(find.text('All · 5'), findsOneWidget);
      expect(find.text('Open · 2'), findsOneWidget);
      expect(find.text('Live · 1'), findsOneWidget);
      expect(find.text('Final · 1'), findsOneWidget);
    });

    testWidgets('narrow the list to the chosen filter', (tester) async {
      await pumpApp(tester, mixedState());
      expect(find.byType(MatchTicket), findsNWidgets(5));
      await tester.tap(find.text('Open · 2'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsNWidgets(2));
      expect(find.text('Open for picks'), findsOneWidget);
      expect(find.text('Live now'), findsNothing);
      await tester.tap(find.text('All · 5'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsNWidgets(5));
    });

    testWidgets('reset when switching between NFL and demo games', (
      tester,
    ) async {
      final state = mixedState();
      (state['games'] as List).add(demoGameJson());
      await pumpApp(tester, state);
      await tester.tap(find.text('Live · 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo games · 1'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsOneWidget);
      expect(find.text('All · 1'), findsOneWidget);
    });
  });

  group('pull to refresh', () {
    testWidgets('asks the server for new data', (tester) async {
      var gets = 0;
      await pumpApp(tester, stateJson(), onRequest: (_) => gets++);
      expect(gets, 1);
      // The drag needed scales with screen height, and this test screen is tall.
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 1800),
        1000,
      );
      await tester.pumpAndSettle();
      expect(gets, 2);
    });

    testWidgets('keeps the chosen filter and search', (tester) async {
      var gets = 0;
      await pumpApp(
        tester,
        stateJson(
          games: [
            demoGameJson(),
            demoGameJson(id: 'demo-2'),
          ],
        ),
        onRequest: (_) => gets++,
      );
      await tester.enterText(find.byType(TextField), 'bills');
      await tester.tap(find.text('Open · 2'));
      await tester.pumpAndSettle();
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 1800),
        1000,
      );
      await tester.pumpAndSettle();
      expect(gets, 2);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'bills',
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Open · 2'))
            .selected,
        isTrue,
      );
    });
  });

  group('your pick on a card', () {
    testWidgets('appears only on the game you picked', (tester) async {
      await pumpApp(
        tester,
        stateJson(
          games: [
            demoGameJson(id: 'demo-1'),
            demoGameJson(
              id: 'demo-2',
              away: 'Dallas Cowboys',
              home: 'Philadelphia Eagles',
            ),
          ],
          picks: [
            pickJson(gameId: 'demo-1', team: 'Buffalo Bills', stake: 250),
          ],
        ),
      );
      expect(find.text('Your pick: Bills · 250 coins'), findsOneWidget);
      expect(find.textContaining('Your pick:'), findsOneWidget);
    });

    testWidgets('stays away when no pick has been made', (tester) async {
      await pumpApp(tester, stateJson());
      expect(find.textContaining('Your pick:'), findsNothing);
    });
  });

  group('NFL problem banner', () {
    Map<String, dynamic> failingFeed() => {
      ...nflOk(),
      'stale': true,
      'error': 'NFL provider is unavailable. Try again shortly.',
    };

    testWidgets('shows the error and retries from the server', (tester) async {
      var gets = 0;
      await pumpApp(
        tester,
        stateJson(nfl: failingFeed(), games: [nflGameJson()]),
        onRequest: (_) => gets++,
      );
      expect(
        find.text('NFL provider is unavailable. Try again shortly.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(gets, 2);
    });

    testWidgets('keeps cached games visible, with no invented scores', (
      tester,
    ) async {
      await pumpApp(
        tester,
        stateJson(nfl: failingFeed(), games: [nflGameJson()]),
      );
      expect(find.byType(MatchTicket), findsOneWidget);
    });

    testWidgets('stays away when the feed is healthy', (tester) async {
      await pumpApp(tester, stateJson(nfl: nflOk(), games: [nflGameJson()]));
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('stays away on the demo list', (tester) async {
      await pumpApp(
        tester,
        stateJson(nfl: failingFeed(), games: [nflGameJson(), demoGameJson()]),
      );
      await tester.tap(find.text('Demo games · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('stays away when no NFL key is configured', (tester) async {
      await pumpApp(
        tester,
        stateJson(nfl: {'configured': false}, games: [demoGameJson()]),
      );
      await tester.tap(find.text('NFL schedule · 0'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('NFL and demo chips', () {
    testWidgets('show how many games each side has', (tester) async {
      await pumpApp(
        tester,
        stateJson(
          nfl: nflOk(),
          games: [
            nflGameJson(id: 'bdl-1'),
            nflGameJson(id: 'bdl-2'),
            demoGameJson(),
          ],
        ),
      );
      expect(find.text('NFL schedule · 2'), findsOneWidget);
      expect(find.text('Demo games · 1'), findsOneWidget);
      expect(find.text('2 games'), findsOneWidget);
    });

    testWidgets('one game reads as "1 game"', (tester) async {
      await pumpApp(tester, stateJson());
      expect(find.text('1 game'), findsOneWidget);
      expect(find.text('1 games'), findsNothing);
    });

    testWidgets('an empty demo list explains itself', (tester) async {
      await pumpApp(tester, stateJson(games: []));
      expect(find.text('No demo games available'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('an empty NFL list still points to demo games', (tester) async {
      await pumpApp(tester, stateJson(nfl: nflOk(), games: [demoGameJson()]));
      expect(find.text('No NFL games available'), findsOneWidget);
    });
  });

  group('team search', () {
    Map<String, dynamic> threeGames() => stateJson(
      games: [
        demoGameJson(id: 'demo-1'),
        demoGameJson(
          id: 'demo-2',
          away: 'Dallas Cowboys',
          home: 'Philadelphia Eagles',
        ),
        demoGameJson(
          id: 'demo-3',
          away: 'Green Bay Packers',
          home: 'Chicago Bears',
        ),
      ],
    );

    testWidgets('narrows the list and updates the chip counts', (tester) async {
      await pumpApp(tester, threeGames());
      await tester.enterText(find.byType(TextField), 'eagles');
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsOneWidget);
      expect(find.text('Philadelphia Eagles'), findsOneWidget);
      expect(find.text('All · 1'), findsOneWidget);
    });

    testWidgets('the clear button brings every game back', (tester) async {
      await pumpApp(tester, threeGames());
      await tester.enterText(find.byType(TextField), 'gb');
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsNWidgets(3));
    });

    testWidgets('no matches offers a way back to every game', (tester) async {
      await pumpApp(tester, threeGames());
      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsNothing);
      expect(find.text('No games match'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsNWidgets(3));
      expect(find.text('No games match'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a filter with no games also offers Clear filters', (
      tester,
    ) async {
      await pumpApp(tester, threeGames());
      await tester.tap(find.text('Live · 0'));
      await tester.pumpAndSettle();
      expect(find.text('No games match'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });
  });
}
