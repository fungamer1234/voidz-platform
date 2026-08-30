import { GAMES, CATS, startGame } from "./games.js";
import { isTouch } from "./engine.js";

const KEY = "voidz_web_v1";
const $ = (id) => document.getElementById(id);

function load() {
  try { return JSON.parse(localStorage.getItem(KEY) || "null"); } catch { return null; }
}
function save(data) { localStorage.setItem(KEY, JSON.stringify(data)); }

function fresh(name) {
  return {
    displayName: name || "Player",
    coins: 250,
    onboarded: true,
    created: Date.now(),
    avatar: { hue: 262, sat: 70 },
    items: ["core_tee"],
    equipped: "core_tee",
    favorites: [],
    likes: [],
    recent: [],
    stats: { plays: 0, wins: 0, logins: 1 },
    settings: { motion: true, volume: 0.8, scale: 1 },
    quests: { plays: 0, wins: 0 },
    daily: 0,
  };
}

let data = load();
let page = "home";
let selected = GAMES[0];
let cat = "All";
let query = "";
let world = null;
let actionHandler = () => {};

const shop = [
  { id: "core_tee", name: "Core Tee", price: 0 },
  { id: "night_jacket", name: "Night Jacket", price: 80 },
  { id: "void_coat", name: "Void Coat", price: 180 },
  { id: "gilded", name: "Gilded Trim", price: 260 },
];

function fmt(n) { return Math.floor(n).toLocaleString(); }
function mark(g) { return g.name.replace(/[^A-Za-z]/g, "").slice(0, 2).toUpperCase(); }
function thumb(g) {
  return `linear-gradient(135deg, ${g.accent}, ${g.accent2})`;
}

function boot() {
  const statuses = ["Initializing...", "Loading profile...", "Preparing avatar...", "Loading games...", "Almost ready..."];
  let i = 0;
  const tick = () => {
    $("boot-status").textContent = statuses[i] || "Almost ready...";
    $("boot-bar").style.width = `${18 + i * 20}%`;
    i += 1;
    if (i < statuses.length) setTimeout(tick, 180);
    else setTimeout(afterBoot, 200);
  };
  tick();
}

function afterBoot() {
  $("boot").classList.add("hidden");
  if (!data || !data.onboarded) showOnboard();
  else { data.stats.logins += 1; save(data); showApp(); }
}

