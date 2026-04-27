import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { STLLoader }     from 'three/addons/loaders/STLLoader.js';

// ============================================================================
//  PROTISEM V5 — Phase 3: afstrijker + geleider + full seed lifecycle.
//
//  Seed lifecycle states:
//    pool      — at rest in seed-pool
//    attached  — vacuum-held against disc-front face, traveling 270° → 90°
//    falling   — released, in free fall (with tangential velocity)
//    gliding   — caught by geleider, sliding along curve to throat
//    exiting   — passing through drop-tube
//    landed    — below housing, counted as successfully sown
//
//  Counters: pool / attached / gliding / exiting (current totals)
//  + sown / skipped / missed (cumulative).
// ============================================================================

// ----- world setup (Z is up to match OpenSCAD's frame) -----
const host = document.getElementById('canvas-host');
const scene = new THREE.Scene();
scene.background = new THREE.Color(0xeeeeee);

const camera = new THREE.PerspectiveCamera(
  40,
  host.clientWidth / host.clientHeight,
  0.1,
  2000,
);
camera.up.set(0, 0, 1);
camera.position.set(220, -240, 100);
camera.lookAt(0, -5, 0);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(host.clientWidth, host.clientHeight);
renderer.localClippingEnabled = true;
host.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.target.set(0, -5, 0);

// ----- lighting -----
scene.add(new THREE.AmbientLight(0xffffff, 0.55));
const key = new THREE.DirectionalLight(0xffffff, 0.95);
key.position.set(120, -180, 220);
scene.add(key);
const fill = new THREE.DirectionalLight(0xffffff, 0.35);
fill.position.set(-180, 120, -100);
scene.add(fill);

// ----- ground/grid -----
const grid = new THREE.GridHelper(400, 20, 0xbbbbbb, 0xdddddd);
grid.rotation.x = Math.PI / 2;
grid.position.z = -55;
scene.add(grid);

// ============================================================================
//  Geometric constants — mirror parameters.scad
// ============================================================================
const TILT = Math.PI / 4;
const COS_T = Math.cos(TILT);
const SIN_T = Math.sin(TILT);
const DISC_AXIS  = new THREE.Vector3(0, -SIN_T, COS_T).normalize();

// FRONT_NORMAL — unit vector pointing INTO the disc-front half-space.
// Derived from pool reference, not guessed:
//
//   disc_plane_eq(x,y,z) = -sin45°·y + cos45°·z = 0  on the disc mid-plane.
//   A pool seed near the bottom of the pool, e.g. (0, -29.7, -33), gives
//   disc_plane_eq = +21.0 + (-23.3) = -2.3 < 0 → that seed is on the
//   FRONT side. So FRONT_NORMAL must point in the direction of decreasing
//   disc_plane_eq, i.e. -gradient = (0, +sin45°, -cos45°).
//
// This is the same direction the SCAD afstrijkers are placed (validated:
// centroid offset from rim is h·(0, +sin45°, -cos45°)) — the viewer was
// previously using -FRONT_NORMAL as a visibility hack which embedded
// attached seeds in the disc plane. See verification log at first pickup.
const FRONT_NORMAL = new THREE.Vector3(0, SIN_T, -COS_T).normalize();
const discPlaneEq = (p) => -SIN_T * p.y + COS_T * p.z;

const R_PICKUP = 42;
const N_HOLES  = 40;
const PICKUP_THETA  = 270 * Math.PI / 180;
const RELEASE_THETA =  90 * Math.PI / 180;
const AFSTRIJKER_THETA  = 250 * Math.PI / 180;
const AFSTRIJKER2_THETA =  95 * Math.PI / 180;
const PICKUP_POS  = new THREE.Vector3(0, -29.698, -29.698);
const RELEASE_POS = new THREE.Vector3(0,  29.698,  29.698);

// Pool geometry — raised 8 mm in Phase-3 visual fix.
const POOL = {
  x: 60, y: 40, depth: 20,
  zTop: -17, zFloor: -37, yCenter: -30,
  fillZ: -24,
};

// Geleider geometry — for catch test and glide path
const GELEIDER = {
  mouthX: 40, mouthY: 20, mouthZ: 20,
  mouthYCenter: 30,
  throatDia: 30, throatZ: -6,
};

