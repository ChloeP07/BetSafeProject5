import 'dart:async';

import 'package:flutter/material.dart';

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
                    CircleAvatar(
                      radius: 21,
                      backgroundColor: _ink,
                      child: Text(
                        state.playerName.trim().isEmpty
                            ? 'P'
                            : state.playerName
                                  .trim()
                                  .substring(0, 1)
                                  .toUpperCase(),
                        style: _type(18, 800, _yellow),
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
                    _DayButton(
                      title: const [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ][day.weekday - 1],
                      date: '${day.month}/${day.day}',
                      selected: !isDemo && DateUtils.isSameDay(activeDay, day),
                      onTap: () => _showList(day: day, isDemo: false),
                    ),
                  _DayButton(
                    title: 'Demo',
                    selected: isDemo,
                    onTap: () => _showList(isDemo: true),
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
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  labelText: 'Search teams',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(search.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                      selectedColor: _ink,
                      checkmarkColor: _yellow,
                      backgroundColor: Colors.white,
                      labelStyle: _type(
                        13,
                        700,
                        filter == option ? Colors.white : _ink,
                      ),
                      onSelected: (_) => setState(() => filter = option),
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
                            TextButton(
                              onPressed: () =>
                                  setState(() => showFinished = !showFinished),
                              style: TextButton.styleFrom(
                                foregroundColor: _ink,
                                minimumSize: const Size(48, 40),
                              ),
                              child: Text(
                                showFinished
                                    ? 'Hide'
                                    : 'Show ${gameCountLabel(section.games.length)}',
                                style: _type(13, 800),
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

/// A short message with an icon, and an optional action such as Try again.
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
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _ink),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: _type(13, 600))),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: _ink,
                minimumSize: const Size(48, 44),
              ),
              child: Text(action!, style: _type(13, 800)),
            ),
        ],
      ),
    ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: _type(16, 800)),
        const SizedBox(height: 4),
        Text(message, style: _type(13, 600, _muted)),
        if (action != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
            ),
            child: Text(action!),
          ),
        ],
      ],
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

class _DayButton extends StatelessWidget {
  const _DayButton({
    required this.title,
    this.date,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String? date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: Semantics(
      selected: selected,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected ? _ink : Colors.white,
          minimumSize: const Size(64, 58),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: onTap,
        child: Column(
          children: [
            Text(title, style: _type(13, 800, selected ? _yellow : _ink)),
            if (date != null)
              Text(
                date!,
                style: _type(11, 600, selected ? Colors.white : _muted),
              ),
          ],
        ),
      ),
    ),
  );
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

    Widget action(_Club club) {
      final picked = pick?.team == club.name;
      return Expanded(
        child: FilledButton(
          onPressed: onOpen == null || (!canOpenPick && !picked)
              ? null
              : () => onOpen!(club.name),
          style: FilledButton.styleFrom(
            backgroundColor: club.color,
            foregroundColor: Colors.white,
            minimumSize: Size(0, featured ? 48 : 44),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(featured ? 14 : 12),
            ),
            side: picked ? const BorderSide(color: _yellow, width: 2) : null,
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              if (picked) const Icon(Icons.check, size: 14, color: _yellow),
              Text(
                picked ? '${club.code} picked' : 'Pick ${club.code}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Material(
      color: featured ? _ink : Colors.white,
      borderRadius: BorderRadius.circular(featured ? 28 : 17),
      clipBehavior: Clip.antiAlias,
      // The whole card opens the game. Screen readers use the buttons instead.
      child: InkWell(
        onTap: onOpen == null ? null : () => onOpen!(null),
        excludeFromSemantics: true,
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff493326),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: _lightMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          until == null || until.isNegative
                                              ? 'Kickoff now'
                                              : 'Kickoff in ${until.inHours}h ${until.inMinutes % 60}m',
                                          style: _type(11, 600, _lightMuted),
                                        ),
                                      ),
                                    ],
                                  ),
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
                  else if (isFinal)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onOpen == null ? null : () => onOpen!(null),
                        style: FilledButton.styleFrom(
                          backgroundColor: featured ? _yellow : _ink,
                          foregroundColor: featured ? _ink : Colors.white,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'See score',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onOpen == null ? null : () => onOpen!(null),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                        ),
                        child: Text(
                          'View game',
                          style: _type(13, 800, foreground),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
