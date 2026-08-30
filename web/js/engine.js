import * as THREE from "https://unpkg.com/three@0.160.1/build/three.module.js";

const KEY = {};
const tmp = new THREE.Vector3();

export function isTouch() {
  return matchMedia("(pointer: coarse)").matches || "ontouchstart" in window;
}

function aabbOverlap(a, b) {
  return a.minX < b.maxX && a.maxX > b.minX &&
    a.minY < b.maxY && a.maxY > b.minY &&
    a.minZ < b.maxZ && a.maxZ > b.minZ;
}

function bodyAABB(pos, hx, hy, hz) {
  return {
    minX: pos.x - hx, maxX: pos.x + hx,
    minY: pos.y - hy, maxY: pos.y + hy,
    minZ: pos.z - hz, maxZ: pos.z + hz,
  };
}

function makePawn(color, scale = 1) {
  const g = new THREE.Group();
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.45, metalness: 0.15 });
  const torso = new THREE.Mesh(new THREE.BoxGeometry(0.7 * scale, 0.9 * scale, 0.4 * scale), mat);
  torso.position.y = 1.15 * scale;
  const head = new THREE.Mesh(new THREE.BoxGeometry(0.5 * scale, 0.5 * scale, 0.5 * scale), mat);
  head.position.y = 1.85 * scale;
  const legM = new THREE.MeshStandardMaterial({ color: new THREE.Color(color).multiplyScalar(0.6) });
  const l = new THREE.Mesh(new THREE.BoxGeometry(0.28 * scale, 0.7 * scale, 0.28 * scale), legM);
  l.position.set(-0.18 * scale, 0.4 * scale, 0);
  const r = l.clone(); r.position.x = 0.18 * scale;
  g.add(torso, head, l, r);
  g.traverse((o) => { if (o.isMesh) { o.castShadow = true; o.receiveShadow = true; } });
  return g;
}

export class VoidWorld {
  constructor(container, opts = {}) {
    this.el = container;
    this.opts = opts;
    this.colliders = [];
    this.items = [];
    this.bots = [];
    this.score = 0;
    this.scores = {};
    this.alive = true;
    this.ended = false;
    this.timeLeft = opts.time || 90;
    this.objective = opts.objective || "Play";
    this.gravity = opts.gravity ?? 28;
    this.speed = opts.speed ?? 9;
    this.jump = opts.jump ?? 9.5;
    this.slip = 0;
    this.reverse = false;
    this.hooks = { tick: [], end: [], msg: [] };
    this.move = { x: 0, z: 0 };
    this.look = { yaw: 0.4, pitch: -0.25 };
    this.velY = 0;
    this.grounded = false;
    this.carrying = null;
    this.kills = 0;

    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(opts.bg || 0x0b0d16);
    this.scene.fog = new THREE.Fog(opts.bg || 0x0b0d16, 28, 90);
    this.cam = new THREE.PerspectiveCamera(60, 1, 0.1, 200);
    this.renderer = new THREE.WebGLRenderer({ antialias: !opts.perf, alpha: false });
    this.renderer.setPixelRatio(Math.min(devicePixelRatio, opts.perf ? 1 : 1.6));
    this.renderer.shadowMap.enabled = !opts.perf;
    this.el.appendChild(this.renderer.domElement);
    this.renderer.domElement.id = "game-canvas";

    const hemi = new THREE.HemisphereLight(0xb8c4ff, 0x1a1428, 1.1);
    const sun = new THREE.DirectionalLight(0xffffff, 1.15);
    sun.position.set(18, 32, 12);
    sun.castShadow = !opts.perf;
    this.scene.add(hemi, sun);

    this.player = makePawn(opts.playerColor || 0x7c5cff);
    this.player.position.set(0, 0.1, 8);
    this.scene.add(this.player);

    this._resize = () => this.resize();
    addEventListener("resize", this._resize);
    this.resize();
    this.bindInput();
    this.last = performance.now();
    this.raf = requestAnimationFrame((t) => this.loop(t));
  }

