/**
 * Account usage (rate limits), taken only from data Claude Code itself
 * hands to the status line on stdin (`rate_limits.five_hour`,
 * `rate_limits.seven_day`). See https://code.claude.com/docs/en/statusline
 *
 * oh-my-clawd never reads or uses Claude Code's OAuth token. Anthropic's
 * terms reserve subscription OAuth for Claude Code and Claude.ai, so a
 * third-party tool calling the API with it (or refreshing it) is not
 * allowed. The trade-off: usage updates only while Claude Code is in use,
 * and only for Pro / Max subscribers (Claude Code omits the field otherwise).
 *
 * The HUD writes what it receives to ~/.claude/pet/usage-cache.json; the
 * menu bar app and the aggregator only read that file.
 */

import { paths } from './paths.mjs';
import { readJsonSync, writeJsonAtomicSync } from './fsutil.mjs';

function clampPercent(v) {
  if (v == null || !Number.isFinite(v)) return null;
  return Math.max(0, Math.min(100, v));
}

/** Unix seconds (statusline) or an ISO string → ISO string. */
function toIso(v) {
  if (v == null || v === '') return null;
  const d = typeof v === 'number' ? new Date(v * 1000) : new Date(v);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

/**
 * Normalize the statusline `rate_limits` object into the cache's `data`
 * shape. Returns null when Claude Code sent no usage (API-key users, or
 * before the session's first response).
 */
export function usageFromStatusline(stdin) {
  const rl = stdin?.rate_limits;
  if (!rl || typeof rl !== 'object') return null;
  const five = clampPercent(rl.five_hour?.used_percentage);
  const week = clampPercent(rl.seven_day?.used_percentage);
  if (five == null && week == null) return null;
  return {
    fiveHourPercent: five,
    weeklyPercent: week,
    fiveHourResetsAt: toIso(rl.five_hour?.resets_at),
    weeklyResetsAt: toIso(rl.seven_day?.resets_at),
    models: [],
  };
}

export function readUsageCache() {
  const cache = readJsonSync(paths.usageCache);
  if (!cache || typeof cache.timestamp !== 'number') return null;
  return cache;
}

/**
 * Record the statusline's usage. A window absent from this update keeps its
 * previous value only until its own reset time (Claude Code drops windows
 * once they reset).
 */
export function recordStatuslineUsage(stdin, { now = Date.now(), sessionId = null } = {}) {
  const fresh = usageFromStatusline(stdin);
  if (!fresh) return null;
  const prev = readUsageCache()?.data ?? null;
  const stillValid = (iso) => iso && Date.parse(iso) > now;
  const data = { ...fresh };
  if (data.fiveHourPercent == null && prev && stillValid(prev.fiveHourResetsAt)) {
    data.fiveHourPercent = prev.fiveHourPercent;
    data.fiveHourResetsAt = prev.fiveHourResetsAt;
  }
  if (data.weeklyPercent == null && prev && stillValid(prev.weeklyResetsAt)) {
    data.weeklyPercent = prev.weeklyPercent;
    data.weeklyResetsAt = prev.weeklyResetsAt;
  }
  try {
    writeJsonAtomicSync(paths.usageCache, { timestamp: now, data, error: false, source: 'statusline', sessionId });
  } catch {}
  return data;
}

/** Usage for display: this run's statusline data, else the last recorded. */
export function currentUsage(stdin, opts = {}) {
  return recordStatuslineUsage(stdin, opts) ?? readUsageCache()?.data ?? null;
}
