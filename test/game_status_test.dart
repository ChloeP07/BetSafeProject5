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
        MaterialApp(
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
    expect((await pillFor('live')).background, BetSafeColors.green);
    expect((await pillFor('postponed')).background, BetSafeColors.clay);
    expect((await pillFor('final')).background, BetSafeColors.cream);
  });

  testWidgets('the card capitalizes a raw feed status', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MatchTicket(game: gameFrom(nflGameJson(status: 'postponed'))),
        ),
      ),
    );
    expect(find.text('Postponed'), findsOneWidget);
    expect(find.text('postponed'), findsNothing);
  });
}
