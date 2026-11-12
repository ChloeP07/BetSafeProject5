import 'package:flutter/material.dart';

import '../models/demo_state.dart';
import '../theme.dart';

String nflTeamCode(String team, [String provided = '']) {
  if (provided.trim().isNotEmpty) return provided.trim().toUpperCase();
  final short = team.trim().split(' ').last;
  return _teams[short]?.$1 ??
      short.substring(0, short.length.clamp(0, 3)).toUpperCase();
}

Color nflTeamColor(String team) =>
    Color(_teams[team.trim().split(' ').last]?.$2 ?? 0xff373431);

class TeamBadge extends StatelessWidget {
  const TeamBadge({
    super.key,
    required this.team,
    this.size = 48,
    this.code,
    this.logoUrl,
    this.ring = BetSafeColors.yellow,
  });
  final String team;
  final double size;
  final String? code, logoUrl;
  final Color ring;

  factory TeamBadge.forGame(
    Game game, {
    required bool home,
    double size = 48,
  }) => TeamBadge(
    team: home ? game.home : game.away,
    code: home ? game.homeAbbreviation : game.awayAbbreviation,
    logoUrl: home ? game.homeLogoUrl : game.awayLogoUrl,
    size: size,
  );

  @override
  Widget build(BuildContext context) {
    final abbreviation = nflTeamCode(team, code ?? '');
    final known = _teams[team.trim().split(' ').last]?.$1;
    final cdnCode = known == 'WAS' ? 'wsh' : known?.toLowerCase();
    final cdn = cdnCode == null
        ? null
        : 'https://a.espncdn.com/i/teamlogos/nfl/500/$cdnCode.png';
    final provided = logoUrl?.trim();
    final initials = ColoredBox(
      color: nflTeamColor(team),
      child: Center(
        child: Text(
          abbreviation,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * .24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
    Widget logo(String url, Widget Function() fallback) => Padding(
      padding: EdgeInsets.all(size * .10),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => fallback(),
      ),
    );
    return Semantics(
      label: team,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: ring, width: 2),
          ),
          child: provided != null && provided.isNotEmpty
              ? logo(
                  provided,
                  () => cdn == null || provided == cdn
                      ? initials
                      : logo(cdn, () => initials),
                )
              : cdn == null
              ? initials
              : logo(cdn, () => initials),
        ),
      ),
    );
  }
}

const _teams = {
  'Cardinals': ('ARI', 0xff97233f),
  'Falcons': ('ATL', 0xffa71930),
  'Ravens': ('BAL', 0xff241773),
  'Bills': ('BUF', 0xff00338d),
  'Panthers': ('CAR', 0xff006b91),
  'Bears': ('CHI', 0xff0b162a),
  'Bengals': ('CIN', 0xffa6360a),
  'Browns': ('CLE', 0xff311d00),
  'Cowboys': ('DAL', 0xff003594),
  'Broncos': ('DEN', 0xffa63c10),
  'Lions': ('DET', 0xff006b9a),
  'Packers': ('GB', 0xff203731),
  'Texans': ('HOU', 0xff03202f),
  'Colts': ('IND', 0xff002c5f),
  'Jaguars': ('JAX', 0xff006778),
  'Chiefs': ('KC', 0xffa8172d),
  'Raiders': ('LV', 0xff000000),
  'Chargers': ('LAC', 0xff006c96),
  'Rams': ('LAR', 0xff003594),
  'Dolphins': ('MIA', 0xff006d71),
  'Vikings': ('MIN', 0xff4f2683),
  'Patriots': ('NE', 0xff002244),
  'Saints': ('NO', 0xff5c4d35),
  'Giants': ('NYG', 0xff0b2265),
  'Jets': ('NYJ', 0xff125740),
  'Eagles': ('PHI', 0xff004c54),
  'Steelers': ('PIT', 0xff3c3014),
  '49ers': ('SF', 0xffaa0000),
  'Seahawks': ('SEA', 0xff002244),
  'Buccaneers': ('TB', 0xffb00018),
  'Titans': ('TEN', 0xff0c2340),
  'Commanders': ('WAS', 0xff5a1414),
};

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.color = BetSafeColors.green,
    this.background = BetSafeColors.mint,
  });
  final String label;
  final Color color, background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    ),
  );
}

