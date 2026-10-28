import 'package:flutter/material.dart';

import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'game_screen.dart';

class PicksScreen extends StatelessWidget {
  const PicksScreen({super.key, required this.api});
  final BetSafeApi api;
  @override
  Widget build(BuildContext context) {
    final state = api.state!;
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text(
          'My picks',
          style: text.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text('Your calls. Your game-day story.'),
        const SizedBox(height: 20),
        Row(
          children: [
            StatusPill(
              '${state.picks.where((p) => p.status == 'pending').length} pending',
            ),
            const SizedBox(width: 8),
            StatusPill(
              '${state.picks.where((p) => p.status == 'won').length} won',
              background: BetSafeColors.clay,
              color: BetSafeColors.brown,
            ),
          ],
        ),
        if (state.picks.isEmpty)
          const EmptyMessage(
            title: 'Your first call is waiting.',
            message: 'Choose a matchup in Games and stake virtual coins to get started.',
            icon: Icons.receipt_long_outlined,
          ),
        const SizedBox(height: 20),
        for (final pick in state.picks.reversed) ...[
          MatchTicket(
            game: state.games.firstWhere((game) => game.id == pick.gameId),
            color: pick.status == 'won'
                ? BetSafeColors.mint
                : pick.status == 'lost'
                ? const Color(0xFFF0DFD5)
                : Colors.white,
            footer: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your pick',
                            style: text.bodySmall?.copyWith(
                              color: BetSafeColors.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pick.team,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${pick.stake} coins staked',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BetSafeColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusPill(
                      pick.status == 'won'
                          ? 'WIN'
                          : pick.status == 'lost'
                          ? 'LOSS'
                          : 'PENDING',
                      background: pick.status == 'lost'
                          ? BetSafeColors.clay
                          : BetSafeColors.mint,
                      color: pick.status == 'lost'
                          ? BetSafeColors.brown
                          : BetSafeColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => GameScreen(api: api, gameId: pick.gameId),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: BetSafeColors.darkBrown,
                    foregroundColor: BetSafeColors.cream,
                  ),
                  child: const Text('View pick'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