// Drop tube
const DROP_TUBE = { od: 30, id: 24, zTop: -6, zBottom: -52 };

// Singulator + release-zone pusher
const AFSTRIJKER_SLIP_PROB  = 0.05;
const AFSTRIJKER2_PUSH_PROB = 0.10;

// Seed visual offset along disc-front normal so spheres float in front of
// the disc surface rather than embedded in it.
const SEED_OFFSET = 5;

// ============================================================================
//  Materials
// ============================================================================
const clipPlane = new THREE.Plane(new THREE.Vector3(-1, 0, 0), 0);

const discMat = new THREE.MeshPhongMaterial({
  color: 0x6699d4, specular: 0x111111, shininess: 28,
  side: THREE.DoubleSide, clippingPlanes: [],
});
const poolMat = new THREE.MeshPhongMaterial({
  color: 0xb0b8c0, specular: 0x222222, shininess: 18,
  side: THREE.DoubleSide, transparent: true, opacity: 0.32,
  clippingPlanes: [],
});
const afstrijkerMat = new THREE.MeshPhongMaterial({
  color: 0x808890, specular: 0x222222, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.85,
  clippingPlanes: [],
});
const geleiderMat = new THREE.MeshPhongMaterial({
  color: 0xa8b0bc, specular: 0x222222, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.40,
  clippingPlanes: [],
});
const dropTubeMat = new THREE.MeshPhongMaterial({
  color: 0xb0b6c0, specular: 0x222222, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.55,
  clippingPlanes: [],
});

const SEED_RADIUS = 3;
const seedGeom = new THREE.SphereGeometry(SEED_RADIUS, 14, 10);
const poolSeedMat     = new THREE.MeshPhongMaterial({ color: 0xc9a23c, shininess: 30 });
const attachedSeedMat = new THREE.MeshPhongMaterial({
  color: 0xe04030, emissive: 0x801010, shininess: 60,
});
const fallingSeedMat  = new THREE.MeshPhongMaterial({ color: 0xe6c84d, shininess: 40 });
const glidingSeedMat  = new THREE.MeshPhongMaterial({
  color: 0xf0a020, emissive: 0x402008, shininess: 50,
});
const exitingSeedMat  = new THREE.MeshPhongMaterial({ color: 0xa08020, shininess: 30 });

// ============================================================================
//  Markers (visible — radius 2.5 mm, not microscopic)
// ============================================================================
const markerGroup = new THREE.Group();
{
  const r = 2.5;
  const mk = (pos, color) => {
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(r, 24, 16),
      new THREE.MeshBasicMaterial({ color }),
    );
    m.position.copy(pos);
    return m;
  };
  markerGroup.add(mk(PICKUP_POS,  0xd9342b));
  markerGroup.add(mk(RELEASE_POS, 0xe89a2e));
}
scene.add(markerGroup);

// ============================================================================
//  STL load — disc, pool, afstrijker, geleider, drop_tube
// ============================================================================
let disc = null;
let afstrijkerMesh = null;
let afstrijker2Mesh = null;
let geleiderMesh = null;
let dropTubeMesh = null;
const loader = new STLLoader();

function loadStl(path, mat, onMesh) {
  loader.load(path, (geometry) => {
    geometry.computeVertexNormals();
    const m = new THREE.Mesh(geometry, mat);
    scene.add(m);
    if (onMesh) onMesh(m);
  }, undefined, (err) => console.error(`${path} load failed:`, err));
}

loadStl('./models/disc.stl',       discMat,        (m) => { disc = m; });
loadStl('./models/seed_pool.stl',  poolMat);
loadStl('./models/afstrijker.stl',  afstrijkerMat, (m) => { afstrijkerMesh  = m; });
loadStl('./models/afstrijker2.stl', afstrijkerMat, (m) => { afstrijker2Mesh = m; });
loadStl('./models/geleider.stl',   geleiderMat,    (m) => { geleiderMesh = m; });
loadStl('./models/drop_tube.stl',  dropTubeMat,    (m) => { dropTubeMesh = m; });

// ============================================================================
//  Pool fill — visible seed pile, with refill so the animation never starves
// ============================================================================
const POOL_TARGET = 50;
const POOL_REFILL_AT = 12;
const poolGroup = new THREE.Group();
scene.add(poolGroup);
const poolSeeds = [];

