import 'game_time.dart';

class Game {
  const Game({
    required this.id,
    required this.home,
    required this.away,
    required this.status,
    required this.label,
    required this.homeScore,
    required this.awayScore,
    this.source = 'simulation',
    this.kickoff,
  });
  factory Game.fromJson(Map<String, dynamic> json) => Game(
    id: json['id'] as String,
    home: json['home'] as String,
    away: json['away'] as String,
    status: json['status'] as String,
    label: json['label'] as String,
    homeScore: json['homeScore'] as int?,
    awayScore: json['awayScore'] as int?,
    source: json['source'] as String? ?? 'simulation',
    kickoff: DateTime.tryParse(json['kickoff'] as String? ?? ''),
  );
  final String id, home, away, status, label;
  final int? homeScore, awayScore;
  final String source;
  final DateTime? kickoff;
  bool get isSimulation => source != 'balldontlie';
  bool get canPick =>
      status == 'scheduled' &&
      (isSimulation || (kickoff?.isAfter(DateTime.now()) ?? false));
  String get kickoffLabel =>
      kickoff == null ? label : friendlyKickoff(kickoff!);
}

class Pick {
  const Pick({
    required this.gameId,
    required this.team,
    required this.stake,
    required this.status,
    required this.payout,
  });
  factory Pick.fromJson(Map<String, dynamic> json) => Pick(
    gameId: json['gameId'] as String,
    team: json['team'] as String,
    stake: json['stake'] as int,
    status: json['status'] as String,
    payout: json['payout'] as int,
  );
  final String gameId, team, status;
  final int stake, payout;
}

class Collectible {
  const Collectible({
    required this.team,
    required this.name,
    required this.rarity,
  });
  factory Collectible.fromJson(Map<String, dynamic> json) => Collectible(
    team: json['team'] as String,
    name: json['name'] as String,
    rarity: json['rarity'] as String,
  );
  final String team, name, rarity;
}

class DemoState {
  DemoState.fromJson(Map<String, dynamic> json)
    : nfl = NflStatus.fromJson(json['nfl'] as Map<String, dynamic>? ?? {}),
      playerName = json['account']['name'] as String? ?? 'Demo player',
      coins = json['account']['coins'] as int,
      dailyLimit = json['account']['dailyLimit'] as int,
      dailyRemaining =
          (json['account']['dailyLimit'] as int) -
          (json['account']['dailyStaked'] as int),
      games = (json['games'] as List)
          .map((item) => Game.fromJson(item as Map<String, dynamic>))
          .toList(),
      picks = (json['picks'] as List)
          .map((item) => Pick.fromJson(item as Map<String, dynamic>))
          .toList(),
      collection = (json['collection'] as List)
          .map((item) => Collectible.fromJson(item as Map<String, dynamic>))
          .toList();
  final NflStatus nfl;
  final String playerName;
  final int coins, dailyLimit, dailyRemaining;
  final List<Game> games;
  final List<Pick> picks;
  final List<Collectible> collection;
  Pick? pickFor(String gameId) {
    for (final pick in picks) {
      if (pick.gameId == gameId) return pick;
    }
    return null;
  }
}

class NflStatus {
  NflStatus.fromJson(Map<String, dynamic> json)
    : configured = json['configured'] as bool? ?? false,
      stale = json['stale'] as bool? ?? false,
      fetchedAt = DateTime.tryParse(json['fetchedAt'] as String? ?? ''),
      error = json['error'] as String?;
  final bool configured, stale;
  final DateTime? fetchedAt;
  final String? error;

  /// True when a configured feed failed or its data has gone out of date.
  bool get hasProblem => configured && (stale || error != null);

  String get description {
    if (!configured) {
      return 'NFL data is not configured. Add the API key to the server’s .env file.';
    }
    if (error != null) return error!;
    if (fetchedAt == null) return 'NFL schedule has not been fetched yet.';
    final time = fetchedAt!.toLocal();
    return 'BALLDONTLIE · fetched ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} local${stale ? ' · may be out of date' : ' · refreshes every minute'}';
  }
}
