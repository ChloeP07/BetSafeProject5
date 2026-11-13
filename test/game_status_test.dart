import 'package:betsafeproject5/models/game_status.dart';
import 'package:betsafeproject5/theme.dart';
import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  final soon = DateTime.now().add(const Duration(hours: 3));
  final past = DateTime.now().subtract(const Duration(hours: 3));

  group('statusLabel', () {
    test('gives readable text for every NFL status', () {
      const expected = {
        'live': 'In progress',
        'final': 'Final',
        'postponed': 'Postponed',
        'canceled': 'Canceled',
        'delayed': 'Delayed',
        'suspended': 'Suspended',
        'abandoned': 'Abandoned',
        'unknown': 'Status unknown',
        'something-new': 'Status unknown',
      };
      expected.forEach((status, label) {
        expect(gameFrom(nflGameJson(status: status)).statusLabel, label);
      });
    });

    test('tells open NFL games from ones past kickoff', () {
      expect(gameFrom(nflGameJson(kickoff: soon)).statusLabel, 'Scheduled');
      expect(
        gameFrom(nflGameJson(kickoff: past)).statusLabel,
        'Awaiting update',
      );
    });

    test('always labels demo games as simulations', () {
      expect(gameFrom(demoGameJson()).statusLabel, 'Demo matchup');
      expect(
        gameFrom(demoGameJson(status: 'live')).statusLabel,
        'Simulation · live',
      );
      expect(
        gameFrom(demoGameJson(status: 'final')).statusLabel,
        'Simulation · final',
      );
    });
  });

  group('tone', () {
    test('sorts statuses by what they mean for the player', () {
      GameTone tone(String status) =>
          gameFrom(nflGameJson(status: status, kickoff: soon)).tone;
      expect(tone('scheduled'), GameTone.open);
      expect(tone('live'), GameTone.live);
      expect(tone('delayed'), GameTone.waiting);
      expect(tone('postponed'), GameTone.waiting);
      expect(tone('unknown'), GameTone.waiting);
      expect(tone('final'), GameTone.finished);
      expect(tone('canceled'), GameTone.finished);
      expect(tone('abandoned'), GameTone.finished);
    });

    test('a scheduled NFL game past kickoff is waiting, not open', () {
      expect(gameFrom(nflGameJson(kickoff: past)).tone, GameTone.waiting);
    });
  });

  testWidgets('pill colors follow the tone', (tester) async {
    Future<StatusPill> pillFor(String status) async {
      await tester.pumpWidget(
        ForuiTestApp(
          home: Scaffold(
            body: GameStatusPill(
              game: gameFrom(nflGameJson(status: status, kickoff: soon)),
            ),
          ),
        ),
      );
      return tester.widget<StatusPill>(find.byType(StatusPill));
    }

    expect((await pillFor('scheduled')).background, BetSafeColors.mint);
    expect((await pillFor('live')).background, BetSafeColors.yellow);
    expect((await pillFor('postponed')).background, BetSafeColors.loss);
    expect((await pillFor('final')).background, BetSafeColors.soft);
  });

  group('matchupDescription', () {
    test('describes a demo game and labels it a simulation', () {
      expect(
        gameFrom(demoGameJson()).matchupDescription,
        'Kansas City Chiefs at Buffalo Bills. Demo matchup.',
      );
      expect(
        gameFrom(demoGameJson(status: 'live', awayScore: 20, homeScore: 24))
            .matchupDescription,
        'Kansas City Chiefs at Buffalo Bills. Simulation, live. Chiefs 20, Bills 24.',
      );
    });

    test('reads out an NFL kickoff in words', () {
      final kickoff = DateTime.now().add(const Duration(days: 30));
      final text = gameFrom(nflGameJson(kickoff: kickoff)).matchupDescription;
      expect(
        text,
        startsWith('Kansas City Chiefs at Buffalo Bills. Scheduled.'),
      );
      expect(text, contains('Kickoff '));
      expect(text, isNot(contains('·')));
    });

    test('says when a score is missing, and never makes one up', () {
      final text = gameFrom(nflGameJson(status: 'live', awayScore: 7))
          .matchupDescription;
      expect(text, contains('Chiefs 7, Bills no score.'));
    });

    test('leaves scores out when the feed has none', () {
      final text = gameFrom(nflGameJson(status: 'postponed'))
          .matchupDescription;
      expect(text, isNot(contains('no score')));
    });
  });

  testWidgets('the card reads as one description and keeps its button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ForuiTestApp(
        home: Scaffold(
          body: MatchTicket(
            game: gameFrom(demoGameJson()),
            footer: FilledButton(onPressed: () {}, child: const Text('Go')),
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Kansas City Chiefs at Buffalo Bills. Demo matchup.',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Kansas City Chiefs'), findsNothing);
    expect(find.bySemanticsLabel('Go'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the card capitalizes a raw feed status', (tester) async {
    await tester.pumpWidget(
      ForuiTestApp(
        home: Scaffold(
          body: MatchTicket(game: gameFrom(nflGameJson(status: 'postponed'))),
        ),
      ),
    );
    expect(find.text('Postponed'), findsOneWidget);
    expect(find.text('postponed'), findsNothing);
  });
}
