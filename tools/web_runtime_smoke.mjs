import { chromium } from "playwright";
import fs from "node:fs";

const baseUrl = process.env.ASHEN_VOW_URL || "http://127.0.0.1:8080/index.html";
const outDir = process.env.ASHEN_VOW_BROWSER_ARTIFACTS || "build/browser-smoke";
fs.mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-angle=swiftshader", "--enable-webgl", "--ignore-gpu-blocklist"],
});

const consoleErrors = [];
const pageErrors = [];
const page = await browser.newPage({
  viewport: { width: 1280, height: 800 },
  deviceScaleFactor: 1,
});

page.on("console", (message) => {
  const line = `[${message.type()}] ${message.text()}`;
  if (message.type() === "error") consoleErrors.push(line);
});
page.on("pageerror", (error) => pageErrors.push(String(error)));

await page.goto(baseUrl, { waitUntil: "domcontentloaded", timeout: 120_000 });
await page.waitForSelector("canvas", { state: "visible", timeout: 120_000 });
await page.waitForFunction(() => {
  const canvas = document.querySelector("canvas");
  return canvas && canvas.width >= 640 && canvas.height >= 360;
}, null, { timeout: 120_000 });
await page.waitForTimeout(5000);

const pwa = await page.evaluate(async () => {
  const manifest = document.querySelector('link[rel="manifest"]')?.getAttribute("href") || "";
  let serviceWorkerActive = false;
  if ("serviceWorker" in navigator) {
    try {
      const registration = await Promise.race([
        navigator.serviceWorker.ready,
        new Promise((_, reject) => setTimeout(() => reject(new Error("service worker timeout")), 15000)),
      ]);
      serviceWorkerActive = Boolean(registration?.active);
    } catch {
      serviceWorkerActive = false;
    }
  }
  return { manifest, serviceWorkerActive };
});
if (!pwa.manifest || !pwa.serviceWorkerActive) {
  throw new Error(`PWA registration failed: ${JSON.stringify(pwa)}`);
}

const titleCanvas = await page.locator("canvas").boundingBox();
if (!titleCanvas || titleCanvas.width < 640 || titleCanvas.height < 360) {
  throw new Error(`Godot canvas has invalid bounds: ${JSON.stringify(titleCanvas)}`);
}
await page.screenshot({ path: `${outDir}/01_web_title.png`, fullPage: true });

await page.keyboard.press("Enter");
await page.waitForTimeout(4000);
await page.screenshot({ path: `${outDir}/02_web_gameplay.png`, fullPage: true });

await page.keyboard.down("KeyD");
await page.waitForTimeout(700);
await page.keyboard.up("KeyD");
await page.waitForTimeout(500);
await page.screenshot({ path: `${outDir}/03_web_movement.png`, fullPage: true });

const runtime = await page.evaluate(() => {
  const canvas = document.querySelector("canvas");
  const rect = canvas.getBoundingClientRect();
  return {
    title: document.title,
    canvasWidth: canvas.width,
    canvasHeight: canvas.height,
    cssWidth: Math.round(rect.width),
    cssHeight: Math.round(rect.height),
    visibility: document.visibilityState,
    pwa,
  };
});

const ignoredConsolePatterns = [
  /AudioContext/i,
  /autoplay/i,
  /favicon/i,
];
const actionableConsoleErrors = consoleErrors.filter(
  (line) => !ignoredConsolePatterns.some((pattern) => pattern.test(line)),
);

const summary = {
  url: baseUrl,
  runtime,
  consoleErrors,
  pageErrors,
  actionableConsoleErrors,
};
fs.writeFileSync(`${outDir}/browser-smoke.json`, JSON.stringify(summary, null, 2) + "\n");

await browser.close();

if (pageErrors.length > 0 || actionableConsoleErrors.length > 0) {
  throw new Error(
    `Browser runtime errors: page=${pageErrors.length}, console=${actionableConsoleErrors.length}`,
  );
}

console.log("WEB_RUNTIME_SMOKE", JSON.stringify(runtime));
