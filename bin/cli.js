#!/usr/bin/env node

import { existsSync, mkdirSync, copyFileSync, readdirSync, statSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const { version: VERSION } = JSON.parse(readFileSync(join(__dirname, '..', 'package.json'), 'utf8'));
const CLAUDE_DIR = join(homedir(), '.claude');
const SRC_DIR = join(__dirname, '..', '.claude');

const args = process.argv.slice(2);

if (args.includes('--version') || args.includes('-v')) {
  console.log(VERSION);
  process.exit(0);
}

if (args[0] !== 'init') {
  console.log(`Usage: npx @oorn/dotclaude init`);
  process.exit(1);
}

// --- init ---

const green = (s) => `\x1b[32m${s}\x1b[0m`;
const dim   = (s) => `\x1b[90m${s}\x1b[0m`;
const bold  = (s) => `\x1b[1m${s}\x1b[0m`;

console.log(`\n${bold('dot-claude')} — installing Claude Code config\n`);

function installFile(src, dest) {
  const destDir = dirname(dest);
  if (!existsSync(destDir)) mkdirSync(destDir, { recursive: true });
  copyFileSync(src, dest);
  const rel = dest.replace(homedir(), '~');
  console.log(`  ${green('✓')} ${rel}`);
}

function installDir(srcDir, destDir) {
  if (!existsSync(srcDir)) return;
  for (const file of readdirSync(srcDir)) {
    const src = join(srcDir, file);
    if (statSync(src).isFile()) {
      installFile(src, join(destDir, file));
    }
  }
}

// Top-level files
for (const file of ['settings.json', 'statusline-command.sh']) {
  const src = join(SRC_DIR, file);
  if (existsSync(src)) installFile(src, join(CLAUDE_DIR, file));
}

// rules/
installDir(join(SRC_DIR, 'rules'), join(CLAUDE_DIR, 'rules'));

// skills/
const skillsSrc = join(SRC_DIR, 'skills');
if (existsSync(skillsSrc)) {
  for (const skill of readdirSync(skillsSrc)) {
    const skillDir = join(skillsSrc, skill);
    if (statSync(skillDir).isDirectory()) {
      installDir(skillDir, join(CLAUDE_DIR, 'skills', skill));
    }
  }
}

console.log(`\n${dim('Claude Code will pick up changes automatically.')}`);
console.log(`${dim('To update: npx @oorn/dotclaude@latest init')}\n`);
