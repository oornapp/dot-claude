#!/usr/bin/env node

import { existsSync, mkdirSync, copyFileSync, readdirSync, statSync, readFileSync } from 'fs';
import { join, dirname } from 'path';
import { homedir, platform } from 'os';
import { fileURLToPath } from 'url';
import { spawnSync } from 'child_process';

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

// --- jq check ---
const yellow = (s) => `\x1b[33m${s}\x1b[0m`;

function hasCmd(cmd) {
  return spawnSync(cmd, ['--version'], { stdio: 'ignore' }).status === 0;
}

function tryInstall(label, ...args) {
  console.log(`  ${yellow('!')} jq not found — installing via ${label}…`);
  return spawnSync(args[0], args.slice(1), { stdio: 'inherit' }).status === 0;
}

function installJq() {
  const os = platform();

  if (os === 'darwin') {
    if (hasCmd('brew'))   return tryInstall('Homebrew', 'brew', 'install', 'jq');
    if (hasCmd('port'))   return tryInstall('MacPorts', 'sudo', 'port', 'install', 'jq');
  }

  if (os === 'linux') {
    if (hasCmd('apt-get'))  return tryInstall('apt',    'sudo', 'apt-get', 'install', '-y', 'jq');
    if (hasCmd('dnf'))      return tryInstall('dnf',    'sudo', 'dnf',     'install', '-y', 'jq');
    if (hasCmd('yum'))      return tryInstall('yum',    'sudo', 'yum',     'install', '-y', 'jq');
    if (hasCmd('pacman'))   return tryInstall('pacman', 'sudo', 'pacman',  '-S', '--noconfirm', 'jq');
    if (hasCmd('zypper'))   return tryInstall('zypper', 'sudo', 'zypper',  'install', '-y', 'jq');
    if (hasCmd('apk'))      return tryInstall('apk',    'sudo', 'apk',     'add', 'jq');
  }

  if (os === 'win32') {
    if (hasCmd('winget'))  return tryInstall('winget', 'winget', 'install', '--id', 'jqlang.jq', '-e', '--silent');
    if (hasCmd('choco'))   return tryInstall('Chocolatey', 'choco', 'install', 'jq', '-y');
    if (hasCmd('scoop'))   return tryInstall('Scoop', 'scoop', 'install', 'jq');
  }

  return false;
}

if (!hasCmd('jq')) {
  const installed = installJq();
  if (installed) {
    console.log(`  ${green('✓')} jq installed`);
  } else {
    console.log(`\n  ${yellow('!')} jq is required for the statusline but could not be installed automatically.`);
    console.log(`  ${dim('Install it manually:')}`);
    console.log(`  ${dim('  macOS:   brew install jq')}`);
    console.log(`  ${dim('  Ubuntu:  sudo apt install jq')}`);
    console.log(`  ${dim('  Fedora:  sudo dnf install jq')}`);
    console.log(`  ${dim('  Arch:    sudo pacman -S jq')}`);
    console.log(`  ${dim('  Alpine:  sudo apk add jq')}`);
    console.log(`  ${dim('  Windows: winget install jqlang.jq')}`);
  }
} else {
  console.log(`  ${green('✓')} jq`);
}

console.log(`\n${dim('Claude Code will pick up changes automatically.')}`);
console.log(`${dim('To update: npx @oorn/dotclaude@latest init')}\n`);
