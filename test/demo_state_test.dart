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

  test('falls back to a neutral name when the server sends none', () {
    final json = stateJson();
    (json['account'] as Map<String, dynamic>).remove('name');
    expect(demoState(json).playerName, 'Demo player');
  });
}
