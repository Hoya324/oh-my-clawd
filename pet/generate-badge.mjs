#!/usr/bin/env node

/**
 * generate-badge.mjs
 *
 * Reads ~/.claude/pet/progress.json and generates an SVG badge
 * showing the selected pet, muscle stage, and unlock count.
 *
 * Usage: node pet/generate-badge.mjs > docs/pet-badge.svg
 */

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const PROGRESS_PATH = join(homedir(), '.claude', 'pet', 'progress.json');

function loadProgress() {
  try {
    const data = JSON.parse(readFileSync(PROGRESS_PATH, 'utf-8'));
    // Handle v1 schema
    if (!data.version || data.version < 2) {
      return {
        version: 2,
        stats: data.stats || { totalSessions: 0, totalTimeMinutes: 0 },
        unlockedAccessories: [],
        selectedHat: null,
        selectedGlasses: null,
        unlockedAt: {},
      };
    }
    return data;
  } catch {
    return {
      version: 2,
      stats: { totalSessions: 0, totalTimeMinutes: 0 },
      unlockedAccessories: [],
      selectedHat: null,
      selectedGlasses: null,
      unlockedAt: {},
    };
  }
}

// Clawd character 8x8 pixel art for SVG badge
const CLAWD_PIXELS = [
  '..MMMMMM..',
  '.MMMMMMMMM',
  '.MMMMMMMMM',
  '.MM.MM.MMM',
  '.MM.MM.MMM',
  '.MMMMMMMMM',
  'MM.MMMM.MM',
  '.MMMMMMMM.',
  '..M.MM.M..',
  '..M.MM.M..',
];

const COLOR_MAP = {
  'M': '#D97757', 'B': '#2D2D2D', 'W': '#FFFFFF',
};

function renderClawdSvg(x, y, scale = 4) {
  let rects = '';
  for (let row = 0; row < CLAWD_PIXELS.length; row++) {
    for (let col = 0; col < CLAWD_PIXELS[row].length; col++) {
      const ch = CLAWD_PIXELS[row][col];
      if (ch === '.') continue;
      const color = COLOR_MAP[ch] || '#D97757';
      rects += `<rect x="${x + col * scale}" y="${y + row * scale}" width="${scale}" height="${scale}" fill="${color}"/>`;
    }
  }
  return rects;
}

function generateBadge() {
  const progress = loadProgress();
  const unlockCount = progress.unlockedAccessories?.length || 0;
  const totalMinutes = progress.stats?.totalTimeMinutes || 0;
  const hours = Math.floor(totalMinutes / 60);

  const hat = progress.selectedHat;
  const glasses = progress.selectedGlasses;
  const accessoryLabel = [hat, glasses].filter(Boolean).join(' + ') || 'No accessories';

  const width = 200;
  const height = 80;

  const clawdArt = renderClawdSvg(12, 8, 5);

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <defs>
    <style>
      @keyframes sparkle { 0%,100% { opacity:1; } 50% { opacity:0.3; } }
      .title { font: bold 13px monospace; fill: #E0E0E0; }
      .stat { font: 10px monospace; fill: #AAAAAA; }
      .sparkle { animation: sparkle 2s ease-in-out infinite; }
    </style>
  </defs>
  <rect width="${width}" height="${height}" rx="8" fill="#1a1a2e"/>
  <rect x="1" y="1" width="${width-2}" height="${height-2}" rx="7" fill="none" stroke="#D97757" stroke-opacity="0.3"/>
  ${clawdArt}
  <text x="72" y="28" class="title">oh-my-clawd</text>
  <text x="72" y="44" class="stat">${unlockCount}/9 accessories</text>
  <text x="72" y="58" class="stat">${hours}h total coding</text>
  <circle cx="${width-12}" cy="12" r="2" fill="#D97757" class="sparkle"/>
</svg>`;
}

process.stdout.write(generateBadge() + '\n');
