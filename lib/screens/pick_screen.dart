import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/game_status.dart';
import '../models/nfl_teams.dart';
import '../models/pick_errors.dart';
import '../models/pick_rules.dart';
import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/balance_preview.dart';
import '../widgets/daily_limit_bar.dart';
import '../widgets/payout_figure.dart';
import '../widgets/pick_confirmation_sheet.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import '../widgets/stake_selector.dart';
import '../widgets/team_option_card.dart';
import 'game_screen.dart';

class PickScreen extends StatefulWidget {
  const PickScreen({super.key, required this.api, required this.gameId});
  final BetSafeApi api;
  final String gameId;
  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  String? team;

  /// The stake the player tapped. The screen uses it while it fits the
  /// balance and today's limit, and falls back to a stake that does.
  int? _chosenStake;

  /// Keeps the kickoff countdown current between server refreshes.
  late final Timer _ticker;

  /// True once this screen has taken charge of moving on to the game view, so
  /// it can never open that view twice.
  bool _leaving = false;

  /// True while the confirmed pick is on its way to the server.
  bool _sending = false;

  /// True when the error on screen came from this screen's last submission.
  bool _submissionFailed = false;

  /// Clears a failed submission's error once the player changes their pick,
  /// since it no longer describes what they have chosen.
  void _clearSubmissionError() {
    if (!_submissionFailed) return;
    _submissionFailed = false;
    widget.api.clearError();
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  /// Selects a team. A second tap on the chosen team clears the choice.
  void _choose(String option) {
    final selecting = team != option;
    if (selecting) HapticFeedback.selectionClick();
    _clearSubmissionError();
    setState(() => team = selecting ? option : null);
  }

  void _showGame() => Navigator.of(context).pushReplacement(
    MaterialPageRoute<void>(
      builder: (_) => GameScreen(api: widget.api, gameId: widget.gameId),
    ),
  );

  /// Asks for confirmation, then sends the pick.
  ///
  /// [_leaving] stays set from the first tap until the pick fails or the
  /// player goes back, so a pick arriving by refresh while the sheet is open
  /// cannot open the game view a second time.
  Future<void> _lockIn(int stake) async {
    if (_leaving) return;
    _leaving = true;
    final chosen = team!;
    final confirmed = await showPickConfirmation(
      context,
      team: chosen,
      stake: stake,
      coins: widget.api.state!.coins,
    );
    if (!mounted) return;
    if (!confirmed) {
      // A pick that arrived meanwhile is picked up by the next build.
      setState(() => _leaving = false);
      return;
    }
    setState(() {
      _sending = true;
      _submissionFailed = false;
    });
    final success = await widget.api.placePick(widget.gameId, chosen, stake);
    if (!mounted) return;
    if (success) {
      _showGame();
    } else {
      setState(() {
        _sending = false;
        _leaving = false;
        _submissionFailed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.api,
    builder: (context, _) {
      final api = widget.api;
      final state = api.state!;
      final game = state.gameById(widget.gameId);
      if (game == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Make your pick')),
          body: SafeArea(
            child: PageBody(
              children: [
                const EmptyMessage(
                  title: 'This game is no longer available',
                  message: 'It has dropped off the schedule, so there is nothing to pick here.',
                  icon: Icons.event_busy,
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to games'),
                ),
              ],
            ),
          ),
        );
      }
      final text = Theme.of(context).textTheme;
      final picked = state.pickFor(widget.gameId) != null;
      final stake = validStake(
        _chosenStake,
        coins: state.coins,
        dailyRemaining: state.dailyRemaining,
      );
      final block = pickBlock(
        game: game,
        picked: picked,
        team: team,
        stake: stake,
        coins: state.coins,
        dailyRemaining: state.dailyRemaining,
      );
      final stakeMessage = stakeProblemMessage(
        block,
        stake: stake,
        coins: state.coins,
        dailyRemaining: state.dailyRemaining,
      );
      // A pick that arrives from elsewhere, such as a refresh, ends this form.
      if (picked && !_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showGame();
        });
      }
      final locked = api.busy || picked || !game.canPick;
      return Scaffold(
        appBar: AppBar(title: const Text('Make your pick')),
        body: SafeArea(
          child: PageBody(
            children: [
              MatchTicket(
                game: game,
                color: BetSafeColors.clay,
                selectedTeam: team,
                onTeamTap: locked ? null : _choose,
              ),
              if (game.closedReason case final reason?) ...[
                const SizedBox(height: 16),
                _ClosedNotice(
                  reason: reason,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ],
              const SizedBox(height: 28),
              Text(
                'Who takes the win?',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Choose your team. Keep it virtual.'),
              if (!game.isSimulation) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Picks close at kickoff.',
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              for (final (option, side) in [
                (game.away, 'Away team'),
                (game.home, 'Home team'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TeamOptionCard(
                    team: option,
                    side: side,
                    selected: team == option,
                    onTap: locked ? null : () => _choose(option),
                  ),
                ),
              if (team case final chosen?)
                Semantics(
                  container: true,
                  liveRegion: true,
                  child: Text(
                    'You’re backing the ${teamShortName(chosen)}',
                    style: text.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Your stake',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              StakeSelector(
                selected: stake,
                onChanged: locked
                    ? null
                    : (value) {
                        _clearSubmissionError();
                        setState(() => _chosenStake = value);
                      },
                isAllowed: (value) => canAffordStake(
                  value,
                  coins: state.coins,
                  dailyRemaining: state.dailyRemaining,
                ),
                caption: stakeCaption(
                  coins: state.coins,
                  dailyRemaining: state.dailyRemaining,
                ),
              ),
              if (stake != null) ...[
                const SizedBox(height: 20),
                SportsPanel(
                  color: BetSafeColors.mint,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'If your team wins',
                        style: TextStyle(color: BetSafeColors.green),
                      ),
                      const SizedBox(height: 8),
                      PayoutFigure(
                        coins: stake * 2,
                        style: text.headlineSmall?.copyWith(
                          color: BetSafeColors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Includes your $stake-coin stake. Lose: your stake is spent. Demo payout: 2×, not real betting odds.',
                        style: const TextStyle(
                          color: BetSafeColors.muted,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SportsPanel(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BalancePreview(coins: state.coins, stake: stake),
                    const SizedBox(height: 12),
                    DailyLimitBar(
                      remaining: state.dailyRemaining,
                      limit: state.dailyLimit,
                    ),
                  ],
                ),
              ),
              if (stakeMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(stakeMessage)),
                      ],
                    ),
                  ),
                ),
              if (api.error != null)
                ServerError(
                  message: friendlyPickError(api.error!),
                  onRetry: api.busy ? null : () => api.refresh(),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    api.busy || _leaving || block != null || stake == null
                    ? null
                    : () => _lockIn(stake),
                child: _sending
                    ? const _SavingLabel()
                    : const Text('Lock in pick'),
              ),
              if (api.busy ? null : lockInHint(block) case final hint?) ...[
                const SizedBox(height: 8),
                Text(hint, textAlign: TextAlign.center, style: text.bodySmall),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A small spinner and "Saving pick…" for inside the Lock in button.
class _SavingLabel extends StatelessWidget {
  const _SavingLabel();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox.square(
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DefaultTextStyle.of(context).style.color,
        ),
      ),
      const SizedBox(width: 12),
      const Flexible(child: Text('Saving pick…')),
    ],
  );
}

/// Explains why a game closed while the player was choosing.
class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.reason, required this.onBack});
  final String reason;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: SportsPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(reason)),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              foregroundColor: BetSafeColors.brown,
            ),
            child: const Text('Back to games'),
          ),
        ],
      ),
    ),
  );
}
