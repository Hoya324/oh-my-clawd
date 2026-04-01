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
    return JSON.parse(readFileSync(PROGRESS_PATH, 'utf-8'));
  } catch {
    return {
      stats: { totalSessions: 0, totalTimeMinutes: 0 },
      unlocked: ['cat'],
      selectedPet: 'cat',
    };
  }
}

// Simple 8x8 pixel art representations for SVG (scaled up)
const PET_PIXELS = {
  cat: [
    '..OO..OO',
    '.OCCCCCO',
    '.CCOOCCC',
    '.CCCPPCC',
    '..CCCCC.',
    '.DDDDDDD',
    '.DDDDDDD',
    '..OOOOO.',
  ],
  hamster: [
    '..MMMM..',
    '.MMEEMM.',
    'MMEBBEMM',
    'MMEEPEEMM',
    '.MEEEEEM.',
    '..NNNN..',
    '.NNNNNN.',
    '..OOOO..',
  ],
  chick: [
    '...YY...',
    '..YYYY..',
    '.YBYBYY.',
    '.YYOOYY.',
    '..YYYY..',
    '..YYYY..',
    '...OO...',
    '..O..O..',
  ],
  penguin: [
    '..BBBB..',
    '.BBWWBB.',
    '.BWBWWB.',
    '.BWWWWB.',
    '.BBWWBB.',
    '..BWWB..',
    '..BWWB..',
    '..OO.OO.',
  ],
  fox: [
    '.OO..OO.',
    'OOOOOOOO',
    'OWOBBOW0',
    'OOWWWWOO',
    '.OOWWOO.',
    '..OOOO..',
    '.OOOOOO.',
    'OO....OW',
  ],
  rabbit: [
    '.WW..WW.',
    '.WW..WW.',
    '.WWWWWW.',
    'WWBWWBWW',
    'WWWWPWWW',
    '.WWWWWW.',
    '..WWWW..',
    '..WW.WW.',
  ],
  goose: [
    '...WW...',
    '..WWWW..',
    '.WBWWBW.',
    '..OOOO..',
    '...WW...',
    '..WWWW..',
    '.WWWWWW.',
    '..OO.OO.',
  ],
  capybara: [
    '.MMMMMM.',
    'MMMBMMM.',
    'MMBBMMM.',
    'MMMPMMM.',
    '.EEEEEE.',
    '.EEEEEE.',
    '.NNNNNN.',
    '.NN..NN.',
  ],
  sloth: [
    '..NNNN..',
    '.NEENNE.',
    'NEBBEEN.',
    '.NEEPEN.',
    '..NNNN..',
    '.NNNNNN.',
    'NNNNNNNN',
    '.NN..NN.',
  ],
  owl: [
    '..GGGG..',
    '.GYYGYG.',
    'GYBGBYGG',
    '.GGOGG..',
    '..GGGG..',
    '.EEEEEE.',
    '.GGGGGG.',
    '..GG.GG.',
  ],
  dragon: [
    '.RR..RR.',
    'RRRRRRRR',
    'RRBRRBRR',
    'RRRYYRRR',
    '.RYYYR..',
    'GRRRRRRG',
    '.RRRRRR.',
    '.RR..RR.',
  ],
  unicorn: [
    '...Y....',
    '..YY....',
    '.WWWWW..',
    'WWBWWBW.',
    'WWWPWWW.',
    '.WWWWW..',
    'RWYWGWBW',
    '.WW..WW.',
  ],
};

const COLOR_MAP = {
  'C': '#06B6D4', 'D': '#059BB0', 'W': '#FFFFFF', 'B': '#2D2D2D',
  'P': '#F5A0B8', 'K': '#FFB8C8', 'O': '#FF8C42', 'Y': '#FFD93D',
  'G': '#7C3AED', 'S': '#87CEEB', 'R': '#FF5722', 'Z': '#AAAAAA',
  'M': '#8B5E3C', 'N': '#6B4226', 'E': '#FFE0B2',
};

function renderPetSvg(petId, x, y, scale = 4) {
  const pixels = PET_PIXELS[petId];
  if (!pixels) return '';
  let rects = '';
  for (let row = 0; row < pixels.length; row++) {
    for (let col = 0; col < pixels[row].length; col++) {
      const ch = pixels[row][col];
      if (ch === '.') continue;
      const color = COLOR_MAP[ch] || '#888';
      rects += `<rect x="${x + col * scale}" y="${y + row * scale}" width="${scale}" height="${scale}" fill="${color}"/>`;
    }
  }
  return rects;
}

function generateBadge() {
  const progress = loadProgress();
  const pet = progress.selectedPet || 'cat';
  const unlockCount = progress.unlocked?.length || 1;
  const totalMinutes = progress.stats?.totalTimeMinutes || 0;
  const hours = Math.floor(totalMinutes / 60);

  const width = 200;
  const height = 80;

  const petArt = renderPetSvg(pet, 12, 12, 5);
  const petName = pet.charAt(0).toUpperCase() + pet.slice(1);

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
  <rect x="1" y="1" width="${width-2}" height="${height-2}" rx="7" fill="none" stroke="#06B6D4" stroke-opacity="0.3"/>
  ${petArt}
  <text x="72" y="28" class="title">Claude Pet</text>
  <text x="72" y="44" class="stat">${petName} | ${unlockCount}/12 unlocked</text>
  <text x="72" y="58" class="stat">${hours}h total coding</text>
  <circle cx="${width-12}" cy="12" r="2" fill="#06B6D4" class="sparkle"/>
</svg>`;
}

process.stdout.write(generateBadge() + '\n');
