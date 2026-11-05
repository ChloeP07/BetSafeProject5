import 'package:betsafeproject5/models/nfl_teams.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lists all 32 teams with unique abbreviations', () {
    expect(nflTeamCodes, hasLength(32));
    expect(nflTeamCodes.values.toSet(), hasLength(32));
  });

  test('teamCode tells apart teams that share a city', () {
    expect(teamCode('New York Giants'), 'NYG');
    expect(teamCode('New York Jets'), 'NYJ');
    expect(teamCode('Los Angeles Rams'), 'LAR');
    expect(teamCode('Los Angeles Chargers'), 'LAC');
  });

  test('teamCode handles unknown and blank names', () {
    expect(teamCode('Springfield Atoms'), 'SA');
    expect(teamCode('   '), '?');
    expect(teamCode(''), '?');
  });

  test('teamShortName gives the everyday name', () {
    expect(teamShortName('Buffalo Bills'), 'Bills');
    expect(teamShortName('San Francisco 49ers'), '49ers');
    expect(teamShortName(''), '');
  });
}
