import 'package:flutter/material.dart';

import '../models/game_list.dart';
import '../models/nfl_teams.dart';
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
  GameFilter filter = GameFilter.all;
  final search = TextEditingController();

  void _chooseSource(bool demo) => setState(() {
    simulation = demo;
    filter = GameFilter.all;
    search.clear();
  });

  void _clearFilters() => setState(() {
    filter = GameFilter.all;
    search.clear();
  });

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final state = api.state!;
    final isDemo = simulation ?? !state.nfl.configured;
    final sourceGames = gamesForSource(state.games, simulation: isDemo);
    final searched = sourceGames
        .where((game) => matchesTeamSearch(game, search.text))
        .toList();
    final games = searched.where(filter.matches).toList();
    final text = Theme.of(context).textTheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return RefreshIndicator(
      color: Theme.of(context).colorScheme.primary,
      onRefresh: api.refresh,
      child: PageBody(
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
              Text(gameCountLabel(games.length), style: text.bodySmall),
            ],
          ),

          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(
                  'NFL schedule · ${gamesForSource(state.games, simulation: false).length}',
                ),
                selected: !isDemo,
                onSelected: (_) => _chooseSource(false),
              ),
              ChoiceChip(
                label: Text(
                  'Demo games · ${gamesForSource(state.games, simulation: true).length}',
                ),
                selected: isDemo,
                onSelected: (_) => _chooseSource(true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isDemo && state.nfl.hasProblem)
            _NflProblemBanner(
              message: state.nfl.description,
              onRetry: api.busy ? null : api.refresh,
            )
          else
            Text(
              isDemo
                  ? 'Simulation · sample games, scores and payouts.'
                  : state.nfl.description,
              style: text.bodySmall,
            ),
          if (sourceGames.isNotEmpty) ...[
            const SizedBox(height: 16),
            TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Search teams',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(search.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in GameFilter.values)
                  ChoiceChip(
                    label: Text(
                      '${option.label} · ${searched.where(option.matches).length}',
                    ),
                    selected: filter == option,
                    selectedColor: BetSafeColors.mint,
                    checkmarkColor: BetSafeColors.green,
                    labelStyle: TextStyle(
                      color: filter == option ? BetSafeColors.green : onSurface,
                    ),
                    onSelected: (_) => setState(() => filter = option),
                  ),
              ],
            ),
          ],
          if (!isDemo && sourceGames.isEmpty)
            const EmptyMessage(
              title: 'No NFL games available',
              message: 'Try refreshing the schedule, or choose Demo games to try the full pick flow.',
              icon: Icons.sports_football_outlined,
            ),
          if (isDemo && sourceGames.isEmpty)
            const EmptyMessage(
              title: 'No demo games available',
              message:
                  'Restart the demo server to bring back the sample games.',
              icon: Icons.sports_football_outlined,
            ),
          if (sourceGames.isNotEmpty && games.isEmpty) ...[
            const EmptyMessage(
              title: 'No games match',
              message: 'Try a different team or filter, or clear them to see every game.',
              icon: Icons.search_off,
            ),
            OutlinedButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
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
                    if (state.pickFor(game.id) case final pick?) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: StatusPill(
                          'Your pick: ${teamShortName(pick.team)} · ${pick.stake} coins',
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
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
                                    state.pickFor(game.id) == null &&
                                        game.canPick
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
      ),
    );
  }
}

/// Says plainly that the NFL feed failed or is out of date, and offers a retry.
class _NflProblemBanner extends StatelessWidget {
  const _NflProblemBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: SportsPanel(
      color: BetSafeColors.clay,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cloud_off, size: 18, color: BetSafeColors.brown),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: BetSafeColors.brown,
              minimumSize: const Size(48, 48),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
