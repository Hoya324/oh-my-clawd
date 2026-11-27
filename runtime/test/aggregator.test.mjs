import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, existsSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  dedupeSessions, isLiveSession, isInteractive, inspectProcesses, matchStates,
  buildSessionDetails, groupProjects, defaultProgress, migrateProgress,
  updateStats, checkRateLimitHit, checkUnlocks, loadUnlockConditions, createAggregator,
  rateLimitFromCache,
} from '../pet-aggregator.mjs';

const NOW = Date.parse('2026-11-27T08:00:00Z');
const noLegacy = { legacy: () => null };

test('dedupeSessions keeps one entry per sessionId', () => {
  const r = dedupeSessions([
    { pid: 1, sessionId: 'a', startedAt: 1 },
    { pid: 2, sessionId: 'a', startedAt: 5 },
    { pid: 3, startedAt: 1 },
  ]);
  assert.equal(r.length, 2);
  assert.equal(r.find((s) => s.sessionId === 'a').pid, 2);
});

test('isLiveSession rejects recycled PIDs', () => {
  const s = { pid: 10, startedAt: NOW };
  // Native installs: the executable is a version number under .../claude/versions/
  assert.equal(isLiveSession(s, { comm: '/Users/x/.local/share/claude/versions/2.0.50', startMs: NOW - 1000 }), true);
  assert.equal(isLiveSession(s, { comm: '/usr/bin/node', startMs: NOW }), true);
  // Started an hour after the session: PID reused by another process.
  assert.equal(isLiveSession(s, { comm: '/x/claude', startMs: NOW + 60 * 60_000 }), false);
  assert.equal(isLiveSession(s, { comm: '/Applications/Safari.app/Contents/MacOS/Safari', startMs: NOW + 60 * 60_000 }), false);
  // Start time unknown: fall back to the executable name.
  assert.equal(isLiveSession({ pid: 1 }, { comm: '/Applications/Safari.app/Contents/MacOS/Safari', startMs: null }), false);
  assert.equal(isLiveSession({ pid: 1 }, { comm: '/opt/homebrew/bin/claude', startMs: null }), true);
  assert.equal(isLiveSession(s, undefined), false);
});

test('isInteractive filters print/sdk runs', () => {
  assert.equal(isInteractive({}), true);
  assert.equal(isInteractive({ kind: 'interactive' }), true);
  assert.equal(isInteractive({ entrypoint: 'sdk-cli' }), false);
  assert.equal(isInteractive({ kind: 'print' }), false);
});

test('inspectProcesses parses ps output', () => {
  const out = '  101 Fri Nov 27 17:20:01 2026 /Users/a/.local/bin/claude\n  202 Thu Nov 26 09:00:00 2026 /usr/bin/node\n';
  const m = inspectProcesses([101, 202, 303], { execPs: () => out });
  assert.equal(m.size, 2);
  assert.match(m.get(101).comm, /claude$/);
  assert.ok(m.get(202).startMs > 0);
});

test('two sessions in one project never share one HUD state', () => {
  const sessions = [
    { pid: 1, sessionId: 's1', cwd: '/p/navi', startedAt: NOW - 1000 },
    { pid: 2, sessionId: 's2', cwd: '/p/navi', startedAt: NOW - 500 },
  ];
  const states = [{ sessionId: 's1', cwd: '/p/navi', timestamp: NOW, runningAgents: 2, model: 'opus' }];
  const m = matchStates(sessions, states, NOW);
  assert.equal(m.get(sessions[0]).sessionId, 's1');
  assert.equal(m.has(sessions[1]), false);

  const details = buildSessionDetails(sessions, states, NOW, noLegacy);
  assert.equal(details.reduce((s, d) => s + d.runningAgents, 0), 2);
  assert.deepEqual(groupProjects(details), [{ name: 'navi', count: 2 }]);
});

test('cwd fallback matches only unclaimed fresh states', () => {
  const sessions = [{ pid: 1, cwd: '/p/a', startedAt: NOW }];
  const states = [
    { sessionId: 'old', cwd: '/p/a', timestamp: NOW - 60 * 60_000 },
    { sessionId: 'new', cwd: '/p/a', timestamp: NOW - 1000 },
  ];
  assert.equal(matchStates(sessions, states, NOW).get(sessions[0]).sessionId, 'new');
});

test('updateStats survives a daemon restart without double counting', () => {
  const p = defaultProgress();
  const d = [{ key: 'id:a', model: 'claude-opus', sessionMinutes: 10, tokens: 1000, runningAgents: 1 }];
  updateStats(p, d, NOW);
  assert.equal(p.stats.totalSessions, 1);
  assert.equal(p.stats.totalTimeMinutes, 10);

  // Simulate restart: progress is reloaded from disk (tracking persisted).
  const reloaded = migrateProgress(JSON.parse(JSON.stringify(p))).progress;
  updateStats(reloaded, [{ ...d[0], sessionMinutes: 12, tokens: 1500 }], NOW + 120_000);
  assert.equal(reloaded.stats.totalSessions, 1);
  assert.equal(reloaded.stats.totalTimeMinutes, 12);
  assert.equal(reloaded.stats.totalTokens, 1500);
  assert.equal(reloaded.stats.opusTimeMinutes, 12);
});