  resize() {
    const w = this.el.clientWidth || innerWidth;
    const h = this.el.clientHeight || innerHeight;
    this.cam.aspect = w / h;
    this.cam.updateProjectionMatrix();
    this.renderer.setSize(w, h);
  }

  ground(size = 80, color = 0x161a24) {
    const mesh = new THREE.Mesh(
      new THREE.BoxGeometry(size, 1.2, size),
      new THREE.MeshStandardMaterial({ color, roughness: 0.9 })
    );
    mesh.position.y = -0.6;
    mesh.receiveShadow = true;
    this.scene.add(mesh);
    this.addCollider(mesh, size, 1.2, size);
    return mesh;
  }

  box(x, y, z, w, h, d, color, extra = {}) {
    const mesh = new THREE.Mesh(
      extra.sphere
        ? new THREE.SphereGeometry(w * 0.5, 16, 12)
        : new THREE.BoxGeometry(w, h, d),
      new THREE.MeshStandardMaterial({
        color,
        emissive: extra.neon ? color : 0x000000,
        emissiveIntensity: extra.neon ? 0.45 : 0,
        roughness: extra.neon ? 0.25 : 0.7,
      })
    );
    mesh.position.set(x, y, z);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    Object.assign(mesh.userData, extra);
    this.scene.add(mesh);
    if (extra.collide !== false) this.addCollider(mesh, w, h, d);
    return mesh;
  }

  addCollider(mesh, w, h, d) {
    this.colliders.push({ mesh, w, h, d, kill: !!mesh.userData.kill });
  }

  spawnItem(mesh, data) {
    mesh.userData.item = data || {};
    this.items.push(mesh);
    return mesh;
  }

  spawnBot(opts = {}) {
    const bot = makePawn(opts.color || 0xff4d6a, opts.scale || 1);
    bot.position.set(opts.x || 0, opts.y || 0.1, opts.z || 0);
    bot.userData = {
      kind: "bot",
      ai: opts.ai || "wander",
      speed: opts.speed || 4.5,
      hp: opts.hp || 100,
      name: opts.name || "Bot",
      home: bot.position.clone(),
      radius: opts.radius || 18,
      carry: null,
      cooldown: 0,
      score: 0,
      alive: true,
    };
    this.scene.add(bot);
    this.bots.push(bot);
    this.scores[bot.userData.name] = 0;
    return bot;
  }

  msg(text) {
    this.hooks.msg.forEach((fn) => fn(text));
  }

  on(ev, fn) { this.hooks[ev].push(fn); }

  end(payload) {
    if (this.ended) return;
    this.ended = true;
    this.hooks.end.forEach((fn) => fn(payload));
  }

  bindInput() {
    this._kd = (e) => { KEY[e.code] = true; if (["Space", "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"].includes(e.code)) e.preventDefault(); };
    this._ku = (e) => { KEY[e.code] = false; };
    addEventListener("keydown", this._kd);
    addEventListener("keyup", this._ku);
    const canvas = this.renderer.domElement;
    canvas.addEventListener("click", () => {
      if (!isTouch()) canvas.requestPointerLock?.();
    });
    this._mm = (e) => {
      if (document.pointerLockElement === canvas) {
        this.look.yaw -= e.movementX * 0.0025;
        this.look.pitch -= e.movementY * 0.0022;
        this.look.pitch = Math.max(-1.1, Math.min(0.35, this.look.pitch));
      }
    };
    addEventListener("mousemove", this._mm);
    this.touch = { lx: 0, ly: 0, active: false };
  }

  setTouch(x, y) {
    this.touch.lx = x;
    this.touch.ly = y;
    this.touch.active = Math.hypot(x, y) > 0.08;
  }

  cameraFollow(dt) {
    const p = this.player.position;
    const dist = 8;
    const off = new THREE.Vector3(
      Math.sin(this.look.yaw) * Math.cos(this.look.pitch) * dist,
      2.4 - Math.sin(this.look.pitch) * 6,
      Math.cos(this.look.yaw) * Math.cos(this.look.pitch) * dist
    );
    const want = p.clone().add(off);
    this.cam.position.lerp(want, 1 - Math.pow(0.0008, dt));
    this.cam.lookAt(p.x, p.y + 1.4, p.z);
  }

