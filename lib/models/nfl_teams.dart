/// Abbreviations for the 32 NFL teams, keyed by the full name the server sends.
const nflTeamCodes = <String, String>{
  'Arizona Cardinals': 'ARI',
  'Atlanta Falcons': 'ATL',
  'Baltimore Ravens': 'BAL',
  'Buffalo Bills': 'BUF',
  'Carolina Panthers': 'CAR',
  'Chicago Bears': 'CHI',
  'Cincinnati Bengals': 'CIN',
  'Cleveland Browns': 'CLE',
  'Dallas Cowboys': 'DAL',
  'Denver Broncos': 'DEN',
  'Detroit Lions': 'DET',
  'Green Bay Packers': 'GB',
  'Houston Texans': 'HOU',
  'Indianapolis Colts': 'IND',
  'Jacksonville Jaguars': 'JAX',
  'Kansas City Chiefs': 'KC',
  'Las Vegas Raiders': 'LV',
  'Los Angeles Chargers': 'LAC',
  'Los Angeles Rams': 'LAR',
  'Miami Dolphins': 'MIA',
  'Minnesota Vikings': 'MIN',
  'New England Patriots': 'NE',
  'New Orleans Saints': 'NO',
  'New York Giants': 'NYG',
  'New York Jets': 'NYJ',
  'Philadelphia Eagles': 'PHI',
  'Pittsburgh Steelers': 'PIT',
  'San Francisco 49ers': 'SF',
  'Seattle Seahawks': 'SEA',
  'Tampa Bay Buccaneers': 'TB',
  'Tennessee Titans': 'TEN',
  'Washington Commanders': 'WAS',
};

List<String> _words(String team) =>
    team.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

/// The team's abbreviation. Unknown names use their initials, and a blank name
/// gives "?" so a bad record can never break a card.
String teamCode(String team) {
  final known = nflTeamCodes[team.trim()];
  if (known != null) return known;
  final words = _words(team);
  if (words.isEmpty) return '?';
  return words.take(3).map((word) => word[0]).join().toUpperCase();
}

/// The everyday name, such as "Bills" for "Buffalo Bills".
String teamShortName(String team) {
  final words = _words(team);
  return words.isEmpty ? team : words.last;
}
