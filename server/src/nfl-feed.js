const ENDPOINT = 'https://api.balldontlie.io/nfl/v1/games';
const MINUTE = 60_000;

export function normalizeGame(raw) {
  const kickoff = Date.parse(raw.date);
  if (!Number.isInteger(raw.id) || !raw.home_team?.full_name || !raw.visitor_team?.full_name || !Number.isFinite(kickoff)) {
    throw new Error('Invalid game record');
  }
  const statuses = { scheduled: 'scheduled', in_progress: 'live', final: 'final',
    postponed: 'postponed', canceled: 'canceled', delayed: 'delayed', suspended: 'suspended', abandoned: 'abandoned' };
  const status = statuses[raw.status_state] ?? 'unknown';
  const score = (value) => Number.isInteger(value) && value >= 0 ? value : null;
  return {
    id: `bdl-${raw.id}`, source: 'balldontlie', home: raw.home_team.full_name, away: raw.visitor_team.full_name,
    homeAbbreviation: raw.home_team.abbreviation ?? '', awayAbbreviation: raw.visitor_team.abbreviation ?? '',
    status, kickoff: new Date(kickoff).toISOString(),
    label: status === 'scheduled' ? 'NFL · scheduled' : `NFL · ${status}`,
    homeScore: score(raw.home_team_score), awayScore: score(raw.visitor_team_score),
  };
}

// One shared request per minute, even if several phones refresh simultaneously.
export function createNflFeed({ apiKey = '', fetchImpl = fetch, now = Date.now } = {}) {
  const configured = Boolean(apiKey.trim());
  let cache = [], fetchedAt = null, retryAt = 0, inflight = null, error = null;
  function result() {
    return { configured, source: 'BALLDONTLIE', games: cache, fetchedAt,
      stale: configured && (!fetchedAt || now() - Date.parse(fetchedAt) > 2 * MINUTE || error !== null),
      error, refreshSeconds: 60 };
  }
  async function request() {
    // A rolling window covers recent results plus upcoming games in a single call.
    const url = new URL(ENDPOINT);
    url.searchParams.set('per_page', '100');
    for (let offset = -3; offset <= 7; offset++) {
      url.searchParams.append('dates[]', new Date(now() + offset * 86_400_000).toISOString().slice(0, 10));
    }
    retryAt = now() + MINUTE;
    try {
      const response = await fetchImpl(url, { headers: { Authorization: apiKey }, signal: AbortSignal.timeout(7000) });
      if (!response.ok) {
        if (response.status === 429) {
          const retry = response.headers.get('retry-after');
          const numeric = Number(retry);
          const delay = retry && Number.isFinite(numeric) ? numeric * 1000 : Date.parse(retry) - now();
          retryAt = now() + Math.max(MINUTE, Number.isFinite(delay) ? delay : MINUTE);
        }
        error = response.status === 401 || response.status === 403
          ? 'NFL access was refused. Check the server API key and free NFL plan.'
          : response.status === 429 ? 'NFL request limit reached. Cached scores will refresh after the cooldown.'
          : 'NFL provider is unavailable. Try again shortly.';
        return result();
      }
      const body = await response.json();
      if (!Array.isArray(body.data) || body.meta?.next_cursor != null) throw new Error('Incomplete response');
      const normalized = body.data.map(normalizeGame);
      cache = normalized.sort((a, b) => a.kickoff.localeCompare(b.kickoff));
      fetchedAt = new Date(now()).toISOString();
      error = null;
    } catch (_) {
      // Never expose upstream response bodies, URLs containing credentials, or headers.
      error = 'Could not refresh NFL games. Showing the last available schedule, if any.';
    }
    return result();
  }
  return { async get() {
    if (!configured) return result();
    if (inflight) return inflight;
    if (now() < retryAt) return result();
    inflight = request();
    try { return await inflight; } finally { inflight = null; }
  } };
}
