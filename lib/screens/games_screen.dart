import 'dart:async';

import 'package:flutter/material.dart';

import '../models/demo_state.dart';
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
  late final Timer clock;

  @override
  void initState() {
    super.initState();
    clock = Timer.periodic(const Duration(seconds: 15), (_) => setState(() {}));
  }

  @override
  void dispose() {
    clock.cancel();
    super.dispose();
  }

  void _open(Game game, {String? team}) {
    final api = widget.api;
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
    final nfl = state.games.where((game) => !game.isSimulation).toList()
      ..sort((a, b) => (a.kickoff ?? now).compareTo(b.kickoff ?? now));
    final featured = nfl
        .where((game) => game.canPick && (game.kickoff?.isAfter(now) ?? false))
        .firstOrNull;
    final remaining = nfl.where((game) => game.id != featured?.id).toList();
    final days = {
      for (final game in remaining)
        if (game.kickoff != null) DateUtils.dateOnly(game.kickoff!.toLocal()),
    }.toList();
    final isDemo = demo ?? !state.nfl.configured;
    final activeDay = days.contains(selectedDay)
        ? selectedDay
        : days
                  .where((day) => !day.isBefore(DateUtils.dateOnly(now)))
                  .firstOrNull ??
              days.lastOrNull;
    final games = isDemo
        ? state.games.where((game) => game.isSimulation).toList()
        : remaining
              .where(
                (game) =>
                    DateUtils.isSameDay(game.kickoff?.toLocal(), activeDay) ||
                    game.kickoff == null,
              )
              .toList();
    final age = state.nfl.fetchedAt == null
        ? null
        : now.difference(state.nfl.fetchedAt!).inMinutes.clamp(0, 99999);

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
        onRefresh: () async {
          await api.refresh();
        },
        child: PageBody(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: _ink,
                  child: Text(
                    state.playerName.trim().isEmpty
                        ? 'P'
                        : state.playerName.trim().substring(0, 1).toUpperCase(),
                    style: _type(18, 800, _yellow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hey,', style: _type(13, 600, _muted)),
                      Text(state.playerName, style: _type(18, 800)),
                    ],
                  ),
                ),
                _CoinChip(state: state),
              ],
            ),
            if (!isDemo && featured != null) ...[
              const SizedBox(height: 18),
              ticket(featured, hero: true),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(child: Text('More this week', style: _type(20, 800))),
                if (!isDemo && age != null)
                  Text(
                    age == 0 ? 'Updated just now' : 'Updated $age min ago',
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
                      onTap: () => setState(() {
                        demo = false;
                        selectedDay = day;
                      }),
                    ),
                  _DayButton(
                    title: 'Demo',
                    selected: isDemo,
                    onTap: () => setState(() => demo = true),
                  ),
                ],
              ),
            ),
            if (!isDemo && (state.nfl.stale || state.nfl.error != null)) ...[
              const SizedBox(height: 12),
              Text(
                'Scores may be out of date. Pull down to refresh.',
                style: _type(12, 600, _muted),
              ),
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
                  if (games.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text('No games to show.', style: _type(14, 600)),
                    ),
                  for (final (index, game) in games.indexed) ...[
                    if (index > 0) const SizedBox(height: 10),
                    ticket(game),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
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
          Column(
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(featured ? 28 : 17),
      child: ColoredBox(
        color: featured ? _ink : Colors.white,
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
                  if (featured) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${MaterialLocalizations.of(context).formatFullDate(kickoff!).split(',').first.toUpperCase()} · NFL',
                            style: _type(
                              12,
                              800,
                              _yellow,
                            ).copyWith(letterSpacing: 1.2),
                          ),
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
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: _lightMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                until == null || until.isNegative
                                    ? 'Kickoff now'
                                    : 'Kickoff in ${until.inHours}h ${until.inMinutes % 60}m',
                                style: _type(11, 600, _lightMuted),
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
                        child: away.badge(foreground, featured: featured),
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
                                isFinal
                                    ? 'Game ended'
                                    : isLive
                                    ? '${game.awayScore ?? '–'} : ${game.homeScore ?? '–'}'
                                    : (timeParts?.first ??
                                          (game.isSimulation ? 'Demo' : 'TBD')),
                                textAlign: TextAlign.center,
                                style: _type(
                                  isFinal ? 13 : (featured ? 34 : 18),
                                  900,
                                  isFinal ? muted : foreground,
                                ),
                              ),
                              if (!isFinal &&
                                  (isLive || (timeParts?.length ?? 0) > 1))
                                Text(
                                  isLive
                                      ? 'Live'
                                      : featured && home.name.contains(' ')
                                      ? '${timeParts!.last} · @ ${home.name.substring(0, home.name.lastIndexOf(' '))}'
                                      : timeParts!.last,
                                  textAlign: TextAlign.center,
                                  style: _type(11, 600, muted),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: home.badge(foreground, featured: featured),
                      ),
                    ],
                  ),
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
                          backgroundColor: _ink,
                          foregroundColor: Colors.white,
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
                        child: Text('View game', style: _type(13, 800)),
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

  Widget badge(Color foreground, {required bool featured}) => Column(
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
        style: _type(12, 700, foreground),
      ),
    ],
  );
}
