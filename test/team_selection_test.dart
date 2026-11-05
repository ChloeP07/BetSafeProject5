import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';

Finder option(String team) => find.widgetWithText(TeamOptionCard, team);

/// Records haptic requests sent to the phone.
List<String> recordHaptics(WidgetTester tester) {
  final haptics = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      haptics.add(call.arguments as String);
    }
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return haptics;
}

void main() {
  testWidgets('selecting a team gives a light haptic', (tester) async {
    final haptics = recordHaptics(tester);
    await pumpPick(tester, stateJson());
    expect(haptics, isEmpty);
    await tester.tap(option('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  group('backing line', () {
    testWidgets('is hidden until a team is chosen', (tester) async {
      await pumpPick(tester, stateJson());
      expect(find.textContaining('backing'), findsNothing);
    });

    testWidgets('names the chosen team and follows a change', (tester) async {
      await pumpPick(tester, stateJson());
      await tester.tap(option('Buffalo Bills'));
      await tester.pumpAndSettle();
      expect(find.text('You’re backing the Bills'), findsOneWidget);
      await tester.tap(option('Kansas City Chiefs'));
      await tester.pumpAndSettle();
      expect(find.text('You’re backing the Chiefs'), findsOneWidget);
      expect(find.text('You’re backing the Bills'), findsNothing);
    });
  });
}
