// cdp-drive.js - minimal CDP driver over Node 24 global WebSocket.
// Usage: node cdp-drive.js <url> <js-to-evaluate> [waitMs]
// Prints JSON result of the evaluation to stdout.
const args = process.argv.slice(2);
const url = args[0];
const js = args[1];
const waitMs = Number(args[2] || "8000");
if (!url || !js) {
  console.error("usage: node cdp-drive.js <url> <js> [waitMs]");
  process.exit(1);
}

let nextId = 1;
const pending = new Map();

function onSocketMessage(ws, raw) {
  let m;
  try {
    m = JSON.parse(String(raw));
  } catch (e) {
    return;
  }
  if (m && m.id && pending.has(m.id)) {
    const entry = pending.get(m.id);
    pending.delete(m.id);
    if (m.error) {
      entry.reject(new Error(JSON.stringify(m.error)));
    } else {
      entry.resolve(m.result);
    }
  }
}

function cdpSend(ws, method, params) {
  const id = nextId++;
  const payload = JSON.stringify({ id: id, method: method, params: params || {} });
  const p = new Promise(function (resolve, reject) {
    pending.set(id, { resolve: resolve, reject: reject });
  });
  ws.send(payload);
  return p;
}

function connect(url) {
  return new Promise(function (resolve, reject) {
    const ws = new WebSocket(url);
    ws.addEventListener("open", function () { resolve(ws); });
    ws.addEventListener("error", function () { reject(new Error("ws-connect-failed")); });
    ws.addEventListener("message", function (ev) { onSocketMessage(ws, ev.data); });
  });
}

function sleep(ms) {
  return new Promise(function (r) { setTimeout(r, ms); });
}

async function main() {
  const list = await fetch("http://127.0.0.1:9333/json/list").then(function (r) { return r.json(); });
  let target = null;
  for (const t of list) {
    if (t.type === "page" && t.url === url) { target = t; break; }
  }
  if (!target) {
    const created = await fetch("http://127.0.0.1:9333/json/new?about:blank", { method: "PUT" }).then(function (r) { return r.json(); });
    const ws0 = await connect(created.webSocketDebuggerUrl);
    await cdpSend(ws0, "Page.enable", {});
    await cdpSend(ws0, "Page.navigate", { url: url });
    ws0.close();
    await sleep(waitMs);
    const list2 = await fetch("http://127.0.0.1:9333/json/list").then(function (r) { return r.json(); });
    target = null;
    for (const t of list2) {
      if (t.id === created.id) { target = t; break; }
    }
    if (!target) { throw new Error("tab-not-found-after-navigate"); }
  } else {
    await sleep(waitMs);
  }
  const ws = await connect(target.webSocketDebuggerUrl);
  await cdpSend(ws, "Runtime.enable", {});
  const res = await cdpSend(ws, "Runtime.evaluate", { expression: js, returnByValue: true, awaitPromise: true });
  let out = null;
  if (res && res.result && ("value" in res.result)) {
    out = res.result.value;
  }
  console.log(JSON.stringify(out));
  ws.close();
}

main().then(
  function () { process.exit(0); },
  function (e) { console.error("CDP-ERROR:" + (e && e.message ? e.message : e)); process.exit(1); }
);
