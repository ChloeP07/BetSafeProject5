import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/demo_state.dart';

String get defaultApiUrl {
  const configured = String.fromEnvironment('API_BASE_URL');
  if (configured.isNotEmpty) return configured;
  return !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';
}

/// What the player is told when a request to the server fails, one message per
/// kind of failure, each with what to do next.
abstract final class ApiMessages {
  /// No answer at all: no network, or the server is not running.
  static const offline =
      'Can’t reach the BetSafe server. Check your connection, then try again.';

  /// The server took longer than 10 seconds.
  static const slow =
      'The BetSafe server is taking too long to answer. Try again in a moment.';

  /// The server answered, but not with data the app can read.
  static const unreadable =
      'The BetSafe server sent a reply the app couldn’t read. Try again in a moment.';

  /// Any other failure.
  static const unexpected =
      'Something went wrong talking to the BetSafe server. Try again in a moment.';

  /// A request the server turned down without saying why.
  static const requestFailed = 'Request failed. Please try again.';

  /// The server, or something in front of it, failed with a 5xx error.
  static String serverProblem(int status) =>
      'The BetSafe server had a problem (error $status). Try again in a moment.';
}

// The server is the source of truth. Screens never calculate or award balances.
class BetSafeApi extends ChangeNotifier {
  BetSafeApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? defaultApiUrl;
  final http.Client _client;
  final String baseUrl;
  DemoState? state;
  bool busy = false;
  String? error;

  Future<bool> refresh() => _request('GET', '/api/state');
  Future<bool> placePick(String gameId, String team, int stake) => _request(
    'POST',
    '/api/picks',
    {'gameId': gameId, 'team': team, 'stake': stake},
  );
  Future<bool> advance(String gameId) => _request(
    'POST',
    '/api/demo/games/${Uri.encodeComponent(gameId)}/advance',
  );

  /// Clears a shown error, for example once the player has changed the
  /// choice that caused it. Does nothing while a request is running.
  void clearError() {
    if (busy || error == null || _disposed) return;
    error = null;
    notifyListeners();
  }

  bool _disposed = false;
  Future<bool> _request(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    if (busy || _disposed) return false;
    busy = true;
    error = null;
    notifyListeners();
    // Each kind of failure gets its own message, so the player is not told the
    // server is unreachable when it answered with something else.
    try {
      final uri = Uri.parse('$baseUrl$path');
      final response =
          await (method == 'GET'
                  ? _client.get(uri)
                  : _client.post(
                      uri,
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode(body ?? {}),
                    ))
              .timeout(const Duration(seconds: 10));
      final data = _jsonObject(response.body);
      if (response.statusCode >= 400) {
        error = switch (data?['error']) {
          final String message => message,
          _ when response.statusCode >= 500 => ApiMessages.serverProblem(
            response.statusCode,
          ),
          _ => ApiMessages.requestFailed,
        };
        return false;
      }
      if (data == null) {
        error = ApiMessages.unreadable;
        return false;
      }
      state = DemoState.fromJson(data);
      return true;
    } on TimeoutException {
      error = ApiMessages.slow;
      return false;
    } on http.ClientException {
      error = ApiMessages.offline;
      return false;
    } on TypeError {
      // A JSON reply that is missing fields or has the wrong types.
      error = ApiMessages.unreadable;
      return false;
    } on Exception {
      error = ApiMessages.unexpected;
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  /// The body as a JSON object, or null when it is not one, such as the HTML
  /// error page a proxy sends.
  static Map<String, dynamic>? _jsonObject(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }
}
