const summary = document.querySelector("#summary");
const tabsList = document.querySelector("#tabs");
const refreshButton = document.querySelector("#refresh");

async function fetchTabs() {
  const response = await chrome.runtime.sendMessage({ type: "get-tabs" });
  return response?.tabs ?? [];
}

function renderTabs(tabs) {
  summary.textContent = `${tabs.length} tab${tabs.length === 1 ? "" : "s"}`;
  tabsList.replaceChildren();

  for (const tab of tabs) {
    const item = document.createElement("li");
    item.className = "tab";

    const title = document.createElement("p");
    title.className = "tab-title";
    title.textContent = tab.title || "Untitled";

    const url = document.createElement("p");
    url.className = "tab-url";
    url.textContent = tab.url || "";

    const meta = document.createElement("p");
    meta.className = "tab-meta";
    meta.textContent = [
      `window ${tab.windowId}`,
      `index ${tab.index}`,
      tab.active ? "active" : null,
      tab.pinned ? "pinned" : null
    ].filter(Boolean).join(" • ");

    item.append(title, url, meta);
    tabsList.append(item);
  }
}

async function loadTabs() {
  summary.textContent = "Loading tabs…";

  try {
    const tabs = await fetchTabs();
    renderTabs(tabs);
  } catch (error) {
    summary.textContent = `Failed to read tabs: ${error.message}`;
    tabsList.replaceChildren();
  }
}

refreshButton.addEventListener("click", loadTabs);
loadTabs();
