import { VoidWorld } from "./engine.js";

const NAMES = ["Nyx", "Orbit", "Kite", "Vex", "Pebble", "Rook", "Lumen", "Ash"];

function bots(world, n, ai, spread = 16) {
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    world.spawnBot({
      name: NAMES[i % NAMES.length] + (i > 7 ? i : ""),
      x: Math.cos(a) * spread,
      z: Math.sin(a) * spread,
      ai,
      color: 0xff5a7a - i * 10,
    });
  }
}

function arena(world, size = 56) {
  world.ground(size + 20, 0x12151e);
  world.box(0, 4, size / 2, size, 8, 1.2, 0x1c2230);
  world.box(0, 4, -size / 2, size, 8, 1.2, 0x1c2230);
  world.box(size / 2, 4, 0, 1.2, 8, size, 0x1c2230);
  world.box(-size / 2, 4, 0, 1.2, 8, size, 0x1c2230);
}

export const GAMES = [
  { id: "brain_snatch", name: "Brain Snatch", cat: "Collection", featured: true, tag: "Grab it. Bank it. Lose it.", desc: "Hunt wandering Brains, bank them in your vault, steal carriers.", plays: 22100, accent: "#f2478c", accent2: "#734cff" },
  { id: "chaos_obby", name: "Chaos Obby", cat: "Obby", featured: true, tag: "The course has opinions.", desc: "Checkpoint race. Gravity, ice, and speed rewrite every round.", plays: 19840, accent: "#59d9ff", accent2: "#ff7333" },
  { id: "last_one_alive", name: "Last One Alive", cat: "Survival", featured: true, tag: "Don't be the story.", desc: "One life-feel disasters. Meteors and flood. Last standing.", plays: 18750, accent: "#ff5933", accent2: "#22181c" },
  { id: "street_racers", name: "Street Racers", cat: "Racing", featured: true, tag: "Hold boost. Hit the apex.", desc: "Kart-speed loop vs bots. Boost on straights.", plays: 17400, accent: "#33b2ff", accent2: "#ffcc33" },
  { id: "base_rush", name: "Base Rush", cat: "Tycoon", featured: false, tag: "Print. Fortify. Steal.", desc: "Stand on your pad to print coins. Upgrade. Contest the lane.", plays: 16220, accent: "#40e68c", accent2: "#e6b233" },
  { id: "haunted_shift", name: "Haunted Shift", cat: "Horror", featured: false, tag: "Clock out alive.", desc: "Finish glowing terminals. A stalker hunts anyone in the open.", plays: 16990, accent: "#8c1420", accent2: "#221c28" },
  { id: "pet_planet", name: "Pet Planet", cat: "Simulator", featured: false, tag: "Hatch something clingy.", desc: "Farm coin pads, buy an egg, wear a multiplier that follows you.", plays: 20550, accent: "#ff80c0", accent2: "#73d9ff" },
  { id: "tower_clash", name: "Tower Clash", cat: "Strategy", featured: false, tag: "Hold the core.", desc: "Spawn marching units. First core to zero loses.", plays: 14110, accent: "#f28c33", accent2: "#4073ff" },
  { id: "grab_and_go", name: "Grab & Go", cat: "Party", featured: false, tag: "Heavy pockets, light feet.", desc: "Carry loot to gold extracts. Bots will mug you.", plays: 15880, accent: "#f2cc33", accent2: "#33d98c" },
  { id: "disaster_city", name: "Disaster City", cat: "Survival", featured: false, tag: "The skyline is temporary.", desc: "A block city that fails on a schedule.", plays: 17640, accent: "#b3bfcc", accent2: "#ff6626" },
  { id: "sword_arena", name: "Sword Arena", cat: "Combat", featured: true, tag: "Read the swing.", desc: "Melee vs bots. Attack in range. Highest downs win.", plays: 19300, accent: "#d9d9eb", accent2: "#bf2633" },
  { id: "hideout", name: "Hideout", cat: "Social", featured: false, tag: "Don't blink first.", desc: "Stay behind cover. The seeker tags anyone in the open.", plays: 15120, accent: "#668cff", accent2: "#262833" },
  { id: "sky_is_falling", name: "Sky Is Falling", cat: "Survival", featured: false, tag: "The floor has a queue.", desc: "Islands drop out. Stay on whatever is left.", plays: 14890, accent: "#8cccff", accent2: "#f28c4d" },
  { id: "build_battle", name: "Build Battle", cat: "Social", featured: false, tag: "Make it obvious.", desc: "Place blocks on your plot before the horn. Volume scores.", plays: 13250, accent: "#8cf2b3", accent2: "#b373ff" },
  { id: "lucky_world", name: "Lucky World", cat: "Collection", featured: false, tag: "Spin the honest wheel.", desc: "Walk to the wheel and roll. Cooldown, no cash shop.", plays: 18880, accent: "#ffbf40", accent2: "#8050ff" },
];

