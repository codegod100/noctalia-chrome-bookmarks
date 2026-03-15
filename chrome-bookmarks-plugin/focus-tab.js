#!/usr/bin/env node
const fs = require("fs");

const tabId = Number(process.argv[2]);
const windowId = Number(process.argv[3]);
const outputPath = process.env.THORIUM_TABS_COMMAND || "/tmp/thorium-tabs-command.json";

if (!Number.isInteger(tabId)) {
  console.error("usage: node focus-tab.js <tabId> [windowId]");
  process.exit(1);
}

const command = {
  type: "focus-tab",
  tabId,
  windowId: Number.isInteger(windowId) ? windowId : null,
  issuedAt: new Date().toISOString()
};

fs.writeFileSync(outputPath, JSON.stringify(command), "utf8");
