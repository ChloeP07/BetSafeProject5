class Game {
  const Game({
    required this.id,
    required this.home,
    required this.away,
    required this.status,
    required this.label,
    required this.homeScore,
    required this.awayScore,
  });
  factory Game.fromJson(Map<String, dynamic> json) => Game(
    id: json['id'] as String,
    home: json['home'] as String,
    away: json['away'] as String,
    status: json['status'] as String,
    label: json['label'] as String,
    homeScore: json['homeScore'] as int,
    awayScore: json['awayScore'] as int,
  );
  final String id, home, away, status, label;
  final int homeScore, awayScore;
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
    : coins = json['account']['coins'] as int,
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
  final int coins, dailyRemaining;
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
