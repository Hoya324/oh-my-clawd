#!/usr/bin/env node
/**
 * pet-aggregator.mjs
 *
 * Background daemon (LaunchAgent) that folds every live Claude Code session
 * into ~/.claude/pet/pet-state.json for the menu bar app, and keeps the
 * long-term stats / unlocks in ~/.claude/pet/progress.json.
 *
 * Ownership (no two processes ever write the same file):
 *   pet-state.json   this daemon
 *   progress.json    this daemon
 *   selection.json   the app (read-only here, except a one-time migration)
 *
 * Pure Node.js, no npm dependencies.
 */

import { readdirSync, statSync, unlinkSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { paths } from './lib/paths.mjs';
import { readJsonSync, writeJsonAtomicSync, writeJsonExclusiveSync } from './lib/fsutil.mjs';
import { readUsageCache } from './lib/usage.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));

export const POLL_INTERVAL_MS = 3000;
export const STATE_FRESH_MS = 15 * 60_000;      // HUD state older than this = idle session
const HEARTBEAT_MS = 15_000;                     // rewrite pet-state at least this often
const USAGE_MAX_AGE_MS = 10 * 60_000;            // ignore usage cache older than this
const SESSION_FILE_TTL_MS = 7 * 24 * 60 * 60_000;
const TRACKING_TTL_MS = 7 * 24 * 60 * 60_000;
const PROCESS_START_SLACK_MS = 2 * 60_000;
const DEFAULT_CONTEXT_WINDOW = 200_000;
const RATE_LIMIT_HIT_PERCENT = 80;

const MODEL_PRIORITY = { opus: 3, sonnet: 2, haiku: 1 };
const SELECTION_KEYS = ['selectedHat', 'selectedGlasses', 'selectedPants'];

// v1 pet → v2 accessory migration map
const PET_TO_ACCESSORY = {
  hamster: 'cap', chick: 'partyHat', penguin: 'santaHat',
  fox: 'silkHat', rabbit: 'hornRimmed', goose: 'cowboyHat',
  capybara: 'sunglasses', sloth: 'roundGlasses', owl: 'starGlasses',
};
const HATS = new Set(['cap', 'partyHat', 'santaHat', 'silkHat', 'cowboyHat']);

export function loadUnlockConditions() {
  const raw = readJsonSync(join(HERE, 'unlocks.json'));
  if (!raw) throw new Error('unlocks.json missing next to pet-aggregator.mjs');
  return raw;
}

// ============================================================================
// Process verification
// ============================================================================

/**
 * Ask `ps` about several PIDs at once. Returns Map<pid, {comm, startMs}>.
 * Missing PIDs are dead. Falls back to kill(0) when ps is unavailable.
 */
export function inspectProcesses(pids, { execPs = defaultExecPs } = {}) {
  const result = new Map();
  if (pids.length === 0) return result;
  let out;
  try {
    out = execPs(pids);
  } catch {
    for (const pid of pids) {
      try { process.kill(pid, 0); result.set(pid, { comm: null, startMs: null }); } catch {}
    }
    return result;
  }
  for (const line of out.split('\n')) {
    // "  123 Fri Nov 27 17:20:01 2026 /path/to/claude"
    const m = line.match(/^\s*(\d+)\s+(\w{3}\s+\w{3}\s+\d+\s+[\d:]+\s+\d{4})\s+(.*)$/);
    if (!m) continue;
    const startMs = new Date(m[2]).getTime();
    result.set(Number(m[1]), {
      comm: m[3].trim(),
      startMs: Number.isNaN(startMs) ? null : startMs,
    });
  }
  return result;
}

function defaultExecPs(pids) {
  return execFileSync('/bin/ps', ['-o', 'pid=,lstart=,comm=', '-p', pids.join(',')], {
    encoding: 'utf8', timeout: 2000, stdio: ['ignore', 'pipe', 'ignore'],
    env: { ...process.env, LC_ALL: 'C', LANG: 'C' },
  });
}

const CLAUDE_PROCESS = /claude|(^|\/)(node|bun)[^/]*$/i;

/**
 * A session file is trusted only if its PID is alive and was not started
 * after the session — a later start means the PID was recycled by an
 * unrelated process after Claude Code exited. That timing check is decisive
 * whatever the executable is called (native installs run from
 * ~/.local/share/claude/versions/<x.y.z>). Only when the start time is
 * unknown do we fall back to the executable name.
 */
export function isLiveSession(session, procInfo) {
  if (!procInfo) return false;
  if (procInfo.startMs && session.startedAt) {
    return procInfo.startMs <= session.startedAt + PROCESS_START_SLACK_MS;
  }
  if (procInfo.comm) return CLAUDE_PROCESS.test(procInfo.comm);
  return true;
}

/** Non-interactive runs (`claude -p`, SDK) are not "sessions" for the pet. */
export function isInteractive(session) {
  if (session.kind && String(session.kind).toLowerCase() !== 'interactive') return false;
  if (session.entrypoint && /sdk|print|headless/i.test(String(session.entrypoint))) return false;
  return true;
}

// ============================================================================
// Session discovery
// ============================================================================

function readSessionFiles() {
  let entries;
  try { entries = readdirSync(paths.claudeSessionsDir); } catch { return []; }
  const out = [];
  for (const f of entries) {
    if (!f.endsWith('.json')) continue;
    const data = readJsonSync(join(paths.claudeSessionsDir, f));
    if (data && Number.isInteger(data.pid)) out.push(data);
  }
  return out;
}

function readHudStates() {
  let entries;
  try { entries = readdirSync(paths.sessionsDir); } catch { return []; }
  const out = [];
  for (const f of entries) {
    if (!f.endsWith('.json')) continue;
    const data = readJsonSync(join(paths.sessionsDir, f));
    if (data?.sessionId) out.push(data);
  }
  return out;
}

/** Keep one entry per sessionId (the most recently started one). */
export function dedupeSessions(sessions) {
  const byKey = new Map();
  for (const s of sessions) {
    const key = s.sessionId ? `id:${s.sessionId}` : `pid:${s.pid}`;
    const prev = byKey.get(key);
    if (!prev || (s.startedAt ?? 0) > (prev.startedAt ?? 0)) byKey.set(key, s);
  }
  return [...byKey.values()];
}

/**
 * Attach the HUD's per-session state to each live session.
 * Match by sessionId first; otherwise give each cwd's freshest unclaimed
 * state to at most one session, so two sessions in one project never share
 * (and double count) a single state.
 */
export function matchStates(sessions, hudStates, now = Date.now()) {
  const fresh = hudStates.filter((st) => now - (st.timestamp ?? 0) <= STATE_FRESH_MS);
  const byId = new Map(fresh.map((st) => [st.sessionId, st]));
  const claimed = new Set();
  const matched = new Map();

  for (const s of sessions) {
    if (s.sessionId && byId.has(s.sessionId)) {
      matched.set(s, byId.get(s.sessionId));
      claimed.add(s.sessionId);
    }
  }
  for (const s of sessions) {
    if (matched.has(s) || !s.cwd) continue;
    const candidate = fresh
      .filter((st) => !claimed.has(st.sessionId) && st.cwd === s.cwd)
      .sort((a, b) => b.timestamp - a.timestamp)[0];
    if (candidate) {
      matched.set(s, candidate);
      claimed.add(candidate.sessionId);
    }
  }
  return matched;
}

/** Legacy HUD (≤ v2.1.8) wrote state into <cwd>/.claude/.hud/. */
function readLegacyState(cwd, now) {
  const st = readJsonSync(join(cwd, '.claude', '.hud', 'session-state.json'));
  if (!st?.timestamp || now - st.timestamp > STATE_FRESH_MS) return null;
  return st;
}

export function estimateTokens(state) {
  if (Number.isFinite(state?.totalTokens)) return state.totalTokens;
  const window = state?.contextWindowSize || DEFAULT_CONTEXT_WINDOW;
  return Math.round(((state?.contextPercent ?? 0) / 100) * window);
}

export function buildSessionDetails(sessions, hudStates, now = Date.now(), { legacy = readLegacyState } = {}) {
  const matched = matchStates(sessions, hudStates, now);
  const legacyClaimed = new Set();
  return sessions.map((s) => {
    let st = matched.get(s) ?? null;
    if (!st && s.cwd && !legacyClaimed.has(s.cwd)) {
      st = legacy(s.cwd, now);
      if (st) legacyClaimed.add(s.cwd);
    }
    const startedAt = s.startedAt ?? now;
    return {
      key: s.sessionId ? `id:${s.sessionId}` : `pid:${s.pid}`,
      pid: s.pid,
      sessionId: s.sessionId ?? null,
      project: s.cwd ? basename(s.cwd) : 'unknown',
      cwd: s.cwd ?? null,
      hasHud: !!st,
      model: st?.model || 'unknown',
      contextPercent: st?.contextPercent ?? 0,
      toolCalls: st?.toolCalls ?? 0,
      runningAgents: st?.runningAgents ?? 0,
      sessionMinutes: st?.sessionMinutes ?? Math.max(0, Math.floor((now - startedAt) / 60_000)),
      tokens: st ? estimateTokens(st) : 0,
    };
  });
}

/** "navi-api ×2" style grouping for the popover. */
export function groupProjects(details) {
  const counts = new Map();
  for (const d of details) counts.set(d.project, (counts.get(d.project) ?? 0) + 1);
  return [...counts.entries()].map(([name, count]) => ({ name, count }));
}

// ============================================================================
// Progress
// ============================================================================

export function defaultProgress() {
  return {
    version: 3,
    stats: {
      totalSessions: 0,
      totalTimeMinutes: 0,
      totalTokens: 0,
      totalAgentRuns: 0,
      maxConcurrentSessions: 0,
      maxConcurrentAgents: 0,
      rateLimitHits: 0,
      longSessions: 0,
      opusTimeMinutes: 0,
    },
    unlockedAccessories: [],
    unlockedAt: {},
    unlockProgress: {},
    tracking: { sessions: {}, rateLimitWindow: null },
  };
}

/** Bring any older progress file up to v3 without losing data. */
export function migrateProgress(data) {
  if (!data || typeof data !== 'object' || !data.stats) return { progress: defaultProgress(), selection: null };
  const base = defaultProgress();
  const p = { ...base, ...data, stats: { ...base.stats, ...data.stats } };

  let selection = null;
  if (!data.version || data.version < 2) {
    const accessories = [];
    const unlockedAt = {};
    for (const pet of data.unlocked || []) {
      const acc = PET_TO_ACCESSORY[pet];
      if (!acc) continue;
      accessories.push(acc);
      if (data.unlockedAt?.[pet]) unlockedAt[acc] = data.unlockedAt[pet];
    }
    p.unlockedAccessories = accessories;
    p.unlockedAt = unlockedAt;
    const mapped = PET_TO_ACCESSORY[data.selectedPet];
    selection = {
      selectedHat: mapped && HATS.has(mapped) ? mapped : null,
      selectedGlasses: mapped && !HATS.has(mapped) ? mapped : null,
      selectedPants: null,
    };
    delete p.unlocked;
    delete p.selectedPet;
  } else if (SELECTION_KEYS.some((k) => k in data)) {
    selection = Object.fromEntries(SELECTION_KEYS.map((k) => [k, data[k] ?? null]));
  }
  for (const k of SELECTION_KEYS) delete p[k];

  p.version = 3;
  p.unlockedAccessories = Array.isArray(p.unlockedAccessories) ? p.unlockedAccessories : [];
  p.unlockedAt = p.unlockedAt && typeof p.unlockedAt === 'object' ? p.unlockedAt : {};
  p.tracking = {
    sessions: data.tracking?.sessions && typeof data.tracking.sessions === 'object' ? data.tracking.sessions : {},
    rateLimitWindow: data.tracking?.rateLimitWindow ?? null,
  };
  return { progress: p, selection };
}

/**
 * Accumulate stats from the current snapshot. Per-session tracking lives in
 * progress.tracking, so restarting the daemon neither drops nor double
 * counts anything.
 */
export function updateStats(progress, details, now = Date.now()) {
  const stats = progress.stats;
  const tracked = progress.tracking.sessions;

  for (const d of details) {
    const isOpus = /opus/i.test(d.model);
    const prev = tracked[d.key];
    if (!prev) {
      // First time this session is seen (new, or running before install):
      // everything it has done so far is real usage that was never counted.
      stats.totalSessions++;
      stats.totalTimeMinutes += d.sessionMinutes;
      stats.totalTokens += d.tokens;
      stats.totalAgentRuns += d.runningAgents;
      if (d.sessionMinutes >= 45) stats.longSessions++;
      if (isOpus) stats.opusTimeMinutes += d.sessionMinutes;
      tracked[d.key] = {
        lastMinutes: d.sessionMinutes,
        lastTokens: d.tokens,
        lastAgents: d.runningAgents,
        wasLong: d.sessionMinutes >= 45,
        lastSeen: now,
      };
      continue;
    }

    const dMin = d.sessionMinutes - prev.lastMinutes;
    if (dMin > 0) {
      stats.totalTimeMinutes += dMin;
      if (isOpus) stats.opusTimeMinutes += dMin;
      prev.lastMinutes = d.sessionMinutes;
    }
    const dTok = d.tokens - prev.lastTokens;
    if (dTok > 0) stats.totalTokens += dTok;
    // Track downward moves too (estimate mode after /compact) so the next
    // increase is not lost.
    prev.lastTokens = d.tokens;
    const dAgents = d.runningAgents - prev.lastAgents;
    if (dAgents > 0) stats.totalAgentRuns += dAgents;
    prev.lastAgents = d.runningAgents;
    if (d.sessionMinutes >= 45 && !prev.wasLong) {
      stats.longSessions++;
      prev.wasLong = true;
    }
    prev.lastSeen = now;
  }

  stats.maxConcurrentSessions = Math.max(stats.maxConcurrentSessions, details.length);
  const agentsNow = details.reduce((sum, d) => sum + d.runningAgents, 0);
  stats.maxConcurrentAgents = Math.max(stats.maxConcurrentAgents, agentsNow);

  for (const [key, t] of Object.entries(tracked)) {
    if (now - (t.lastSeen ?? 0) > TRACKING_TTL_MS) delete tracked[key];
  }
}

/** Count a rate-limit hit at most once per 5-hour window. */
export function checkRateLimitHit(progress, rateLimit) {
  const pct = rateLimit?.fiveHourPercent;
  if (pct == null || pct < RATE_LIMIT_HIT_PERCENT) return;
  const window = rateLimit.fiveHourResetsAt ?? 'unknown';
  if (sameWindow(progress.tracking.rateLimitWindow, window)) return;
  progress.tracking.rateLimitWindow = window;
  progress.stats.rateLimitHits++;
}

/** Reset times can jitter by seconds between API responses. */
export function sameWindow(a, b) {
  if (a == null || b == null) return false;
  if (a === b) return true;
  const ta = Date.parse(a);
  const tb = Date.parse(b);
  if (Number.isNaN(ta) || Number.isNaN(tb)) return false;
  return Math.abs(ta - tb) < 10 * 60_000;
}

export function checkUnlocks(progress, conditions, now = Date.now()) {
  const unlockedNow = [];
  progress.unlockProgress = {};
  for (const [id, cond] of Object.entries(conditions)) {
    const current = progress.stats[cond.metric] ?? 0;
    progress.unlockProgress[id] = { metric: cond.metric, current, target: cond.threshold };
    if (progress.unlockedAccessories.includes(id)) continue;
    if (current >= cond.threshold) {
      progress.unlockedAccessories.push(id);
      progress.unlockedAt[id] = new Date(now).toISOString();
      unlockedNow.push(id);
    }
  }
  return unlockedNow;
}

// ============================================================================
// Pet state
// ============================================================================

function modelPriority(model) {
  const lower = (model || '').toLowerCase();
  for (const [k, p] of Object.entries(MODEL_PRIORITY)) if (lower.includes(k)) return p;
  return 0;
}

export function pickDominantModel(models) {
  const known = models.filter((m) => m && m !== 'unknown');
  if (!known.length) return 'unknown';
  const counts = {};
  for (const m of known) counts[m] = (counts[m] || 0) + 1;
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1] || modelPriority(b[0]) - modelPriority(a[0]))[0][0];
}

