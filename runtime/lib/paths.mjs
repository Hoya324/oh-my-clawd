/**
 * Every file oh-my-clawd reads or writes lives under ~/.claude/pet so that
 * nothing is ever written into the user's project directories.
 *
 *   ~/.claude/pet/
 *     pet-state.json        aggregator → app   (live sessions, rate limit)
 *     progress.json         aggregator only    (stats, unlocks)
 *     selection.json        app only           (selected hat/glasses/pants)
 *     usage-cache.json      HUD + app          (shared usage API cache)
 *     sessions/<id>.json    HUD → aggregator   (per-session state)
 *     runtime/              installed copy of these scripts
 *
 * OH_MY_CLAWD_HOME overrides the root (used by tests).
 */

import { homedir } from 'node:os';
import { join } from 'node:path';

export function homeDir() {
  return process.env.OH_MY_CLAWD_HOME || process.env.HOME || homedir();
}

export function claudeDir() {
  return join(homeDir(), '.claude');
}

export function petDir() {
  return join(claudeDir(), 'pet');
}

export const paths = {
  get petDir() { return petDir(); },
  get claudeSessionsDir() { return join(claudeDir(), 'sessions'); },
  get petState() { return join(petDir(), 'pet-state.json'); },
  get progress() { return join(petDir(), 'progress.json'); },
  get selection() { return join(petDir(), 'selection.json'); },
  get usageCache() { return join(petDir(), 'usage-cache.json'); },
  get sessionsDir() { return join(petDir(), 'sessions'); },
  sessionState(sessionId) { return join(petDir(), 'sessions', `${sanitizeId(sessionId)}.json`); },
};

/** Session ids become file names: keep them to a safe character set. */
export function sanitizeId(id) {
  return String(id || 'default').replace(/[^A-Za-z0-9._-]/g, '_').slice(0, 128);
}
