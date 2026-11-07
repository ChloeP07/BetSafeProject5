import 'package:betsafeproject5/models/pick_rules.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

PickBlock? blockFor({
  Map<String, dynamic>? game,
  bool picked = false,
  String? team = 'Buffalo Bills',
  int? stake = 100,
  int coins = 1000,
  int dailyRemaining = 500,
}) => pickBlock(
  game: gameFrom(game ?? demoGameJson()),
  picked: picked,
  team: team,
  stake: stake,
  coins: coins,
  dailyRemaining: dailyRemaining,
);

void main() {
  group('canAffordStake', () {
    test('needs both the balance and the daily limit', () {
      expect(canAffordStake(100, coins: 100, dailyRemaining: 100), isTrue);
      expect(canAffordStake(100, coins: 99, dailyRemaining: 500), isFalse);
      expect(canAffordStake(100, coins: 1000, dailyRemaining: 99), isFalse);
    });
  });

  group('pickBlock', () {
    test('is null when the pick can be sent', () {
      expect(blockFor(), isNull);
    });

    test('a pick that already exists comes first', () {
      expect(
        blockFor(picked: true, game: demoGameJson(status: 'live')),
        PickBlock.alreadyPicked,
      );
    });

    test('a game that is not open is closed', () {
      expect(blockFor(game: demoGameJson(status: 'live')), PickBlock.closed);
      expect(
        blockFor(game: nflGameJson(status: 'postponed')),
        PickBlock.closed,
      );
      expect(
        blockFor(
          game: nflGameJson(
            kickoff: DateTime.now().subtract(const Duration(minutes: 1)),
          ),
        ),
        PickBlock.closed,
      );
    });

    test('says when no stake fits at all, before asking for a team', () {
      expect(blockFor(coins: 40, team: null), PickBlock.noAffordableStake);
      expect(
        blockFor(dailyRemaining: 0, team: null),
        PickBlock.noAffordableStake,
      );
    });

    test('asks for a team, then a stake', () {
      expect(blockFor(team: null), PickBlock.noTeam);
      expect(blockFor(stake: null), PickBlock.noStake);
    });

    test('names the balance when the stake is more than the coins', () {
      expect(blockFor(stake: 250, coins: 200), PickBlock.lowBalance);
    });

    test('names the daily limit when the stake is over what is left', () {
      expect(blockFor(stake: 250, dailyRemaining: 200), PickBlock.dailyLimit);
    });

    test('the balance is named first when both are too low', () {
      expect(
        blockFor(stake: 250, coins: 200, dailyRemaining: 150),
        PickBlock.lowBalance,
      );
    });
  });
}
