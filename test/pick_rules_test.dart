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

  group('validStake', () {
    int? valid(int? chosen, {int coins = 1000, int dailyRemaining = 500}) =>
        validStake(chosen, coins: coins, dailyRemaining: dailyRemaining);

    test('starts at 100 when it fits', () {
      expect(valid(null), 100);
    });

    test('keeps the chosen stake while it fits', () {
      expect(valid(250), 250);
      expect(valid(50), 50);
    });

    test('falls back to 100 when the chosen stake no longer fits', () {
      expect(valid(250, dailyRemaining: 200), 100);
    });

    test('uses the largest stake that fits when 100 does not', () {
      expect(valid(null, coins: 80), 50);
      expect(valid(250, dailyRemaining: 60), 50);
    });

    test('is null when no stake fits', () {
      expect(valid(null, coins: 40), isNull);
      expect(valid(100, dailyRemaining: 0), isNull);
    });

    test('ignores a stake the server does not accept', () {
      expect(valid(75), 100);
    });
  });

  group('stakeCaption', () {
    test('is null when every stake fits', () {
      expect(stakeCaption(coins: 1000, dailyRemaining: 500), isNull);
      expect(stakeCaption(coins: 250, dailyRemaining: 250), isNull);
    });

    test('names the balance when it is the lower of the two', () {
      expect(
        stakeCaption(coins: 120, dailyRemaining: 500),
        'Stakes over your 120-coin balance are unavailable.',
      );
    });

    test('names today’s limit when it is the lower of the two', () {
      expect(
        stakeCaption(coins: 1000, dailyRemaining: 150),
        'Stakes over the 150 coins left in today’s limit are unavailable.',
      );
    });
  });

  group('noStakeMessage', () {
    test('is null while the smallest stake fits', () {
      expect(noStakeMessage(coins: 50, dailyRemaining: 50), isNull);
    });

    test('names the balance when coins run low', () {
      expect(
        noStakeMessage(coins: 30, dailyRemaining: 500),
        'You have 30 virtual coins, less than the smallest 50-coin stake. '
        'Winning picks return coins when their games finish.',
      );
    });

    test('names a used-up daily limit', () {
      expect(
        noStakeMessage(coins: 1000, dailyRemaining: 0),
        'You’ve used all of today’s stake limit. '
        'You can pick again after it resets at midnight UTC.',
      );
    });

    test('names a daily limit with too little left', () {
      expect(
        noStakeMessage(coins: 1000, dailyRemaining: 20),
        'Only 20 coins are left in today’s stake limit, less than the '
        'smallest 50-coin stake. '
        'You can pick again after it resets at midnight UTC.',
      );
    });
  });

  group('stakeProblemMessage', () {
    String? message(PickBlock? block, {int coins = 1000, int left = 500}) =>
        stakeProblemMessage(
          block,
          stake: 250,
          coins: coins,
          dailyRemaining: left,
        );

    test('low balance, daily limit and no stake each read differently', () {
      final balance = message(PickBlock.lowBalance, coins: 200);
      final limit = message(PickBlock.dailyLimit, left: 200);
      final none = message(PickBlock.noAffordableStake, coins: 20);
      expect(
        balance,
        'A 250-coin stake is more than your 200-coin balance. '
        'Choose a smaller stake.',
      );
      expect(
        limit,
        'A 250-coin stake is more than the 200 coins left in today’s limit. '
        'Choose a smaller stake.',
      );
      expect(none, startsWith('You have 20 virtual coins'));
      expect({balance, limit, none}, hasLength(3));
    });

    test('is null for problems that are not about the stake', () {
      expect(message(null), isNull);
      expect(message(PickBlock.noTeam), isNull);
      expect(message(PickBlock.closed), isNull);
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