export const CATS = ["All", "Featured", ...Array.from(new Set(GAMES.map((g) => g.cat)))];

export function startGame(id, container, hooks) {
  const def = GAMES.find((g) => g.id === id);
  const builders = {
    brain_snatch: brainSnatch,
    chaos_obby: chaosObby,
    last_one_alive: lastOneAlive,
    street_racers: streetRacers,
    base_rush: baseRush,
    haunted_shift: hauntedShift,
    pet_planet: petPlanet,
    tower_clash: towerClash,
    grab_and_go: grabAndGo,
    disaster_city: disasterCity,
    sword_arena: swordArena,
    hideout: hideout,
    sky_is_falling: skyIsFalling,
    build_battle: buildBattle,
    lucky_world: luckyWorld,
  };
  return builders[id](container, def, hooks);
}

function brainSnatch(el, def, hooks) {
  const w = new VoidWorld(el, { time: 90, objective: def.tag, playerColor: 0x7c5cff });
  arena(w, 52);
  const vault = w.box(0, 0.4, -20, 8, 0.8, 8, 0x2ee6a6, { neon: true, collide: false });
  const brains = [];
  for (let i = 0; i < 10; i++) {
    const b = w.box((Math.random() - 0.5) * 40, 1.1, (Math.random() - 0.5) * 40, 1.1, 1.1, 1.1, Math.random() < 0.2 ? 0xff4da6 : 0x66ff99, { neon: true, collide: false, sphere: true });
    b.userData.val = b.material.color.getHex() === 0xff4da6 ? 3 : 1;
    w.spawnItem(b, {
      onPick: (it) => {
        if (w.carrying) return;
        w.carrying = it;
        it.userData.held = true;
        w.msg("Carrying a Brain — bank it in the mint pad.");
      },
    });
    brains.push(b);
  }
  bots(w, 4, "wander", 18);
  w.on("tick", (dt) => {
    for (const b of brains) {
      if (b.userData.held) continue;
      b.userData.ang = (b.userData.ang || Math.random() * 6) + dt * 0.6;
      b.position.x += Math.sin(b.userData.ang) * dt * 1.4;
      b.position.z += Math.cos(b.userData.ang * 0.8) * dt * 1.4;
    }
    if (w.carrying && w.player.position.distanceTo(vault.position) < 4.5) {
      w.score += w.carrying.userData.val || 1;
      w.carrying.visible = false;
      w.carrying.userData.held = true;
      w.carrying = null;
      w.msg("Banked. Score " + w.score);
      if (w.score >= 12) w.end({ win: true, score: w.score, reason: "cap" });
    }
  });
  hooks.actions(["drop"]);
  hooks.onAction((a) => {
    if (a === "drop" && w.carrying) {
      w.carrying.userData.held = false;
      const d = w.player.position.clone();
      d.y += 1; d.z += 2;
      w.carrying.position.copy(d);
      w.carrying = null;
    }
  });
  return w;
}

function chaosObby(el, def, hooks) {
  const mods = ["speed", "lowgrav", "ice"];
  const mod = mods[Math.floor(Math.random() * mods.length)];
  const w = new VoidWorld(el, { time: 80, objective: "Modifier: " + mod, gravity: mod === "lowgrav" ? 14 : 28, speed: mod === "speed" ? 14 : 9 });
  if (mod === "ice") w.slip = 1;
  w.ground(24, 0x10131c);
  w.player.position.set(0, 1, 0);
  let z = 6;
  const cps = [];
  for (let i = 0; i < 16; i++) {
    const x = Math.sin(i * 0.7) * 6;
    const y = 0.6 + (i % 4) * 0.7;
    const p = w.box(x, y, z, 5.2, 0.6, 4.2, THREEColor(i / 16), { collide: true });
    if (i % 3 === 0) cps.push(w.box(x, y + 1.6, z, 0.6, 2.4, 0.6, 0x66ffaa, { neon: true, collide: false }));
    z += 7.2;
  }
  const finish = w.box(0, 2, z + 2, 8, 0.8, 8, 0xffdd55, { neon: true, collide: false });
  w.box(0, -2, z / 2, 40, 1, z + 30, 0xaa2233, { kill: true, collide: true });
  let prog = 0;
  w.on("tick", () => {
    cps.forEach((c, i) => {
      if (w.player.position.distanceTo(c.position) < 2.2) prog = Math.max(prog, i + 1);
    });
    w.score = prog;
    if (w.player.position.distanceTo(finish.position) < 4) w.end({ win: true, score: 100, reason: "finish" });
  });
  hooks.actions([]);
  return w;
}

