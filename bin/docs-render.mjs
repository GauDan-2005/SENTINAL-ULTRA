#!/usr/bin/env node
// docs-render.mjs - render every Sentinel Ultra Hub tab in headless Chrome and dump its HTML.
//
// The Hub is a single-page app: all tab text is compiled into one JS bundle and there are no
// per-page endpoints, so the only faithful way to export a tab is to render it and read the DOM.
// This is the first half of bin/docs-export.sh; bin/docs-html2md.py is the second.
//
// The Hub sits behind an email gate. It is a CLIENT-SIDE check: the bundle carries a list of
// SHA-256 hashes of approved contributor addresses, compares the address you type against that
// list in the browser, and stores the result in sessionStorage under "sentinel-ultra-auth".
// There is no server call and no token, but there is also no way to render a tab without an
// approved address. Pass one in SENTINEL_HUB_EMAIL. It is not a credential and it is not stored
// here, which is why this file has no default.
//
// Usage: SENTINEL_HUB_EMAIL=you@example.com node bin/docs-render.mjs <out-dir>
//
// Writes <out-dir>/<slug>.html (the .content innerHTML), <slug>.txt (innerText, useful for a
// content-coverage diff) and tabs.json. Exit 0 on success, 3 on a setup failure.

import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync } from 'node:fs';

const OUT = process.argv[2];
const EMAIL = process.env.SENTINEL_HUB_EMAIL;
// ?changelog reveals the Changelog tab, which is hidden from the live navigation otherwise.
const HUB = 'https://snorkel-ai.github.io/Sentinel_Ultra_Hub/?changelog';
const PORT = Number(process.env.SENTINEL_CDP_PORT || 9333);
// The welcome/update modal renders whenever localStorage's stamp differs from the bundle's build
// constant, and it sits over the tab buttons. Seeding any value suppresses it; the value itself
// does not matter because we never read it back.
const WELCOME_STAMP = '9999-12-31';

function die(msg) { console.error('SKIP ' + msg); process.exit(3); }

if (!OUT) die('usage: SENTINEL_HUB_EMAIL=... node bin/docs-render.mjs <out-dir>');
if (!EMAIL) die('SENTINEL_HUB_EMAIL is unset. The Hub will not render a tab without an approved address.');

mkdirSync(OUT, { recursive: true });

const chrome = spawn('google-chrome', [
  '--headless=new', `--remote-debugging-port=${PORT}`, '--disable-gpu', '--no-sandbox',
  '--disable-dev-shm-usage', `--user-data-dir=/tmp/chrome-sentinel-docs-${process.pid}`,
  '--window-size=1600,3000', 'about:blank',
], { stdio: ['ignore', 'pipe', 'pipe'] });
chrome.on('error', () => die('could not launch google-chrome'));
chrome.stderr.on('data', d => { if (process.env.DEBUG) process.stderr.write(d); });

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function wsUrl() {
  for (let i = 0; i < 60; i++) {
    try {
      const j = await (await fetch(`http://127.0.0.1:${PORT}/json/version`)).json();
      if (j.webSocketDebuggerUrl) return j.webSocketDebuggerUrl;
    } catch { /* not up yet */ }
    await sleep(250);
  }
  die('chrome did not open a debugging port');
}

const ws = new WebSocket(await wsUrl());
const pending = new Map();
let idc = 0;
await new Promise(r => ws.addEventListener('open', r));
ws.addEventListener('message', ev => {
  const m = JSON.parse(ev.data);
  if (!m.id || !pending.has(m.id)) return;
  const { res, rej } = pending.get(m.id); pending.delete(m.id);
  m.error ? rej(new Error(JSON.stringify(m.error))) : res(m.result);
});
const raw = (method, params = {}, sessionId) => new Promise((res, rej) => {
  const id = ++idc;
  pending.set(id, { res, rej });
  ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
});

const { targetId } = await raw('Target.createTarget', { url: 'about:blank' });
const { sessionId } = await raw('Target.attachToTarget', { targetId, flatten: true });
const S = (m, p) => raw(m, p, sessionId);

await S('Page.enable');
await S('Runtime.enable');
await S('Page.addScriptToEvaluateOnNewDocument', {
  source: `try {
    sessionStorage.setItem('sentinel-ultra-auth', JSON.stringify({isAuthenticated:true,email:${JSON.stringify(EMAIL)}}));
    localStorage.setItem('sentinelWelcomeSeen', ${JSON.stringify(WELCOME_STAMP)});
  } catch (e) {}`,
});

async function evalJs(expression) {
  const r = await S('Runtime.evaluate', { expression, returnByValue: true });
  if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails).slice(0, 600));
  return r.result.value;
}

await S('Page.navigate', { url: HUB });
await sleep(4000);

const gate = await evalJs(`(() => ({
  login: !!document.querySelector('.login-card'),
  tabs: [...document.querySelectorAll('.tab-btn')].map(b => b.textContent),
  content: !!document.querySelector('.content'),
}))()`);

if (gate.login) die(`the Hub rejected ${EMAIL}. It is not on the approved-contributor allowlist.`);
if (!gate.content || !gate.tabs.length) die('the Hub rendered no .content or no tab buttons - the site layout changed');

const manifest = [];
for (let i = 0; i < gate.tabs.length; i++) {
  const label = gate.tabs[i];
  await evalJs(`(() => { [...document.querySelectorAll('.tab-btn')][${i}].click(); return 1; })()`);
  await sleep(1200);
  // Accordions ship collapsed and their content is in the DOM but hidden; open every one or the
  // Guidelines and FAQ tabs export with their bodies missing.
  await evalJs(`(() => { document.querySelectorAll('details').forEach(d => d.open = true); return 1; })()`);
  await sleep(600);
  const html = await evalJs(`document.querySelector('.content')?.innerHTML ?? ''`);
  const text = await evalJs(`document.querySelector('.content')?.innerText ?? ''`);
  if (!html) die(`tab "${label}" rendered empty`);
  const slug = label.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  writeFileSync(`${OUT}/${slug}.html`, html);
  writeFileSync(`${OUT}/${slug}.txt`, text);
  manifest.push({ index: i, label, slug, htmlBytes: html.length, textBytes: text.length });
  console.error(`rendered ${label} -> ${slug}.html (${html.length} bytes)`);
}

writeFileSync(`${OUT}/tabs.json`, JSON.stringify(manifest, null, 2) + '\n');
console.error(`${manifest.length} tabs written to ${OUT}`);
ws.close();
chrome.kill();
process.exit(0);
