import 'dart:async';

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/demo_state.dart';
import '../models/game_list.dart';
import '../models/game_status.dart';
import '../models/game_time.dart';
import '../models/pick_rules.dart';
import '../services/betsafe_api.dart';
import '../theme.dart';
import '../widgets/shared.dart';
import '../widgets/sports_ui.dart';
import 'game_screen.dart';
import 'pick_screen.dart';

const _ink = BetSafeColors.ink;
const _yellow = BetSafeColors.yellow;
const _paper = BetSafeColors.paper;
const _muted = BetSafeColors.muted;
const _lightMuted = Color(0xffcfc9be);
const _border = Color(0xFFE2DCD2);

TextStyle _type(double size, double weight, [Color color = _ink]) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  color: color,
  fontVariations: [FontVariation('wght', weight)],
);

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key, required this.api});
  final BetSafeApi api;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  DateTime? selectedDay;
  bool? demo;
  GameFilter filter = GameFilter.all;
  final search = TextEditingController();
  bool showFinished = false;
  late final Timer clock;

  @override
  void initState() {
    super.initState();
    // Keeps kickoff countdowns and "Updated N min ago" current.
    clock = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clock.cancel();
    search.dispose();
    super.dispose();
  }

  /// Switches the list (a day or Demo) and starts it with no filters.
  void _showList({DateTime? day, required bool isDemo}) => setState(() {
    demo = isDemo;
    if (day != null) selectedDay = day;
    filter = GameFilter.all;
    search.clear();
    showFinished = false;
  });

  void _clearFilters() => setState(() {
    filter = GameFilter.all;
    search.clear();
  });

  void _open(Game game, {String? team}) {
    final api = widget.api;
    if (api.busy) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => api.state!.pickFor(game.id) == null && game.canPick
            ? PickScreen(api: api, gameId: game.id, initialTeam: team)
            : GameScreen(api: api, gameId: game.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = widget.api;
    final state = api.state!;
    final now = DateTime.now();
    final nfl = gamesForSource(state.games, simulation: false)
      ..sort((a, b) => (a.kickoff ?? now).compareTo(b.kickoff ?? now));
    final featured = nfl
        .where((game) => game.canPick && (game.kickoff?.isAfter(now) ?? false))
        .firstOrNull;
    final remaining = nfl.where((game) => game.id != featured?.id).toList();
    final days = {
      for (final game in remaining)
        if (game.kickoff != null) DateUtils.dateOnly(game.kickoff!.toLocal()),
    }.toList()..sort();
    final isDemo = demo ?? !state.nfl.configured;
    final activeDay = days.contains(selectedDay)
        ? selectedDay
        : days
                  .where((day) => !day.isBefore(DateUtils.dateOnly(now)))
                  .firstOrNull ??
              days.lastOrNull;
    final listGames = isDemo
        ? gamesForSource(state.games, simulation: true)
        : (remaining
              .where(
                (game) =>
                    game.kickoff == null ||
                    DateUtils.isSameDay(game.kickoff!.toLocal(), activeDay),
              )
              .toList()
            ..sort(compareGames));
    final searched = listGames
        .where((game) => matchesTeamSearch(game, search.text))
        .toList();
    final shown = searched.where(filter.matches).toList();
    final sections = groupGames(shown);
    // Finished games fold away only when other games are on screen. A search or
    // the Final filter is asking for them, so those keep them open.
    final canCollapse =
        sections.length > 1 &&
        filter != GameFilter.finished &&
        search.text.trim().isEmpty;
    final summary = gameSummary(listGames, state.picks);
    final walletNotice = noStakeMessage(
      coins: state.coins,
      dailyRemaining: state.dailyRemaining,
    );

    Widget ticket(Game game, {bool hero = false}) => _GameCard(
      game: game,
      featured: hero,
      pick: state.pickFor(game.id),
      now: now,
      onOpen: api.busy ? null : (team) => _open(game, team: team),
    );

    return ColoredBox(
      color: _paper,
      child: RefreshIndicator(
        color: _ink,
        onRefresh: api.refresh,
        child: PageBody(
          children: [
            // At large text sizes the coin chip moves below the greeting
            // instead of pushing it off the screen.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FAvatar.raw(
                      size: 42,
                      child: Text(
                        state.playerName.trim().isEmpty
                            ? 'P'
                            : state.playerName
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                        style: _type(18, 800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hey,', style: _type(13, 600, _muted)),
                          Text(state.playerName, style: _type(18, 800)),
                        ],
                      ),
                    ),
                  ],
                ),
                _CoinChip(state: state),
              ],
            ),
            if (walletNotice != null) ...[
              const SizedBox(height: 12),
              _Notice(icon: Icons.info_outline, message: walletNotice),
            ],
            if (!isDemo && featured != null) ...[
              const SizedBox(height: 18),
              ticket(featured, hero: true),
            ],
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 4,
              children: [
                Text('More this week', style: _type(20, 800)),
                if (!isDemo && state.nfl.fetchedAt != null)
                  Text(
                    updatedAgo(state.nfl.fetchedAt!, now: now),
                    style: _type(11, 600, _muted),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final day in days)
                    _ToggleButton(
                      label:
                          '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1]} ${day.month}/${day.day}',
                      selected: !isDemo && DateUtils.isSameDay(activeDay, day),
                      onPress: () => _showList(day: day, isDemo: false),
                    ),
                  _ToggleButton(
                    label: 'Demo',
                    selected: isDemo,
                    onPress: () => _showList(isDemo: true),
                  ),
                ],
              ),
            ),
            if (!isDemo && state.nfl.hasProblem) ...[
              const SizedBox(height: 12),
              _Notice(
                icon: Icons.cloud_off,
                message:
                    state.nfl.description ??
                    'Scores may be out of date. Try refreshing.',
                action: 'Try again',
                onAction: api.busy ? null : api.refresh,
              ),
            ] else if (isDemo) ...[
              const SizedBox(height: 10),
              Text(
                'Simulation · sample games, scores and payouts.',
                style: _type(12, 600, _muted),
              ),
            ],
            if (listGames.isNotEmpty) ...[
              const SizedBox(height: 14),
              FTextField(
                control: .managed(
                  controller: search,
                  onChange: (_) => setState(() {}),
                ),
                hint: 'Search teams',
                textInputAction: TextInputAction.search,
                prefixBuilder: (context, style, variants) => const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: Icon(Icons.search, size: 20, color: _muted),
                ),
                clearable: (value) => value.text.isNotEmpty,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in GameFilter.values)
                    _ToggleButton(
                      label:
                          '${option.label} · ${searched.where(option.matches).length}',
                      selected: filter == option,
                      onPress: () => setState(() => filter = option),
                      trailingGap: false,
                    ),
                ],
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(summary, style: _type(12, 600, _muted)),
              ],
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _yellow,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (listGames.isEmpty)
                    _EmptyList(
                      title: isDemo
                          ? 'No demo games available'
                          : featured == null
                          ? 'No NFL games available'
                          : 'No more games this week',
                      message: isDemo
                          ? 'Restart the demo server to bring back the sample games.'
                          : 'Pull down to refresh, or choose Demo to try the full pick flow.',
                    )
                  else if (shown.isEmpty)
                    _EmptyList(
                      title: 'No games match',
                      message: 'Try a different team or filter, or clear them to see every game.',
                      action: 'Clear filters',
                      onAction: _clearFilters,
                    ),
                  for (final (index, section) in sections.indexed) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        6,
                        index == 0 ? 2 : 14,
                        0,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              header: true,
                              child: Text(section.title, style: _type(15, 800)),
                            ),
                          ),
                          if (canCollapse && section.tone == GameTone.finished)
                            // Flexible, so at large text sizes the label wraps
                            // instead of pushing the button off the screen.
                            Flexible(
                              child: FButton(
                                variant: .ghost,
                                size: .lg,
                                mainAxisSize: .min,
                                onPress: () => setState(
                                  () => showFinished = !showFinished,
                                ),
                                child: ButtonLabel(
                                  showFinished
                                      ? 'Hide'
                                      : 'Show ${gameCountLabel(section.games.length)}',
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!canCollapse ||
                        showFinished ||
                        section.tone != GameTone.finished)
                      for (final (gameIndex, game)
                          in section.games.indexed) ...[
                        if (gameIndex > 0) const SizedBox(height: 10),
                        ticket(game),
                      ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No deposits. No cash-outs. Collectibles have no cash value.',
              textAlign: TextAlign.center,
              style: _type(11, 600, _muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// A Forui button that shows whether it is the chosen one, for the day picker
/// and the status filters. Large, so it meets the 48-pixel touch target.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onPress,
    this.trailingGap = true,
  });
  final String label;
  final bool selected;
  final VoidCallback onPress;
  final bool trailingGap;

  @override
  Widget build(BuildContext context) {
    final button = FButton(
      variant: selected ? .primary : .outline,
      size: .lg,
      mainAxisSize: .min,
      selected: selected,
      onPress: onPress,
      child: ButtonLabel(label),
    );
    return trailingGap
        ? Padding(padding: const EdgeInsets.only(right: 8), child: button)
        : button;
  }
}

/// A Forui alert with an optional action, such as Try again.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FAlert(icon: Icon(icon), title: Text(message)),
      if (action != null) ...[
        const SizedBox(height: 8),
        FButton(
          variant: .outline,
          size: .lg,
          onPress: onAction,
          child: ButtonLabel(action!),
        ),
      ],
    ],
  );
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final String title, message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _type(16, 800)),
          const SizedBox(height: 4),
          Text(message, style: _type(13, 600, _muted)),
          if (action != null) ...[
            const SizedBox(height: 12),
            FButton(size: .lg, onPress: onAction, child: ButtonLabel(action!)),
          ],
        ],
      ),
    ),
  );
}

