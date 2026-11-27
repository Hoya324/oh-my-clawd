import { test, beforeEach } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { usageFromStatusline, recordStatuslineUsage, readUsageCache, currentUsage } from '../lib/usage.mjs';

const NOW = Date.parse('2026-11-27T09:50:00Z');
const stdinWith = (five, week) => ({
  rate_limits: {
    ...(five ? { five_hour: { used_percentage: five[0], resets_at: five[1] } } : {}),
    ...(week ? { seven_day: { used_percentage: week[0], resets_at: week[1] } } : {}),
  },
});
const FIVE_RESET = Date.parse('2026-11-27T10:50:00Z') / 1000;
const WEEK_RESET = Date.parse('2026-11-29T16:00:00Z') / 1000;

beforeEach(() => {
  process.env.OH_MY_CLAWD_HOME = mkdtempSync(join(tmpdir(), 'omc-usage-'));
});

test('usageFromStatusline reads rate_limits (epoch seconds → ISO)', () => {
  const d = usageFromStatusline(stdinWith([56, FIVE_RESET], [57.4, WEEK_RESET]));
  assert.equal(d.fiveHourPercent, 56);
  assert.equal(d.weeklyPercent, 57.4);
  assert.equal(d.fiveHourResetsAt, '2026-11-27T10:50:00.000Z');
  assert.equal(usageFromStatusline({}), null);                    // API-key users / early session
  assert.equal(usageFromStatusline({ rate_limits: {} }), null);
  assert.equal(usageFromStatusline(stdinWith([140, FIVE_RESET])).fiveHourPercent, 100);
});

test('records to the shared cache and serves the last value without new data', () => {
  recordStatuslineUsage(stdinWith([56, FIVE_RESET], [57, WEEK_RESET]), { now: NOW, sessionId: 's1' });
  const c = readUsageCache();
  assert.equal(c.source, 'statusline');
  assert.equal(c.data.weeklyPercent, 57);
  // A later run without rate_limits must not wipe the cache.
  assert.equal(currentUsage({}, { now: NOW + 1000 }).fiveHourPercent, 56);
  assert.equal(readUsageCache().timestamp, NOW);
});

test('a window missing from an update keeps its previous value until it resets', () => {
  recordStatuslineUsage(stdinWith([56, FIVE_RESET], [57, WEEK_RESET]), { now: NOW });
  const d = recordStatuslineUsage(stdinWith(null, [58, WEEK_RESET]), { now: NOW + 60_000 });
  assert.equal(d.fiveHourPercent, 56);
  assert.equal(d.weeklyPercent, 58);
  // After the 5h reset time, the old 5h value is not carried over.
  const later = recordStatuslineUsage(stdinWith(null, [59, WEEK_RESET]), { now: FIVE_RESET * 1000 + 1 });
  assert.equal(later.fiveHourPercent, null);
});