class SportsPanel extends StatelessWidget {
  const SportsPanel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(24),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: BetSafeColors.ink),
      child: IconTheme(
        data: const IconThemeData(color: BetSafeColors.ink),
        child: child,
      ),
    ),
  );
}

class MatchTicket extends StatelessWidget {
  const MatchTicket({
    super.key,
    required this.game,
    this.footer,
    this.color = Colors.white,
  });
  final Game game;
  final Widget? footer;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final scheduled = game.status == 'scheduled';
    final isFinal = game.status == 'final';
    final awayScore = game.awayScore;
    final homeScore = game.homeScore;
    String? result;
    var hasWinner = false;
    if (isFinal && awayScore != null && homeScore != null) {
      hasWinner = awayScore != homeScore;
      if (hasWinner) {
        final winner = awayScore > homeScore ? game.away : game.home;
        result = '$winner Win';
      } else {
        result = 'Game tied';
      }
    }
    final text = Theme.of(context).textTheme;
    return SportsPanel(
      color: color,
      child: Column(
        children: [
          StatusPill(
            switch (game.status) {
              'scheduled' => game.isSimulation ? 'Demo matchup' : 'Scheduled',
              'live' => game.isSimulation ? 'Simulation · live' : 'In progress',
              'final' => game.isSimulation ? 'Simulation · Final' : 'Final',
              _ => game.status,
            },
            color: BetSafeColors.muted,
            background: BetSafeColors.soft,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TeamColumn(badge: TeamBadge.forGame(game, home: false)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: Column(
                  children: [
                    Text(
                      scheduled
                          ? 'VS'
                          : '${awayScore ?? '–'} : ${homeScore ?? '–'}',
                      style: text.headlineSmall?.copyWith(
                        color: BetSafeColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!isFinal) ...[
                      const SizedBox(height: 4),
                      Text(
                        scheduled
                            ? 'Away / Home'
                            : game.status == 'live'
                            ? (game.isSimulation ? '4th quarter' : 'Live score')
                            : 'Score',
                        style: const TextStyle(
                          color: BetSafeColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _TeamColumn(badge: TeamBadge.forGame(game, home: true)),
              ),
            ],
          ),
          if (result != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hasWinner ? BetSafeColors.mint : BetSafeColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    result,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: hasWinner
                          ? BetSafeColors.green
                          : BetSafeColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (!game.isSimulation) ...[
            const SizedBox(height: 16),
            Text(
              game.kickoffLabel,
              style: const TextStyle(fontSize: 12, color: BetSafeColors.muted),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0x22302419)),
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({required this.badge});
  final TeamBadge badge;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      badge,
      const SizedBox(height: 10),
      Text(
        badge.team,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    ],
  );
}

/// Yard markings are football-field geometry, not simulated sports statistics.
class FieldArtwork extends StatelessWidget {
  const FieldArtwork({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: _FieldPainter(),
        child: const SizedBox(
          width: 86,
          height: 112,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Icon(
                Icons.sports_football,
                size: 48,
                color: BetSafeColors.soft,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = BetSafeColors.green);
    final paint = Paint()
      ..color = BetSafeColors.mint.withValues(alpha: .35)
      ..strokeWidth = 1;
    for (double y = 12; y < size.height; y += 26) {
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), paint);
    }
    canvas.drawLine(const Offset(10, 0), Offset(10, size.height), paint);
    canvas.drawLine(
      Offset(size.width - 10, 0),
      Offset(size.width - 10, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
