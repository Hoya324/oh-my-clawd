/**
 * Shared Anthropic usage (rate limit) lookup.
 *
 * Both the HUD and the menu bar app read and write the same cache file
 * (~/.claude/pet/usage-cache.json), so whichever runs first serves the
 * other and the API is hit at most once per TTL.
 *
 * IMPORTANT: this module never refreshes OAuth tokens. Refreshing with
 * Claude Code's refresh token without writing the result back can rotate
 * the token out from under Claude Code and sign the user out. When the
 * access token has expired we simply serve the cached value until Claude
 * Code refreshes it itself.
 */

import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { userInfo } from 'node:os';
import https from 'node:https';

import { paths, claudeDir } from './paths.mjs';
import { readJsonSync, writeJsonAtomicSync } from './fsutil.mjs';

export const USAGE_TTL_MS = 90_000;
export const USAGE_FAILURE_TTL_MS = 30_000;
export const USAGE_RATE_LIMIT_BACKOFF_MS = 5 * 60_000;
const API_TIMEOUT_MS = 10_000;

// ---------------------------------------------------------------------------
// Credentials (read-only)
// ---------------------------------------------------------------------------

function configDir() {
  return process.env.CLAUDE_CONFIG_DIR || claudeDir();
}

function keychainServiceName() {
  const dir = process.env.CLAUDE_CONFIG_DIR;
  if (dir) {
    const hash = createHash('sha256').update(dir).digest('hex').slice(0, 8);
    return `Claude Code-credentials-${hash}`;
  }
  return 'Claude Code-credentials';
}

function parseCredentialBlob(raw, source) {
  try {
    const parsed = JSON.parse(raw);
    const creds = parsed.claudeAiOauth || parsed;
    if (!creds?.accessToken) return null;
    return { accessToken: creds.accessToken, expiresAt: creds.expiresAt ?? null, source };
  } catch {
    return null;
  }
}

function readKeychain(account) {
  try {
    const args = ['find-generic-password', '-s', keychainServiceName()];
    if (account) args.push('-a', account);
    args.push('-w');
    // execFile (no shell) so the service name can never be interpreted.
    const out = execFileSync('/usr/bin/security', args, {
      encoding: 'utf8', timeout: 2000, stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    return out ? parseCredentialBlob(out, 'keychain') : null;
  } catch {
    return null;
  }
}

function readKeychainCredentials() {
  if (process.platform !== 'darwin') return null;
  const accounts = [];
  try {
    const name = userInfo().username?.trim();
    if (name) accounts.push(name);
  } catch {}
  accounts.push(undefined);

  let expired = null;
  for (const account of accounts) {
    const creds = readKeychain(account);
    if (!creds) continue;
    if (!creds.expiresAt || creds.expiresAt > Date.now()) return creds;
    expired ??= creds;
  }
  return expired;
}

function readFileCredentials() {
  const p = join(configDir(), '.credentials.json');
  if (!existsSync(p)) return null;
  try {
    return parseCredentialBlob(readFileSync(p, 'utf8'), 'file');
  } catch {
    return null;
  }
}

export function readCredentials() {
  return readKeychainCredentials() || readFileCredentials();
}

// ---------------------------------------------------------------------------
// API
// ---------------------------------------------------------------------------

export function fetchUsageFromApi(accessToken) {
  return new Promise((resolve) => {
    const req = https.request({
      hostname: 'api.anthropic.com',
      path: '/api/oauth/usage',
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'anthropic-beta': 'oauth-2025-04-20',
        'Content-Type': 'application/json',
      },
      timeout: API_TIMEOUT_MS,
    }, (res) => {
      let body = '';
      res.on('data', (c) => { body += c; });
      res.on('end', () => {
        if (res.statusCode === 200) {
          try { resolve({ status: 200, body: JSON.parse(body) }); }
          catch { resolve({ status: 200, body: null }); }
        } else {
          resolve({ status: res.statusCode, body: null });
        }
      });
    });
    req.on('error', () => resolve({ status: 0, body: null }));
    req.on('timeout', () => { req.destroy(); resolve({ status: 0, body: null }); });
    req.end();
  });
}

function clampPercent(v) {
  if (v == null || !Number.isFinite(v)) return null;
  return Math.max(0, Math.min(100, v));
}

function isoOrNull(s) {
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d.toISOString();
}

/** Normalize the API body into the cache's `data` shape (ISO strings). */
export function parseUsageResponse(body) {
  if (!body) return null;
  const five = clampPercent(body.five_hour?.utilization);
  const week = clampPercent(body.seven_day?.utilization);
  if (five == null && week == null) return null;
  // Per-model weekly limits, when the account has them (same keys the app reads).
  const models = [];
  for (const model of ['opus', 'sonnet']) {
    const pct = clampPercent(body[`seven_day_${model}`]?.utilization);
    if (pct != null) models.push({ model, percent: pct, resetsAt: isoOrNull(body[`seven_day_${model}`]?.resets_at) });
  }
  return {
    fiveHourPercent: five,
    weeklyPercent: week,
    fiveHourResetsAt: isoOrNull(body.five_hour?.resets_at),
    weeklyResetsAt: isoOrNull(body.seven_day?.resets_at),
    models,
  };
}

// ---------------------------------------------------------------------------
// Cache
// ---------------------------------------------------------------------------

export function readUsageCache() {
  const cache = readJsonSync(paths.usageCache);
  if (!cache || typeof cache.timestamp !== 'number') return null;
  return cache;
}

export function writeUsageCache(entry) {
  try { writeJsonAtomicSync(paths.usageCache, entry); } catch {}
}

/** True when the cache should be served without calling the API. */
export function isCacheFresh(cache, now = Date.now()) {
  if (!cache) return false;
  if (cache.retryAfter && now < cache.retryAfter) return true;
  const ttl = cache.error ? USAGE_FAILURE_TTL_MS : USAGE_TTL_MS;
  return now - cache.timestamp < ttl;
}

/**
 * Returns the latest usage data (or null). Never refreshes tokens.
 * Dependencies are injectable for tests.
 */
export async function getUsage({
  now = Date.now(),
  readCreds = readCredentials,
  fetchUsage = fetchUsageFromApi,
  source = 'hud',
} = {}) {
  const cache = readUsageCache();
  if (isCacheFresh(cache, now)) return cache.data ?? null;

  const creds = readCreds();
  if (!creds) return cache?.data ?? null;
  if (creds.expiresAt && creds.expiresAt <= now) {
    // Expired: leave refreshing to Claude Code. Keep the last good data.
    return cache?.data ?? null;
  }

  const res = await fetchUsage(creds.accessToken);
  const data = res.status === 200 ? parseUsageResponse(res.body) : null;
  if (data) {
    writeUsageCache({ timestamp: now, data, error: false, source });
    return data;
  }

  const entry = {
    timestamp: now,
    data: cache?.data ?? null,   // keep showing the last good value
    error: true,
    source,
  };
  if (res.status === 429) entry.retryAfter = now + USAGE_RATE_LIMIT_BACKOFF_MS;
  writeUsageCache(entry);
  return entry.data;
}
