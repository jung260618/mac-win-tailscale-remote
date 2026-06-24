#!/usr/bin/env node
/*
 * Claude Code custom statusline
 * Renders: 🏷 session  📁 dir  📝 note  🤖 model⚡effort  🧠 context  ⏳ 5h  📅 7d
 * Input: JSON on stdin (see https://code.claude.com/docs/en/statusline)
 */
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

// ---- read stdin ----
let raw = '';
try { raw = fs.readFileSync(0, 'utf8'); } catch (_) { raw = ''; }

let d = {};
try { d = JSON.parse(raw || '{}'); } catch (_) { d = {}; }

// ---- ANSI helpers ----
const C = {
  reset: '\x1b[0m',
  dim:   '\x1b[2m',
  gray:  '\x1b[38;5;245m',
  green: '\x1b[38;5;78m',
  yellow:'\x1b[38;5;221m',
  red:   '\x1b[38;5;203m',
  cyan:  '\x1b[38;5;80m',
  blue:  '\x1b[38;5;111m',
  mag:   '\x1b[38;5;176m',
};
const paint = (s, c) => `${c}${s}${C.reset}`;

// visible width: strip ANSI, drop variation selectors, count emoji as 2 cols
function vlen(s) {
  const plain = s.replace(/\x1b\[[0-9;]*m/g, '').replace(/️/g, '');
  let w = [...plain].length;
  const wide = plain.match(/[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{23E9}-\u{23FA}]/gu);
  if (wide) w += wide.length;
  return w;
}

// usage -> color
function lvlColor(pct) {
  if (pct >= 85) return C.red;
  if (pct >= 60) return C.yellow;
  return C.green;
}

// 5-segment progress bar (compact, fits split panes)
const BARW = 5;
function bar(pct) {
  const p = Math.max(0, Math.min(100, Number(pct) || 0));
  const filled = Math.round((p / 100) * BARW);
  const col = lvlColor(p);
  return paint('█'.repeat(filled) + C.gray + '░'.repeat(BARW - filled), col);
}

// seconds-until -> "Xd Yh" / "Xh Ym" / "Zm"
function untilStr(epochSec) {
  if (!epochSec) return '';
  const diff = Math.floor(Number(epochSec) - Date.now() / 1000);
  if (!isFinite(diff) || diff <= 0) return 'now';
  const dd = Math.floor(diff / 86400);
  const hh = Math.floor((diff % 86400) / 3600);
  const mm = Math.floor((diff % 3600) / 60);
  if (dd > 0) return `${dd}d ${hh}h`;
  if (hh > 0) return `${hh}h ${mm}m`;
  return `${mm}m`;
}

// ---- gather fields (defensive) ----
// Order = priority. Narrow split panes clip from the RIGHT, so the usage
// indicators go first and the long session name goes last (clipped first).
const segs = [];

// 🏷 session name (capped so it doesn't push usage off-screen)
const sessionName = d.session_name;
if (sessionName) {
  const sn = sessionName.length > 24 ? sessionName.slice(0, 23) + '…' : sessionName;
  segs.push(paint('🏷 ' + sn, C.mag));
}

// 🧠 context window usage
const cw = d.context_window || {};
let ctxPct = cw.used_percentage;
if (ctxPct == null && cw.context_window_size) {
  const used = (cw.total_input_tokens || 0) + (cw.total_output_tokens || 0);
  ctxPct = (used / cw.context_window_size) * 100;
}
if (ctxPct != null) {
  segs.push('🧠 ' + bar(ctxPct) + ' ' + paint(Math.round(ctxPct) + '%', lvlColor(ctxPct)));
}

// ⏳ 5-hour rate limit  /  📅 7-day rate limit  (Pro/Max only, after first response)
const rl = d.rate_limits || {};
function limitSeg(icon, label, obj) {
  if (!obj || obj.used_percentage == null) return null;
  const pct = obj.used_percentage;
  const reset = untilStr(obj.resets_at);
  let s = `${icon}${label} ` + bar(pct) + ' ' +
          paint(Math.round(pct) + '%', lvlColor(pct));
  if (reset) s += paint(` ${reset.replace(/ /g, '')}`, C.gray);
  return s;
}
const s5 = limitSeg('⏳', '5h', rl.five_hour);
const s7 = limitSeg('📅', '7d', rl.seven_day);
if (s5) segs.push(s5);
if (s7) segs.push(s7);

// 🤖 model (strip parentheticals like "(1M context)") + effort
let model = (d.model && d.model.display_name) || (d.model && d.model.id) || '';
model = model.replace(/\s*\([^)]*\)\s*$/, '').trim();
let effort = (d.effort && d.effort.level) || d.effort_level ||
             (d.model && d.model.effort) || '';
let modelSeg = '🤖 ' + model;
if (effort) modelSeg += ' ⚡' + effort;
if (model) segs.push(paint(modelSeg, C.cyan));

// 📁 current directory (basename)
const cwd = (d.workspace && d.workspace.current_dir) || d.cwd || '';
if (cwd) segs.push(paint('📁 ' + path.basename(cwd), C.blue));

// 📝 optional note from ~/.claude/statusline-note.txt
try {
  const noteFile = path.join(os.homedir(), '.claude', 'statusline-note.txt');
  if (fs.existsSync(noteFile)) {
    const note = fs.readFileSync(noteFile, 'utf8').trim().split(/\r?\n/)[0];
    if (note) segs.push(paint('📝 ' + note, C.gray));
  }
} catch (_) {}

// ---- join: pack into lines that fit the current pane width ----
const SEP = ' ' + paint('|', C.gray) + ' ';
const SEPW = 3; // visible width of " | "
const cols = parseInt(process.env.COLUMNS, 10) || 0;

if (!cols) {
  // width unknown -> single line (old behavior)
  process.stdout.write(segs.join(SEP));
} else {
  const max = cols - 1; // small safety margin
  const lines = [];
  let cur = '', curw = 0;
  for (const seg of segs) {
    const sw = vlen(seg);
    if (cur === '') { cur = seg; curw = sw; }
    else if (curw + SEPW + sw <= max) { cur += SEP + seg; curw += SEPW + sw; }
    else { lines.push(cur); cur = seg; curw = sw; }
  }
  if (cur) lines.push(cur);
  process.stdout.write(lines.join('\n'));
}
