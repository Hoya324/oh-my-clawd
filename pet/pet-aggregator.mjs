#!/usr/bin/env node

/**
 * pet-aggregator.mjs
 *
 * A Node.js daemon that aggregates multiple Claude Code session states
 * into a single pet state file at ~/.claude/pet/pet-state.json.
 *
 * Runs on a 3-second interval. Pure Node.js, no npm dependencies.
 */

import { readdir, readFile, writeFile, rename, mkdir } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, basename } from 'node:path';

const HOME = homedir();
const SESSIONS_DIR = join(HOME, '.claude', 'sessions');
const PET_DIR = join(HOME, '.claude', 'pet');
const PET_STATE_PATH = join(PET_DIR, 'pet-state.json');
const PET_STATE_TMP = join(PET_DIR, 'pet-state.json.tmp');

const POLL_INTERVAL_MS = 3000;
const IDLE_THRESHOLD_MS = 15 * 60_000;

const MODEL_PRIORITY = { opus: 3, sonnet: 2, haiku: 1 };

const PROGRESS_PATH = join(PET_DIR, 'progress.json');
const PROGRESS_TMP = join(PET_DIR, 'progress.json.tmp');

const UNLOCK_CONDITIONS = {
  cap:          { type: 'totalSessions', threshold: 10 },
  partyHat:     { type: 'totalTimeMinutes', threshold: 300 },
  santaHat:     { type: 'totalTokens', threshold: 500000 },
  silkHat:      { type: 'totalAgentRuns', threshold: 50 },
  cowboyHat:    { type: 'totalTimeMinutes', threshold: 1800 },
  hornRimmed:   { type: 'maxConcurrentSessions', threshold: 3 },
  sunglasses:   { type: 'rateLimitHits', threshold: 10 },
  roundGlasses: { type: 'longSessions', threshold: 20 },
  starGlasses:  { type: 'opusTimeMinutes', threshold: 600 },
  // Pants
  jeans:        { type: 'totalTimeMinutes', threshold: 900 },
  shorts:       { type: 'totalSessions', threshold: 100 },
  slacks:       { type: 'totalTokens', threshold: 1000000 },
  joggers:      { type: 'totalAgentRuns', threshold: 100 },
  cargo:        { type: 'totalTimeMinutes', threshold: 3000 },
};

// v1 pet → v2 accessory migration map
const PET_TO_ACCESSORY = {
  hamster: 'cap', chick: 'partyHat', penguin: 'santaHat',
  fox: 'silkHat', rabbit: 'hornRimmed', goose: 'cowboyHat',
  capybara: 'sunglasses', sloth: 'roundGlasses', owl: 'starGlasses',
};

function isPidAlive(pid) {
  try { process.kill(pid, 0); return true; } catch { return false; }
}

async function readJsonSafe(filePath) {
  try { return JSON.parse(await readFile(filePath, 'utf-8')); } catch { return null; }
}

function getModelPriority(model) {
  if (!model) return 0;
  const lower = model.toLowerCase();
  for (const [key, pri] of Object.entries(MODEL_PRIORITY)) {
    if (lower.includes(key)) return pri;
  }
  return 0;
}

function pickDominantModel(models) {
  if (!models.length) return 'unknown';
  const counts = {};
  for (const m of models) counts[m] = (counts[m] || 0) + 1;

  let best = null, bestCount = 0, bestPri = -1;
  for (const [model, count] of Object.entries(counts)) {
    const pri = getModelPriority(model);
    if (count > bestCount || (count === bestCount && pri > bestPri)) {
      best = model; bestCount = count; bestPri = pri;
    }
  }
  return best || 'unknown';
}

async function writeAtomicJson(data) {
  const json = JSON.stringify(data, null, 2) + '\n';
  await writeFile(PET_STATE_TMP, json, 'utf-8');
  await rename(PET_STATE_TMP, PET_STATE_PATH);
}

function defaultProgress() {
  return {
    version: 2,
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
    selectedHat: null,
    selectedGlasses: null,
    selectedPants: null,
    unlockedAt: {},
  };
}

async function loadProgress() {
  const data = await readJsonSafe(PROGRESS_PATH);
  if (!data || !data.stats) return defaultProgress();

  // Migrate v1 → v2 if needed
  if (!data.version || data.version < 2) {
    const oldUnlocked = data.unlocked || [];
    const accessories = [];
    const newUnlockedAt = {};
    for (const pet of oldUnlocked) {
      const acc = PET_TO_ACCESSORY[pet];
      if (acc) {
        accessories.push(acc);
        if (data.unlockedAt?.[pet]) newUnlockedAt[acc] = data.unlockedAt[pet];
      }
    }
    let selectedHat = null;
    let selectedGlasses = null;
    const mapped = PET_TO_ACCESSORY[data.selectedPet];
    if (mapped) {
      const hatSet = new Set(['cap', 'partyHat', 'santaHat', 'silkHat', 'cowboyHat']);
      if (hatSet.has(mapped)) selectedHat = mapped;
      else selectedGlasses = mapped;
    }
    data.version = 2;
    data.unlockedAccessories = accessories;
    data.selectedHat = selectedHat;
    data.selectedGlasses = selectedGlasses;
    data.unlockedAt = newUnlockedAt;
    delete data.unlocked;
    delete data.selectedPet;
  }

  // Ensure new fields exist (forward-compatible)
  if (data.selectedPants === undefined) data.selectedPants = null;

  return data;
}

