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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        error = data['error'] as String? ?? 'Request failed. Please try again.';
        return false;
      }
      state = DemoState.fromJson(data);
      return true;
    } catch (_) {
      error = 'Cannot reach the demo server. Check that it is running and try again.';
      return false;
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _client.close();
    super.dispose();
  }
}
