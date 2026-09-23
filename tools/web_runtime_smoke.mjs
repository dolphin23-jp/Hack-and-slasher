import { chromium } from "playwright";
import fs from "node:fs";

const url = new URL(process.env.ASHEN_VOW_URL || "http://127.0.0.1:8080/index.html");
url.searchParams.set("smoke", "1");
const baseUrl = url.href;
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

const titleCanvas = await page.locator("canvas").boundingBox();
if (!titleCanvas || titleCanvas.width < 640 || titleCanvas.height < 360) {
  throw new Error(`Godot canvas has invalid bounds: ${JSON.stringify(titleCanvas)}`);
}
await page.screenshot({ path: `${outDir}/01_web_title.png`, fullPage: true });

const clickBase = async (x,y) => {
  const c=await page.locator("canvas").boundingBox();
  const scale=Math.min(c.width/1440,c.height/900);
  await page.mouse.click(c.x+(c.width-1440*scale)/2+x*scale,c.y+(c.height-900*scale)/2+y*scale);
};
await page.keyboard.press("Enter");
await page.waitForFunction(()=>window.__ashenSmoke?.mode==="build_confirm");
await clickBase(720,677);
await page.waitForFunction(()=>window.__ashenSmoke?.mode==="play");
await clickBase(720,132);
await page.waitForFunction(()=>window.__ashenSmoke?.mode==="route");
await page.screenshot({path:`${outDir}/02a_web_routes.png`});
await clickBase(255,780);
await page.waitForFunction(()=>window.__ashenSmoke?.path.length===2 && window.__ashenSmoke.active>=0);

await page.screenshot({ path: `${outDir}/02_web_gameplay.png`, fullPage: true });

await page.keyboard.down("KeyD");
await page.waitForTimeout(700);
await page.keyboard.up("KeyD");
await page.waitForTimeout(500);
await page.screenshot({ path: `${outDir}/03_web_movement.png`, fullPage: true });

const runtime = await page.evaluate(async () => {
  const canvas = document.querySelector("canvas");
  const rect = canvas.getBoundingClientRect();
  const manifest = document.querySelector('link[rel="manifest"]')?.href || "";
  let serviceWorker = false;
  if ("serviceWorker" in navigator) {
    serviceWorker = await Promise.race([
      navigator.serviceWorker.ready.then(() => true),
      new Promise((resolve) => setTimeout(() => resolve(false), 10_000)),
    ]);
  }
  return {
    title: document.title,
    canvasWidth: canvas.width,
    canvasHeight: canvas.height,
    cssWidth: Math.round(rect.width),
    cssHeight: Math.round(rect.height),
    visibility: document.visibilityState,
    manifest,
    serviceWorker,
  };
});

if (!runtime.manifest || !runtime.serviceWorker) {
  throw new Error(`PWA registration incomplete: ${JSON.stringify(runtime)}`);
}

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

const touchErrors = [];
const touchPageErrors = [];
const touchPage = await browser.newPage({
  viewport: { width: 1024, height: 768 },
  deviceScaleFactor: 1,
  isMobile: true,
  hasTouch: true,
});
touchPage.on("console", (message) => {
  if (message.type() === "error") touchErrors.push(`[error] ${message.text()}`);
});
touchPage.on("pageerror", (error) => touchPageErrors.push(String(error)));

await touchPage.goto(baseUrl, { waitUntil: "domcontentloaded", timeout: 120_000 });
await touchPage.waitForSelector("canvas", { state: "visible", timeout: 120_000 });
await touchPage.waitForTimeout(5000);

const touchCanvas = await touchPage.locator("canvas").boundingBox();
if (!touchCanvas) throw new Error("Touch smoke canvas has no bounds");
const tapBase = async (x, y) => {
  // UI ignores touches for 180 ms after a mode change to prevent click-through.
  await touchPage.waitForTimeout(250);
  const scale = Math.min(touchCanvas.width / 1440, touchCanvas.height / 900);
  const offsetX = (touchCanvas.width - 1440 * scale) * 0.5;
  const offsetY = (touchCanvas.height - 900 * scale) * 0.5;
  const sx = touchCanvas.x + offsetX + x * scale;
  const sy = touchCanvas.y + offsetY + y * scale;
  await touchPage.touchscreen.tap(sx, sy);
};

await tapBase(281, 577);
await touchPage.waitForFunction(()=>window.__ashenSmoke?.mode==="build_confirm");
await tapBase(720,677);
await touchPage.waitForFunction(()=>window.__ashenSmoke?.mode==="play");
await tapBase(720,132);
await touchPage.waitForFunction(()=>window.__ashenSmoke?.mode==="route");
await touchPage.screenshot({path:`${outDir}/04a_web_ipad_routes.png`,fullPage:true});
await tapBase(255,780);
await touchPage.waitForFunction(()=>window.__ashenSmoke?.path.length===2 && window.__ashenSmoke.active>=0);
await touchPage.screenshot({ path: `${outDir}/04_web_touch_gameplay.png`, fullPage: true });

await tapBase(1128, 698);
await touchPage.waitForTimeout(800);
await touchPage.screenshot({ path: `${outDir}/05_web_touch_dash.png`, fullPage: true });

const actionableTouchErrors = touchErrors.filter(
  (line) => !ignoredConsolePatterns.some((pattern) => pattern.test(line)),
);
fs.writeFileSync(
  `${outDir}/touch-smoke.json`,
  JSON.stringify(
    {
      canvas: touchCanvas,
      consoleErrors: touchErrors,
      pageErrors: touchPageErrors,
      actionableConsoleErrors: actionableTouchErrors,
    },
    null,
    2,
  ) + "\n",
);

await browser.close();

if (touchPageErrors.length > 0 || actionableTouchErrors.length > 0) {
  throw new Error(
    `Touch browser runtime errors: page=${touchPageErrors.length}, console=${actionableTouchErrors.length}`,
  );
}

if (pageErrors.length > 0 || actionableConsoleErrors.length > 0) {
  throw new Error(
    `Browser runtime errors: page=${pageErrors.length}, console=${actionableConsoleErrors.length}`,
  );
}

console.log("WEB_RUNTIME_SMOKE", JSON.stringify(runtime));
