import 'dart:async';
import 'dart:convert';

import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support/fixtures.dart';

/// A client that answers every request with [status] and [body].
BetSafeApi answering(int status, String body) =>
    BetSafeApi(client: MockClient((_) async => http.Response(body, status)));

/// Refreshes once and returns the message the player would see.
Future<String?> errorAfterRefresh(BetSafeApi api) async {
  addTearDown(api.dispose);
  expect(await api.refresh(), isFalse);
  return api.error;
}

void main() {
  test(
    'a proxy error page names the server problem, not the connection',
    () async {
      final api = answering(502, '<html><h1>502 Bad Gateway</h1></html>');
      expect(await errorAfterRefresh(api), ApiMessages.serverProblem(502));
      expect(api.error, contains('error 502'));
      expect(api.error, isNot(contains('reach')));
    },
  );

  test('a server error with its own message shows that message', () async {
    final api = answering(
      500,
      jsonEncode({'error': 'Server error. Please try again.'}),
    );
    expect(await errorAfterRefresh(api), 'Server error. Please try again.');
  });

  test('a rejection keeps the server’s reason', () async {
    final api = answering(
      409,
      jsonEncode({'error': 'Picks close at kickoff.'}),
    );
    expect(await errorAfterRefresh(api), 'Picks close at kickoff.');
  });

  test('a rejection without a reason says the request failed', () async {
    final api = answering(404, 'Not found');
    expect(await errorAfterRefresh(api), ApiMessages.requestFailed);
  });

  test('a success that is not JSON is called unreadable', () async {
    final api = answering(200, '<html>Welcome</html>');
    expect(await errorAfterRefresh(api), ApiMessages.unreadable);
  });

  test('JSON with missing fields is called unreadable', () async {
    final api = answering(
      200,
      jsonEncode({
        'account': {'name': 'Demo'},
      }),
    );
    expect(await errorAfterRefresh(api), ApiMessages.unreadable);
  });

  test('no connection says to check the connection', () async {
    final api = BetSafeApi(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await errorAfterRefresh(api), ApiMessages.offline);
  });

  test('anything else gets a general message instead of escaping', () async {
    final api = BetSafeApi(
      client: MockClient((_) async => throw const FileSystemExceptionLike()),
    );
    expect(await errorAfterRefresh(api), ApiMessages.unexpected);
    expect(api.busy, isFalse);
  });

  testWidgets('a server that never answers is called slow', (tester) async {
    final api = BetSafeApi(
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.dispose);
    final result = api.refresh();
    await tester.pump(const Duration(seconds: 11));
    expect(await result, isFalse);
    expect(api.error, ApiMessages.slow);
  });

  test('a good reply after a failure clears the message', () async {
    var fail = true;
    final api = BetSafeApi(
      client: MockClient(
        (_) async => fail
            ? http.Response('<html>502</html>', 502)
            : http.Response(jsonEncode(stateJson()), 200),
      ),
    );
    addTearDown(api.dispose);
    await api.refresh();
    expect(api.error, isNotNull);
    fail = false;
    expect(await api.refresh(), isTrue);
    expect(api.error, isNull);
    expect(api.state, isNotNull);
  });
}

/// An exception that is neither a timeout nor a client error.
class FileSystemExceptionLike implements Exception {
  const FileSystemExceptionLike();
}
