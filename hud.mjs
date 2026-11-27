#!/usr/bin/env node
// Compatibility shim: older installs point Claude Code's statusLine here.
// The HUD now lives in runtime/hud.mjs.
import { main } from './runtime/hud.mjs';
main();