class _CoinChip extends StatelessWidget {
  const _CoinChip({required this.state});
  final DemoState state;

  @override
  Widget build(BuildContext context) {
    final progress = state.dailyLimit > 0
        ? (state.dailyRemaining / state.dailyLimit).clamp(0.0, 1.0)
        : 0.0;
    return Container(
      constraints: const BoxConstraints(minHeight: 42),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 27,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  color: _yellow,
                  backgroundColor: const Color(0xff695043),
                  strokeWidth: 2,
                ),
                const Icon(Icons.toll_outlined, color: _yellow, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(context).formatDecimal(state.coins),
                  style: _type(15, 800, Colors.white),
                  semanticsLabel: '${state.coins} virtual coins',
                ),
                Text(
                  '${state.dailyRemaining} left today',
                  style: _type(11, 600, _lightMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.featured,
    required this.pick,
    required this.now,
    required this.onOpen,
  });
  final Game game;
  final bool featured;
  final Pick? pick;
  final DateTime now;
  final void Function(String?)? onOpen;

  @override
  Widget build(BuildContext context) {
    final away = _Club.fromGame(game, home: false);
    final home = _Club.fromGame(game, home: true);
    final kickoff = game.kickoff?.toLocal();
    final time = kickoff == null
        ? null
        : MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(kickoff));
    final timeParts = time?.split(' ');
    final until = kickoff?.difference(now);
    final foreground = featured ? Colors.white : _ink;
    final muted = featured ? _lightMuted : _muted;
    final canOpenPick = game.canPick && pick == null;
    final isFinal = game.status == 'final';
    final isLive = game.status == 'live';
    final hasScore = game.awayScore != null && game.homeScore != null;
    final closed = pick == null && !isFinal ? game.closedReason : null;
    final radius = BorderRadius.circular(featured ? 28 : 18);

    // The big middle line: a score once there is one, otherwise the kickoff.
    final headline = isFinal
        ? (hasScore ? '${game.awayScore} : ${game.homeScore}' : 'Game ended')
        : isLive
        ? '${game.awayScore ?? '–'} : ${game.homeScore ?? '–'}'
        : (timeParts?.first ?? (game.isSimulation ? 'Demo' : 'TBD'));
    final caption = isFinal
        ? (game.isTied ? 'Tied' : 'Final')
        : isLive
        ? 'Live'
        : game.tone == GameTone.waiting
        ? game.statusLabel
        : (timeParts?.length ?? 0) > 1
        ? (featured && home.name.contains(' ')
              ? '${timeParts!.last} · @ ${home.name.substring(0, home.name.lastIndexOf(' '))}'
              : timeParts!.last)
        : null;

    // On the dark featured card, buttons use the yellow accent.
    Widget action(_Club club) {
      final picked = pick?.team == club.name;
      return Expanded(
        child: FButton(
          variant: picked || featured ? .secondary : .primary,
          size: .lg,
          onPress: onOpen == null || (!canOpenPick && !picked)
              ? null
              : () => onOpen!(club.name),
          prefix: picked
              ? const Icon(Icons.check, size: 16)
              : _TeamDot(color: club.color),
          child: ButtonLabel(
            picked ? '${club.code} picked' : 'Pick ${club.code}',
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      // The whole card opens the game. Screen readers use the buttons instead.
      child: InkWell(
        borderRadius: radius,
        onTap: onOpen == null ? null : () => onOpen!(null),
        excludeFromSemantics: true,
        child: FCard(
          clipBehavior: Clip.antiAlias,
          style: .delta(
            decoration: .boxDelta(
              color: featured ? _ink : Colors.white,
              borderRadius: radius,
              border: Border.all(color: featured ? _ink : _border),
            ),
          ),
          child: Column(
            children: [
              if (!featured)
                Row(
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: away.color,
                        child: const SizedBox(height: 5),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: home.color,
                        child: const SizedBox(height: 5),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.all(featured ? 18 : 12),
                child: Column(
                  children: [
                    Semantics(
                      container: true,
                      label: game.matchupDescription,
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            if (featured && kickoff != null) ...[
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Text(
                                    '${MaterialLocalizations.of(context).formatFullDate(kickoff).split(',').first.toUpperCase()} · NFL',
                                    style: _type(
                                      12,
                                      800,
                                      _yellow,
                                    ).copyWith(letterSpacing: 1.2),
                                  ),
                                  StatusPill(
                                    until == null || until.isNegative
                                        ? 'Kickoff now'
                                        : 'Kickoff in ${until.inHours}h ${until.inMinutes % 60}m',
                                    color: _lightMuted,
                                    background: const Color(0xff493326),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: away.badge(
                                    foreground,
                                    featured: featured,
                                    won: game.winner == away.name,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      left: 4,
                                      right: 4,
                                      top: featured ? 17 : 14,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          headline,
                                          textAlign: TextAlign.center,
                                          style: _type(
                                            featured ? 34 : 18,
                                            900,
                                            foreground,
                                          ),
                                        ),
                                        if (caption != null)
                                          Text(
                                            caption,
                                            textAlign: TextAlign.center,
                                            style: _type(11, 600, muted),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: home.badge(
                                    foreground,
                                    featured: featured,
                                    won: game.winner == home.name,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (closed != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        closed,
                        textAlign: TextAlign.center,
                        style: _type(12, 600, muted),
                      ),
                    ],
                    const SizedBox(height: 14),
                    if (!isFinal && (canOpenPick || pick != null))
                      Row(
                        children: [
                          action(away),
                          const SizedBox(width: 8),
                          action(home),
                        ],
                      )
                    else
                      FButton(
                        variant: featured
                            ? .secondary
                            : isFinal
                            ? .primary
                            : .outline,
                        size: .lg,
                        onPress: onOpen == null ? null : () => onOpen!(null),
                        child: ButtonLabel(isFinal ? 'See score' : 'View game'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small dot in the team's color, shown in its Pick button.
class _TeamDot extends StatelessWidget {
  const _TeamDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
  );
}

class _Club {
  const _Club(this.name, this.code, this.color, this.logo);
  final String name, code;
  final Color color;
  final String? logo;

  factory _Club.fromGame(Game game, {required bool home}) {
    final name = home ? game.home : game.away;
    return _Club(
      name,
      nflTeamCode(name, home ? game.homeAbbreviation : game.awayAbbreviation),
      nflTeamColor(name),
      home ? game.homeLogoUrl : game.awayLogoUrl,
    );
  }

  Widget badge(Color foreground, {required bool featured, bool won = false}) =>
      Column(
        children: [
          TeamBadge(
            team: name,
            code: code,
            logoUrl: logo,
            size: featured ? 64 : 52,
          ),
          const SizedBox(height: 6),
          Text(
            featured ? name : name.split(' ').last,
            textAlign: TextAlign.center,
            style: _type(12, won ? 900 : 700, foreground),
          ),
          if (won)
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 3,
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 13,
                  color: featured ? _yellow : BetSafeColors.green,
                ),
                Text(
                  'Winner',
                  style: _type(
                    11,
                    800,
                    featured ? _yellow : BetSafeColors.green,
                  ),
                ),
              ],
            ),
        ],
      );
}
