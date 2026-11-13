import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Map<String, dynamic> mixedState() => stateJson(
  games: [
    demoGameJson(id: 'demo-1'),
    demoGameJson(
      id: 'demo-2',
      away: 'Dallas Cowboys',
      home: 'Philadelphia Eagles',
      status: 'final',
      awayScore: 20,
      homeScore: 27,
    ),
    demoGameJson(
      id: 'demo-3',
      away: 'Green Bay Packers',
      home: 'Chicago Bears',
      status: 'final',
      awayScore: 20,
      homeScore: 27,
    ),
  ],
);

void main() {
  testWidgets('finished games start folded, under a visible heading', (
    tester,
  ) async {
    await pumpApp(tester, mixedState());
    expect(find.text('Finished'), findsOneWidget);
    expect(find.text('Show 2 games'), findsOneWidget);
    expect(gameCard(), findsOneWidget);
  });

  testWidgets('Show and Hide fold them in and out', (tester) async {
    await pumpApp(tester, mixedState());
    await tester.tap(find.text('Show 2 games'));
    await tester.pumpAndSettle();
    expect(gameCard(), findsNWidgets(3));
    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(gameCard(), findsOneWidget);
    expect(find.text('Show 2 games'), findsOneWidget);
  });

  testWidgets('the Final filter always shows them', (tester) async {
    await pumpApp(tester, mixedState());
    await tester.tap(find.text('Final · 2'));
    await tester.pumpAndSettle();
    expect(gameCard(), findsNWidgets(2));
    expect(find.text('Show 2 games'), findsNothing);
  });

  testWidgets('a search finds them without unfolding by hand', (tester) async {
    await pumpApp(tester, mixedState());
    await tester.enterText(find.byType(TextField), 'eagles');
    await tester.pumpAndSettle();
    expect(find.text('Eagles'), findsOneWidget);
    expect(find.text('Show 1 game'), findsNothing);
  });

  testWidgets('a list of only finished games stays open', (tester) async {
    await pumpApp(
      tester,
      stateJson(
        games: [demoGameJson(status: 'final', awayScore: 20, homeScore: 27)],
      ),
    );
    expect(gameCard(), findsOneWidget);
    expect(find.text('Show 1 game'), findsNothing);
  });

  testWidgets('a refresh keeps them unfolded', (tester) async {
    final api = await pumpApp(tester, mixedState());
    await tester.tap(find.text('Show 2 games'));
    await tester.pumpAndSettle();
    await api.refresh();
    await tester.pumpAndSettle();
    expect(gameCard(), findsNWidgets(3));
  });
}
