import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, appendFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import { sumUsageTokens, accumulateTokens, parseTranscriptLines, sessionIdFrom, formatResetTime } from '../hud.mjs';

const assistant = (id, u) => JSON.stringify({ message: { id, role: 'assistant', usage: u, content: [] } });

test('sumUsageTokens counts each message id once and skips cache reads', () => {
  const u = { input_tokens: 10, output_tokens: 5, cache_creation_input_tokens: 100, cache_read_input_tokens: 99999 };
  const text = [assistant('m1', u), assistant('m1', u), assistant('m2', u), 'garbage'].join('\n');
  assert.equal(sumUsageTokens(text).tokens, 230);
});

test('accumulateTokens is incremental and ignores partial lines', () => {
  const dir = mkdtempSync(join(tmpdir(), 'omc-hud-'));
  const file = join(dir, 't.jsonl');
  const u = { input_tokens: 1, output_tokens: 1, cache_creation_input_tokens: 0 };
  writeFileSync(file, assistant('a', u) + '\n' + '{"message":{"id":"b","role":"assistant","usa');
  let st = accumulateTokens(file, null);
  assert.equal(st.totalTokens, 2);

  appendFileSync(file, 'ge":{"input_tokens":3,"output_tokens":0}}}\n');
  st = accumulateTokens(file, { transcriptPath: file, transcriptOffset: st.offset, totalTokens: st.totalTokens, lastMessageId: st.lastMessageId });
  assert.equal(st.totalTokens, 5);

  // Same message streamed again across a chunk boundary is not recounted.
  appendFileSync(file, '{"message":{"id":"b","role":"assistant","usage":{"input_tokens":3}}}\n');
  st = accumulateTokens(file, { transcriptPath: file, transcriptOffset: st.offset, totalTokens: st.totalTokens, lastMessageId: st.lastMessageId });
  assert.equal(st.totalTokens, 5);
});

test('parseTranscriptLines tracks running agents', () => {
  const lines = [
    JSON.stringify({ timestamp: new Date().toISOString(), message: { content: [{ type: 'tool_use', id: 'x', name: 'Agent' }] } }),
    JSON.stringify({ message: { content: [{ type: 'tool_use', id: 'y', name: 'Bash' }] } }),
    JSON.stringify({ message: { content: [{ type: 'tool_use', id: 'z', name: 'Task' }] } }),
    JSON.stringify({ message: { content: [{ type: 'tool_result', tool_use_id: 'z', content: 'done' }] } }),
  ];
  const r = parseTranscriptLines(lines);
  assert.equal(r.toolCallCount, 3);
  assert.equal(r.agents.length, 1);
});

test('sessionIdFrom prefers session_id', () => {
  assert.equal(sessionIdFrom({ session_id: 'abc' }), 'abc');
  assert.match(sessionIdFrom({ transcript_path: '/x' }), /^t-/);
});

test('formatResetTime', () => {
  const now = Date.parse('2026-11-27T00:00:00Z');
  assert.equal(formatResetTime('2026-11-27T03:51:00Z', now), '3h51m');
  assert.equal(formatResetTime('2026-11-30T05:00:00Z', now), '3d5h');
  assert.equal(formatResetTime(null, now), null);
});
