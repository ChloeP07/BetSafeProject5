import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

FilledButton lockIn(WidgetTester tester) => tester.widget<FilledButton>(
  find.widgetWithText(FilledButton, 'Lock in pick'),
);

void main() {
  group('kickoff note', () {
    testWidgets('shows on an NFL pick with the countdown', (tester) async {
      await pumpPick(
        tester,
        stateJson(
          nfl: nflOk(),
          games: [
            nflGameJson(kickoff: DateTime.now().add(const Duration(hours: 3))),
          ],
        ),
      );
      expect(find.text('Picks close at kickoff.'), findsOneWidget);
      expect(find.textContaining('Kicks off in'), findsOneWidget);
    });

    testWidgets('stays off a demo pick, which has no kickoff', (tester) async {
      await pumpPick(tester, stateJson());
      expect(find.text('Picks close at kickoff.'), findsNothing);
      expect(find.textContaining('Kicks off in'), findsNothing);
    });

    testWidgets('the countdown timer stops when leaving the screen', (
      tester,
    ) async {
      await pumpPick(tester, stateJson());
      await tester.pageBack();
      await tester.pumpAndSettle();
      // A timer left running would fail this test when it ends.
      await tester.pump(const Duration(seconds: 31));
      expect(find.text('Make a pick'), findsOneWidget);
    });
  });

  group('a game that closes while picking', () {
    Future<Map<String, dynamic>> closeGame(
      WidgetTester tester,
      String status,
    ) async {
      final json = stateJson(nfl: nflOk(), games: [nflGameJson()]);
      final api = await pumpPick(tester, json);
      await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
      await tester.pumpAndSettle();
      expect(lockIn(tester).onPressed, isNotNull);
      json['games'] = [nflGameJson(status: status)];
      await api.refresh();
      await tester.pumpAndSettle();
      return json;
    }

    testWidgets('explains why and stops the pick', (tester) async {
      await closeGame(tester, 'live');
      expect(find.text('Picks closed at kickoff.'), findsOneWidget);
      expect(lockIn(tester).onPressed, isNull);
    });

    testWidgets('names the status when a game is postponed', (tester) async {
      await closeGame(tester, 'postponed');
      expect(
        find.text('Picks are paused while this game is postponed.'),
        findsOneWidget,
      );
    });

    testWidgets('disables teams and stakes', (tester) async {
      await closeGame(tester, 'live');
      final cards = tester.widgetList<TeamOptionCard>(
        find.byType(TeamOptionCard),
      );
      expect(cards.every((card) => card.onTap == null), isTrue);
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips.every((chip) => chip.onSelected == null), isTrue);
    });

    testWidgets('offers a way back to the list', (tester) async {
      await closeGame(tester, 'live');
      await tester.tap(find.text('Back to games'));
      await tester.pumpAndSettle();
      expect(find.byType(PickScreen), findsNothing);
      expect(find.text('NFL matchups'), findsOneWidget);
    });

    testWidgets('an open game shows no notice', (tester) async {
      await pumpPick(tester, stateJson());
      expect(find.text('Back to games'), findsNothing);
    });
  });

  group('a game that drops out of the server data', () {
    testWidgets('shows a message instead of crashing', (tester) async {
      final json = stateJson();
      final api = await pumpPick(tester, json);
      json['games'] = <Map<String, dynamic>>[];
      await api.refresh();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('This game is no longer available'), findsOneWidget);
      expect(find.text('Lock in pick'), findsNothing);
    });

    testWidgets('offers a way back to the list', (tester) async {
      final json = stateJson();
      final api = await pumpPick(tester, json);
      json['games'] = <Map<String, dynamic>>[];
      await api.refresh();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back to games'));
      await tester.pumpAndSettle();
      expect(find.byType(PickScreen), findsNothing);
    });
  });
}