  wishDir() {
    let x = 0, z = 0;
    if (KEY.KeyW || KEY.ArrowUp) z -= 1;
    if (KEY.KeyS || KEY.ArrowDown) z += 1;
    if (KEY.KeyA || KEY.ArrowLeft) x -= 1;
    if (KEY.KeyD || KEY.ArrowRight) x += 1;
    if (this.touch.active) { x += this.touch.lx; z += this.touch.ly; }
    if (this.reverse) { x = -x; z = -z; }
    const len = Math.hypot(x, z) || 1;
    const fx = Math.sin(this.look.yaw);
    const fz = Math.cos(this.look.yaw);
    const rx = Math.cos(this.look.yaw);
    const rz = -Math.sin(this.look.yaw);
    const wx = (rx * x + fx * z) / len;
    const wz = (rz * x + fz * z) / len;
    return { x: wx, z: wz, mag: Math.min(1, Math.hypot(x, z)) };
  }

  collidePlayer(next) {
    const box = bodyAABB(next, 0.35, 0.95, 0.35);
    for (const c of this.colliders) {
      const p = c.mesh.position;
      const other = {
        minX: p.x - c.w / 2, maxX: p.x + c.w / 2,
        minY: p.y - c.h / 2, maxY: p.y + c.h / 2,
        minZ: p.z - c.d / 2, maxZ: p.z + c.d / 2,
      };
      if (!aabbOverlap(box, other)) continue;
      if (c.kill || c.mesh.userData.kill) {
        this.hurt(100, "hazard");
        return next;
      }
      const below = this.player.position.y >= other.maxY - 0.2 && this.velY <= 0;
      if (below && next.y <= other.maxY + 0.02) {
        next.y = other.maxY;
        this.velY = 0;
        this.grounded = true;
      } else {
        const dx1 = other.maxX - box.minX;
        const dx2 = box.maxX - other.minX;
        const dz1 = other.maxZ - box.minZ;
        const dz2 = box.maxZ - other.minZ;
        if (Math.min(dx1, dx2) < Math.min(dz1, dz2)) {
          next.x += dx1 < dx2 ? dx1 : -dx2;
        } else {
          next.z += dz1 < dz2 ? dz1 : -dz2;
        }
      }
    }
    return next;
  }

  hurt(n, why) {
    if (!this.alive) return;
    this.player.userData.hp = (this.player.userData.hp ?? 100) - n;
    if (this.player.userData.hp <= 0) {
      this.alive = false;
      this.msg("You were taken out.");
      if (this.opts.respawn === 0) return;
      this.player.position.y = 40;
      setTimeout(() => {
        if (this.ended) return;
        this.alive = true;
        this.player.userData.hp = 100;
        this.player.position.set(0, 2, 6);
        this.velY = 0;
      }, 1600);
    }
  }

  nearestBot(max = 8) {
    let best = null, bestD = max;
    for (const b of this.bots) {
      if (!b.userData.alive) continue;
      const d = b.position.distanceTo(this.player.position);
      if (d < bestD) { bestD = d; best = b; }
    }
    return best;
  }

  attack() {
    const now = performance.now();
    if (this._atk && now - this._atk < 380) return false;
    this._atk = now;
    const t = this.nearestBot(7.2);
    if (t) {
      t.userData.hp -= 34;
      tmp.copy(t.position).sub(this.player.position).setY(0).normalize();
      t.position.addScaledVector(tmp, 1.4);
      if (t.userData.hp <= 0) {
        t.userData.alive = false;
        t.visible = false;
        this.kills += 1;
        this.score += 8;
        this.msg("Downed " + t.userData.name);
        setTimeout(() => {
          if (this.ended) return;
          t.userData.alive = true;
          t.userData.hp = 100;
          t.visible = true;
          t.position.copy(t.userData.home);
        }, 2200);
      }
      return true;
    }
    return false;
  }