async function writeProgressAtomic(progress) {
  const json = JSON.stringify(progress, null, 2) + '\n';
  await writeFile(PROGRESS_TMP, json, 'utf-8');
  await rename(PROGRESS_TMP, PROGRESS_PATH);
}

async function discoverSessions() {
  try {
    const entries = await readdir(SESSIONS_DIR);
    const sessions = [];
    for (const f of entries.filter(f => f.endsWith('.json'))) {
      const data = await readJsonSafe(join(SESSIONS_DIR, f));
      if (data?.pid != null) sessions.push(data);
    }
    return sessions;
  } catch { return []; }
}

const seenPids = new Set();
const sessionTracking = new Map(); // pid -> { lastMinutes, lastAgents, lastTokens, wasLong, lastOpusMinutes }
let lastRateLimitHigh = false;

function updateStats(progress, sessionDetails) {
  const stats = progress.stats;
  const activePids = new Set();

  for (const s of sessionDetails) {
    activePids.add(s.pid);
    const prev = sessionTracking.get(s.pid);
    const isOpus = s.model?.toLowerCase().includes('opus') || false;
    const estimatedTokens = Math.round(s.contextPercent / 100 * 200000);

    if (!prev) {
      // First time seeing this PID in this aggregator run
      const isNew = s.sessionMinutes <= 1;

      if (isNew && !seenPids.has(s.pid)) {
        stats.totalSessions++;
      }
      seenPids.add(s.pid);

      sessionTracking.set(s.pid, {
        lastMinutes: s.sessionMinutes,
        lastAgents: s.runningAgents,
        lastTokens: estimatedTokens,
        wasLong: s.sessionMinutes >= 45,
        lastOpusMinutes: isOpus ? s.sessionMinutes : 0,
      });

      // For genuinely new sessions, add initial values
      if (isNew) {
        stats.totalTimeMinutes += s.sessionMinutes;
        stats.totalTokens += estimatedTokens;
        if (s.runningAgents > 0) stats.totalAgentRuns += s.runningAgents;
        if (s.sessionMinutes >= 45) stats.longSessions++;
        if (isOpus) stats.opusTimeMinutes += s.sessionMinutes;
      }
      // For pre-existing sessions (aggregator restart), skip to avoid double-counting
    } else {
      // Known session — accumulate positive deltas

      const deltaMinutes = s.sessionMinutes - prev.lastMinutes;
      if (deltaMinutes > 0) {
        stats.totalTimeMinutes += deltaMinutes;
        prev.lastMinutes = s.sessionMinutes;
      }

      const deltaAgents = s.runningAgents - prev.lastAgents;
      if (deltaAgents > 0) {
        stats.totalAgentRuns += deltaAgents;
      }
      prev.lastAgents = s.runningAgents;

      const deltaTokens = estimatedTokens - prev.lastTokens;
      if (deltaTokens > 0) {
        stats.totalTokens += deltaTokens;
        prev.lastTokens = estimatedTokens;
      }

      if (s.sessionMinutes >= 45 && !prev.wasLong) {
        stats.longSessions++;
        prev.wasLong = true;
      }

      if (isOpus) {
        const deltaOpus = s.sessionMinutes - prev.lastOpusMinutes;
        if (deltaOpus > 0) {
          stats.opusTimeMinutes += deltaOpus;
          prev.lastOpusMinutes = s.sessionMinutes;
        }
      }
    }
  }

  // Max concurrent tracking (high water mark by nature)
  const currentSessions = sessionDetails.length;
  if (currentSessions > stats.maxConcurrentSessions) {
    stats.maxConcurrentSessions = currentSessions;
  }
  const totalAgentsNow = sessionDetails.reduce((sum, s) => sum + s.runningAgents, 0);
  if (totalAgentsNow > stats.maxConcurrentAgents) {
    stats.maxConcurrentAgents = totalAgentsNow;
  }

  // Clean up tracking for dead sessions
  for (const pid of sessionTracking.keys()) {
    if (!activePids.has(pid)) {
      sessionTracking.delete(pid);
    }
  }

  return stats;
}