export function rateLimitFromCache(cache, now = Date.now()) {
  const empty = { fiveHourPercent: null, weeklyPercent: null, fiveHourResetsAt: null, weeklyResetsAt: null };
  if (!cache?.data || now - cache.timestamp > USAGE_MAX_AGE_MS) return empty;
  return {
    fiveHourPercent: cache.data.fiveHourPercent ?? null,
    weeklyPercent: cache.data.weeklyPercent ?? null,
    fiveHourResetsAt: cache.data.fiveHourResetsAt ?? null,
    weeklyResetsAt: cache.data.weeklyResetsAt ?? null,
  };
}

export function buildPetState(details, rateLimit, now = Date.now()) {
  return {
    version: 2,
    timestamp: now,
    activeSessions: details.length,
    rateLimit,
    aggregate: {
      maxContextPercent: details.reduce((m, d) => Math.max(m, d.contextPercent), 0),
      totalToolCalls: details.reduce((s, d) => s + d.toolCalls, 0),
      totalRunningAgents: details.reduce((s, d) => s + d.runningAgents, 0),
      longestSessionMinutes: details.reduce((m, d) => Math.max(m, d.sessionMinutes), 0),
      dominantModel: pickDominantModel(details.map((d) => d.model)),
    },
    projects: groupProjects(details),
    sessions: details.map(({ key, tokens, ...rest }) => rest),
  };
}

