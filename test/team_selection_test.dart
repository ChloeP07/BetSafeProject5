import 'package:betsafeproject5/widgets/sports_ui.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import 'support/fixtures.dart';

Finder option(String team) => find.widgetWithText(TeamOptionCard, team);

Finder onTicket(String text) =>
    find.descendant(of: find.byType(MatchTicket), matching: find.text(text));

FButton lockInButton(WidgetTester tester) =>
    tester.widget<FButton>(find.widgetWithText(FButton, 'Lock in pick'));

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

  testWidgets('a second tap clears the choice and blocks Lock in', (
    tester,
  ) async {
    final haptics = recordHaptics(tester);
    await pumpPick(tester, stateJson());
    await tester.tap(option('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(lockInButton(tester).onPress, isNotNull);

    await tester.tap(option('Buffalo Bills'));
    await tester.pumpAndSettle();
    expect(lockInButton(tester).onPress, isNull);
    expect(find.textContaining('backing'), findsNothing);
    expect(
      tester.widget<TeamOptionCard>(option('Buffalo Bills')).selected,
      isFalse,
    );
    // Only selecting buzzes, not clearing.
    expect(haptics, hasLength(1));
  });

  group('tapping a team on the ticket', () {
    testWidgets('selects it, matching the option below', (tester) async {
      await pumpPick(tester, stateJson());
      await tester.tap(onTicket('Buffalo Bills'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TeamOptionCard>(option('Buffalo Bills')).selected,
        isTrue,
      );
      expect(onTicket('Your pick'), findsOneWidget);
      expect(find.text('You’re backing the Bills'), findsOneWidget);
    });

    testWidgets('a second tap clears it', (tester) async {
      await pumpPick(tester, stateJson());
      await tester.tap(onTicket('Buffalo Bills'));
      await tester.pumpAndSettle();
      await tester.tap(onTicket('Buffalo Bills'));
      await tester.pumpAndSettle();
      expect(onTicket('Your pick'), findsNothing);
      expect(onTicket('Home'), findsOneWidget);
      expect(lockInButton(tester).onPress, isNull);
    });

    testWidgets('a choice below shows on the ticket too', (tester) async {
      await pumpPick(tester, stateJson());
      await tester.tap(option('Kansas City Chiefs'));
      await tester.pumpAndSettle();
      expect(onTicket('Your pick'), findsOneWidget);
      expect(onTicket('Away'), findsNothing);
      expect(onTicket('Home'), findsOneWidget);
    });
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
