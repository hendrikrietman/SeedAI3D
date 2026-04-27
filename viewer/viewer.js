import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { STLLoader }     from 'three/addons/loaders/STLLoader.js';

// ============================================================================
//  PROTISEM V5 — Phase 2: bottom seed-pool, vacuum pickup, 180° travel arc
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
camera.position.set(220, -240, 80);
camera.lookAt(0, -10, 0);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(host.clientWidth, host.clientHeight);
renderer.localClippingEnabled = true;
host.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.target.set(0, -10, 0);

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
const DISC_FRONT = new THREE.Vector3(0,  SIN_T, -COS_T).normalize();   // +Y component
const R_PICKUP   = 42;             // pickup-hole circle
const N_HOLES    = 40;
const PICKUP_THETA  = 270 * Math.PI / 180;   // pickup angle (disc-local)
const RELEASE_THETA =  90 * Math.PI / 180;   // release angle
const PICKUP_POS  = new THREE.Vector3(0, -29.698, -29.698);
const RELEASE_POS = new THREE.Vector3(0,  29.698,  29.698);

// Pool geometry
const POOL = {
  x: 60, y: 40, depth: 20,
  zTop: -25, zFloor: -45, yCenter: -30,
  fillZ: -32,    // approximate seed-pile top when full
};

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

const SEED_RADIUS = 3;     // mm
const seedGeom = new THREE.SphereGeometry(SEED_RADIUS, 14, 10);
const poolSeedMat     = new THREE.MeshPhongMaterial({ color: 0xc9a23c, shininess: 30 });
const capturedSeedMat = new THREE.MeshPhongMaterial({
  color: 0xe04030, emissive: 0x801010, shininess: 60,
});                                             // red-glow on disc
const fallingSeedMat  = new THREE.MeshPhongMaterial({ color: 0xe6c84d, shininess: 40 });

// ============================================================================
//  Markers
// ============================================================================
const markerGroup = new THREE.Group();
{
  const r = 2.0;
  const mk = (pos, color) => {
    const m = new THREE.Mesh(
      new THREE.SphereGeometry(r, 24, 16),
      new THREE.MeshBasicMaterial({ color }),
    );
    m.position.copy(pos);
    return m;
  };
  markerGroup.add(mk(PICKUP_POS,  0xd9342b));   // pickup  (red)   θ=270°
  markerGroup.add(mk(RELEASE_POS, 0xe89a2e));   // release (orange) θ=90°
}
scene.add(markerGroup);

// ============================================================================
//  STL load
// ============================================================================
let disc = null;
const loader = new STLLoader();

loader.load('./models/disc.stl', (geometry) => {
  geometry.computeVertexNormals();
  disc = new THREE.Mesh(geometry, discMat);
  scene.add(disc);
}, undefined, (err) => console.error('disc load failed:', err));

loader.load('./models/seed_pool.stl', (geometry) => {
  geometry.computeVertexNormals();
  const m = new THREE.Mesh(geometry, poolMat);
  scene.add(m);
}, undefined, (err) => console.error('seed_pool load failed:', err));

// ============================================================================
//  Seed-pool fill — ~80 loose seeds piled in the pool
// ============================================================================
const poolGroup = new THREE.Group();
scene.add(poolGroup);
const poolSeeds = [];        // available for pickup

function spawnPoolFill(n) {
  // Pile seeds along the V-trough bottom (narrow strip in X, full Y).
  // Random scatter biased toward the disc-rim dip line.
  const yMin = POOL.yCenter - POOL.y/2 + 4;
  const yMax = POOL.yCenter + POOL.y/2 - 4;
  for (let i = 0; i < n; i++) {
    const m = new THREE.Mesh(seedGeom, poolSeedMat);
    // Strong bias toward the V-trough centerline (x≈0)
    const x = (Math.random() - 0.5) * 12;
    const y = yMin + Math.random() * (yMax - yMin);
    // Stack vertically — a few rows from floor up to fill level
    const layer = Math.floor(i / 16);   // ~16 seeds per layer
    const z = POOL.zFloor + SEED_RADIUS + layer * (SEED_RADIUS * 1.6)
              + (Math.random() - 0.5) * 1.5;
    m.position.set(x, y, Math.min(z, POOL.fillZ));
    poolGroup.add(m);
    poolSeeds.push(m);
  }
}
spawnPoolFill(80);

// ============================================================================
//  Hole tracking, capture/travel/release state
// ============================================================================
//
// Each of N_HOLES has a fixed disc-local angle θ_n = n·(2π/N_HOLES).
// Disc rotation φ adds to it: world disc-local angle = (θ_n + φ) mod 2π.
// At PICKUP_THETA → attempt capture. At RELEASE_THETA → detach.
// Per-hole state tracks one captured seed.
//
// Travel direction (Option 1, per V5 spec): θ DECREASES over time —
// pickup θ=270° decreases through 180° (left side) up to 90° (release).
// In Three.js, we apply rotation around DISC_AXIS by NEGATIVE rotationAngle
// to achieve decreasing θ.

const holeState = new Array(N_HOLES).fill(null);    // null | { seed: Mesh }

let rotationAngle = 0;          // +ω in disc-local frame; we apply -rotationAngle to mesh

function holeWorldPosition(n, phi) {
  // φ is the cumulative rotation. Effective disc-local angle = θ_n - φ
  // (Option 1: θ decreases). Then apply tilt to map disc-local → world.
  const theta = (n * 2 * Math.PI / N_HOLES) - phi;
  const lx = R_PICKUP * Math.cos(theta);
  const ly = R_PICKUP * Math.sin(theta);
  return new THREE.Vector3(lx, ly * COS_T, ly * SIN_T);
}