function placePoolSeed(seed) {
  const yMin = POOL.yCenter - POOL.y / 2 + 4;
  const yMax = POOL.yCenter + POOL.y / 2 - 4;
  const x = (Math.random() - 0.5) * 12;        // V-trough bias
  const y = yMin + Math.random() * (yMax - yMin);
  const layer = Math.floor(poolSeeds.length / 14);
  const z = POOL.zFloor + SEED_RADIUS
            + layer * (SEED_RADIUS * 1.6)
            + (Math.random() - 0.5) * 1.5;
  seed.position.set(x, y, Math.min(z, POOL.fillZ));
}

function spawnPoolSeed() {
  const m = new THREE.Mesh(seedGeom, poolSeedMat);
  placePoolSeed(m);
  poolGroup.add(m);
  poolSeeds.push(m);
}

function refillPoolIfLow() {
  if (poolSeeds.length < POOL_REFILL_AT) {
    while (poolSeeds.length < POOL_TARGET) spawnPoolSeed();
  }
}

while (poolSeeds.length < POOL_TARGET) spawnPoolSeed();

// One-time front-normal verification — log disc_plane_eq for the topmost
// pool seed (which by construction is on the front side) so the convention
// is auditable in the console at startup.
{
  let top = poolSeeds[0];
  for (const s of poolSeeds) if (s.position.z > top.position.z) top = s;
  const eqTop = discPlaneEq(top.position);
  console.log(
    `[FRONT_NORMAL] pool top seed at (${top.position.x.toFixed(2)}, ` +
    `${top.position.y.toFixed(2)}, ${top.position.z.toFixed(2)}) ` +
    `→ disc_plane_eq = ${eqTop.toFixed(3)} ` +
    `(<0 means front side, expected for a pool seed near the floor)`,
  );
}

let _frontNormalVerified = false;
function verifyFrontNormalOnce(holePos, seedPos) {
  if (_frontNormalVerified) return;
  const eqHole = discPlaneEq(holePos);
  const eqSeed = discPlaneEq(seedPos);
  const onFrontSide = eqSeed < eqHole;
  console.log(
    `[FRONT_NORMAL verify] disc_plane_eq(hole)=${eqHole.toFixed(3)}, ` +
    `disc_plane_eq(seed)=${eqSeed.toFixed(3)}, ` +
    `seed < hole (front-side) = ${onFrontSide}`,
  );
  if (!onFrontSide) {
    console.warn('[FRONT_NORMAL] seed offset is on WRONG side — flip sign.');
  }
  _frontNormalVerified = true;
}

// ============================================================================
//  Per-hole state, rotation
// ============================================================================
//
// Disc rotation φ accumulates over time. Effective hole angle in disc-local
// frame = θ_n - φ (Option 1: θ decreasing over time, seed travels 270° → 90°).
// We apply a NEGATIVE rotation to the disc mesh so its world appearance
// matches that decreasing-θ convention.

const holeState = new Array(N_HOLES).fill(null); // null | { seed, sawAfstrijker }
let rotationAngle = 0;

function holeWorldPosition(n, phi) {
  const theta = (n * 2 * Math.PI / N_HOLES) - phi;
  const lx = R_PICKUP * Math.cos(theta);
  const ly = R_PICKUP * Math.sin(theta);
  return new THREE.Vector3(lx, ly * COS_T, ly * SIN_T);
}

function effectiveTheta(n, phi) {
  let t = ((n * 2 * Math.PI / N_HOLES) - phi) % (2 * Math.PI);
  if (t < 0) t += 2 * Math.PI;
  return t;
}

function holeIsAt(n, phi, target, tol) {
  const t = effectiveTheta(n, phi);
  const d = Math.abs(t - target);
  return Math.min(d, 2 * Math.PI - d) < tol;
}

// ============================================================================
//  In-flight groups — falling, gliding, exiting
// ============================================================================
const GRAVITY = 9810;          // mm/s²
const TIME_SCALE = 0.18;       // visualisation slow-down

const fallingGroup = new THREE.Group(); scene.add(fallingGroup);
const glidingGroup = new THREE.Group(); scene.add(glidingGroup);
const exitingGroup = new THREE.Group(); scene.add(exitingGroup);

