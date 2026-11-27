#!/usr/bin/env node
/**
 * oh-my-clawd HUD — status line for Claude Code
 *
 *   [HUD] | 5h:14%(3h51m) | wk:62%(3d5h) | session:29m | ctx:39% | 🔧53 | agents:2 | opus-4-6
 *
 * Data sources:
 *   - 5h / weekly usage: `rate_limits` that Claude Code passes on stdin
 *     (never Claude Code's OAuth token; see lib/usage.mjs)
 *   - session / tools / agents / tokens: transcript parsing
 *   - context window: stdin JSON from Claude Code
 *
 * Side effect: writes ~/.claude/pet/sessions/<session_id>.json for the
 * menu bar companion. Nothing is written into the project directory.
 */

import { existsSync, statSync, openSync, readSync, closeSync } from 'node:fs';
import { createHash } from 'node:crypto';

import { paths } from './lib/paths.mjs';
import { readJsonSync, writeJsonAtomicSync } from './lib/fsutil.mjs';
import { currentUsage } from './lib/usage.mjs';

// ============================================================================
// ANSI
// ============================================================================
const RESET = '\x1b[0m';
const DIM = '\x1b[2m';
const BOLD = '\x1b[1m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BRAND_BOLD = `${BOLD}${CYAN}`;

const MAX_TAIL_BYTES = 512 * 1024;
/** Max bytes read per run for token accounting (keeps the status line fast). */
const MAX_TOKEN_SCAN_BYTES = 8 * 1024 * 1024;
const MAX_AGENT_MAP_SIZE = 100;
const AGENT_STALE_MS = 30 * 60_000;
const TOOL_ICON = '\u{1F527}';
const AGENT_TOOL_NAMES = new Set(['Task', 'proxy_Task', 'Agent']);

// ============================================================================
// Stdin
// ============================================================================