function pruneOldSessionFiles(now) {
  let entries;
  try { entries = readdirSync(paths.sessionsDir); } catch { return; }
  for (const f of entries) {
    const p = join(paths.sessionsDir, f);
    try {
      if (now - statSync(p).mtimeMs > SESSION_FILE_TTL_MS) unlinkSync(p);
    } catch {}
  }
}

// ============================================================================
// Daemon
// ============================================================================

export function createAggregator({ conditions = loadUnlockConditions(), log = (m) => process.stderr.write(`[pet-aggregator] ${m}\n`) } = {}) {
  let lastStateJson = null;
  let lastStateWrite = 0;
  let lastProgressJson = null;
  let lastPrune = 0;

  function loadProgress() {
    const raw = readJsonSync(paths.progress);
    const { progress, selection } = migrateProgress(raw);
    if (selection && writeJsonExclusiveSync(paths.selection, selection)) {
      log('migrated accessory selection to selection.json');
    }
    return progress;
  }

  function tick(now = Date.now()) {
    const sessions = dedupeSessions(readSessionFiles().filter(isInteractive));
    const procs = inspectProcesses(sessions.map((s) => s.pid));
    const live = sessions.filter((s) => isLiveSession(s, procs.get(s.pid)));
    const details = buildSessionDetails(live, readHudStates(), now);
    const rateLimit = rateLimitFromCache(readUsageCache(), now);

    const progress = loadProgress();
    updateStats(progress, details, now);
    checkRateLimitHit(progress, rateLimit);
    for (const id of checkUnlocks(progress, conditions, now)) log(`unlocked: ${id}`);

    const progressJson = JSON.stringify(progress);
    if (progressJson !== lastProgressJson) {
      writeJsonAtomicSync(paths.progress, progress, { pretty: true });
      lastProgressJson = progressJson;
    }

    const petState = buildPetState(details, rateLimit, now);
    const { timestamp, ...comparable } = petState;
    const stateJson = JSON.stringify(comparable);
    if (stateJson !== lastStateJson || now - lastStateWrite >= HEARTBEAT_MS) {
      writeJsonAtomicSync(paths.petState, petState, { pretty: true });
      lastStateJson = stateJson;
      lastStateWrite = now;
    }

    if (now - lastPrune > 60 * 60_000) {
      pruneOldSessionFiles(now);
      lastPrune = now;
    }
    return { details, progress, petState };
  }

  return { tick };
}

export function start() {
  const aggregator = createAggregator();
  const safeTick = () => {
    try { aggregator.tick(); }
    catch (err) { process.stderr.write(`[pet-aggregator] tick error: ${err.message}\n`); }
  };
  process.stderr.write(`[pet-aggregator] started (pid=${process.pid}, interval=${POLL_INTERVAL_MS}ms)\n`);
  safeTick();
  const id = setInterval(safeTick, POLL_INTERVAL_MS);
  const shutdown = (sig) => {
    process.stderr.write(`[pet-aggregator] ${sig}, shutting down\n`);
    clearInterval(id);
    process.exit(0);
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

const isDirectRun = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/'));
if (isDirectRun) start();

