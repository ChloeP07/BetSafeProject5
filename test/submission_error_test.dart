import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/models/pick_errors.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

final rejected = friendlyPickError('Not enough virtual coins.');

/// Opens the pick screen against a server that rejects every pick.
Future<BetSafeApi> openRejectingPick(
  WidgetTester tester, {
  bool Function()? offline,
}) async {
  final json = stateJson();
  tester.view.physicalSize = const Size(420, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final api = BetSafeApi(
    client: MockClient((request) async {
      if (offline?.call() ?? false) throw Exception('offline');
      if (request.method == 'POST') {
        return http.Response(
          jsonEncode({'error': 'Not enough virtual coins.'}),
          400,
        );
      }
      return http.Response(jsonEncode(json), 200);
    }),
  );
  addTearDown(api.dispose);
  await tester.pumpWidget(BetSafeApp(api: api));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Make a pick'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('choosing another stake clears the old error', (tester) async {
    await openRejectingPick(tester);
    await lockInPick(tester);
    expect(find.text(rejected), findsOneWidget);
    await tester.tap(find.text('50 coins'));
    await tester.pumpAndSettle();
    expect(find.text(rejected), findsNothing);
  });

  testWidgets('choosing another team clears the old error', (tester) async {
    await openRejectingPick(tester);
    await lockInPick(tester);
    expect(find.text(rejected), findsOneWidget);
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Kansas City Chiefs'));
    await tester.pumpAndSettle();
    expect(find.text(rejected), findsNothing);
  });

  testWidgets('a failed refresh is not cleared by a new choice', (
    tester,
  ) async {
    var offline = false;
    final api = await openRejectingPick(tester, offline: () => offline);
    offline = true;
    await api.refresh();
    await tester.pumpAndSettle();
    expect(find.textContaining('Cannot reach the demo server'), findsOneWidget);
    await tester.tap(find.text('50 coins'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cannot reach the demo server'), findsOneWidget);
    expect(find.byType(PickScreen), findsOneWidget);
  });

  test('clearError leaves a running request alone', () {
    final api =
        BetSafeApi(client: MockClient((_) async => http.Response('{}', 500)))
          ..error = 'Old error'
          ..busy = true;
    addTearDown(api.dispose);
    api.clearError();
    expect(api.error, 'Old error');
    api.busy = false;
    api.clearError();
    expect(api.error, isNull);
  });
}
