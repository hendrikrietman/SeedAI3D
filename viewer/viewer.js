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

// FRONT_NORMAL — unit vector pointing INTO the half-space where seeds sit.
// FLIP (2026-04-27): Hendrik's correction: seeds and pool fill should be
// on the *operator-visible* side of the disc; chamber on the operator-far
// side ("behind"). The default viewer camera is at (+X, -Y, +Z), which is
// in the disc_plane_eq > 0 half-space. So FRONT_NORMAL points into eq>0:
//
//   disc_plane_eq(x,y,z) = -sin45°·y + cos45°·z
//   FRONT_NORMAL = +∇(eq)/|...| = (0, -sin45°, +cos45°)
//
// Attached seeds at θ=270° rim (0,-29.7,-29.7) offset by FN·SEED_RADIUS
// land at (0, -31.8, -27.6); disc_plane_eq = +3.0 (eq>0, camera-visible).
// The vacuum chamber's SCAD source has been mirrored so its bulk is now
// in +Y, -Z (eq<0, hidden behind disc). Both afstrijker SCAD modules
// have ALSO been flipped (mirror removed) so the blades stay on the
// seed-attachment face — they physically must, to brush off seeds.
const FRONT_NORMAL = new THREE.Vector3(0, -SIN_T, COS_T).normalize();
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

// Vacuum chamber sector — disc-local θ ∈ [90°, 270°] which maps to world
// x ≤ 0 (chamber sector covers the back-arc through θ=180°). A pickup hole
// is "in the vacuum sector" when its world x ≤ 0.
const VAC_SECTOR_X_MAX = 0;

// Singulator + release-zone pusher
const AFSTRIJKER_SLIP_PROB  = 0.05;
const AFSTRIJKER2_PUSH_PROB = 0.10;