function THREEColor(t) {
  const c = { r: t, g: 0.4, b: 1 - t };
  return (Math.floor(c.r * 255) << 16) + (Math.floor(c.g * 255) << 8) + Math.floor(c.b * 255);
}

function lastOneAlive(el, def, hooks) {
  const w = new VoidWorld(el, { time: 75, objective: "Survive", respawn: 0 });
  arena(w, 48);
  bots(w, 5, "wander", 14);
  w.player.userData.hp = 100;
  let next = 6;
  const mets = [];
  w.on("tick", (dt) => {
    next -= dt;
    if (next <= 0) {
      next = 9;
      w.msg("Meteor set inbound");
      for (let i = 0; i < 8; i++) {
        const m = w.box((Math.random() - 0.5) * 40, 18 + Math.random() * 8, (Math.random() - 0.5) * 40, 2.2, 2.2, 2.2, 0xff6622, { neon: true, collide: false });
        m.userData.fall = true;
        mets.push(m);
      }
    }
    for (const m of mets) {
      if (!m.visible) continue;
      m.position.y -= 18 * dt;
      if (m.position.distanceTo(w.player.position) < 2.2) w.hurt(50, "meteor");
      if (m.position.y < 0) m.visible = false;
    }
    w.score += dt;
    const liveBots = w.bots.filter((b) => b.userData.alive).length;
    if (!w.alive) w.end({ win: false, score: Math.floor(w.score), reason: "down" });
    else if (liveBots === 0) w.end({ win: true, score: Math.floor(w.score) + 20, reason: "last" });
  });
  hooks.actions(["sprint"]);
  hooks.onAction((a) => { if (a === "sprint") w.speed = 13; setTimeout(() => w.speed = 9, 1400); });
  return w;
}

function streetRacers(el, def, hooks) {
  const w = new VoidWorld(el, { time: 80, objective: "3 laps", speed: 14, jump: 0 });
  w.ground(70, 0x1a3d24);
  for (let i = 0; i < 16; i++) {
    const a = (i / 16) * Math.PI * 2;
    const r = 22;
    w.box(Math.cos(a) * r, 0.2, Math.sin(a) * r, 8, 0.4, 6, 0x22262e, { collide: false });
  }
  w.player.position.set(22, 1, 0);
  bots(w, 3, "race", 22);
  w.bots.forEach((b, i) => { b.userData.t = i; b.position.set(Math.cos(i) * 22, 0.1, Math.sin(i) * 22); });
  let yaw = 0, laps = 0, last = 0;
  w.on("tick", () => {
    yaw = Math.atan2(w.player.position.z, w.player.position.x);
    if (last < -2 && yaw > 2) laps += 1;
    last = yaw;
    w.score = laps * 10;
    if (laps >= 3) w.end({ win: true, score: 100, reason: "laps" });
  });
  hooks.actions(["boost"]);
  hooks.onAction((a) => {
    if (a === "boost") { w.speed = 22; setTimeout(() => w.speed = 14, 1200); }
  });
  return w;
}

function baseRush(el, def, hooks) {
  const w = new VoidWorld(el, { time: 90, objective: "Print coins, stay on your pad" });
  arena(w, 50);
  const pad = w.box(-12, 0.4, 0, 10, 0.7, 10, 0x2ee6a6, { neon: true, collide: false });
  const enemy = w.box(12, 0.4, 0, 10, 0.7, 10, 0xff4d6a, { neon: true, collide: false });
  bots(w, 3, "chase", 16);
  let rate = 2;
  w.on("tick", (dt) => {
    if (w.player.position.distanceTo(pad.position) < 6) w.score += rate * dt;
    if (w.player.position.distanceTo(enemy.position) < 6) w.score += dt * 0.4;
  });
  hooks.actions(["upgrade", "attack"]);
  hooks.onAction((a) => {
    if (a === "upgrade" && w.score >= 12) { w.score -= 12; rate += 1.4; w.msg("Dropper lv up"); }
    if (a === "attack") w.attack();
  });
  return w;
}

