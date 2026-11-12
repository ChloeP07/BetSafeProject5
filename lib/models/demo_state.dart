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
    this.awayAbbreviation = '',
    this.homeAbbreviation = '',
    this.awayLogoUrl,
    this.homeLogoUrl,
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
    awayAbbreviation: json['awayAbbreviation'] as String? ?? '',
    homeAbbreviation: json['homeAbbreviation'] as String? ?? '',
    awayLogoUrl: json['awayLogoUrl'] as String?,
    homeLogoUrl: json['homeLogoUrl'] as String?,
    kickoff: DateTime.tryParse(json['kickoff'] as String? ?? ''),
  );
  final String id, home, away, status, label;
  final int? homeScore, awayScore;
  final String source, awayAbbreviation, homeAbbreviation;
  final String? awayLogoUrl, homeLogoUrl;
  final DateTime? kickoff;
  bool get isSimulation => source != 'balldontlie';
  bool get canPick =>
      status == 'scheduled' &&
      (isSimulation || (kickoff?.isAfter(DateTime.now()) ?? false));
  String get kickoffLabel {
    if (kickoff == null) return label;
    final local = kickoff!.toLocal();
    return '${local.month}/${local.day} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} local';
  }
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
      playerName = json['account']['name'] as String? ?? 'Player',
      dailyLimit = json['account']['dailyLimit'] as int,
      coins = json['account']['coins'] as int,
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
  String? get description {
    if (!configured) return 'NFL games are unavailable. Try Demo games.';
    if (error != null || stale) {
      return 'Scores may be out of date. Try refreshing.';
    }
    if (fetchedAt == null) return 'Checking for NFL games…';
    return null;
  }
}
