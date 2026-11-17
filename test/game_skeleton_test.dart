import 'dart:async';
import 'dart:convert';

import 'package:betsafeproject5/main.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:betsafeproject5/widgets/game_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets('placeholder cards show until the first response arrives', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final api = BetSafeApi(client: MockClient((_) => response.future));
    addTearDown(api.dispose);
    await tester.pumpWidget(BetSafeApp(api: api));
    await tester.pump();
    expect(find.byType(GameListSkeleton), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    response.complete(http.Response(jsonEncode(stateJson()), 200));
    await tester.pumpAndSettle();
    expect(find.byType(GameListSkeleton), findsNothing);
    expect(find.text('1,000'), findsOneWidget);
  });

  testWidgets('placeholder cards hold still when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: ForuiTestApp(home: Scaffold(body: GameListSkeleton())),
      ),
    );
    // Settling would time out if the pulse kept running.
    await tester.pumpAndSettle();
    expect(find.byType(GameListSkeleton), findsOneWidget);
  });

  testWidgets('placeholder cards are announced once, as loading', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const ForuiTestApp(home: Scaffold(body: GameListSkeleton())),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Loading games'), findsOneWidget);
    semantics.dispose();
  });
}
