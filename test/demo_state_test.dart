import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  test('reads the player name and daily limit from the account', () {
    final state = demoState(
      stateJson(name: 'Sam', dailyLimit: 800, dailyStaked: 300),
    );
    expect(state.playerName, 'Sam');
    expect(state.dailyLimit, 800);
    expect(state.dailyRemaining, 500);
  });

  test('finds a game by id, and returns null for a missing one', () {
    final state = demoState(stateJson(games: [demoGameJson(id: 'demo-7')]));
    expect(state.gameById('demo-7')?.id, 'demo-7');
    expect(state.gameById('demo-8'), isNull);
  });

  test('falls back to a neutral name when the server sends none', () {
    final json = stateJson();
    (json['account'] as Map<String, dynamic>).remove('name');
    expect(demoState(json).playerName, 'Demo player');
  });
}
