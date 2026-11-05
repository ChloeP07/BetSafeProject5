import 'package:flutter/material.dart';

import '../models/demo_state.dart';
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
    final text = Theme.of(context).textTheme;
    return SportsPanel(
      color: color,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.sports_football, size: 16),
              const SizedBox(width: 6),
              const Text('NFL', style: TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              StatusPill(
                scheduled
                    ? (game.isSimulation ? 'Demo matchup' : 'Scheduled')
                    : game.status == 'live'
                    ? (game.isSimulation ? 'Simulation · live' : 'In progress')
                    : (game.isSimulation ? 'Simulation · final' : game.status),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _TeamColumn(team: game.away)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Text(
                      scheduled
                          ? 'VS'
                          : '${game.awayScore ?? '–'} : ${game.homeScore ?? '–'}',
                      style: text.headlineSmall?.copyWith(
                        color: BetSafeColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      scheduled
                          ? 'Away / Home'
                          : game.status == 'live'
                          ? (game.isSimulation ? '4th quarter' : 'Live score')
                          : game.status == 'final'
                          ? 'Final score'
                          : 'Score',
                      style: const TextStyle(
                        color: BetSafeColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _TeamColumn(team: game.home)),
            ],
          ),
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
  const _TeamColumn({required this.team});
  final String team;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      TeamBadge(team: team),
      const SizedBox(height: 10),
      Text(
        team,
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