function showOnboard() {
  $("onboard").style.display = "block";
  let step = 1;
  const name = (data && data.displayName) || "Player";
  const render = () => {
    $("onboard").innerHTML = `<div class="onboard-inner">
      <div class="dots">${[1,2,3,4,5].map((n) => `<i class="${n <= step ? "on" : ""}"></i>`).join("")}</div>
      ${step === 1 ? `<h2>Welcome to VOIDZ</h2><p>A universe of games in your browser. This profile lives on this device — not a Roblox account, and we never ask for a password.</p>` : ""}
      ${step === 2 ? `<h2>Choose a display name</h2><p>3–16 letters, numbers, or underscores.</p><input id="name-in" maxlength="16" value="${name.replace(/[^\w]/g, "").slice(0, 16) || "Player"}">` : ""}
      ${step === 3 ? `<h2>Pick a look</h2><p>Hue for your avatar in every game.</p><input id="hue" type="range" min="0" max="360" value="262" style="width:60%">` : ""}
      ${step === 4 ? `<h2>Starter grant</h2><p>+250 VoidCoins to spend in the shop.</p>` : ""}
      ${step === 5 ? `<h2>You're in.</h2><p>Home is live. Discover a title and hit Play — the match is 3D, in this tab.</p>` : ""}
      <div class="row" style="margin-top:24px">
        ${step > 1 && step < 5 ? `<button class="btn ghost" id="back">Back</button>` : ""}
        <span class="spacer"></span>
        <button class="btn accent" id="next">${step === 5 ? "Enter VOIDZ" : step === 4 ? "Collect" : "Continue"}</button>
      </div>
      <p id="on-err" style="color:var(--danger)"></p>
    </div>`;
    $("back")?.addEventListener("click", () => { step -= 1; render(); });
    $("next").addEventListener("click", () => {
      if (step === 2) {
        const v = ($("name-in").value || "").trim();
        if (!/^[\w]{3,16}$/.test(v) || ["admin", "voidz", "system"].includes(v.toLowerCase())) {
          $("on-err").textContent = "Use 3–16 letters, numbers, or underscores.";
          return;
        }
        data = fresh(v);
      }
      if (step === 3) data.avatar.hue = Number($("hue").value);
      if (step < 5) { step += 1; render(); }
      else { data.onboarded = true; save(data); $("onboard").style.display = "none"; showApp(); }
    });
  };
  render();
}

function showApp() {
  $("app").style.display = "grid";
  renderApp();
}

function navBtn(id, label) {
  return `<button data-page="${id}" class="${page === id ? "on" : ""}">${label}</button>`;
}

function card(g) {
  return `<button class="card" data-open="${g.id}">
    <div class="thumb" style="background:${thumb(g)}">${mark(g)}</div>
    <div class="body"><h3>${g.name}</h3><p>${g.cat} · ${fmt(g.plays)} plays<br>${g.tag}</p></div>
  </button>`;
}

function listGames() {
  let list = GAMES.slice();
  if (cat === "Featured") list = list.filter((g) => g.featured);
  else if (cat !== "All") list = list.filter((g) => g.cat === cat);
  if (query) {
    const q = query.toLowerCase();
    list = list.filter((g) => (g.name + g.cat + g.tag + g.desc).toLowerCase().includes(q));
  }
  return list;
}

function renderApp() {
  const rec = data.recent.map((id) => GAMES.find((g) => g.id === id)).filter(Boolean);
  $("app").innerHTML = `
    <aside class="nav">
      <div class="brand">VOIDZ</div>
      ${navBtn("home", "◆ Home")}
      ${navBtn("discover", "▣ Discover")}
      ${navBtn("avatar", "◈ Avatar")}
      ${navBtn("inventory", "▤ Inventory")}
      ${navBtn("friends", "◎ Friends")}
      ${navBtn("profile", "◉ Profile")}
      ${navBtn("settings", "◍ Settings")}
    </aside>
    <header class="top">
      <input id="search" placeholder="Search games, categories" value="${query}">
      <div class="spacer"></div>
      <div class="coin">${fmt(data.coins)} VC</div>
    </header>
    <main class="main" id="main"></main>`;
  $("search").addEventListener("input", (e) => {
    query = e.target.value;
    page = "discover";
    renderApp();
    $("search").focus();
    $("search").setSelectionRange(query.length, query.length);
  });
  document.querySelectorAll(".nav button").forEach((b) => b.addEventListener("click", () => { page = b.dataset.page; renderApp(); }));
  renderPage();
}

function renderPage() {
  const main = $("main");
  if (page === "home") {
    main.innerHTML = `
      <div class="hero">
        <h2>Welcome back, ${data.displayName}</h2>
        <p>A universe of games. Fifteen live titles. Click Play and you're in the match.</p>
        <div class="row">
          <button class="btn accent" id="go-disc">Discover games</button>
          <button class="btn ghost" id="go-av">Edit avatar</button>
          <button class="btn ghost" id="daily">Daily drop</button>
        </div>
      </div>
      <h3 class="shelf-title">Featured</h3>
      <div class="shelf">${GAMES.filter((g) => g.featured).map(card).join("")}</div>
      ${rec.length ? `<h3 class="shelf-title">Continue</h3><div class="shelf">${rec.map(card).join("")}</div>` : ""}
      <h3 class="shelf-title">Popular</h3>
      <div class="shelf">${GAMES.slice().sort((a,b)=>b.plays-a.plays).slice(0,8).map(card).join("")}</div>`;
    $("go-disc").onclick = () => { page = "discover"; renderApp(); };
    $("go-av").onclick = () => { page = "avatar"; renderApp(); };
    $("daily").onclick = claimDaily;
  } else if (page === "discover") {
    const list = listGames();
    main.innerHTML = `<h1 class="page">Discover</h1>
      <div class="chips">${CATS.map((c) => `<button class="chip ${c === cat ? "on" : ""}" data-c="${c}">${c}</button>`).join("")}</div>
      <div class="shelf">${list.length ? list.map(card).join("") : `<div class="empty">No games match that search.</div>`}</div>`;
    main.querySelectorAll(".chip").forEach((c) => c.onclick = () => { cat = c.dataset.c; renderApp(); });
  } else if (page === "game") {
    const g = selected;
    const fav = data.favorites.includes(g.id);
    main.innerHTML = `
      <button class="btn ghost" id="back">← Back</button>
      <div class="detail" style="margin-top:14px">
        <div>
          <div class="thumb" style="height:180px;border-radius:20px;background:${thumb(g)}">${mark(g)}</div>
          <h1 class="page" style="margin-top:14px">${g.name}</h1>
          <p class="sub">${g.cat} · VOIDZ Studios · ${fmt(g.plays)} plays</p>
          <div class="row">
            <button class="btn accent" id="play-btn">Play</button>
            <button class="btn ghost" id="fav">${fav ? "Favorited" : "Favorite"}</button>
            <button class="btn ghost" id="like">Like</button>
          </div>
          <div class="panel" style="margin-top:16px"><b>About</b><p class="sub">${g.desc}</p><p class="sub">${g.tag}</p></div>
        </div>
        <div class="panel">
          <b>Status</b>
          <p class="sub">Live in browser · bots fill the lobby · rewards are VoidCoins on this device.</p>
          <div class="stats">
            <div class="stat"><b>Live</b><span>Ready</span></div>
            <div class="stat"><b>15</b><span>Library</span></div>
            <div class="stat"><b>${g.featured ? "Yes" : "No"}</b><span>Featured</span></div>
            <div class="stat"><b>${fmt(g.plays)}</b><span>Plays</span></div>
          </div>
        </div>
      </div>
      <h3 class="shelf-title">More ${g.cat}</h3>
      <div class="shelf">${GAMES.filter((x) => x.cat === g.cat && x.id !== g.id).map(card).join("")}</div>`;
    $("back").onclick = () => { page = "discover"; renderApp(); };
    $("play-btn").onclick = () => play(g);
    $("fav").onclick = () => {
      if (fav) data.favorites = data.favorites.filter((id) => id !== g.id);
      else data.favorites.push(g.id);
      save(data); renderApp();
    };
    $("like").onclick = () => { if (!data.likes.includes(g.id)) data.likes.push(g.id); save(data); };
  } else if (page === "avatar") {
    main.innerHTML = `<h1 class="page">Avatar</h1>
      <p class="sub">This look tints your pawn in every match.</p>
      <div class="panel">
        <label>Hue</label>
        <input id="hue" type="range" min="0" max="360" value="${data.avatar.hue}" style="width:100%">
        <div id="swatch" style="height:120px;border-radius:16px;margin-top:12px;background:hsl(${data.avatar.hue} 70% 55%)"></div>
        <button class="btn accent" id="save-av" style="margin-top:12px">Save</button>
      </div>`;
    $("hue").oninput = (e) => { $("swatch").style.background = `hsl(${e.target.value} 70% 55%)`; };
    $("save-av").onclick = () => { data.avatar.hue = Number($("hue").value); save(data); toast("Avatar saved"); };
  } else if (page === "inventory") {
    main.innerHTML = `<h1 class="page">Inventory</h1>
      <div class="list">${shop.map((it) => {
        const own = data.items.includes(it.id);
        return `<div class="item"><div><b>${it.name}</b><div class="sub">${own ? "Owned" : it.price + " VC"}</div></div>
          ${own
            ? `<button class="btn ${data.equipped === it.id ? "accent" : "ghost"}" data-eq="${it.id}">${data.equipped === it.id ? "Equipped" : "Equip"}</button>`
            : `<button class="btn accent" data-buy="${it.id}">Buy</button>`}</div>`;
      }).join("")}</div>`;
    main.querySelectorAll("[data-buy]").forEach((b) => b.onclick = () => buy(b.dataset.buy));
    main.querySelectorAll("[data-eq]").forEach((b) => b.onclick = () => { data.equipped = b.dataset.eq; save(data); renderApp(); });
  } else if (page === "friends") {
    const pals = ["Nyx", "Orbit", "Kite", "Vex"].map((n, i) => ({ n, on: i < 2 }));
    main.innerHTML = `<h1 class="page">Friends</h1>
      <p class="sub">Lobby list for this session. Party is local — Play still fills matches with bots.</p>
      <div class="list">${pals.map((p) => `<div class="item"><div><b>${p.n}</b><div class="sub">${p.on ? "Online" : "Offline"}</div></div><button class="btn ghost">Invite</button></div>`).join("")}</div>`;
  } else if (page === "profile") {
    main.innerHTML = `<h1 class="page">${data.displayName}</h1>
      <p class="sub">Joined ${new Date(data.created).toLocaleDateString()}</p>
      <div class="stats">
        <div class="stat"><b>${fmt(data.coins)}</b><span>VoidCoins</span></div>
        <div class="stat"><b>${data.stats.plays}</b><span>Matches</span></div>
        <div class="stat"><b>${data.stats.wins}</b><span>Wins</span></div>
        <div class="stat"><b>${data.stats.logins}</b><span>Logins</span></div>
      </div>
      <h3 class="shelf-title">Quests</h3>
      <div class="list">
        <div class="item"><span>Finish 1 match</span><b>${data.quests.plays >= 1 ? "Done" : data.quests.plays + "/1"}</b></div>
        <div class="item"><span>Win 3 matches</span><b>${Math.min(3, data.quests.wins)}/3</b></div>
      </div>
      <h3 class="shelf-title">Favorites</h3>
      <div class="shelf">${data.favorites.map((id) => GAMES.find((g) => g.id === id)).filter(Boolean).map(card).join("") || `<div class="empty">Favorite a title from its page.</div>`}</div>`;
  } else if (page === "settings") {
    main.innerHTML = `<h1 class="page">Settings</h1>
      <div class="panel">
        <p>Master volume</p>
        <input id="vol" type="range" min="0" max="1" step="0.05" value="${data.settings.volume}" style="width:100%">
        <p style="margin-top:12px">Performance mode reduces pixel ratio and shadows.</p>
        <label><input id="perf" type="checkbox"> Performance mode</label>
        <p class="sub" style="margin-top:18px">VOIDZ browser build 1.1 · progress saves in this browser only.</p>
      </div>`;
    $("vol").oninput = (e) => { data.settings.volume = Number(e.target.value); save(data); };
  }
  main.querySelectorAll("[data-open]").forEach((b) => b.addEventListener("click", () => {
    selected = GAMES.find((g) => g.id === b.dataset.open);
    page = "game";
    renderApp();
  }));
}

function buy(id) {
  const it = shop.find((s) => s.id === id);
  if (!it || data.coins < it.price) { toast("Not enough VoidCoins"); return; }
  data.coins -= it.price;
  data.items.push(id);
  save(data);
  renderApp();
}

function claimDaily() {
  const day = Math.floor(Date.now() / 86400000);
  if (data.daily === day) { toast("Already claimed today"); return; }
  data.daily = day;
  data.coins += 50;
  save(data);
  toast("+50 VC daily drop");
  renderApp();
}

function toast(t) {
  const n = document.createElement("div");
  n.textContent = t;
  n.style.cssText = "position:fixed;right:16px;bottom:16px;background:#1c2230;border:1px solid #3a425a;padding:10px 14px;border-radius:12px;z-index:200";
  document.body.appendChild(n);
  setTimeout(() => n.remove(), 2200);
}

function play(g) {
  data.stats.plays += 1;
  data.quests.plays += 1;
  data.recent = [g.id, ...data.recent.filter((id) => id !== g.id)].slice(0, 8);
  save(data);
  $("play").style.display = "block";
  $("play").innerHTML = `
    <div class="hud">
      <div class="hud-top">
        <div><div class="hud-obj" id="hud-obj">${g.name}</div><div class="sub" id="hud-sub">${g.tag}</div></div>
        <div class="hud-time" id="hud-time">1:30</div>
      </div>
      <div class="toast-feed" id="feed"></div>
      <div class="hud-board" id="board"></div>
      <div class="hud-actions" id="acts"></div>
      <button class="btn ghost" id="leave" style="position:absolute;left:16px;top:78px">Leave</button>
    </div>
    <div class="overlay" id="count"><div class="panel"><h2 id="count-t">Get ready</h2><p class="sub">Click the world to look around. WASD to move, Space to jump, Shift to sprint. On a phone, use the stick and JUMP.</p></div></div>
    ${isTouch() ? `<div class="touch"><div class="stick" id="stick"><div class="knob" id="knob"></div></div><div class="jump-btn" id="jump">JUMP</div></div>` : ""}`;
  $("leave").onclick = () => stopPlay(null);
  let n = 3;
  const cd = setInterval(() => {
    $("count-t").textContent = n > 0 ? String(n) : "GO";
    n -= 1;
    if (n < -1) {
      clearInterval(cd);
      $("count").classList.add("hidden");
      launchWorld(g);
    }
  }, 450);
}

function launchWorld(g) {
  const color = `hsl(${data.avatar.hue} 70% 55%)`;
  const wrap = $("play");
  actionHandler = () => {};
  world = startGame(g.id, wrap, {
    actions(list) {
      $("acts").innerHTML = list.map((a) => `<button class="btn accent" data-a="${a}">${a.toUpperCase()}</button>`).join("");
      $("acts").querySelectorAll("button").forEach((b) => b.onclick = () => actionHandler(b.dataset.a));
    },
    onAction(fn) { actionHandler = fn; },
  });
  world.player.traverse((o) => {
    if (o.isMesh && o.material && o.material.color) {
      try { o.material.color.set(color); } catch {}
    }
  });
  world.on("msg", (t) => {
    const d = document.createElement("div");
    d.textContent = t;
    $("feed").prepend(d);
    setTimeout(() => d.remove(), 3500);
  });
  world.on("tick", () => {
    const s = Math.max(0, Math.floor(world.timeLeft));
    $("hud-time").textContent = `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
    $("hud-obj").textContent = g.name + " — " + world.objective;
    const rows = [{ name: data.displayName, score: world.score }, ...world.bots.map((b) => ({ name: b.userData.name, score: b.userData.score || 0 }))];
    rows.sort((a, b) => b.score - a.score);
    $("board").innerHTML = rows.slice(0, 8).map((r, i) => `<div>${i + 1}. ${r.name} · ${Math.floor(r.score)}</div>`).join("");
  });
  world.on("end", (payload) => stopPlay(payload, g));
  bindTouch();
  addEventListener("keydown", keyAct);
}

