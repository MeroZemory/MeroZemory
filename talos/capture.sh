#!/usr/bin/env bash
set -euo pipefail

TALOS_VIZ_DIR="${1:-/Users/merozemory/projects/MeroZemory/aegis-nexus/talos/src/talos-viz}"
OUT_DIR="$(cd "$(dirname "$0")" && pwd)"
PORT="${PORT:-4173}"

cd "$TALOS_VIZ_DIR"
nohup npm run dev -- --host 127.0.0.1 --port "$PORT" >/tmp/talos-viz-dev.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT

for i in {1..60}; do
  if curl -sSf "http://127.0.0.1:${PORT}" >/dev/null 2>&1; then break; fi
  sleep 1
done

OUT_DIR="$OUT_DIR" PORT="$PORT" node --input-type=module <<'EON'
import { chromium } from 'playwright';
import fs from 'fs';

const outDir = process.env.OUT_DIR;
const port = process.env.PORT || '4173';
fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 1720, height: 1080 } });
await page.goto(`http://127.0.0.1:${port}`, { waitUntil: 'domcontentloaded', timeout: 60000 });
await page.waitForTimeout(5000);

await page.screenshot({ path: `${outDir}/talos-hero-globe-dashboard.png` });
await page.evaluate(() => document.querySelector('button[title="Engagement mode"]')?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
await page.waitForTimeout(1500);
await page.screenshot({ path: `${outDir}/talos-engagement-3d-hud.png` });

await page.evaluate(() => Array.from(document.querySelectorAll('button')).find(b => b.textContent?.trim() === 'KPI Dashboard')?.dispatchEvent(new MouseEvent('click', { bubbles: true })));
await page.waitForTimeout(1500);
await page.screenshot({ path: `${outDir}/talos-kpi-dashboard-full.png` });

await browser.close();
EON
