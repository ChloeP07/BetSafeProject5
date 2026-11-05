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

  testWidgets('open tickets stay neutral, since green means selection or wins', (
    tester,
  ) async {
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
  });

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
      await tester.tap(find.text('Demo games'));
      await tester.pumpAndSettle();
      expect(find.byType(MatchTicket), findsOneWidget);
      expect(find.text('All · 1'), findsOneWidget);
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
  });
}