function hauntedShift(el, def, hooks) {
  const w = new VoidWorld(el, { time: 100, objective: "Finish terminals. Don't get caught.", bg: 0x0a080c });
  arena(w, 46);
  w.scene.fog.near = 8; w.scene.fog.far = 28;
  const terms = [];
  for (let i = 0; i < 5; i++) {
    const a = (i / 5) * Math.PI * 2;
    const t = w.box(Math.cos(a) * 16, 1.2, Math.sin(a) * 16, 1.4, 2.2, 0.5, 0x5599ff, { neon: true, collide: false });
    t.userData.done = false;
    terms.push(t);
  }
  const stalker = w.spawnBot({ name: "Stalker", x: 0, z: -18, ai: "chase", speed: 5.2, color: 0x220000, scale: 1.15 });
  let hidden = false;
  w.on("tick", (dt) => {
    let n = 0;
    for (const t of terms) {
      if (!t.userData.done && w.player.position.distanceTo(t.position) < 2.4) {
        t.userData.prog = (t.userData.prog || 0) + dt;
        if (t.userData.prog > 1.6) { t.userData.done = true; t.material.color.set(0x66ffaa); w.msg("Terminal done"); }
      }
      if (t.userData.done) n++;
    }
    w.score = n * 10;
    if (hidden) stalker.userData.ai = "wander";
    else stalker.userData.ai = "chase";
    if (n >= terms.length) w.end({ win: true, score: 80, reason: "shift" });
  });
  hooks.actions(["hide"]);
  hooks.onAction((a) => {
    if (a === "hide") { hidden = !hidden; w.msg(hidden ? "Hidden" : "Exposed"); }
  });
  return w;
}

function petPlanet(el, def, hooks) {
  const w = new VoidWorld(el, { time: 80, objective: "Farm pads, hatch a pet" });
  arena(w, 50);
  const pads = [];
  for (let i = 0; i < 6; i++) {
    const a = (i / 6) * Math.PI * 2;
    pads.push(w.box(Math.cos(a) * 16, 0.3, Math.sin(a) * 16, 6, 0.5, 6, 0xffd24d, { neon: true, collide: false }));
  }
  let mult = 1, pet = null;
  w.on("tick", (dt) => {
    for (const p of pads) if (w.player.position.distanceTo(p.position) < 4) w.score += 6 * dt * mult;
    if (pet) {
      const t = w.player.position.clone();
      t.x += 1.4; t.y += 1.1; t.z += 1.2;
      pet.position.lerp(t, 0.12);
    }
  });
  hooks.actions(["egg1", "egg2", "egg3"]);
  hooks.onAction((a) => {
    const cost = { egg1: 10, egg2: 28, egg3: 50 }[a];
    const m = { egg1: 1.4, egg2: 2, egg3: 3 }[a];
    if (w.score < cost) { w.msg("Need " + cost); return; }
    w.score -= cost; mult = m;
    if (pet) w.scene.remove(pet);
    pet = w.box(0, 1, 0, 0.8, 0.8, 0.8, 0xff77cc, { neon: true, collide: false, sphere: true });
    w.msg("Hatched. Multiplier x" + m);
  });
  return w;
}

