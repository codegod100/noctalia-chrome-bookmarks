const HOST_NAME = "org.noctalia.thorium_tabs";
let nativePort = null;

function queryTabs() {
  return new Promise((resolve) => {
    chrome.tabs.query({}, (tabs) => {
      resolve(tabs.map((tab) => ({
        id: tab.id,
        windowId: tab.windowId,
        index: tab.index,
        active: tab.active,
        pinned: tab.pinned,
        audible: tab.audible,
        discarded: tab.discarded,
        title: tab.title ?? "",
        url: tab.url ?? "",
        favIconUrl: tab.favIconUrl ?? ""
      })));
    });
  });
}

function ensureNativePort() {
  if (nativePort) {
    return nativePort;
  }

  nativePort = chrome.runtime.connectNative(HOST_NAME);
  nativePort.onMessage.addListener(handleNativeMessage);
  nativePort.onDisconnect.addListener(() => {
    if (chrome.runtime.lastError) {
      console.error("Native host disconnected", chrome.runtime.lastError.message);
    }
    nativePort = null;
  });

  return nativePort;
}

function handleNativeMessage(message) {
  if (message?.type !== "focus-tab") {
    return;
  }

  if (typeof message.windowId === "number") {
    chrome.windows.update(message.windowId, { focused: true });
  }

  if (typeof message.tabId === "number") {
    chrome.tabs.update(message.tabId, { active: true });
  }
}

async function publishTabs() {
  const tabs = await queryTabs();

  try {
    ensureNativePort().postMessage({
      type: "tabs-snapshot",
      source: "thorium-tabs-extension",
      capturedAt: new Date().toISOString(),
      tabs
    });
  } catch (error) {
    console.error("Failed to publish tabs to native host", error);
  }

  return tabs;
}

chrome.runtime.onInstalled.addListener(() => {
  ensureNativePort();
  publishTabs();
});

chrome.runtime.onStartup.addListener(() => {
  ensureNativePort();
  publishTabs();
});

ensureNativePort();

chrome.tabs.onActivated.addListener(() => {
  publishTabs();
});

chrome.tabs.onCreated.addListener(() => {
  publishTabs();
});

chrome.tabs.onRemoved.addListener(() => {
  publishTabs();
});

chrome.tabs.onUpdated.addListener(() => {
  publishTabs();
});

chrome.tabs.onMoved.addListener(() => {
  publishTabs();
});

chrome.tabs.onAttached.addListener(() => {
  publishTabs();
});

chrome.tabs.onDetached.addListener(() => {
  publishTabs();
});

chrome.windows.onFocusChanged.addListener(() => {
  publishTabs();
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type !== "get-tabs") {
    return false;
  }

  queryTabs().then((tabs) => {
    sendResponse({ tabs });
    publishTabs();
  });

  return true;
});
