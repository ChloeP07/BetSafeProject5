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
}
