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
const IDLE_THRESHOLD_MS = 5 * 60_000;

const MODEL_PRIORITY = { opus: 3, sonnet: 2, haiku: 1 };

const PROGRESS_PATH = join(PET_DIR, 'progress.json');
const PROGRESS_TMP = join(PET_DIR, 'progress.json.tmp');

const UNLOCK_CONDITIONS = {
  cat:      { type: 'default' },
  hamster:  { type: 'totalSessions', threshold: 10 },
  chick:    { type: 'totalTimeMinutes', threshold: 300 },
  penguin:  { type: 'totalTokens', threshold: 500000 },
  fox:      { type: 'totalAgentRuns', threshold: 50 },
  rabbit:   { type: 'maxConcurrentSessions', threshold: 3 },
  goose:    { type: 'totalTimeMinutes', threshold: 1800 },
  capybara: { type: 'rateLimitHits', threshold: 10 },
  sloth:    { type: 'longSessions', threshold: 20 },
  owl:      { type: 'opusTimeMinutes', threshold: 600 },
  dragon:   { type: 'maxConcurrentAgents', threshold: 5 },
  unicorn:  { type: 'allUnlocked' },
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
    unlocked: ['cat'],
    selectedPet: 'cat',
    unlockedAt: { cat: new Date().toISOString() },
  };
}

async function loadProgress() {
  const data = await readJsonSafe(PROGRESS_PATH);
  if (!data || !data.stats) return defaultProgress();
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
let lastRateLimitHigh = false;

function updateStats(progress, sessionDetails) {
  const stats = progress.stats;

  for (const s of sessionDetails) {
    if (!seenPids.has(s.pid)) {
      seenPids.add(s.pid);
      stats.totalSessions++;
    }
  }

  const totalActiveMinutes = sessionDetails.reduce((sum, s) => sum + s.sessionMinutes, 0);
  if (totalActiveMinutes > stats.totalTimeMinutes) {
    stats.totalTimeMinutes = totalActiveMinutes;
  }

  const totalTokensNow = sessionDetails.reduce((sum, s) => sum + Math.round(s.contextPercent / 100 * 200000), 0);
  if (totalTokensNow > stats.totalTokens) {
    stats.totalTokens = totalTokensNow;
  }

  const currentAgents = sessionDetails.reduce((sum, s) => sum + s.runningAgents, 0);
  stats.totalAgentRuns = Math.max(stats.totalAgentRuns, currentAgents);

  const currentSessions = sessionDetails.length;
  if (currentSessions > stats.maxConcurrentSessions) {
    stats.maxConcurrentSessions = currentSessions;
  }

  if (currentAgents > stats.maxConcurrentAgents) {
    stats.maxConcurrentAgents = currentAgents;
  }

  const longNow = sessionDetails.filter(s => s.sessionMinutes >= 45).length;
  if (longNow > stats.longSessions) {
    stats.longSessions = longNow;
  }

  const opusMinutes = sessionDetails
    .filter(s => s.model && s.model.toLowerCase().includes('opus'))
    .reduce((sum, s) => sum + s.sessionMinutes, 0);
  if (opusMinutes > stats.opusTimeMinutes) {
    stats.opusTimeMinutes = opusMinutes;
  }

  return stats;
}

function checkUnlocks(progress) {
  const { stats, unlocked } = progress;
  let changed = false;

  for (const [petId, condition] of Object.entries(UNLOCK_CONDITIONS)) {
    if (unlocked.includes(petId)) continue;

    let met = false;
    if (condition.type === 'default') {
      met = true;
    } else if (condition.type === 'allUnlocked') {
      const otherPets = Object.keys(UNLOCK_CONDITIONS).filter(id => id !== 'unicorn');
      met = otherPets.every(id => unlocked.includes(id));
    } else {
      met = (stats[condition.type] || 0) >= condition.threshold;
    }

    if (met) {
      unlocked.push(petId);
      progress.unlockedAt[petId] = new Date().toISOString();
      changed = true;
      process.stderr.write(`[pet-aggregator] unlocked: ${petId}\n`);
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

        const state = await readJsonSafe(stateFile);
        if (!state) continue;

        const now = Date.now();
        if (state.timestamp && (now - state.timestamp) > IDLE_THRESHOLD_MS) continue;

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
