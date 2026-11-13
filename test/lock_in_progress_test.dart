import 'dart:async';
import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/screens/game_screen.dart';
import 'package:betsafeproject5/screens/pick_screen.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/pick_confirmation_sheet.dart';
import 'package:betsafeproject5/widgets/team_option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

/// Lets the sheet finish closing. pumpAndSettle would also run the clock past
/// the request timeout while the server holds its reply.
Future<void> settleSheet(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Map<String, dynamic> json;
  late List<http.Request> posts;
  late Completer<void> serverReply;

  /// Opens the pick screen with a server that holds each POST until
  /// [serverReply] completes.
  Future<void> openPick(WidgetTester tester) async {
    json = stateJson();
    posts = [];
    serverReply = Completer<void>();
    tester.view.physicalSize = const Size(420, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = BetSafeApi(
      client: MockClient((request) async {
        if (request.method == 'POST') {
          posts.add(request);
          await serverReply.future;
          json['picks'] = [pickJson()];
        }
        return http.Response(jsonEncode(json), 200);
      }),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pumpAndSettle();
    await openGame(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TeamOptionCard, 'Buffalo Bills'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows progress inside the button while saving', (tester) async {
    await openPick(tester);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm pick'));
    await settleSheet(tester);
    final button = find.ancestor(
      of: find.text('Saving pick…'),
      matching: find.byType(FButton),
    );
    expect(button, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byType(FCircularProgress)),
      findsOneWidget,
    );
    expect(tester.widget<FButton>(button).onPress, isNull);
    expect(find.text('Choose a team to continue.'), findsNothing);

    serverReply.complete();
    await tester.pumpAndSettle();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('a double tap on Lock in opens one sheet', (tester) async {
    await openPick(tester);
    await tester.tap(find.text('Lock in pick'));
    await tester.tap(find.text('Lock in pick'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(PickConfirmationSheet), findsOneWidget);
  });

  testWidgets('a double tap on Confirm pick sends one pick', (tester) async {
    await openPick(tester);
    await tester.tap(find.text('Lock in pick'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm pick'));
    await tester.tap(find.text('Confirm pick'), warnIfMissed: false);
    await settleSheet(tester);
    // The second tap must not close the pick screen behind the sheet.
    expect(find.byType(PickScreen), findsOneWidget);
    expect(posts, hasLength(1));

    serverReply.complete();
    await tester.pumpAndSettle();
    expect(posts, hasLength(1));
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('a refresh alone does not claim to be saving a pick', (
    tester,
  ) async {
    await openPick(tester);
    final api = tester.widget<PickScreen>(find.byType(PickScreen)).api;
    final refresh = api.refresh();
    await tester.pump();
    expect(find.text('Saving pick…'), findsNothing);
    expect(find.text('Lock in pick'), findsOneWidget);
    await refresh;
    await tester.pumpAndSettle();
  });
}
