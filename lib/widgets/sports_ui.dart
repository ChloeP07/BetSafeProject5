import 'package:flutter/material.dart';

import '../models/demo_state.dart';
import '../models/game_status.dart';
import '../models/game_time.dart';
import '../models/nfl_teams.dart';
import '../theme.dart';

/// Initial badges are deliberate placeholders; no unlicensed team artwork.
class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.team, this.size = 48});
  final String team;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: team,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: BetSafeColors.cream,
          shape: BoxShape.circle,
          border: Border.all(
            color: BetSafeColors.brown.withValues(alpha: .18),
            width: 2,
          ),
        ),
        child: Text(
          teamCode(team),
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: BetSafeColors.brown,
            fontSize: size * .24,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

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

/// Status pill colored by what the game's status means for the player.
class GameStatusPill extends StatelessWidget {
  const GameStatusPill({super.key, required this.game});
  final Game game;
  @override
  Widget build(BuildContext context) {
    final (color, background) = switch (game.tone) {
      GameTone.open => (BetSafeColors.green, BetSafeColors.mint),
      GameTone.live => (BetSafeColors.cream, BetSafeColors.green),
      GameTone.waiting => (BetSafeColors.brown, BetSafeColors.clay),
      GameTone.finished => (BetSafeColors.muted, BetSafeColors.cream),
    };
    return StatusPill(game.statusLabel, color: color, background: background);
  }
}

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
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(24);
    final content = DefaultTextStyle.merge(
      style: const TextStyle(color: BetSafeColors.ink),
      child: IconTheme(
        data: const IconThemeData(color: BetSafeColors.ink),
        child: child,
      ),
    );
    if (onTap == null) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(color: color, borderRadius: radius),
        child: content,
      );
    }
    return Material(
      color: color,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        excludeFromSemantics: true,
        child: Padding(padding: padding, child: content),
      ),
    );
  }
}

class MatchTicket extends StatelessWidget {
  const MatchTicket({
    super.key,
    required this.game,
    this.footer,
    this.color = Colors.white,
    this.onTap,
  });
  final Game game;
  final Widget? footer;
  final Color color;
  final VoidCallback? onTap;
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
                          team: game.away,
                          side: 'Away',
                          won: game.winner == game.away,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      Expanded(
                        child: _TeamColumn(
                          team: game.home,
                          side: 'Home',
                          won: game.winner == game.home,
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
                          color: BetSafeColors.brown,
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
  const _TeamColumn({required this.team, required this.side, this.won = false});
  final String team, side;
  final bool won;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TeamBadge(team: team),
      const SizedBox(height: 10),
      Text(
        team,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: won ? FontWeight.w900 : FontWeight.w700,
          height: 1.25,
          color: won ? BetSafeColors.green : null,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        side,
        style: const TextStyle(fontSize: 11, color: BetSafeColors.muted),
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
                color: BetSafeColors.clay,
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