// Seed offset = SEED_RADIUS so the seed's near pole touches the disc-front
// surface centred on the pickup hole. Hole Ø=4 mm < seed Ø=6 mm, so the
// seed rests against the disc face around the hole and cannot pass through.
// Defined further down once SEED_RADIUS is in scope.

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
const vacuumChamberMat = new THREE.MeshPhongMaterial({
  color: 0x8aa4d4, specular: 0x222244, shininess: 40,
  side: THREE.DoubleSide, transparent: true, opacity: 0.30,
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

// ----- Per-hole vacuum-glow markers -----
// One small additive blue sphere per pickup hole. Each frame we hide/show
// based on whether the hole's current world position lies inside the
// vacuum sector (x ≤ 0) AND vacuum is on. Visualises which holes are
// currently "active" pickups.
const holeGlowGroup = new THREE.Group();
scene.add(holeGlowGroup);
const holeGlowMeshes = [];
{
  const glowGeom = new THREE.SphereGeometry(2.0, 12, 8);
  const glowMat = new THREE.MeshBasicMaterial({
    color: 0x66bbff, transparent: true, opacity: 0.75,
    blending: THREE.AdditiveBlending, depthWrite: false,
  });
  for (let n = 0; n < N_HOLES; n++) {
    const m = new THREE.Mesh(glowGeom, glowMat);
    m.visible = false;
    holeGlowGroup.add(m);
    holeGlowMeshes.push(m);
  }
}

// ============================================================================
//  STL load — disc, pool, afstrijker, geleider, drop_tube
// ============================================================================
let disc = null;
let afstrijkerMesh = null;
let afstrijker2Mesh = null;
let geleiderMesh = null;
let dropTubeMesh = null;
let vacuumChamberMesh = null;
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
loadStl('./models/afstrijker.stl',  afstrijkerMat, (m) => {
  afstrijkerMesh  = m;
  m.updateMatrixWorld(true);
  verifyMeshAgainstAnchor('afstrijker1', m, ANCHOR.afstrijker1, 1.5);
});
loadStl('./models/afstrijker2.stl', afstrijkerMat, (m) => {
  afstrijker2Mesh = m;
  m.updateMatrixWorld(true);
  verifyMeshAgainstAnchor('afstrijker2', m, ANCHOR.afstrijker2, 1.5);
});
loadStl('./models/geleider.stl',   geleiderMat,    (m) => {
  geleiderMesh = m;
  m.updateMatrixWorld(true);
  // Geleider has long curved body; check sign of disc_plane_eq, not strict Δ.
  const c = meshCentroid(m);
  console.log(
    `[anchor ✓] geleider STL centroid (${c.x.toFixed(2)}, ${c.y.toFixed(2)}, ` +
    `${c.z.toFixed(2)}) | disc_plane_eq=${discPlaneEq(c).toFixed(2)} ` +
    `(expect <0 for front-side) | ${discPlaneEq(c) < 0 ? 'PASS' : 'FAIL'}`,
  );
});
loadStl('./models/drop_tube.stl',  dropTubeMat,    (m) => { dropTubeMesh = m; });
loadStl('./models/vacuum_chamber.stl', vacuumChamberMat, (m) => {
  vacuumChamberMesh = m;
  m.updateMatrixWorld(true);
  verifyMeshAgainstAnchor('vacuum_chamber', m, ANCHOR.chamber, 2.0);
  const c = meshCentroid(m);
  console.log(
    `[anchor ✓] chamber back-side check: disc_plane_eq=${discPlaneEq(c).toFixed(2)} ` +
    `(expect >0 for back-side) | ${discPlaneEq(c) > 0 ? 'PASS' : 'FAIL'}`,
  );
});

// ============================================================================
//  Pool fill — visible seed pile, with refill so the animation never starves
// ============================================================================
const POOL_TARGET = 50;
const POOL_REFILL_AT = 12;
const poolGroup = new THREE.Group();
scene.add(poolGroup);
const poolSeeds = [];

function placePoolSeed(seed) {
  // Reservoir seeds must sit on the seed-side of the disc plane (eq > 0
  // post-flip), so all visible pool fill is on the same half-space as
  // the attached seeds and the operator's view. disc_plane_eq(0,y,z) =
  // -sin45°·y + cos45°·z, so eq > 0 ⇔ z > y. We pick the layer-z first,
  // then clamp y so y < z − 1.5 mm (margin keeps the seed clear of the
  // disc plane). The result is a wedge of seeds piling up against the
  // far-y end of the pool — physically what happens when a tilted disc
  // dips into a pool: seeds collect on the lower side of the dipping
  // edge.
  const yMin = POOL.yCenter - POOL.y / 2 + 4;
  const yMax = POOL.yCenter + POOL.y / 2 - 4;
  const x = (Math.random() - 0.5) * 12;
  const layer = Math.floor(poolSeeds.length / 14);
  const z_layer = POOL.zFloor + SEED_RADIUS
                + layer * (SEED_RADIUS * 1.6)
                + (Math.random() - 0.5) * 1.5;
  const z = Math.min(z_layer, POOL.fillZ);
  const y_max_eff = Math.min(yMax, z - 1.5);
  const y = yMin + Math.random() * Math.max(0.5, y_max_eff - yMin);
  seed.position.set(x, y, z);
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
//  ANCHOR-BASED VERIFICATION  (2026-04-27)
//
//  Spec: afstrijkers physically must be on the seed-side of the disc, since
//  their job is to brush off mis-attached seeds. They are therefore the
//  visual ground truth for "front side". All other front-side components
//  (pool, attached seeds, geleider mouth) must lie on the same side as the
//  afstrijkers; the back-side component (vacuum chamber + nipple) must lie
//  on the opposite side.
//
//  Each anchor's expected centroid is computed by offsetting the relevant
//  rim point along ±FRONT_NORMAL by the SCAD's chosen standoff. On STL
//  load we compute the loaded mesh centroid and check (i) the same-Y-sign
//  test from the spec, (ii) sign of disc_plane_eq, and (iii) Euclidean
//  distance to the computed expected centroid.
// ============================================================================

const DISC_THICKNESS = 4;
const AFS_HEIGHT  = 8;     // afstrijker 1 blade height
const AFS2_HEIGHT = 6;     // afstrijker 2 blade height

function rimPointWorld(thetaDeg) {
  const t = thetaDeg * Math.PI / 180;
  return new THREE.Vector3(
    R_PICKUP * Math.cos(t),
    R_PICKUP * Math.sin(t) * COS_T,
    R_PICKUP * Math.sin(t) * SIN_T,
  );
}

function offsetAlongFront(rimPt, distance) {
  return rimPt.clone().add(FRONT_NORMAL.clone().multiplyScalar(distance));
}

// SCAD blade-centroid is at offset (DISC_THICKNESS/2 + height/2 + 1) along
// FRONT_NORMAL from the rim point at the blade's θ.
const AFS1_OFFSET  = DISC_THICKNESS / 2 + AFS_HEIGHT  / 2 + 1;   // 7
const AFS2_OFFSET  = DISC_THICKNESS / 2 + AFS2_HEIGHT / 2 + 1;   // 6

const ANCHOR = {
  afstrijker1: offsetAlongFront(rimPointWorld(250), AFS1_OFFSET),
  afstrijker2: offsetAlongFront(rimPointWorld(95),  AFS2_OFFSET),
  seedAtPickup: offsetAlongFront(rimPointWorld(270), SEED_RADIUS),
  // Geleider catch-mouth: catches seeds AFTER they've crossed the disc
  // plane during free-fall. Sits at z=20 below the release point. Its
  // disc_plane_eq is < 0 (chamber-side); seeds enter from eq>0 side and
  // descend through it. Position itself is unchanged by the flip.
  geleiderMouth: new THREE.Vector3(0, GELEIDER.mouthYCenter, GELEIDER.mouthZ),
  // Vacuum chamber centroid (post-FLIP): SCAD-validated (-26.67, +6.67, -6.67).
  // disc_plane_eq = -9.43 < 0 → chamber-side, opposite of seeds.
  chamber: new THREE.Vector3(-26.67, 6.67, -6.67),
};

function meshCentroid(mesh) {
  mesh.geometry.computeBoundingBox();
  const c = new THREE.Vector3();
  mesh.geometry.boundingBox.getCenter(c);
  c.applyMatrix4(mesh.matrixWorld);
  return c;
}

function logAnchorReport() {
  const POOL_Y = POOL.yCenter;       // -30
  const RELEASE_Y = +29.7;
  const sameSign = (a, b) => Math.sign(a) === Math.sign(b) && a !== 0;
  console.log('=== ANCHOR-BASED VERIFICATION ===');
  console.log(
    `FRONT_NORMAL = (${FRONT_NORMAL.x.toFixed(4)}, ` +
    `${FRONT_NORMAL.y.toFixed(4)}, ${FRONT_NORMAL.z.toFixed(4)})`,
  );

  const a1 = ANCHOR.afstrijker1;
  console.log(
    `[anchor] afstrijker1 (θ=250°) expected centroid ` +
    `(${a1.x.toFixed(2)}, ${a1.y.toFixed(2)}, ${a1.z.toFixed(2)})`,
  );
  console.log(
    `         pool y_center=${POOL_Y}, afstrijker1.y=${a1.y.toFixed(2)} ` +
    `→ same Y sign? ${sameSign(POOL_Y, a1.y)} ` +
    `(disc_plane_eq=${discPlaneEq(a1).toFixed(2)}, expect <0)`,
  );

  const a2 = ANCHOR.afstrijker2;
  console.log(
    `[anchor] afstrijker2 (θ=95°)  expected centroid ` +
    `(${a2.x.toFixed(2)}, ${a2.y.toFixed(2)}, ${a2.z.toFixed(2)})`,
  );
  console.log(
    `         release y=${RELEASE_Y}, afstrijker2.y=${a2.y.toFixed(2)} ` +
    `→ same Y sign? ${sameSign(RELEASE_Y, a2.y)} ` +
    `(disc_plane_eq=${discPlaneEq(a2).toFixed(2)}, expect <0)`,
  );

  const sp = ANCHOR.seedAtPickup;
  console.log(
    `[anchor] seed at pickup (θ=270°) expected ` +
    `(${sp.x.toFixed(2)}, ${sp.y.toFixed(2)}, ${sp.z.toFixed(2)}) ` +
    `→ pool y same sign? ${sameSign(POOL_Y, sp.y)} ` +
    `(disc_plane_eq=${discPlaneEq(sp).toFixed(2)}, expect <0)`,
  );

  const gm = ANCHOR.geleiderMouth;
  console.log(
    `[anchor] geleider mouth at (${gm.x.toFixed(2)}, ${gm.y.toFixed(2)}, ` +
    `${gm.z.toFixed(2)}) → release y same sign? ${sameSign(RELEASE_Y, gm.y)} ` +
    `(disc_plane_eq=${discPlaneEq(gm).toFixed(2)}, expect <0)`,
  );

  const cc = ANCHOR.chamber;
  console.log(
    `[anchor] chamber centroid (${cc.x.toFixed(2)}, ${cc.y.toFixed(2)}, ` +
    `${cc.z.toFixed(2)}) → opposite-of-pool? ${!sameSign(POOL_Y, cc.y)} ` +
    `(disc_plane_eq=${discPlaneEq(cc).toFixed(2)}, expect >0)`,
  );

  console.log('=== /ANCHOR ===');
}

function verifyMeshAgainstAnchor(label, mesh, anchor, tolMm) {
  const c = meshCentroid(mesh);
  const d = c.distanceTo(anchor);
  const eq = discPlaneEq(c);
  console.log(
    `[anchor ✓] ${label} STL centroid (${c.x.toFixed(2)}, ` +
    `${c.y.toFixed(2)}, ${c.z.toFixed(2)}) | ` +
    `expected (${anchor.x.toFixed(2)}, ${anchor.y.toFixed(2)}, ` +
    `${anchor.z.toFixed(2)}) | ` +
    `Δ=${d.toFixed(2)} mm (tol ${tolMm}) | ` +
    `disc_plane_eq=${eq.toFixed(2)} | ` +
    `${d <= tolMm ? 'PASS' : 'FAIL'}`,
  );
}

logAnchorReport();

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
const vacChamberInput  = document.getElementById('show-vacuum-chamber');
const vacGlowInput     = document.getElementById('show-vacuum-glow');

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
  for (const m of [discMat, poolMat, afstrijkerMat, geleiderMat, dropTubeMat,
                   vacuumChamberMat]) {
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
vacChamberInput.addEventListener('change', () => {
  if (vacuumChamberMesh) vacuumChamberMesh.visible = vacChamberInput.checked;
});
vacGlowInput.addEventListener('change', () => {
  holeGlowGroup.visible = vacGlowInput.checked;
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
      // Offset = SEED_RADIUS → seed near pole rests on disc-front surface
      // centred on the (4 mm) hole. Seed Ø=6 mm > hole Ø=4 mm: cannot pass
      // through.
      const wp = holeWorldPosition(n, rotationAngle);
      state.seed.position.set(
        wp.x + FRONT_NORMAL.x * SEED_RADIUS,
        wp.y + FRONT_NORMAL.y * SEED_RADIUS,
        wp.z + FRONT_NORMAL.z * SEED_RADIUS,
      );
      verifyFrontNormalOnce(wp, state.seed.position);

      // Vacuum off → seed drops immediately (no tangential velocity).
      // Most likely misses the geleider; counted as missed.
      if (vacuum < 5) {
        detachToFalling(state.seed, 0,
          state.seed.position.x, state.seed.position.y, state.seed.position.z);
        holeState[n] = null;
        continue;
      }

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

  // Per-hole vacuum glow — visible when hole is in the chamber sector
  // (world x ≤ 0) AND vacuum is on. Position rides the rotating hole.
  const glowVisible = vacuum > 5;
  for (let n = 0; n < N_HOLES; n++) {
    const wp = holeWorldPosition(n, rotationAngle);
    const inSector = wp.x <= VAC_SECTOR_X_MAX;
    const m = holeGlowMeshes[n];
    if (glowVisible && inSector) {
      m.position.copy(wp);
      m.visible = true;
    } else {
      m.visible = false;
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
