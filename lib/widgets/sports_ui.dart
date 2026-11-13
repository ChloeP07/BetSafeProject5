import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/demo_state.dart';
import '../models/game_status.dart';
import '../models/game_time.dart';
import '../models/nfl_teams.dart';
import '../theme.dart';
import 'glass.dart';

/// The team's abbreviation: the server's when it sends one, then the known
/// NFL code, then the name's initials ("?" for a blank name).
String nflTeamCode(String team, [String provided = '']) {
  if (provided.trim().isNotEmpty) return provided.trim().toUpperCase();
  final short = team.trim().split(' ').last;
  return _teams[short]?.$1 ?? teamCode(team);
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
    this.heroTag,
  });
  final String team;
  final double size;
  final String? code, logoUrl;
  final Color ring;

  /// When set, the badge flies between pages that show the same team of the
  /// same game, such as from a game card to its pick page.
  final Object? heroTag;

  /// The hero tag for one side of a game, shared by every page that shows it.
  static String heroFor(Game game, {required bool home}) =>
      'team-${game.id}-${home ? 'home' : 'away'}';

  factory TeamBadge.forGame(
    Game game, {
    required bool home,
    double size = 48,
  }) => TeamBadge(
    team: home ? game.home : game.away,
    code: home ? game.homeAbbreviation : game.awayAbbreviation,
    logoUrl: home ? game.homeLogoUrl : game.awayLogoUrl,
    size: size,
    heroTag: heroFor(game, home: home),
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
    // The initials sit under the logo, so they show while it loads and stay if
    // it never does.
    Widget logo(String url, Widget Function() fallback) => Stack(
      fit: StackFit.expand,
      children: [
        initials,
        Image.network(
          url,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
          frameBuilder: (context, child, frame, synchronous) =>
              frame == null && !synchronous
              ? const SizedBox.shrink()
              : ColoredBox(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(size * .10),
                    child: child,
                  ),
                ),
          errorBuilder: (_, _, _) => fallback(),
        ),
      ],
    );
    final badge = Semantics(
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
    return heroTag == null ? badge : Hero(tag: heroTag!, child: badge);
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

  /// A Forui badge in this pill's own colors.
  @override
  Widget build(BuildContext context) => FBadge(
    style: .delta(
      decoration: .boxDelta(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: background),
      ),
      labelTextStyle: .delta(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
    child: Text(label),
  );
}

/// Status pill colored by what the game's status means for the player.
class GameStatusPill extends StatelessWidget {
  const GameStatusPill({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (game.tone) {
      GameTone.open => (BetSafeColors.green, BetSafeColors.mint),
      GameTone.live => (BetSafeColors.onAccent, BetSafeColors.yellow),
      GameTone.waiting => (BetSafeColors.lossInk, BetSafeColors.loss),
      GameTone.finished => (BetSafeColors.muted, BetSafeColors.soft),
    };
    return StatusPill(game.statusLabel, color: color, background: background);
  }
}

/// A frosted-glass panel. White (the default) or [BetSafeColors.soft] is
/// plain glass; any other [color] tints it, such as mint for a win.
class SportsPanel extends StatelessWidget {
  const SportsPanel({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  /// Makes the whole panel tappable. Screen readers skip this, so a tappable
  /// panel needs its own button for the same action.
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GlassPanel(
    radius: 24,
    padding: padding,
    tint: color == Colors.white || color == BetSafeColors.soft ? null : color,
    onTap: onTap,
    child: child,
  );
}

class MatchTicket extends StatelessWidget {
  const MatchTicket({
    super.key,
    required this.game,
    this.footer,
    this.color = Colors.white,
    this.onTap,
    this.onTeamTap,
    this.selectedTeam,
  });
  final Game game;
  final Widget? footer;
  final Color color;
  final VoidCallback? onTap;

  /// Lets a tap on either team choose it. The pick screen's team options give
  /// screen readers the same action, so this stays out of their way.
  final ValueChanged<String>? onTeamTap;
  final String? selectedTeam;

  VoidCallback? _tapFor(String team) =>
      onTeamTap == null ? null : () => onTeamTap!(team);

  @override
  Widget build(BuildContext context) {
    // A game that never got a score, such as a postponed one, stays "VS". A live
    // game keeps its score line, because its first points are on the way.
    final showScore =
        game.status != 'scheduled' &&
        (game.status == 'live' ||
            game.awayScore != null ||
            game.homeScore != null);
    final text = Theme.of(context).textTheme;
    final countdown = game.canPick && game.kickoff != null
        ? kickoffCountdown(game.kickoff!)
        : null;
    return SportsPanel(
      color: color,
      onTap: onTap,
      child: Column(
        children: [
          // One description for the whole matchup. The footer keeps its own
          // buttons and text, so it stays outside this.
          Semantics(
            container: true,
            label: game.matchupDescription,
            child: ExcludeSemantics(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_football, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'NFL',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 12),
                      // A long status wraps inside its pill on narrow screens.
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GameStatusPill(game: game),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _TeamColumn(
                          game: game,
                          home: false,
                          won: game.winner == game.away,
                          picked: selectedTeam == game.away,
                          onTap: _tapFor(game.away),
                        ),
                      ),
                      // At large text sizes a score such as "14 : 10" can be
                      // wider than the ticket. It shrinks to a third of the
                      // row instead of pushing the teams off the edge.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width / 3,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              children: [
                                Text(
                                  showScore
                                      ? '${game.awayScore ?? '–'} : ${game.homeScore ?? '–'}'
                                      : 'VS',
                                  style: text.headlineSmall?.copyWith(
                                    color: BetSafeColors.ink,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (showScore) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    game.status == 'live'
                                        ? (game.isSimulation
                                              ? '4th quarter'
                                              : 'Live score')
                                        : game.isTied
                                        ? 'Tied'
                                        : game.status == 'final'
                                        ? 'Final score'
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
                        ),
                      ),
                      Expanded(
                        child: _TeamColumn(
                          game: game,
                          home: true,
                          won: game.winner == game.home,
                          picked: selectedTeam == game.home,
                          onTap: _tapFor(game.home),
                        ),
                      ),
                    ],
                  ),
                  if (!game.isSimulation) ...[
                    const SizedBox(height: 16),
                    Text(
                      game.kickoffLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: BetSafeColors.muted,
                      ),
                    ),
                    if (countdown != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        countdown,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BetSafeColors.ink,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          if (footer != null) ...[
            const SizedBox(height: 20),
            const Divider(height: 1, color: BetSafeColors.line),
            const SizedBox(height: 16),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.game,
    required this.home,
    required this.won,
    required this.picked,
    required this.onTap,
  });
  final Game game;
  final bool home, won, picked;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      excludeFromSemantics: true,
      child: Column(
        children: [
          TeamBadge.forGame(game, home: home),
          const SizedBox(height: 10),
          Text(
            home ? game.home : game.away,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: won ? FontWeight.w900 : FontWeight.w700,
              height: 1.25,
              // Set directly, because the Material above resets inherited text
              // styles to the theme's.
              color: won || picked ? BetSafeColors.green : BetSafeColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            picked ? 'Your pick' : (home ? 'Home' : 'Away'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: picked ? FontWeight.w700 : null,
              color: picked ? BetSafeColors.green : BetSafeColors.muted,
            ),
          ),
          if (won) ...[
            const SizedBox(height: 4),
            // Wraps instead of overflowing when the column is narrow.
            const Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Icon(Icons.emoji_events, size: 14, color: BetSafeColors.green),
                Text(
                  'Winner',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: BetSafeColors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
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
                color: Color(0xFFF3F0EA),
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
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF245B43),
    );
    final paint = Paint()
      ..color = const Color(0x59DCEACD)
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