function keyAct(e) {
  if (!$("play") || $("play").style.display === "none") return;
  if (e.code === "KeyF" || e.code === "KeyE" || e.code === "KeyQ" || e.code === "KeyR") {
    const btn = $("acts")?.querySelector("button");
    if (e.code === "KeyR") actionHandler("roll");
    if (e.code === "KeyQ") actionHandler("dash");
    if (e.code === "KeyE") actionHandler("grab") || actionHandler("place");
    if (e.code === "KeyF") actionHandler("attack") || actionHandler("lock") || actionHandler("block");
  }
  if (e.code === "Mouse" ) {}
}
document.addEventListener("mousedown", (e) => {
  if ($("play")?.style.display === "block" && e.button === 0 && document.pointerLockElement) actionHandler("attack");
});

function bindTouch() {
  const stick = $("stick");
  if (!stick || !world) return;
  const set = (cx, cy, x, y) => {
    const dx = (x - cx) / 55;
    const dy = (y - cy) / 55;
    const m = Math.hypot(dx, dy) || 1;
    const nx = dx / m * Math.min(1, m);
    const ny = dy / m * Math.min(1, m);
    world.setTouch(nx, ny);
    $("knob").style.transform = `translate(${nx * 28}px, ${ny * 28}px)`;
  };
  const end = () => { world.setTouch(0, 0); $("knob").style.transform = ""; };
  stick.addEventListener("touchstart", (e) => { const t = e.touches[0]; const r = stick.getBoundingClientRect(); set(r.left + r.width / 2, r.top + r.height / 2, t.clientX, t.clientY); }, { passive: true });
  stick.addEventListener("touchmove", (e) => { const t = e.touches[0]; const r = stick.getBoundingClientRect(); set(r.left + r.width / 2, r.top + r.height / 2, t.clientX, t.clientY); }, { passive: true });
  stick.addEventListener("touchend", end);
  $("jump")?.addEventListener("touchstart", () => { world._jump = true; });
}

