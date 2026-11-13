import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

/// Tomorrow at [hour]:00, local time, so every game lands on one day.
DateTime tomorrowAt(int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1, hour);
}

/// One NFL day: the first open game is featured above the list, and the rest
/// cover every section.
Map<String, dynamic> nflDay() => stateJson(
  nfl: nflOk(),
  games: [
    nflGameJson(id: 'bdl-1', kickoff: tomorrowAt(12)),
    nflGameJson(
      id: 'bdl-2',
      away: 'Dallas Cowboys',
      home: 'Philadelphia Eagles',
      kickoff: tomorrowAt(15),
    ),
    nflGameJson(
      id: 'bdl-3',
      away: 'Detroit Lions',
      home: 'Minnesota Vikings',
      kickoff: tomorrowAt(16),
    ),
    nflGameJson(
      id: 'bdl-4',
      away: 'Seattle Seahawks',
      home: 'Los Angeles Rams',
      status: 'live',
      kickoff: tomorrowAt(13),
      awayScore: 14,
      homeScore: 10,
    ),
    nflGameJson(
      id: 'bdl-5',
      away: 'Denver Broncos',
      home: 'Las Vegas Raiders',
      status: 'postponed',
      kickoff: tomorrowAt(17),
    ),
    nflGameJson(
      id: 'bdl-6',
      away: 'Tennessee Titans',
      home: 'Houston Texans',
      status: 'final',
      kickoff: tomorrowAt(9),
      awayScore: 17,
      homeScore: 24,
    ),
  ],
);

Map<String, dynamic> threeDemoGames() => stateJson(
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

ChoiceChip chip(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

void main() {
  testWidgets('greets the player and shows what the server sent', (
    tester,
  ) async {
    await pumpApp(
      tester,
      stateJson(name: 'Sam', dailyLimit: 800, dailyStaked: 300),
    );
    expect(find.text('Hey,'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('1,000'), findsOneWidget);
    expect(find.text('500 left today'), findsOneWidget);
  });

  testWidgets('features the next open NFL game above the list', (tester) async {
    await pumpApp(tester, nflDay());
    // The featured card spells out full team names; list cards are short.
    expect(find.text('Kansas City Chiefs'), findsOneWidget);
    expect(find.textContaining('Kickoff in'), findsOneWidget);
  });

  testWidgets('the list shows a heading for each kind of game', (tester) async {
    await pumpApp(tester, nflDay());
    expect(find.text('Live now'), findsOneWidget);
    expect(find.text('Open for picks'), findsOneWidget);
    expect(find.text('Waiting for an update'), findsOneWidget);
    expect(find.text('Finished'), findsOneWidget);
  });

  testWidgets('a summary line counts the list', (tester) async {
    await pumpApp(
      tester,
      stateJson(
        games: [
          demoGameJson(id: 'demo-1'),
          demoGameJson(id: 'demo-2'),
        ],
        picks: [pickJson(gameId: 'demo-1')],
      ),
    );
    expect(find.text('2 open · 1 picked'), findsOneWidget);
  });

  group('filter chips', () {
    testWidgets('show a count for each filter', (tester) async {
      await pumpApp(tester, nflDay());
      expect(find.text('All · 5'), findsOneWidget);
      expect(find.text('Open · 2'), findsOneWidget);
      expect(find.text('Live · 1'), findsOneWidget);
      expect(find.text('Final · 1'), findsOneWidget);
    });

    testWidgets('narrow the list to the chosen filter', (tester) async {
      await pumpApp(tester, nflDay());
      await tester.tap(find.text('Open · 2'));
      await tester.pumpAndSettle();
      expect(find.text('Open for picks'), findsOneWidget);
      expect(find.text('Live now'), findsNothing);
      expect(find.text('Eagles'), findsOneWidget);
      expect(find.text('Rams'), findsNothing);
      await tester.tap(find.text('All · 5'));
      await tester.pumpAndSettle();
      expect(find.text('Rams'), findsOneWidget);
    });

    testWidgets('reset when switching to the demo list', (tester) async {
      final state = nflDay();
      (state['games'] as List).add(demoGameJson());
      await pumpApp(tester, state);
      await tester.tap(find.text('Live · 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Demo'));
      await tester.pumpAndSettle();
      expect(find.text('All · 1'), findsOneWidget);
      expect(chip(tester, 'All · 1').selected, isTrue);
    });
  });

  group('team search', () {
    testWidgets('narrows the list and updates the chip counts', (tester) async {
      await pumpApp(tester, threeDemoGames());
      await tester.enterText(find.byType(TextField), 'eagles');
      await tester.pumpAndSettle();
      expect(gameCard(), findsOneWidget);
      expect(find.text('Eagles'), findsOneWidget);
      expect(find.text('All · 1'), findsOneWidget);
    });

    testWidgets('the clear button brings every game back', (tester) async {
      await pumpApp(tester, threeDemoGames());
      await tester.enterText(find.byType(TextField), 'gb');
      await tester.pumpAndSettle();
      expect(gameCard(), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(gameCard(), findsNWidgets(3));
    });

    testWidgets('no matches offers a way back to every game', (tester) async {
      await pumpApp(tester, threeDemoGames());
      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pumpAndSettle();
      expect(gameCard(), findsNothing);
      expect(find.text('No games match'), findsOneWidget);
      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();
      expect(gameCard(), findsNWidgets(3));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });

    testWidgets('a filter with no games also offers Clear filters', (
      tester,
    ) async {
      await pumpApp(tester, threeDemoGames());
      await tester.tap(find.text('Live · 0'));
      await tester.pumpAndSettle();
      expect(find.text('No games match'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
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
      await pumpApp(tester, threeDemoGames(), onRequest: (_) => gets++);
      await tester.enterText(find.byType(TextField), 'bills');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open · 1'));
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
      expect(chip(tester, 'Open · 1').selected, isTrue);
    });
  });

  group('NFL problem notice', () {
    Map<String, dynamic> failingFeed() => {
      ...nflOk(),
      'stale': true,
      'error': 'NFL provider is unavailable. Try again shortly.',
    };

    testWidgets('says so and retries from the server', (tester) async {
      var gets = 0;
      await pumpApp(
        tester,
        stateJson(nfl: failingFeed(), games: [nflGameJson()]),
        onRequest: (_) => gets++,
      );
      expect(
        find.text('Scores may be out of date. Try refreshing.'),
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
      expect(gameCard(), findsOneWidget);
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
      await tester.tap(find.text('Demo'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('stays away when no NFL key is configured', (tester) async {
      await pumpApp(
        tester,
        stateJson(nfl: {'configured': false}, games: [demoGameJson()]),
      );
      expect(find.text('Try again'), findsNothing);
    });
  });

  group('empty lists', () {
    testWidgets('an empty demo list explains itself', (tester) async {
      await pumpApp(tester, stateJson(games: []));
      expect(find.text('No demo games available'), findsOneWidget);
      expect(find.text('Clear filters'), findsNothing);
    });

    testWidgets('an empty NFL schedule points to the demo games', (
      tester,
    ) async {
      await pumpApp(tester, stateJson(nfl: nflOk(), games: [demoGameJson()]));
      expect(find.text('No NFL games available'), findsOneWidget);
    });
  });

  group('a picked game', () {
    testWidgets('marks the chosen team on its card', (tester) async {
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
      expect(find.text('BUF picked'), findsOneWidget);
      expect(find.textContaining('picked'), findsNWidgets(2));
    });
  });
}
