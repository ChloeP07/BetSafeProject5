import 'dart:async';
import 'dart:convert';

import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A client whose every request answers with [reply].
BetSafeApi apiAnswering(Future<http.Response> Function() reply) =>
    BetSafeApi(client: MockClient((_) => reply()));

Map<String, dynamic> validState() => {
  'account': {'coins': 1000, 'dailyLimit': 500, 'dailyStaked': 100},
  'games': <Map<String, dynamic>>[],
  'picks': <Map<String, dynamic>>[],
  'collection': <Map<String, dynamic>>[],
};

void main() {
  test('reads the account as a typed map', () async {
    final api = apiAnswering(
      () async => http.Response(jsonEncode(validState()), 200),
    );
    addTearDown(api.dispose);
    expect(await api.refresh(), isTrue);
    expect(api.state!.coins, 1000);
    expect(api.state!.dailyRemaining, 400);
    expect(api.error, isNull);
  });

  test('a server that cannot be reached says so', () async {
    final api = apiAnswering(
      () async => throw http.ClientException('Connection refused'),
    );
    addTearDown(api.dispose);
    expect(await api.refresh(), isFalse);
    expect(api.error, startsWith('Cannot reach the demo server.'));
  });

  test('a reply that is not JSON is not blamed on the network', () async {
    final api = apiAnswering(
      () async => http.Response('<html>Bad gateway</html>', 200),
    );
    addTearDown(api.dispose);
    expect(await api.refresh(), isFalse);
    expect(api.error, BetSafeApi.unreadableReply);
  });

  test('a reply with a missing account is not blamed on the network', () async {
    final broken = validState()..remove('account');
    final api = apiAnswering(
      () async => http.Response(jsonEncode(broken), 200),
    );
    addTearDown(api.dispose);
    expect(await api.refresh(), isFalse);
    expect(api.error, BetSafeApi.unreadableReply);
    expect(api.state, isNull);
  });

  testWidgets('a server that stops answering times out with its own message', (
    tester,
  ) async {
    final never = Completer<http.Response>();
    final api = apiAnswering(() => never.future);
    addTearDown(api.dispose);
    final result = api.refresh();
    await tester.pump(const Duration(seconds: 11));
    expect(await result, isFalse);
    expect(api.error, startsWith('The demo server took too long to answer.'));
    expect(api.busy, isFalse);
  });
}
