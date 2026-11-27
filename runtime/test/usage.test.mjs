import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { getUsage, readUsageCache, parseUsageResponse, USAGE_TTL_MS, USAGE_RATE_LIMIT_BACKOFF_MS } from '../lib/usage.mjs';

const BODY = {
  five_hour: { utilization: 42.4, resets_at: '2026-11-27T12:00:00Z' },
  seven_day: { utilization: 63, resets_at: '2026-11-30T00:00:00Z' },
};

beforeEach(() => {
  process.env.OH_MY_CLAWD_HOME = mkdtempSync(join(tmpdir(), 'omc-usage-'));
});

test('parseUsageResponse clamps and normalizes dates', () => {
  const d = parseUsageResponse({ five_hour: { utilization: 140, resets_at: 'bad' }, seven_day: { utilization: -3 } });
  assert.equal(d.fiveHourPercent, 100);
  assert.equal(d.weeklyPercent, 0);
  assert.equal(d.fiveHourResetsAt, null);
  assert.equal(parseUsageResponse({}), null);
});

test('parseUsageResponse keeps per-model weekly limits when present', () => {
  const d = parseUsageResponse({ ...BODY, seven_day_opus: { utilization: 12, resets_at: '2026-11-30T00:00:00Z' }, seven_day_sonnet: null });
  assert.deepEqual(d.models, [{ model: 'opus', percent: 12, resetsAt: '2026-11-30T00:00:00.000Z' }]);
  assert.deepEqual(parseUsageResponse(BODY).models, []);
});

test('fetches, caches, and serves from cache within TTL', async () => {
  let calls = 0;
  const deps = {
    now: 1_000_000,
    readCreds: () => ({ accessToken: 't', expiresAt: 2_000_000 }),
    fetchUsage: async () => { calls++; return { status: 200, body: BODY }; },
  };
  const first = await getUsage(deps);
  assert.equal(first.fiveHourPercent, 42.4);
  assert.equal(first.fiveHourResetsAt, '2026-11-27T12:00:00.000Z');
  await getUsage({ ...deps, now: deps.now + USAGE_TTL_MS - 1 });
  assert.equal(calls, 1);
  await getUsage({ ...deps, now: deps.now + USAGE_TTL_MS + 1 });
  assert.equal(calls, 2);
});

test('expired token: never refreshes, keeps last good data', async () => {
  let fetched = false;
  await getUsage({
    now: 1_000,
    readCreds: () => ({ accessToken: 't', expiresAt: 5_000 }),
    fetchUsage: async () => ({ status: 200, body: BODY }),
  });
  const r = await getUsage({
    now: 1_000 + USAGE_TTL_MS + 10,
    readCreds: () => ({ accessToken: 't', expiresAt: 5_000 }),
    fetchUsage: async () => { fetched = true; return { status: 200, body: BODY }; },
  });
  assert.equal(fetched, false);
  assert.equal(r.fiveHourPercent, 42.4);
});

test('429 backs off and keeps last value', async () => {
  const creds = () => ({ accessToken: 't' });
  await getUsage({ now: 0, readCreds: creds, fetchUsage: async () => ({ status: 200, body: BODY }) });
  let calls = 0;
  const limited = async () => { calls++; return { status: 429, body: null }; };
  const t1 = USAGE_TTL_MS + 1;
  const r = await getUsage({ now: t1, readCreds: creds, fetchUsage: limited });
  assert.equal(r.weeklyPercent, 63);
  assert.equal(readUsageCache().error, true);
  await getUsage({ now: t1 + USAGE_RATE_LIMIT_BACKOFF_MS - 1, readCreds: creds, fetchUsage: limited });
  assert.equal(calls, 1);
});