function towerClash(el, def, hooks) {
  const w = new VoidWorld(el, { time: 90, objective: "Break the amber core" });
  w.ground(30, 0x1a1e28);
  w.box(0, 0.2, 0, 10, 0.4, 48, 0x2a3142, { collide: false });
  const blue = w.box(0, 2, -20, 6, 4, 6, 0x478cff, { neon: true });
  const amber = w.box(0, 2, 20, 6, 4, 6, 0xffb14d, { neon: true });
  let hpB = 80, hpA = 80;
  const units = [];
  w.player.position.set(0, 1, -14);
  w.on("tick", (dt) => {
    for (const u of units) {
      u.position.z += u.userData.dir * 8 * dt;
      if (u.userData.dir > 0 && u.position.distanceTo(amber.position) < 4) { hpA -= 6; u.position.z = -99; }
      if (u.userData.dir < 0 && u.position.distanceTo(blue.position) < 4) { hpB -= 6; u.position.z = 99; }
    }
    w.score = Math.max(0, 80 - hpA);
    if (hpA <= 0) w.end({ win: true, score: 90, reason: "core" });
    if (hpB <= 0) w.end({ win: false, score: w.score, reason: "core" });
  });
  hooks.actions(["spawn"]);
  hooks.onAction((a) => {
    if (a === "spawn") {
      const u = w.box(0, 1, -16, 1.2, 1.2, 1.2, 0x66aaff, { neon: true, collide: false, sphere: true });
      u.userData.dir = 1;
      units.push(u);
      const e = w.box(0, 1, 16, 1.2, 1.2, 1.2, 0xffaa55, { neon: true, collide: false, sphere: true });
      e.userData.dir = -1;
      units.push(e);
    }
  });
  return w;
}

function grabAndGo(el, def, hooks) {
  const w = new VoidWorld(el, { time: 80, objective: "Extract the gold" });
  arena(w, 50);
  const extracts = [w.box(-18, 0.4, -18, 7, 0.6, 7, 0xffc857, { neon: true, collide: false }), w.box(18, 0.4, 18, 7, 0.6, 7, 0xffc857, { neon: true, collide: false })];
  for (let i = 0; i < 8; i++) {
    const loot = w.box((Math.random() - 0.5) * 30, 1, (Math.random() - 0.5) * 30, 1.2, 1.2, 1.2, 0xffdd66, { neon: true, collide: false });
    w.spawnItem(loot, {
      onPick: (it) => {
        if (w.carrying) return;
        w.carrying = it; it.userData.held = true;
      },
    });
  }
  bots(w, 3, "chase", 14);
  w.on("tick", () => {
    if (!w.carrying) return;
    for (const e of extracts) {
      if (w.player.position.distanceTo(e.position) < 4) {
        w.score += 4;
        w.carrying.visible = false;
        w.carrying.userData.held = true;
        w.carrying = null;
        w.msg("Extracted");
      }
    }
  });
  hooks.actions(["dash"]);
  hooks.onAction((a) => {
    if (a === "dash") {
      const d = w.wishDir();
      w.player.position.x += d.x * 4;
      w.player.position.z += d.z * 4;
    }
  });
  return w;
}

function disasterCity(el, def, hooks) {
  const w = new VoidWorld(el, { time: 85, objective: "Stay alive in the grid" });
  arena(w, 54);
  for (let x = -2; x <= 2; x++) for (let z = -2; z <= 2; z++) {
    if (!x && !z) continue;
    const h = 3 + Math.random() * 8;
    w.box(x * 8, h / 2, z * 8, 4.5, h, 4.5, 0x3a4050);
  }
  bots(w, 4, "flee", 12);
  let next = 7;
  const hazards = [];
  w.on("tick", (dt) => {
    w.score += dt;
    next -= dt;
    if (next <= 0) {
      next = 10;
      w.msg("CITY ALERT");
      for (let i = 0; i < 6; i++) {
        const m = w.box((Math.random() - 0.5) * 40, 16, (Math.random() - 0.5) * 40, 2, 2, 2, 0xff7733, { neon: true, collide: false });
        hazards.push(m);
      }
    }
    for (const m of hazards) {
      m.position.y -= 14 * dt;
      if (m.position.distanceTo(w.player.position) < 2) w.hurt(40, "meteor");
    }
  });
  hooks.actions(["sprint"]);
  hooks.onAction((a) => { if (a === "sprint") { w.speed = 13; setTimeout(() => w.speed = 9, 1500); } });
  return w;
}

function swordArena(el, def, hooks) {
  const w = new VoidWorld(el, { time: 80, objective: "Down the bots" });
  arena(w, 40);
  for (let i = 0; i < 4; i++) w.box(Math.cos(i) * 10, 2, Math.sin(i) * 10, 2, 4, 2, 0x4a4e5c);
  bots(w, 4, "chase", 12);
  w.on("tick", () => { w.score = w.kills * 8; });
  hooks.actions(["attack", "block"]);
  hooks.onAction((a) => {
    if (a === "attack") w.attack();
    if (a === "block") { w.player.userData.block = true; setTimeout(() => w.player.userData.block = false, 600); }
  });
  return w;
}

