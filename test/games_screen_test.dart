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
}