const fallingSeeds = [];   // { mesh, vx, vy, vz, t }
const glidingSeeds = [];   // { mesh, t, dur, p0, p1 }
const exitingSeeds = [];   // { mesh, t, dur, p0, p1 }

// ----- transitions -----
function detachToFalling(seedMesh, omega, x0, y0, z0) {
  // Tangential velocity at release: v = ω × r. ω = -|ω|·DISC_AXIS (Option 1).
  const r = new THREE.Vector3(x0, y0, z0);
  const wVec = DISC_AXIS.clone().multiplyScalar(-omega);
  const v = new THREE.Vector3().crossVectors(wVec, r);
  seedMesh.material = fallingSeedMat;
  fallingGroup.attach(seedMesh);
  fallingSeeds.push({
    mesh: seedMesh,
    vx: v.x, vy: v.y, vz: v.z,
    t: 0,
  });
}

function detachToPool(seedMesh) {
  // Afstrijker knock-off — drop seed back into the pool.
  seedMesh.material = poolSeedMat;
  poolGroup.attach(seedMesh);
  placePoolSeed(seedMesh);
  poolSeeds.push(seedMesh);
}

function captureToGliding(item) {
  // Falling seed entered geleider catch-mouth — switch to glide along curve.
  const m = item.mesh;
  m.material = glidingSeedMat;
  glidingGroup.attach(m);
  const dur = 0.4;   // seconds (visualisation time)
  const p0 = m.position.clone();
  const p1 = new THREE.Vector3(0, 0, GELEIDER.throatZ + 1);
  glidingSeeds.push({ mesh: m, t: 0, dur, p0, p1 });
}

function pushToGliding(seedMesh) {
  // Afstrijker 2 push — seed is wiped off the disc directly into the
  // geleider catch-mouth. Skips free-fall: visualises the redundancy
  // without ballistic trajectory. Starts at the seed's current world
  // position (still attached at θ≈95°), routed to the throat with a
  // brief intermediate arc into the catch-mouth so it visually clears
  // the disc edge before sliding down.
  seedMesh.material = glidingSeedMat;
  glidingGroup.attach(seedMesh);
  const dur = 0.55;
  const p0 = seedMesh.position.clone();
  const p1 = new THREE.Vector3(0, 0, GELEIDER.throatZ + 1);
  savedCount++;
  glidingSeeds.push({ mesh: seedMesh, t: 0, dur, p0, p1 });
}

function captureToExiting(g) {
  const m = g.mesh;
  m.material = exitingSeedMat;
  exitingGroup.attach(m);
  const dur = 0.35;
  const p0 = m.position.clone();
  const p1 = new THREE.Vector3(0, 0, DROP_TUBE.zBottom + 2);
  exitingSeeds.push({ mesh: m, t: 0, dur, p0, p1 });
}

function landSeed(e) {
  exitingGroup.remove(e.mesh);
  e.mesh.material = null;
  e.mesh.geometry = null;
}

// ----- per-frame updates -----
function updateFalling(dt) {
  const sdt = dt * TIME_SCALE;
  for (let i = fallingSeeds.length - 1; i >= 0; i--) {
    const s = fallingSeeds[i];
    s.vz -= GRAVITY * sdt;
    s.mesh.position.x += s.vx * sdt;
    s.mesh.position.y += s.vy * sdt;
    s.mesh.position.z += s.vz * sdt;
    s.t += dt;

    // Test geleider catch — seed inside catch-mouth bounds.
    if (insideGeleiderMouth(s.mesh.position)) {
      fallingSeeds.splice(i, 1);
      captureToGliding(s);
      continue;
    }
    // Missed — fell past the geleider z range without being caught.
    if (s.mesh.position.z < -10 || s.t > 2.5) {
      fallingGroup.remove(s.mesh);
      fallingSeeds.splice(i, 1);
      missedCount++;
    }
  }
}

function updateGliding(dt) {
  for (let i = glidingSeeds.length - 1; i >= 0; i--) {
    const g = glidingSeeds[i];
    g.t += dt;
    const u = Math.min(g.t / g.dur, 1);
    // Ease curve: in y/x linearly, in z follow a slight arc so the path
    // feels like a slide. Bezier-ish: midpoint dipped a touch.
    const eased = u * u * (3 - 2 * u);   // smoothstep
    g.mesh.position.lerpVectors(g.p0, g.p1, eased);
    if (u >= 1) {
      glidingSeeds.splice(i, 1);
      captureToExiting(g);
    }
  }
}