function holeIsAt(n, phi, targetTheta, tol) {
  // Current effective θ in disc-local
  let theta = ((n * 2 * Math.PI / N_HOLES) - phi) % (2 * Math.PI);
  if (theta < 0) theta += 2 * Math.PI;
  const d = Math.abs(theta - targetTheta);
  return Math.min(d, 2 * Math.PI - d) < tol;
}

// ============================================================================
//  Falling seeds (after release)
// ============================================================================
const GRAVITY  = 9810;          // mm/s²
const TIME_SCALE = 0.18;        // visualisation slow-down
const fallingGroup = new THREE.Group();
scene.add(fallingGroup);
const fallingSeeds = [];

function releaseSeed(seedMesh, omega) {
  // Compute tangential velocity at release: v = ω × r
  // Travel direction is -ω in disc-local (Option 1) → world ω = -|ω|·DISC_AXIS
  // For the velocity calc we just use the result: at release (0, 29.7, 29.7),
  // |v| = |ω|·R, direction +X.
  const r = RELEASE_POS;
  const wMag = omega;   // rad/s, signed (positive in our convention)
  // ω vector (Option 1): along -DISC_AXIS times wMag
  const wVec = DISC_AXIS.clone().multiplyScalar(-wMag);
  const v = new THREE.Vector3().crossVectors(wVec, r);
  seedMesh.material = fallingSeedMat;
  seedMesh.userData = { vx: v.x, vy: v.y, vz: v.z, t: 0, falling: true };
  fallingGroup.attach(seedMesh);   // re-parent to scene root
  fallingSeeds.push(seedMesh);
}

function updateFallingSeeds(dt) {
  const sdt = dt * TIME_SCALE;
  for (let i = fallingSeeds.length - 1; i >= 0; i--) {
    const s = fallingSeeds[i];
    s.userData.vz -= GRAVITY * sdt;
    s.position.x  += s.userData.vx * sdt;
    s.position.y  += s.userData.vy * sdt;
    s.position.z  += s.userData.vz * sdt;
    s.userData.t  += dt;

    // Remove when far below the disc
    if (s.position.z < -60 || s.userData.t > 4.0) {
      fallingGroup.remove(s);
      fallingSeeds.splice(i, 1);
    }
  }
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
const angleEl       = document.getElementById('info-angle');
const poolEl        = document.getElementById('info-pool');
const captEl        = document.getElementById('info-captured');
const relEl         = document.getElementById('info-released');

let rpm = parseFloat(rpmInput.value);
let vacuum = parseFloat(vacuumInput.value);
let releasedCount = 0;

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
  discMat.clippingPlanes = planes;
  poolMat.clippingPlanes = planes;
  discMat.needsUpdate = true;
  poolMat.needsUpdate = true;
});
markersInput.addEventListener('change', () => {
  markerGroup.visible = markersInput.checked;
});
poolFillInput.addEventListener('change', () => {
  poolGroup.visible = poolFillInput.checked;
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

  // Disc rotation (Option 1: θ decreases — apply -rotationAngle to mesh).
  const omega = (rpm / 60) * 2 * Math.PI;     // rad/s
  rotationAngle += omega * dt;
  rotationAngle %= 2 * Math.PI;
  if (disc) disc.setRotationFromAxisAngle(DISC_AXIS, -rotationAngle);

  // Per-hole pickup / travel / release
  const tol = Math.max(0.05, omega * dt * 1.2);   // a slice in θ
  for (let n = 0; n < N_HOLES; n++) {
    const state = holeState[n];

    // Update captured seed position so it rides the hole
    if (state) {
      const wp = holeWorldPosition(n, rotationAngle);
      // Sit the seed on the disc-front face (offset by SEED_RADIUS along front normal)
      state.seed.position.set(
        wp.x + DISC_FRONT.x * SEED_RADIUS,
        wp.y + DISC_FRONT.y * SEED_RADIUS,
        wp.z + DISC_FRONT.z * SEED_RADIUS,
      );
    }

    // Release at θ=90° if the hole is carrying a seed
    if (state && holeIsAt(n, rotationAngle, RELEASE_THETA, tol)) {
      releaseSeed(state.seed, omega);
      holeState[n] = null;
      releasedCount++;
      continue;
    }

    // Pickup at θ=270° if vacuum is on AND pool has seeds AND hole is empty
    if (!state && vacuum > 5 && poolSeeds.length > 0
        && holeIsAt(n, rotationAngle, PICKUP_THETA, tol)) {
      // Take the topmost (highest-z) pool seed
      let topIdx = 0;
      for (let i = 1; i < poolSeeds.length; i++) {
        if (poolSeeds[i].position.z > poolSeeds[topIdx].position.z) topIdx = i;
      }
      const seed = poolSeeds[topIdx];
      poolSeeds.splice(topIdx, 1);
      poolGroup.remove(seed);
      seed.material = capturedSeedMat;
      scene.add(seed);
      holeState[n] = { seed };
    }
  }

  updateFallingSeeds(dt);

  // HUD
  angleEl.textContent  = (rotationAngle * 180 / Math.PI).toFixed(1) + '°';
  poolEl.textContent   = poolSeeds.length;
  const captured = holeState.filter(s => s).length;
  captEl.textContent   = captured;
  relEl.textContent    = releasedCount;

  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
animate();
