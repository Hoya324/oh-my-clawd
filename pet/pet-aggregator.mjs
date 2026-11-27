#!/usr/bin/env node
// Compatibility shim: older LaunchAgents point here.
// The aggregator now lives in runtime/pet-aggregator.mjs.
import { start } from '../runtime/pet-aggregator.mjs';
start();