function updateExiting(dt) {
  for (let i = exitingSeeds.length - 1; i >= 0; i--) {
    const e = exitingSeeds[i];
    e.t += dt;
    const u = Math.min(e.t / e.dur, 1);
    e.mesh.position.lerpVectors(e.p0, e.p1, u);
    if (u >= 1) {
      exitingSeeds.splice(i, 1);
      landSeed(e);
      sownCount++;
    }
  }
}

function insideGeleiderMouth(p) {
  // Catch-mouth is an upward-facing rectangular opening. Seed enters when
  // it is within the X×Y footprint AND its Z is in the mouth-acceptance band
  // (between mouth top and mouth bottom). Mouth top wall sits at z=22, the
  // opening is at z=20 → accept zone z ∈ [18, 22] catches descending seeds.
  const xHalf = GELEIDER.mouthX / 2;
  const yMin = GELEIDER.mouthYCenter - GELEIDER.mouthY / 2;
  const yMax = GELEIDER.mouthYCenter + GELEIDER.mouthY / 2;
  return Math.abs(p.x) < xHalf
      && p.y > yMin && p.y < yMax
      && p.z < GELEIDER.mouthZ + 2
      && p.z > GELEIDER.mouthZ - 4;
}

// ============================================================================
//  UI
// ============================================================================
const rpmInput      = document.getElementById('rpm');
const rpmValue      = document.getElementById('rpm-value');
const vacuumInput   = document.getElementById('vacuum');
const vacuumValue   = document.getElementById('vacuum-value');
const csInput       = document.getElementById('cross-section');
const markersInput  = document.getElementById('show-markers');
const poolFillInput = document.getElementById('show-pool-fill');
const seedsOnDiscInput = document.getElementById('show-seeds-on-disc');
const afstrijkerInput  = document.getElementById('show-afstrijker');
const afstrijker2Input = document.getElementById('show-afstrijker2');
const geleiderInput    = document.getElementById('show-geleider');
const dropTubeInput    = document.getElementById('show-drop-tube');

const angleEl    = document.getElementById('info-angle');
const poolEl     = document.getElementById('info-pool');
const onDiscEl   = document.getElementById('info-on-disc');
const inGelEl    = document.getElementById('info-in-geleider');
const inTubeEl   = document.getElementById('info-in-tube');
const sownEl     = document.getElementById('info-sown');
const skipEl     = document.getElementById('info-skip');
const missEl     = document.getElementById('info-miss');

let rpm = parseFloat(rpmInput.value);
let vacuum = parseFloat(vacuumInput.value);
let sownCount = 0;
let skippedCount = 0;
let missedCount = 0;
let savedCount = 0;

rpmInput.addEventListener('input', () => {
  rpm = parseFloat(rpmInput.value);
  rpmValue.textContent = rpm.toFixed(1) + ' rpm';
});
vacuumInput.addEventListener('input', () => {
  vacuum = parseFloat(vacuumInput.value);
  vacuumValue.textContent = vacuum.toFixed(0) + '%';
});
csInput.addEventListener('change', () => {
  const planes = csInput.checked ? [clipPlane] : [];
  for (const m of [discMat, poolMat, afstrijkerMat, geleiderMat, dropTubeMat]) {
    m.clippingPlanes = planes;
    m.needsUpdate = true;
  }
});
markersInput.addEventListener('change',  () => { markerGroup.visible    = markersInput.checked; });
poolFillInput.addEventListener('change', () => { poolGroup.visible      = poolFillInput.checked; });
seedsOnDiscInput.addEventListener('change', () => {
  // Toggle visibility of all attached-seed meshes.
  for (const s of holeState) if (s) s.seed.visible = seedsOnDiscInput.checked;
});
afstrijkerInput.addEventListener('change', () => {
  if (afstrijkerMesh) afstrijkerMesh.visible = afstrijkerInput.checked;
});
afstrijker2Input.addEventListener('change', () => {
  if (afstrijker2Mesh) afstrijker2Mesh.visible = afstrijker2Input.checked;
});
geleiderInput.addEventListener('change', () => {
  if (geleiderMesh) geleiderMesh.visible = geleiderInput.checked;
});
dropTubeInput.addEventListener('change', () => {
  if (dropTubeMesh) dropTubeMesh.visible = dropTubeInput.checked;
});