test('sessions first seen mid-way are still counted', () => {
  const p = defaultProgress();
  updateStats(p, [{ key: 'id:late', model: 'sonnet', sessionMinutes: 50, tokens: 0, runningAgents: 0 }], NOW);
  assert.equal(p.stats.totalSessions, 1);
  assert.equal(p.stats.longSessions, 1);
});

test('rate limit hits count once per window', () => {
  const p = defaultProgress();
  checkRateLimitHit(p, { fiveHourPercent: 85, fiveHourResetsAt: 'w1' });
  checkRateLimitHit(p, { fiveHourPercent: 79, fiveHourResetsAt: 'w1' });
  checkRateLimitHit(p, { fiveHourPercent: 90, fiveHourResetsAt: 'w1' });
  assert.equal(p.stats.rateLimitHits, 1);
  checkRateLimitHit(p, { fiveHourPercent: 90, fiveHourResetsAt: 'w2' });
  assert.equal(p.stats.rateLimitHits, 2);

  // Reset time jitter (seconds) is the same window; 5 hours later is not.
  const q = defaultProgress();
  checkRateLimitHit(q, { fiveHourPercent: 85, fiveHourResetsAt: '2026-11-27T12:00:00.000Z' });
  checkRateLimitHit(q, { fiveHourPercent: 85, fiveHourResetsAt: '2026-11-27T12:00:03.000Z' });
  assert.equal(q.stats.rateLimitHits, 1);
  checkRateLimitHit(q, { fiveHourPercent: 85, fiveHourResetsAt: '2026-11-27T17:00:00.000Z' });
  assert.equal(q.stats.rateLimitHits, 2);
});

test('migrateProgress moves selection out and upgrades v1', () => {
  const v2 = { version: 2, stats: { totalSessions: 3 }, unlockedAccessories: ['cap'], unlockedAt: {}, selectedHat: 'cap', selectedPants: null };
  const r = migrateProgress(v2);
  assert.equal(r.progress.version, 3);
  assert.equal('selectedHat' in r.progress, false);
  assert.deepEqual(r.selection, { selectedHat: 'cap', selectedGlasses: null, selectedPants: null });

  const v1 = { stats: { totalSessions: 1 }, unlocked: ['owl', 'cat'], selectedPet: 'owl', unlockedAt: { owl: 'x' } };
  const r1 = migrateProgress(v1);
  assert.deepEqual(r1.progress.unlockedAccessories, ['starGlasses']);
  assert.equal(r1.selection.selectedGlasses, 'starGlasses');
});

test('checkUnlocks reports progress from unlocks.json', () => {
  const p = defaultProgress();
  p.stats.totalSessions = 10;
  const newly = checkUnlocks(p, loadUnlockConditions(), NOW);
  assert.deepEqual(newly, ['cap']);
  assert.deepEqual(p.unlockProgress.shorts, { metric: 'totalSessions', current: 10, target: 100 });
});

test('end-to-end tick writes state, progress and migrates selection once', () => {
  const home = mkdtempSync(join(tmpdir(), 'omc-agg-'));
  process.env.OH_MY_CLAWD_HOME = home;
  const claude = join(home, '.claude');
  mkdirSync(join(claude, 'sessions'), { recursive: true });
  mkdirSync(join(claude, 'pet', 'sessions'), { recursive: true });
  writeFileSync(join(claude, 'pet', 'progress.json'), JSON.stringify({ version: 2, stats: {}, unlockedAccessories: [], unlockedAt: {}, selectedHat: 'cap' }));
  // Our own PID is alive and is a node process.
  writeFileSync(join(claude, 'sessions', `${process.pid}.json`), JSON.stringify({ pid: process.pid, sessionId: 'e2e', cwd: '/p/demo', startedAt: Date.now() }));
  writeFileSync(join(claude, 'pet', 'sessions', 'e2e.json'), JSON.stringify({ sessionId: 'e2e', cwd: '/p/demo', timestamp: Date.now(), model: 'Opus', contextPercent: 40, toolCalls: 7, runningAgents: 1, sessionMinutes: 3, totalTokens: 1234 }));

  const agg = createAggregator({ log: () => {} });
  const { petState } = agg.tick();
  assert.equal(petState.activeSessions, 1);
  assert.equal(petState.sessions[0].hasHud, true);

  const progress = JSON.parse(readFileSync(join(claude, 'pet', 'progress.json'), 'utf8'));
  assert.equal(progress.stats.totalTokens, 1234);
  assert.equal(progress.selectedHat, undefined);
  assert.ok(existsSync(join(claude, 'pet', 'selection.json')));
  assert.equal(JSON.parse(readFileSync(join(claude, 'pet', 'selection.json'), 'utf8')).selectedHat, 'cap');
});

test('rateLimitFromCache keeps values until their window resets', () => {
  const cache = { timestamp: NOW - 3 * 60 * 60_000, data: {
    fiveHourPercent: 56, fiveHourResetsAt: new Date(NOW + 60_000).toISOString(),
    weeklyPercent: 57, weeklyResetsAt: new Date(NOW - 1).toISOString() } };
  const r = rateLimitFromCache(cache, NOW);
  assert.equal(r.fiveHourPercent, 56);     // old cache, window still open
  assert.equal(r.weeklyPercent, null);     // window already reset
  assert.equal(rateLimitFromCache(null, NOW).fiveHourPercent, null);
});
