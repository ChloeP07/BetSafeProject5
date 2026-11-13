import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('explains when today’s limit is used up', (tester) async {
    await pumpApp(tester, stateJson(dailyStaked: 500));
    expect(
      find.textContaining('You’ve used all of today’s stake limit.'),
      findsOneWidget,
    );
  });

  testWidgets('explains when too little of the limit is left', (tester) async {
    await pumpApp(tester, stateJson(dailyStaked: 480));
    expect(
      find.textContaining('Only 20 coins are left in today’s stake limit'),
      findsOneWidget,
    );
  });

  testWidgets('explains when the coins have run out', (tester) async {
    await pumpApp(tester, stateJson(coins: 10));
    expect(find.textContaining('You have 10 virtual coins'), findsOneWidget);
  });

  testWidgets('says nothing while a stake still fits', (tester) async {
    await pumpApp(tester, stateJson(coins: 50, dailyStaked: 450));
    expect(find.textContaining('less than the smallest'), findsNothing);
    expect(find.textContaining('You’ve used all'), findsNothing);
  });
}