  tickBots(dt) {
    for (const b of this.bots) {
      if (!b.userData.alive) continue;
      const u = b.userData;
      u.cooldown = Math.max(0, u.cooldown - dt);
      const toPlayer = this.player.position.clone().sub(b.position);
      const dist = toPlayer.length();
      let target = null;
      if (u.ai === "chase" && this.alive) target = this.player.position;
      else if (u.ai === "flee" && dist < 12) target = b.position.clone().add(toPlayer.multiplyScalar(-1));
      else if (u.ai === "seek" && this.alive) target = this.player.position;
      else if (u.ai === "race") {
        u.t = (u.t || 0) + dt * u.speed * 0.08;
        target = new THREE.Vector3(Math.sin(u.t) * 22, 0.1, Math.cos(u.t) * 22);
      } else {
        u.wander = u.wander ?? Math.random() * Math.PI * 2;
        if (Math.random() < 0.01) u.wander += (Math.random() - 0.5) * 1.4;
        target = u.home.clone().add(new THREE.Vector3(Math.cos(u.wander) * u.radius, 0, Math.sin(u.wander) * u.radius));
      }
      if (target) {
        const dir = target.clone().sub(b.position); dir.y = 0;
        if (dir.length() > 0.4) {
          dir.normalize();
          b.position.addScaledVector(dir, u.speed * dt);
          b.rotation.y = Math.atan2(dir.x, dir.z);
        }
      }
      if ((u.ai === "chase" || u.ai === "seek") && dist < 2.4 && u.cooldown <= 0 && this.alive) {
        u.cooldown = 1.1;
        this.hurt(18, "bot");
      }
    }
  }

  loop(t) {
    const dt = Math.min(0.05, (t - this.last) / 1000);
    this.last = t;
    if (!this.ended) {
      this.timeLeft -= dt;
      if (this.timeLeft <= 0) {
        this.timeLeft = 0;
        this.end({ win: this.score > 0, score: this.score, kills: this.kills, reason: "time" });
      }
      this.grounded = false;
      const wish = this.wishDir();
      const spd = this.speed * (KEY.ShiftLeft ? 1.45 : 1);
      const next = this.player.position.clone();
      next.x += wish.x * wish.mag * spd * dt;
      next.z += wish.z * wish.mag * spd * dt;
      if ((KEY.Space || this._jump) && this.grounded) {
        this.velY = this.jump;
        this.grounded = false;
        this._jump = false;
      }
      this.velY -= this.gravity * dt;
      next.y += this.velY * dt;
      if (next.y < 0.1) { next.y = 0.1; this.velY = 0; this.grounded = true; }
      this.collidePlayer(next);
      this.player.position.copy(next);
      if (wish.mag > 0.1) this.player.rotation.y = Math.atan2(wish.x, wish.z);
      if (this.carrying) this.carrying.position.copy(this.player.position).add(new THREE.Vector3(0, 2.1, 0));
      this.tickBots(dt);
      for (const it of this.items) {
        if (!it.visible || it.userData.held) continue;
        it.rotation.y += dt;
        if (it.position.distanceTo(this.player.position) < (it.userData.reach || 1.8)) {
          const fn = it.userData.item.onPick;
          if (fn) fn(it, this);
        }
      }
      this.hooks.tick.forEach((fn) => fn(dt, this));
    }
    this.cameraFollow(dt);
    this.renderer.render(this.scene, this.cam);
    this.raf = requestAnimationFrame((n) => this.loop(n));
  }

  dispose() {
    this.ended = true;
    cancelAnimationFrame(this.raf);
    removeEventListener("resize", this._resize);
    removeEventListener("keydown", this._kd);
    removeEventListener("keyup", this._ku);
    removeEventListener("mousemove", this._mm);
    document.exitPointerLock?.();
    this.renderer.dispose();
    this.renderer.domElement.remove();
  }
}