function hideout(el, def, hooks) {
  const w = new VoidWorld(el, { time: 70, objective: "Stay out of the seeker's sight" });
  arena(w, 42);
  for (let i = 0; i < 10; i++) w.box((Math.random() - 0.5) * 28, 1.6, (Math.random() - 0.5) * 28, 2.4, 3.2, 2.4, 0x2a3144);
  const seeker = w.spawnBot({ name: "Seeker", x: 0, z: -16, ai: "wander", speed: 6, color: 0x4466ff });
  setTimeout(() => { seeker.userData.ai = "seek"; w.msg("Hunting starts"); }, 6000);
  w.on("tick", (dt) => {
    if (w.alive) w.score += dt;
    if (seeker.position.distanceTo(w.player.position) < 2.2 && seeker.userData.ai === "seek") {
      w.end({ win: false, score: Math.floor(w.score), reason: "tagged" });
    }
  });
  hooks.actions([]);
  return w;
}

function skyIsFalling(el, def, hooks) {
  const w = new VoidWorld(el, { time: 70, objective: "Stay on an island", gravity: 24 });
  const islands = [];
  for (let i = 0; i < 9; i++) {
    const r = Math.floor(i / 3) - 1, c = (i % 3) - 1;
    islands.push(w.box(c * 9, 0.4, r * 9, 7, 0.8, 7, 0x6aa8d9));
  }
  w.box(0, -8, 0, 80, 1, 80, 0x661122, { kill: true });
  w.player.position.set(0, 2, 0);
  bots(w, 3, "wander", 8);
  let next = 8;
  w.on("tick", (dt) => {
    if (w.alive) w.score += dt;
    next -= dt;
    if (next <= 0 && islands.length > 1) {
      next = 7;
      const isl = islands.pop();
      isl.position.y -= 0.2;
      isl.userData.falling = true;
      w.msg("Island dropped");
    }
    for (const isl of [...islands]) {
      if (isl.userData.falling) isl.position.y -= 6 * dt;
    }
  });
  hooks.actions(["shove"]);
  hooks.onAction((a) => { if (a === "shove") w.attack(); });
  return w;
}

function buildBattle(el, def, hooks) {
  const themes = ["Haunted House", "Spaceship", "Snack Stand", "Dragon"];
  const theme = themes[Math.floor(Math.random() * themes.length)];
  const w = new VoidWorld(el, { time: 55, objective: "Theme: " + theme });
  w.ground(40, 0x1c2230);
  w.box(0, 0.2, 0, 16, 0.4, 16, 0x2a3144, { collide: false });
  w.player.position.set(0, 1, 8);
  const placed = [];
  w.on("tick", () => { w.score = placed.length; });
  hooks.actions(["place", "delete"]);
  hooks.onAction((a) => {
    if (a === "place" && placed.length < 40) {
      const p = w.player.position;
      placed.push(w.box(Math.round(p.x), 1 + placed.length % 5, Math.round(p.z - 2), 1.4, 1.4, 1.4, [0xee5555, 0x55cc77, 0x5588ee, 0xeecc44][placed.length % 4]));
    }
    if (a === "delete" && placed.length) {
      const m = placed.pop();
      w.scene.remove(m);
    }
  });
  return w;
}

function luckyWorld(el, def, hooks) {
  const w = new VoidWorld(el, { time: 70, objective: "Roll the honest wheel" });
  arena(w, 40);
  const wheel = w.box(0, 1, -8, 6, 0.8, 6, 0xffc857, { neon: true, collide: false });
  let cd = 0;
  w.on("tick", (dt) => { cd = Math.max(0, cd - dt); wheel.rotation.y += dt; });
  hooks.actions(["roll"]);
  hooks.onAction((a) => {
    if (a !== "roll") return;
    if (w.player.position.distanceTo(wheel.position) > 6) { w.msg("Get closer to the wheel"); return; }
    if (cd > 0) { w.msg("Cooling down"); return; }
    cd = 2.2;
    const r = Math.random();
    if (r < 0.62) { const n = 4 + Math.floor(Math.random() * 9); w.score += n; w.msg("+" + n + " luck"); }
    else if (r < 0.84) { w.speed = 14; setTimeout(() => w.speed = 9, 5000); w.score += 6; w.msg("Speed burst"); }
    else { const n = 20 + Math.floor(Math.random() * 16); w.score += n; w.msg("Jackpot +" + n); }
  });
  return w;
}