// ----- resize -----
function onResize() {
  const w = host.clientWidth;
  const h = host.clientHeight;
  renderer.setSize(w, h);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
}
window.addEventListener('resize', onResize);

// ============================================================================
//  Animation
// ============================================================================
const clock = new THREE.Clock();

function animate() {
  const dt = Math.min(clock.getDelta(), 0.05);

  const omega = (rpm / 60) * 2 * Math.PI;
  rotationAngle += omega * dt;
  rotationAngle %= 2 * Math.PI;
  if (disc) disc.setRotationFromAxisAngle(DISC_AXIS, -rotationAngle);

  refillPoolIfLow();

  // Per-hole pickup / travel / afstrijker / release
  const tol = Math.max(0.05, omega * dt * 1.2);

  for (let n = 0; n < N_HOLES; n++) {
    const state = holeState[n];

    if (state) {
      // Update attached-seed position to ride the rotating hole.
      const wp = holeWorldPosition(n, rotationAngle);
      state.seed.position.set(
        wp.x + FRONT_NORMAL.x * SEED_OFFSET,
        wp.y + FRONT_NORMAL.y * SEED_OFFSET,
        wp.z + FRONT_NORMAL.z * SEED_OFFSET,
      );
      verifyFrontNormalOnce(wp, state.seed.position);

      // Afstrijker singulator effect — once per pass.
      if (!state.sawAfstrijker
          && holeIsAt(n, rotationAngle, AFSTRIJKER_THETA, tol)) {
        state.sawAfstrijker = true;
        if (Math.random() < AFSTRIJKER_SLIP_PROB) {
          detachToPool(state.seed);
          holeState[n] = null;
          continue;
        }
      }

      // Afstrijker 2 (release-zone pusher) — once per pass.
      // ~10% of seeds get pushed straight into the geleider before reaching
      // the natural release at θ=90°. Visually shows the redundancy.
      if (!state.sawAfstrijker2
          && holeIsAt(n, rotationAngle, AFSTRIJKER2_THETA, tol)) {
        state.sawAfstrijker2 = true;
        if (Math.random() < AFSTRIJKER2_PUSH_PROB) {
          pushToGliding(state.seed);
          holeState[n] = null;
          continue;
        }
      }

      // Release at θ=90°.
      if (holeIsAt(n, rotationAngle, RELEASE_THETA, tol)) {
        detachToFalling(state.seed, omega,
          state.seed.position.x, state.seed.position.y, state.seed.position.z);
        holeState[n] = null;
        continue;
      }
    } else {
      // Pickup at θ=270° if vacuum on, hole empty, pool not empty.
      if (holeIsAt(n, rotationAngle, PICKUP_THETA, tol)) {
        if (vacuum > 5 && poolSeeds.length > 0) {
          // Take topmost (highest-z) pool seed.
          let topIdx = 0;
          for (let i = 1; i < poolSeeds.length; i++) {
            if (poolSeeds[i].position.z > poolSeeds[topIdx].position.z) topIdx = i;
          }
          const seed = poolSeeds.splice(topIdx, 1)[0];
          poolGroup.remove(seed);
          seed.material = attachedSeedMat;
          if (!seedsOnDiscInput.checked) seed.visible = false;
          scene.add(seed);
          holeState[n] = { seed, sawAfstrijker: false, sawAfstrijker2: false };
        } else if (vacuum > 5) {
          // Vacuum on but pool empty — count a skip per pass per hole.
          skippedCount++;
        }
      }
    }
  }

  updateFalling(dt);
  updateGliding(dt);
  updateExiting(dt);

  // HUD
  angleEl.textContent  = (rotationAngle * 180 / Math.PI).toFixed(1) + '°';
  poolEl.textContent   = poolSeeds.length;
  const onDisc = holeState.filter(s => s).length;
  onDiscEl.textContent = onDisc;
  inGelEl.textContent  = glidingSeeds.length;
  inTubeEl.textContent = exitingSeeds.length;
  sownEl.textContent   = sownCount;
  skipEl.textContent   = skippedCount;
  missEl.textContent   = missedCount;

  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
animate();