function checkUnlocks(progress) {
  const unlocked = progress.unlockedAccessories;
  let changed = false;

  for (const [accessoryId, condition] of Object.entries(UNLOCK_CONDITIONS)) {
    if (unlocked.includes(accessoryId)) continue;

    const met = (progress.stats[condition.type] || 0) >= condition.threshold;

    if (met) {
      unlocked.push(accessoryId);
      progress.unlockedAt[accessoryId] = new Date().toISOString();
      changed = true;
      process.stderr.write(`[oh-my-clawd] unlocked: ${accessoryId}\n`);
    }
  }

  return changed;
}

function checkRateLimitHit(progress, rateLimit) {
  const fh = rateLimit.fiveHourPercent;
  if (fh != null && fh >= 80 && !lastRateLimitHigh) {
    progress.stats.rateLimitHits++;
    lastRateLimitHigh = true;
  } else if (fh == null || fh < 80) {
    lastRateLimitHigh = false;
  }
}

async function tick() {
  try {
    const rawSessions = await discoverSessions();
    const aliveSessions = rawSessions.filter(s => isPidAlive(s.pid));

    const sessionDetails = [];
    const models = [];
    let latestUsage = null;
    let latestUsageTs = 0;

    for (const session of aliveSessions) {
      try {
        const cwd = session.cwd;
        if (!cwd) continue;

        const stateFile = join(cwd, '.claude', '.hud', 'session-state.json');
        const usageFile = join(cwd, '.claude', '.hud', 'usage-cache.json');

        const rawState = await readJsonSafe(stateFile);
        const now = Date.now();
        const stateFresh =
          rawState?.timestamp &&
          (now - rawState.timestamp) <= IDLE_THRESHOLD_MS;
        const state = stateFresh ? rawState : null;

        if (state) {
          const usage = await readJsonSafe(usageFile);
          if (usage?.timestamp && usage.timestamp > latestUsageTs) {
            latestUsageTs = usage.timestamp;
            latestUsage = usage.data || null;
          }

          sessionDetails.push({
            pid: session.pid,
            project: basename(cwd),
            model: state.model || 'unknown',
            contextPercent: state.contextPercent || 0,
            toolCalls: state.toolCalls || 0,
            runningAgents: state.runningAgents || 0,
            sessionMinutes: state.sessionMinutes || 0,
          });

          if (state.model) models.push(state.model);
        } else {
          const startedAt = session.startedAt ?? now;
          sessionDetails.push({
            pid: session.pid,
            project: basename(cwd),
            model: 'unknown',
            contextPercent: 0,
            toolCalls: 0,
            runningAgents: 0,
            sessionMinutes: Math.max(0, Math.floor((now - startedAt) / 60_000)),
          });
        }
      } catch { continue; }
    }

    const rateLimit = latestUsage
      ? {
          fiveHourPercent: latestUsage.fiveHourPercent ?? null,
          weeklyPercent: latestUsage.weeklyPercent ?? null,
          fiveHourResetsAt: latestUsage.fiveHourResetsAt ?? null,
          weeklyResetsAt: latestUsage.weeklyResetsAt ?? null,
        }
      : { fiveHourPercent: null, weeklyPercent: null, fiveHourResetsAt: null, weeklyResetsAt: null };

    const petState = {
      timestamp: Date.now(),
      activeSessions: sessionDetails.length,
      rateLimit,
      aggregate: {
        maxContextPercent: sessionDetails.reduce((m, s) => Math.max(m, s.contextPercent), 0),
        totalToolCalls: sessionDetails.reduce((sum, s) => sum + s.toolCalls, 0),
        totalRunningAgents: sessionDetails.reduce((sum, s) => sum + s.runningAgents, 0),
        longestSessionMinutes: sessionDetails.reduce((m, s) => Math.max(m, s.sessionMinutes), 0),
        dominantModel: pickDominantModel(models),
      },
      sessions: sessionDetails,
    };

    if (!existsSync(PET_DIR)) await mkdir(PET_DIR, { recursive: true });

    // --- Progress tracking ---
    const progress = await loadProgress();
    updateStats(progress, sessionDetails);
    checkRateLimitHit(progress, rateLimit);
    checkUnlocks(progress);
    await writeProgressAtomic(progress);
    // --- End progress tracking ---

    await writeAtomicJson(petState);
  } catch (err) {
    process.stderr.write(`[pet-aggregator] tick error: ${err.message}\n`);
  }
}

// Startup
process.stderr.write(`[pet-aggregator] started (pid=${process.pid}, interval=${POLL_INTERVAL_MS}ms)\n`);
tick();
const intervalId = setInterval(tick, POLL_INTERVAL_MS);

function shutdown(sig) {
  process.stderr.write(`[pet-aggregator] ${sig}, shutting down\n`);
  clearInterval(intervalId);
  process.exit(0);
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
