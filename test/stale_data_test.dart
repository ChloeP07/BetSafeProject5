import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:http/http.dart' as http;

import 'support/fixtures.dart';

const warning =
    'The NFL data may be out of date, so NFL picks are paused until a refresh '
    'works.';

Map<String, dynamic> staleNfl() => {...nflOk(), 'stale': true};

FButton lockIn(WidgetTester tester) =>
    tester.widget<FButton>(find.widgetWithText(FButton, 'Lock in pick'));

Future<void> chooseBills(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('stale NFL data warns and blocks the pick', (tester) async {
    await pumpPick(tester, stateJson(nfl: staleNfl(), games: [nflGameJson()]));
    await chooseBills(tester);
    expect(find.text(warning), findsOneWidget);
    expect(find.text('Refresh the NFL data to continue.'), findsOneWidget);
    expect(lockIn(tester).onPress, isNull);
  });

  testWidgets('a failed NFL feed also blocks the pick', (tester) async {
    await pumpPick(
      tester,
      stateJson(
        nfl: {...nflOk(), 'error': 'Provider unavailable.'},
        games: [nflGameJson()],
      ),
    );
    await chooseBills(tester);
    expect(find.text(warning), findsOneWidget);
    expect(lockIn(tester).onPress, isNull);
  });

  testWidgets('a refresh that brings fresh data unblocks the pick', (
    tester,
  ) async {
    final json = stateJson(nfl: staleNfl(), games: [nflGameJson()]);
    final requests = <http.Request>[];
    await pumpPick(tester, json, onRequest: requests.add);
    await chooseBills(tester);
    json['nfl'] = nflOk();
    final before = requests.length;
    await tester.tap(find.text('Refresh NFL data'));
    await tester.pumpAndSettle();
    expect(requests.length, before + 1);
    expect(find.text(warning), findsNothing);
    expect(lockIn(tester).onPress, isNotNull);
  });

  testWidgets('demo games are not held up by stale NFL data', (tester) async {
    await pumpApp(tester, stateJson(nfl: staleNfl()));
    await tester.tap(find.text('Demo'));
    await tester.pumpAndSettle();
    await openGame(tester);
    await tester.pumpAndSettle();
    await chooseBills(tester);
    expect(find.text(warning), findsNothing);
    expect(lockIn(tester).onPress, isNotNull);
  });
}
