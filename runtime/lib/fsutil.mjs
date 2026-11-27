/**
 * Small filesystem helpers shared by the HUD and the aggregator.
 * Pure Node.js, no dependencies.
 */

import { readFileSync, writeFileSync, renameSync, mkdirSync, openSync, closeSync, constants } from 'node:fs';
import { dirname } from 'node:path';
import { randomBytes } from 'node:crypto';

export function readJsonSync(filePath) {
  try {
    return JSON.parse(readFileSync(filePath, 'utf8'));
  } catch {
    return null;
  }
}

/**
 * Write JSON atomically: write to a unique temp file in the same directory,
 * then rename over the target. A reader never sees a half-written file, and
 * two writers never share a temp path.
 */
export function writeJsonAtomicSync(filePath, data, { pretty = false } = {}) {
  mkdirSync(dirname(filePath), { recursive: true });
  const json = (pretty ? JSON.stringify(data, null, 2) : JSON.stringify(data)) + '\n';
  const tmp = `${filePath}.${process.pid}.${randomBytes(4).toString('hex')}.tmp`;
  writeFileSync(tmp, json, 'utf8');
  renameSync(tmp, filePath);
  return json;
}

/**
 * Create a file only if it does not exist yet (O_EXCL). Returns true when
 * this call created it. Used for one-time migrations where two processes
 * might race.
 */
export function writeJsonExclusiveSync(filePath, data) {
  mkdirSync(dirname(filePath), { recursive: true });
  let fd;
  try {
    fd = openSync(filePath, constants.O_WRONLY | constants.O_CREAT | constants.O_EXCL, 0o644);
  } catch {
    return false;
  }
  try {
    writeFileSync(fd, JSON.stringify(data, null, 2) + '\n', 'utf8');
  } finally {
    closeSync(fd);
  }
  return true;
}
