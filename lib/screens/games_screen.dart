import 'package:flutter/material.dart';

import '../models/game_list.dart';
import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'pick_screen.dart';
import 'game_screen.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key, required this.api});
  final BetSafeApi api;
  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  bool? simulation;
  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final state = api.state!;
    final isDemo = simulation ?? !state.nfl.configured;
    final games = gamesForSource(state.games, simulation: isDemo);
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hey, ${state.playerName}',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Ready to make your call?', style: text.bodySmall),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: BetSafeColors.mint,
              foregroundColor: BetSafeColors.green,
              child: Icon(Icons.person_outline),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SportsPanel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.toll, size: 18, color: BetSafeColors.green),
                  SizedBox(width: 8),
                  Text(
                    'Demo balance',
                    style: TextStyle(color: BetSafeColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${state.coins} virtual coins',
                style: text.headlineSmall?.copyWith(
                  color: BetSafeColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: BetSafeColors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${state.dailyRemaining} of ${state.dailyLimit} coins left to stake today',
                      style: const TextStyle(
                        fontSize: 12,
                        color: BetSafeColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BetSafeColors.brown,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Big calls.\nZero cash.',
                      style: text.headlineSmall?.copyWith(
                        color: BetSafeColors.cream,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All the game-day feeling.\nOnly virtual coins.',
                      style: TextStyle(color: Color(0xFFE7D3C1), height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const FieldArtwork(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'NFL matchups',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text('${games.length} games', style: text.bodySmall),
          ],
        ),

        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('NFL schedule'),
              selected: !isDemo,
              onSelected: (_) => setState(() => simulation = false),
            ),
            ChoiceChip(
              label: const Text('Demo games'),
              selected: isDemo,
              onSelected: (_) => setState(() => simulation = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isDemo
              ? 'Simulation · sample games, scores and payouts.'
              : state.nfl.description,
          style: text.bodySmall,
        ),
        if (!isDemo && games.isEmpty)
          const EmptyMessage(
            title: 'No NFL games available',
            message: 'Try refreshing the schedule, or choose Demo games to try the full pick flow.',
            icon: Icons.sports_football_outlined,
          ),
        const SizedBox(height: 16),
        for (final section in groupGames(games)) ...[
          Semantics(
            header: true,
            child: Text(
              section.title,
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          for (final game in section.games) ...[
            MatchTicket(
              game: game,
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    game.isSimulation
                        ? '2× demo return · virtual coins only'
                        : '2× virtual-coin return · no real-money odds',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BetSafeColors.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: api.busy
                        ? null
                        : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  state.pickFor(game.id) == null && game.canPick
                                  ? PickScreen(api: api, gameId: game.id)
                                  : GameScreen(api: api, gameId: game.id),
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: BetSafeColors.darkBrown,
                      foregroundColor: BetSafeColors.cream,
                    ),
                    child: Text(
                      state.pickFor(game.id) == null && game.canPick
                          ? 'Make a pick'
                          : 'View game',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
        ],
        Text(
          'No deposits. No cash-outs. Collectibles have no cash value.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}
