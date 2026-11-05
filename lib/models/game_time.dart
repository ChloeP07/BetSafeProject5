const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _clock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// Kickoff in the phone's time zone, such as "Today · 7:20 PM" or
/// "Sun 11/8 · 1:00 PM".
String friendlyKickoff(DateTime kickoff, {DateTime? now}) {
  final local = kickoff.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  // Compare calendar dates in UTC so a daylight-saving change cannot shift them.
  final days = DateTime.utc(local.year, local.month, local.day)
      .difference(DateTime.utc(current.year, current.month, current.day))
      .inDays;
  final day = switch (days) {
    0 => 'Today',
    1 => 'Tomorrow',
    -1 => 'Yesterday',
    _ => '${_weekdays[local.weekday - 1]} ${local.month}/${local.day}',
  };
  return '$day · ${_clock(local)}';
}