async function readStdin() {
  if (process.stdin.isTTY) return null;
  const chunks = [];
  try {
    process.stdin.setEncoding('utf8');
    for await (const chunk of process.stdin) chunks.push(chunk);
    const raw = chunks.join('');
    return raw.trim() ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function getContextPercent(stdin) {
  const native = stdin?.context_window?.used_percentage;
  if (typeof native === 'number' && !Number.isNaN(native)) {
    return Math.min(100, Math.max(0, Math.round(native)));
  }
  const size = stdin?.context_window?.context_window_size;
  if (!size || size <= 0) return 0;
  const u = stdin?.context_window?.current_usage;
  const total = (u?.input_tokens ?? 0) + (u?.cache_creation_input_tokens ?? 0) + (u?.cache_read_input_tokens ?? 0);
  return Math.min(100, Math.round((total / size) * 100));
}

export function sessionIdFrom(stdin) {
  if (stdin?.session_id) return String(stdin.session_id);
  if (stdin?.transcript_path) {
    return 't-' + createHash('sha256').update(stdin.transcript_path).digest('hex').slice(0, 16);
  }
  return 'default';
}

// ============================================================================
// Transcript: tools / agents (tail scan)
// ============================================================================

function readRange(filePath, start, end) {
  const length = Math.max(0, end - start);
  if (length === 0) return '';
  const fd = openSync(filePath, 'r');
  const buf = Buffer.alloc(length);
  try { readSync(fd, buf, 0, length, start); } finally { closeSync(fd); }
  return buf.toString('utf8');
}

function tailLines(filePath, size, maxBytes) {
  const start = Math.max(0, size - maxBytes);
  const lines = readRange(filePath, start, size).split('\n');
  if (start > 0 && lines.length > 0) lines.shift(); // first line is partial
  return lines;
}

export function parseTranscriptLines(lines, now = Date.now()) {
  const result = { agents: [], sessionStart: null, toolCallCount: 0 };
  const agentMap = new Map();

  for (const line of lines) {
    if (!line.trim()) continue;
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    const ts = entry.timestamp ? new Date(entry.timestamp) : null;
    if (!result.sessionStart && ts && !Number.isNaN(ts.getTime())) result.sessionStart = ts;

    const content = entry.message?.content;
    if (!Array.isArray(content)) continue;

    for (const block of content) {
      if (block?.type === 'tool_use' && block.id && block.name) {
        result.toolCallCount++;
        if (AGENT_TOOL_NAMES.has(block.name)) {
          if (agentMap.size >= MAX_AGENT_MAP_SIZE) evictOldestCompleted(agentMap);
          agentMap.set(block.id, { id: block.id, status: 'running', startTime: ts ?? new Date(now) });
        }
      }
      if (block?.type === 'tool_result' && block.tool_use_id) {
        const agent = agentMap.get(block.tool_use_id);
        if (agent && !isBackgroundLaunch(block.content)) agent.status = 'completed';
      }
    }
  }

  for (const agent of agentMap.values()) {
    if (agent.status === 'running' && now - agent.startTime.getTime() > AGENT_STALE_MS) {
      agent.status = 'completed';
    }
  }
  result.agents = [...agentMap.values()].filter((a) => a.status === 'running');
  return result;
}

function isBackgroundLaunch(content) {
  if (typeof content === 'string') return content.includes('Async agent launched');
  return Array.isArray(content) && content.some((c) => c?.text?.includes('Async agent launched'));
}

function evictOldestCompleted(agentMap) {
  let oldestId = null;
  let oldest = Infinity;
  for (const [id, a] of agentMap) {
    if (a.status === 'completed' && a.startTime.getTime() < oldest) {
      oldest = a.startTime.getTime();
      oldestId = id;
    }
  }
  if (oldestId) agentMap.delete(oldestId);
}

function parseTranscript(transcriptPath) {
  if (!transcriptPath || !existsSync(transcriptPath)) {
    return { agents: [], sessionStart: null, toolCallCount: 0 };
  }
  try {
    const size = statSync(transcriptPath).size;
    return parseTranscriptLines(tailLines(transcriptPath, size, MAX_TAIL_BYTES));
  } catch {
    return { agents: [], sessionStart: null, toolCallCount: 0 };
  }
}

// ============================================================================
// Transcript: token accounting (incremental)
// ============================================================================

/**
 * Sum real token usage from assistant messages in `text`.
 * Streaming writes one transcript line per content block, each repeating the
 * same message.id and usage, so usage is counted once per message id.
 * Cache reads are excluded: they are re-billed every turn and would inflate
 * the total by orders of magnitude.
 */
export function sumUsageTokens(text, lastMessageId = null) {
  let tokens = 0;
  let lastId = lastMessageId;
  const seen = new Set(lastId ? [lastId] : []);
  for (const line of text.split('\n')) {
    if (!line.includes('"usage"')) continue;
    let entry;
    try { entry = JSON.parse(line); } catch { continue; }
    const msg = entry.message;
    const u = msg?.usage;
    if (!u || msg.role !== 'assistant') continue;
    const id = msg.id ?? entry.uuid ?? null;
    if (id && seen.has(id)) continue;
    if (id) { seen.add(id); lastId = id; }
    tokens += (u.input_tokens ?? 0) + (u.output_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0);
  }
  return { tokens, lastMessageId: lastId };
}

/**
 * Continue counting from where the previous run stopped. Only complete lines
 * are consumed so a half-written line is picked up next time.
 */
export function accumulateTokens(transcriptPath, prev) {
  const state = {
    transcriptPath,
    offset: 0,
    totalTokens: 0,
    lastMessageId: null,
  };
  if (prev && prev.transcriptPath === transcriptPath) {
    state.offset = prev.transcriptOffset ?? 0;
    state.totalTokens = prev.totalTokens ?? 0;
    state.lastMessageId = prev.lastMessageId ?? null;
  }
  if (!transcriptPath || !existsSync(transcriptPath)) return state;

  let size;
  try { size = statSync(transcriptPath).size; } catch { return state; }
  if (size < state.offset) {            // file was rewritten: start over
    state.offset = 0;
    state.totalTokens = 0;
    state.lastMessageId = null;
  }
  if (state.offset === 0 && size > MAX_TOKEN_SCAN_BYTES) {
    state.offset = size - MAX_TOKEN_SCAN_BYTES;   // first run on a huge file
  }
  const end = Math.min(size, state.offset + MAX_TOKEN_SCAN_BYTES);
  if (end <= state.offset) return state;

  let chunk;
  try { chunk = readRange(transcriptPath, state.offset, end); } catch { return state; }
  const lastNl = chunk.lastIndexOf('\n');
  if (lastNl < 0) return state;
  const complete = chunk.slice(0, lastNl + 1);
  const r = sumUsageTokens(complete, state.lastMessageId);
  state.totalTokens += r.tokens;
  state.lastMessageId = r.lastMessageId;
  state.offset += Buffer.byteLength(complete, 'utf8');
  return state;
}

// ============================================================================
// Formatting
// ============================================================================

export function formatResetTime(iso, now = Date.now()) {
  if (!iso) return null;
  const t = new Date(iso).getTime();
  if (Number.isNaN(t)) return null;
  const diff = t - now;
  if (diff <= 0) return null;
  const mins = Math.floor(diff / 60_000);
  const hours = Math.floor(mins / 60);
  const days = Math.floor(hours / 24);
  if (days > 0) return `${days}d${hours % 24}h`;
  return `${hours}h${mins % 60}m`;
}

function formatDuration(ms) {
  const total = Math.floor(ms / 60_000);
  if (total < 60) return `${total}m`;
  return `${Math.floor(total / 60)}h${total % 60}m`;
}

const limitColor = (p) => (p >= 90 ? RED : p >= 70 ? YELLOW : GREEN);
const contextColor = (p) => (p >= 85 ? RED : p >= 70 ? YELLOW : GREEN);
const sessionColor = (m) => (m >= 60 ? RED : m >= 30 ? YELLOW : GREEN);

export function shortModelName(stdin) {
  const name = stdin?.model?.display_name ?? stdin?.model?.id;
  if (!name) return '';
  return name
    .replace(/^claude-?/i, '')
    .replace(/-\d{8}$/, '')
    .replace(/\s*\(.*\)$/, '')
    .toLowerCase();
}

// ============================================================================
// Render
// ============================================================================

export function render({ stdin, transcript, usage, sessionStart, now = Date.now() }) {
  const parts = [`${BRAND_BOLD}[HUD]${RESET}`];

  if (usage?.fiveHourPercent != null) {
    const p = Math.round(usage.fiveHourPercent);
    const reset = formatResetTime(usage.fiveHourResetsAt, now);
    parts.push(`5h:${limitColor(p)}${p}%${RESET}${reset ? `${DIM}(${reset})${RESET}` : ''}`);
  }
  if (usage?.weeklyPercent != null) {
    const p = Math.round(usage.weeklyPercent);
    const reset = formatResetTime(usage.weeklyResetsAt, now);
    parts.push(`${DIM}wk:${RESET}${limitColor(p)}${p}%${RESET}${reset ? `${DIM}(${reset})${RESET}` : ''}`);
  }
  if (sessionStart) {
    const ms = now - sessionStart.getTime();
    parts.push(`session:${sessionColor(Math.floor(ms / 60_000))}${formatDuration(ms)}${RESET}`);
  }
  if (stdin) {
    const ctx = getContextPercent(stdin);
    parts.push(`ctx:${contextColor(ctx)}${ctx}%${RESET}`);
  }
  if (transcript.toolCallCount > 0) parts.push(`${TOOL_ICON}${transcript.toolCallCount}`);
  if (transcript.agents.length > 0) parts.push(`agents:${CYAN}${transcript.agents.length}${RESET}`);
  const model = shortModelName(stdin);
  if (model) parts.push(`${DIM}${model}${RESET}`);

  return parts.join(`${DIM} | ${RESET}`);
}

// ============================================================================
// Main
// ============================================================================

export async function main() {
  try {
    const stdin = await readStdin();
    const now = Date.now();
    const sessionId = sessionIdFrom(stdin);
    const usage = currentUsage(stdin, { now, sessionId });
    const statePath = paths.sessionState(sessionId);
    const prev = readJsonSync(statePath);

    const transcriptPath = stdin?.transcript_path ?? null;
    const transcript = parseTranscript(transcriptPath);

    // The tail scan may not reach the first line of a long transcript, so
    // keep the earliest start we have ever seen for this session.
    let sessionStart = transcript.sessionStart;
    const persisted = prev?.sessionStart ? new Date(prev.sessionStart) : null;
    if (persisted && !Number.isNaN(persisted.getTime()) && (!sessionStart || persisted < sessionStart)) {
      sessionStart = persisted;
    }

    const tokens = accumulateTokens(transcriptPath, prev);

    try {
      writeJsonAtomicSync(statePath, {
        version: 2,
        timestamp: now,
        sessionId,
        cwd: stdin?.workspace?.current_dir ?? stdin?.cwd ?? process.cwd(),
        projectDir: stdin?.workspace?.project_dir ?? null,
        model: stdin?.model?.display_name ?? stdin?.model?.id ?? '',
        contextPercent: stdin ? getContextPercent(stdin) : 0,
        contextWindowSize: stdin?.context_window?.context_window_size ?? null,
        toolCalls: transcript.toolCallCount,
        runningAgents: transcript.agents.length,
        sessionStart: sessionStart ? sessionStart.toISOString() : null,
        sessionMinutes: sessionStart ? Math.floor((now - sessionStart.getTime()) / 60_000) : 0,
        transcriptPath,
        transcriptOffset: tokens.offset,
        totalTokens: tokens.totalTokens,
        lastMessageId: tokens.lastMessageId,
      });
    } catch {}

    process.stdout.write(render({ stdin, transcript, usage, sessionStart, now }) + '\n');
  } catch {
    process.stdout.write(`${BRAND_BOLD}[HUD]${RESET}\n`);
  }
}

const isDirectRun = process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/\\/g, '/'));
if (isDirectRun) main();