function stopPlay(payload, g) {
  removeEventListener("keydown", keyAct);
  if (world) { world.dispose(); world = null; }
  if (payload && g) {
    const coins = Math.max(8, Math.floor((payload.score || 0) * 0.6) + (payload.win ? 35 : 10));
    data.coins += coins;
    if (payload.win) { data.stats.wins += 1; data.quests.wins += 1; }
    save(data);
    $("play").innerHTML = `<div class="overlay"><div class="panel">
      <h2>${payload.win ? "WINNER" : "GAME OVER"}</h2>
      <p class="sub">${g.name} · ${payload.reason || "round over"}</p>
      <div class="stats">
        <div class="stat"><b>${Math.floor(payload.score || 0)}</b><span>Score</span></div>
        <div class="stat"><b>+${coins}</b><span>VoidCoins</span></div>
        <div class="stat"><b>${payload.kills || 0}</b><span>Takedowns</span></div>
        <div class="stat"><b>${data.stats.wins}</b><span>Wins</span></div>
      </div>
      <div class="row" style="margin-top:16px">
        <button class="btn accent" id="again">Play again</button>
        <button class="btn ghost" id="ret">Return to VOIDZ</button>
      </div>
    </div></div>`;
    $("again").onclick = () => play(g);
    $("ret").onclick = closePlay;
    return;
  }
  closePlay();
}

function closePlay() {
  $("play").style.display = "none";
  $("play").innerHTML = "";
  renderApp();
}

boot();
