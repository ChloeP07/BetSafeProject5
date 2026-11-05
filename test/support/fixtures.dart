import 'dart:convert';

import 'package:betsafeproject5/models/demo_state.dart';
import 'package:betsafeproject5/services/betsafe_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A real-feed game in the shape the server sends.
Map<String, dynamic> nflGameJson({
  String id = 'bdl-1',
  String away = 'Kansas City Chiefs',
  String home = 'Buffalo Bills',
  String status = 'scheduled',
  DateTime? kickoff,
  int? awayScore,
  int? homeScore,
}) => {
  'id': id,
  'source': 'balldontlie',
  'away': away,
  'home': home,
  'status': status,
  'label': 'NFL · $status',
  'kickoff': (kickoff ?? DateTime.now().add(const Duration(days: 2)))
      .toUtc()
      .toIso8601String(),
  'awayScore': awayScore,
  'homeScore': homeScore,
};

/// A simulation game in the shape the server sends.
Map<String, dynamic> demoGameJson({
  String id = 'demo-1',
  String away = 'Kansas City Chiefs',
  String home = 'Buffalo Bills',
  String status = 'scheduled',
  int awayScore = 0,
  int homeScore = 0,
}) => {
  'id': id,
  'away': away,
  'home': home,
  'status': status,
  'label': 'Demo matchup',
  'awayScore': awayScore,
  'homeScore': homeScore,
};

Map<String, dynamic> pickJson({
  String gameId = 'demo-1',
  String team = 'Buffalo Bills',
  int stake = 100,
  String status = 'pending',
  int payout = 0,
}) => {
  'gameId': gameId,
  'team': team,
  'stake': stake,
  'status': status,
  'payout': payout,
};

/// A full `/api/state` snapshot.
Map<String, dynamic> stateJson({
  List<Map<String, dynamic>>? games,
  List<Map<String, dynamic>> picks = const [],
  String name = 'Demo player',
  int coins = 1000,
  int dailyLimit = 500,
  int dailyStaked = 0,
  Map<String, dynamic>? nfl,
}) => {
  'account': {
    'name': name,
    'coins': coins,
    'dailyLimit': dailyLimit,
    'dailyStaked': dailyStaked,
  },
  'games': games ?? [demoGameJson()],
  'picks': picks,
  'collection': <Map<String, dynamic>>[],
  'nfl': ?nfl,
};

/// `nfl` block for a working feed.
Map<String, dynamic> nflOk() => {
  'configured': true,
  'source': 'BALLDONTLIE',
  'fetchedAt': DateTime.now().toUtc().toIso8601String(),
  'stale': false,
  'error': null,
  'refreshSeconds': 60,
};

DemoState demoState(Map<String, dynamic> json) => DemoState.fromJson(json);

Game gameFrom(Map<String, dynamic> json) => Game.fromJson(json);

/// An API client that always answers with [json], counting requests in [onRequest].
BetSafeApi apiWith(
  Map<String, dynamic> json, {
  void Function(http.Request request)? onRequest,
}) => BetSafeApi(
  client: MockClient((request) async {
    onRequest?.call(request);
    return http.Response(jsonEncode(json), 200);
  }),
);
