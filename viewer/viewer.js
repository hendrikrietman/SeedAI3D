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

// Pool geometry — Phase 7 hopper replaces the half-disc pool.
// Hopper is a vertical funnel (axis along world -Z). Pool seeds spawn in
// the narrow bottom (30×30) at world (X≈0, Y≈-46.67, Z≈-67..-47), where
// the disc-rim at θ=270° (world (0, -46.67, -46.67)) dips into the pool
// surface. Mirrors parameters.scad HOPPER_*.
const POOL = {
  // v5.8.3: spawn region now covers the full hopper interior (pool floor
  // up through funnel) so 100 seeds are visible inside the hopper, not
  // stacked at the floor.
  bottomX: 22, bottomY: 22,         // narrow (pool) cross-section
  topX: 50,    topY: 35,            // wide (hopper top) cross-section
  xCenter: 0,  yCenter: -30,
  zFloor: -42, zTop: -32,           // pool zone (constant cross-section)
  zHopperTop: -7,                   // hopper top (open)
  fillZ: -10,                        // cap seeds just below hopper top
};

// Phase 6 — disc-mal integrated plate. Pre-tilt frame (= disc-local).
// Plate Z range and pinion centre come from parameters.scad.
const MAL = {
  plateX: 180, plateY: 180, plateThickness: 15,
  zFront: 2.5, zBack: -12.5,
  chamberRIn: 32, chamberROut: 52, chamberDepth: 8,
  pinionCentreX: -75, pinionPitchR: 15, pinionOD: 33, pinionThickness: 8,
  motorBodySize: 42, motorBodyLength: 47,
  shaftBoreDia: 7,
};

// Pinion rotates 3× faster than disc (60-tooth disc / 20-tooth pinion).
// Pinion axis = disc axis (same direction). Engagement direction is
// reversed since they're external gears.
const PINION_RATIO = 60 / 20;

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
// poolMat removed in Phase 7 (seed_pool.stl archived; hopper takes over).
const afstrijkerMat = new THREE.MeshPhongMaterial({
  color: 0x484c54, specular: 0x111114, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.92,
  clippingPlanes: [],
});
const geleiderMat = new THREE.MeshPhongMaterial({
  color: 0x2c3036, specular: 0x111114, shininess: 32,
  side: THREE.DoubleSide, transparent: true, opacity: 0.72,
  clippingPlanes: [],
});
const dropTubeMat = new THREE.MeshPhongMaterial({
  color: 0x2c3036, specular: 0x111114, shininess: 32,
  side: THREE.DoubleSide, transparent: true, opacity: 0.82,
  clippingPlanes: [],
});
const malPlateMat = new THREE.MeshPhongMaterial({
  color: 0x4a4a52, specular: 0x222226, shininess: 32,
  side: THREE.DoubleSide, transparent: true, opacity: 0.78,
  clippingPlanes: [],
});
const pinionMat = new THREE.MeshPhongMaterial({
  color: 0x6699d4, specular: 0x222226, shininess: 50,
  side: THREE.DoubleSide,
  clippingPlanes: [],
});
const motorMat = new THREE.MeshPhongMaterial({
  color: 0xa0a0a8, specular: 0x222226, shininess: 60,
  side: THREE.DoubleSide,
  clippingPlanes: [],
});
// Phase 7 — transparent housing (industrial PETG-clear look).
const hopperMat = new THREE.MeshPhongMaterial({
  color: 0xb4b4c8, specular: 0x222226, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.35,
  clippingPlanes: [],
});
const lidMat = new THREE.MeshPhongMaterial({
  color: 0xb4b4c8, specular: 0x222226, shininess: 30,
  side: THREE.DoubleSide, transparent: true, opacity: 0.30,
  clippingPlanes: [],
});
const dustRingMat = new THREE.MeshPhongMaterial({
  color: 0x8a1818, specular: 0x222226, shininess: 25,
  side: THREE.DoubleSide, transparent: true, opacity: 0.85,
  clippingPlanes: [],
});
const vacTubeMat = new THREE.MeshPhongMaterial({
  color: 0x4a4a52, specular: 0x222226, shininess: 35,
  side: THREE.DoubleSide, transparent: true, opacity: 0.75,
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
const cleaningSeedMat = new THREE.MeshPhongMaterial({
  color: 0x55a8d4, emissive: 0x113344, shininess: 60,
});

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
//  Vacuum O-ring seals (procedural — no STL).
//  D14 dual-sector: TWO independent racetrack loops, one per sub-sector,
//  with the partition wall handling sealing between them. Each loop:
//  outer arc R=53 + inner arc R=31 + 2 radial end-cap cords closing the
//  racetrack at the sector boundaries. Geometry mirrors the groove cuts
//  in scad/v5_6_disc_mal.scad's oring_groove_for_sector.
// ============================================================================
const ORING_OUTER_R     = 53;
const ORING_INNER_R     = 31;
const ORING_CORD_R      = 1.25;
const ORING_GROOVE_HALF_W = 1.6;
const ORING_Z_PLATE_FACE  = -2.5;
const ORING_Z_GROOVE_FLR  = -4.4;
const ORING_Z_CORD_CENTER = -3.25;
const ORING_Z_WALL_MID    = (ORING_Z_PLATE_FACE + ORING_Z_GROOVE_FLR) / 2;
const ORING_WALL_HEIGHT   = ORING_Z_PLATE_FACE - ORING_Z_GROOVE_FLR;
const ORING_WALL_T        = 0.4;
const VACUUM_THETA_START_DEG = 110;       // matches SCAD SECTOR_VACUUM_THETA_START
const VACUUM_THETA_END_DEG   = 270;
const BLOW_THETA_START_DEG   = 90;
const BLOW_THETA_END_DEG     = 110;

const oringGroup = new THREE.Group();
{
  const cordMat = new THREE.MeshPhongMaterial({
    color: 0x1a1a1a, shininess: 12, specular: 0x222222,
  });
  const wallMat = new THREE.MeshPhongMaterial({
    color: 0x6e6e6e, shininess: 4,
  });
  // Add one closed-loop racetrack at the given sub-sector.
  const addLoop = (theta_start_deg, theta_end_deg) => {
    const theta_start = theta_start_deg * Math.PI / 180;
    const arc_rad     = (theta_end_deg - theta_start_deg) * Math.PI / 180;
    const arc_segs    = Math.max(16, Math.ceil((theta_end_deg - theta_start_deg) / 2));
    // Cord arcs: TorusGeometry's arc starts at local +X. Rotate by
    // theta_start around Z to align the start with the desired angle.
    const cordArc = (R, z) => {
      const m = new THREE.Mesh(
        new THREE.TorusGeometry(R, ORING_CORD_R, 8, arc_segs, arc_rad), cordMat,
      );
      m.rotation.z = theta_start;
      m.position.z = z;
      return m;
    };
    oringGroup.add(cordArc(ORING_OUTER_R, ORING_Z_CORD_CENTER));
    oringGroup.add(cordArc(ORING_INNER_R, ORING_Z_CORD_CENTER));
    // End-straight cords: each is a radial segment at theta_start and
    // theta_end, going from R=ORING_INNER to R=ORING_OUTER. Cylinder along
    // disc-local Y by default; rotated by (theta - 90°) so its axis aligns
    // with the radial direction at that angle.
    const straightLen = ORING_OUTER_R - ORING_INNER_R;
    const straightMid = (ORING_OUTER_R + ORING_INNER_R) / 2;
    const straightGeom = new THREE.CylinderGeometry(
      ORING_CORD_R, ORING_CORD_R, straightLen, 16
    );
    for (const theta_deg of [theta_start_deg, theta_end_deg]) {
      const theta = theta_deg * Math.PI / 180;
      const m = new THREE.Mesh(straightGeom, cordMat);
      m.position.set(
        Math.cos(theta) * straightMid,
        Math.sin(theta) * straightMid,
        ORING_Z_CORD_CENTER,
      );
      m.rotation.z = theta - Math.PI / 2;   // align cylinder Y-axis with radial direction at θ
      oringGroup.add(m);
    }
    // Slot-wall outlines (light grey, exaggerated thickness for visibility).
    const wallArcMesh = (R, z) => {
      const m = new THREE.Mesh(
        new THREE.TorusGeometry(R, ORING_WALL_T / 2, 4, arc_segs, arc_rad),
        wallMat,
      );
      m.rotation.z = theta_start;
      m.position.z = z;
      m.scale.z = ORING_WALL_HEIGHT / ORING_WALL_T;
      return m;
    };
    oringGroup.add(wallArcMesh(ORING_OUTER_R - ORING_GROOVE_HALF_W, ORING_Z_WALL_MID));
    oringGroup.add(wallArcMesh(ORING_OUTER_R + ORING_GROOVE_HALF_W, ORING_Z_WALL_MID));
    oringGroup.add(wallArcMesh(ORING_INNER_R - ORING_GROOVE_HALF_W, ORING_Z_WALL_MID));
    oringGroup.add(wallArcMesh(ORING_INNER_R + ORING_GROOVE_HALF_W, ORING_Z_WALL_MID));
    // End-cap walls: thin BoxGeometry slabs at theta_start and theta_end.
    const endStraightLen = (ORING_OUTER_R - ORING_INNER_R) + 2 * ORING_GROOVE_HALF_W;
    const endWallGeom = new THREE.BoxGeometry(
      endStraightLen, ORING_WALL_T, ORING_WALL_HEIGHT
    );
    for (const theta_deg of [theta_start_deg, theta_end_deg]) {
      const theta = theta_deg * Math.PI / 180;
      const dx = Math.cos(theta) * straightMid;
      const dy = Math.sin(theta) * straightMid;
      // Two walls bordering the end-cap (one inner, one outer along the
      // tangential direction). Tangent = perpendicular to radial = (-sin, cos).
      const tx = -Math.sin(theta), ty = Math.cos(theta);
      for (const wSign of [-1, +1]) {
        const m = new THREE.Mesh(endWallGeom, wallMat);
        m.position.set(
          dx + wSign * tx * ORING_GROOVE_HALF_W,
          dy + wSign * ty * ORING_GROOVE_HALF_W,
          ORING_Z_WALL_MID,
        );
        m.rotation.z = theta - Math.PI / 2;
        oringGroup.add(m);
      }
    }
  };
  // Two loops: vacuum sub-sector + blow sub-sector.
  addLoop(VACUUM_THETA_START_DEG, VACUUM_THETA_END_DEG);
  addLoop(BLOW_THETA_START_DEG, BLOW_THETA_END_DEG);
}
oringGroup.rotation.x = TILT;
oringGroup.visible = false;
scene.add(oringGroup);

// ============================================================================
//  Partition wall (D14 — sector A / sector B divider).
//  Procedural: a thin slab at θ=110° in disc-local, between R_IN and R_OUT,
//  full chamber depth, top sticks up 0.4 mm above plate face. Mirrors
//  scad/v5_6_disc_mal.scad's mal_partition_wall.
// ============================================================================
const partitionGroup = new THREE.Group();
{
  const PARTITION_THETA_DEG = 110;
  const PARTITION_T         = 1.5;
  const PARTITION_OVERSIZE  = 0.4;
  const CHAMBER_R_IN        = 32;
  const CHAMBER_R_OUT       = 52;
  const CHAMBER_DEPTH       = 8;
  const Z_CHAMBER_BK        = -10.5;
  const partitionMat = new THREE.MeshPhongMaterial({
    color: 0x444444, shininess: 8, specular: 0x222222,
  });
  const slab = new THREE.Mesh(
    new THREE.BoxGeometry(
      CHAMBER_R_OUT - CHAMBER_R_IN + 1,
      PARTITION_T,
      CHAMBER_DEPTH + PARTITION_OVERSIZE,
    ),
    partitionMat,
  );
  // Centre the slab radially at midpoint, vertically at chamber-mid.
  const theta = PARTITION_THETA_DEG * Math.PI / 180;
  const r_mid = (CHAMBER_R_IN + CHAMBER_R_OUT) / 2;
  const z_mid = Z_CHAMBER_BK + (CHAMBER_DEPTH + PARTITION_OVERSIZE) / 2;
  slab.position.set(
    Math.cos(theta) * r_mid,
    Math.sin(theta) * r_mid,
    z_mid,
  );
  slab.rotation.z = theta;   // align slab's local X with the radial direction
  partitionGroup.add(slab);
}
partitionGroup.rotation.x = TILT;
scene.add(partitionGroup);

// ============================================================================
//  Blow nipple fitting (D14 — sourced part, NOT in mal_plate.stl).
//  Procedural visualization of the Ø10/Ø6 push-in fitting that mounts
//  in the bore at (BLOW_NIPPLE_X, BLOW_NIPPLE_Y) on plate-back.
// ============================================================================
const blowFittingGroup = new THREE.Group();
{
  const BLOW_NIPPLE_THETA_DEG = 101.25;
  const BLOW_NIPPLE_R         = 42;
  const BLOW_OD               = 10;
  const BLOW_ID               = 6;
  const BLOW_LEN              = 25;
  const Z_PLATE_BACK          = -12.5;
  const fittingMat = new THREE.MeshPhongMaterial({
    color: 0x2a4d8c, shininess: 30, specular: 0x4477aa,    // dark blue, machined-fitting look
  });
  // Body: hollow cylinder, hangs off plate-back along -Z (pre-tilt).
  const ringGeom = new THREE.CylinderGeometry(BLOW_OD / 2, BLOW_OD / 2, BLOW_LEN, 24, 1, true);
  const ring = new THREE.Mesh(ringGeom, fittingMat);
  // CylinderGeometry default axis is Y; rotate to make it along -Z (axial).
  ring.rotation.x = Math.PI / 2;
  // Position: centred on bore, half-length below plate-back.
  const theta = BLOW_NIPPLE_THETA_DEG * Math.PI / 180;
  ring.position.set(
    Math.cos(theta) * BLOW_NIPPLE_R,
    Math.sin(theta) * BLOW_NIPPLE_R,
    Z_PLATE_BACK - BLOW_LEN / 2,
  );
  blowFittingGroup.add(ring);
}
blowFittingGroup.rotation.x = TILT;
scene.add(blowFittingGroup);

// ============================================================================
//  STL load — disc, pool, afstrijker, geleider, drop_tube
// ============================================================================
let disc = null;
let afstrijkerMesh = null;
let afstrijker2Mesh = null;
let geleiderMesh = null;
let dropTubeMesh = null;
let malPlateMesh = null;
let pinionMesh = null;
let motorMesh = null;
let hopperMesh = null;
let lidMesh = null;
let dustRingMesh = null;
let vacTubeMesh = null;
const loader = new STLLoader();

const STL_CACHE_BUST = `?v=${Date.now()}`;
function loadStl(path, mat, onMesh) {
  const url = path + STL_CACHE_BUST;
  loader.load(url, (geometry) => {
    geometry.computeVertexNormals();
    const m = new THREE.Mesh(geometry, mat);
    scene.add(m);
    geometry.computeBoundingBox();
    const bb = geometry.boundingBox;
    console.log(`[stl ✓] ${path} loaded — bounds x[${bb.min.x.toFixed(1)},${bb.max.x.toFixed(1)}] y[${bb.min.y.toFixed(1)},${bb.max.y.toFixed(1)}] z[${bb.min.z.toFixed(1)},${bb.max.z.toFixed(1)}]`);
    if (onMesh) onMesh(m);
  }, undefined, (err) => console.error(`${path} load failed:`, err));
}

loadStl('./models/disc.stl',       discMat,        (m) => { disc = m; });
// Phase 7: seed_pool archived → replaced by hopper. Loaded below.
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
loadStl('./models/mal_plate.stl', malPlateMat, (m) => {
  malPlateMesh = m;
  m.updateMatrixWorld(true);
  const c = meshCentroid(m);
  console.log(
    `[anchor ✓] mal_plate centroid (${c.x.toFixed(2)}, ${c.y.toFixed(2)}, ` +
    `${c.z.toFixed(2)}) | disc_plane_eq=${discPlaneEq(c).toFixed(2)} ` +
    `(expect <0 — plate bulk is on disc-back side post-tilt)`,
  );
});
loadStl('./models/pinion.stl', pinionMat, (m) => {
  pinionMesh = m;
  // To rotate the pinion around its own axis (disc-axis through (-75,0,0)),
  // shift the geometry so the pinion centre lands at mesh-local origin,
  // then place the mesh at the pinion centre. Subsequent
  // setRotationFromAxisAngle(DISC_AXIS, angle) rotates the gear in place.
  m.geometry.translate(-MAL.pinionCentreX, 0, 0);   // shift +75 in X
  m.position.set(MAL.pinionCentreX, 0, 0);
});
loadStl('./models/motor.stl', motorMat, (m) => { motorMesh = m; });
loadStl('./models/hopper.stl', hopperMat, (m) => { hopperMesh = m; });
loadStl('./models/lid.stl', lidMat, (m) => { lidMesh = m; });
loadStl('./models/dust_ring.stl', dustRingMat, (m) => { dustRingMesh = m; });
loadStl('./models/vac_tube.stl', vacTubeMat, (m) => { vacTubeMesh = m; });

// ============================================================================
//  Pool fill — visible seed pile, with refill so the animation never starves
// ============================================================================
const POOL_TARGET = 100;        // v5.8.3: 100 seeds enter the hopper
const POOL_REFILL_AT = 20;      // refill once disc has picked 80, leaving 20
const poolGroup = new THREE.Group();
scene.add(poolGroup);
const poolSeeds = [];

function computePoolSpawnPosition(occupancyCount) {
  // Spawn seeds in layers from pool floor upward. Layer footprint
  // matches the hopper cross-section at that z (constant in pool zone,
  // widening through the funnel). Used by both placePoolSeed (for
  // direct/initial fill) and the feeder animation target.
  const seedsPerLayer = 6;
  const layer = Math.floor(occupancyCount / seedsPerLayer);
  const z_layer = POOL.zFloor + SEED_RADIUS
                + layer * (SEED_RADIUS * 1.6)
                + (Math.random() - 0.5) * 1.0;
  const z = Math.min(z_layer, POOL.fillZ);
  let footX, footY;
  if (z <= POOL.zTop) {
    footX = POOL.bottomX;
    footY = POOL.bottomY;
  } else {
    const t = Math.min(1, (z - POOL.zTop) / (POOL.zHopperTop - POOL.zTop));
    footX = POOL.bottomX + t * (POOL.topX - POOL.bottomX);
    footY = POOL.bottomY + t * (POOL.topY - POOL.bottomY);
  }
  const halfX = footX / 2 - 2;
  const halfY = footY / 2 - 2;
  const x = POOL.xCenter + (Math.random() - 0.5) * 2 * halfX;
  const y = POOL.yCenter + (Math.random() - 0.5) * 2 * halfY;
  return new THREE.Vector3(x, y, z);
}

function placePoolSeed(seed) {
  seed.position.copy(computePoolSpawnPosition(poolSeeds.length));
}

function spawnPoolSeed() {
  const m = new THREE.Mesh(seedGeom, poolSeedMat);
  placePoolSeed(m);
  poolGroup.add(m);
  poolSeeds.push(m);
}

function refillPoolIfLow() {
  // v5.8.4: refills now drip in through the feeder tube instead of
  // teleporting. Account for seeds already in flight so we don't
  // over-queue.
  const total = poolSeeds.length + feedingSeeds.length + refillRemaining;
  if (total < POOL_REFILL_AT) {
    refillRemaining = POOL_TARGET - poolSeeds.length - feedingSeeds.length;
  }
}

function pumpFeeder(dt) {
  if (refillRemaining <= 0) return;
  feedAccumulator += dt * FEED_RATE;
  while (feedAccumulator >= 1 && refillRemaining > 0) {
    feedAccumulator -= 1;
    refillRemaining -= 1;
    spawnFeedingSeed();
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
    `(>0 means seed-side post-FLIP, expected for a pool seed)`,
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

const fallingGroup  = new THREE.Group(); scene.add(fallingGroup);
const glidingGroup  = new THREE.Group(); scene.add(glidingGroup);
const exitingGroup  = new THREE.Group(); scene.add(exitingGroup);
const cleaningGroup = new THREE.Group(); scene.add(cleaningGroup);
const feedingGroup  = new THREE.Group(); scene.add(feedingGroup);

const fallingSeeds  = [];   // { mesh, vx, vy, vz, t }
const glidingSeeds  = [];   // { mesh, t, dur, p0, p1 }
const exitingSeeds  = [];   // { mesh, t, dur, p0, p1 }
const cleaningSeeds = [];   // { mesh, t, stage, p0, p1, p2 }
const feedingSeeds  = [];   // { mesh, t, dur, p0, p1 }

// =====================================================================
//  Clean-cycle (Phase 5b) — operator pulls all pool seeds out via the
//  top-mount vac-cleanup tube, leaving the compartment empty between
//  runs / between varieties / for storage.
//
//  Tube geometry mirrors parameters.scad VAC_CLEAN_TUBE_*.
//  Mouth: inside the pool at z = floor + 7 = -43.
//  Direction: 80° elev from horizontal in -Y (tilts toward operator).
//  Length: 25 mm in-pool + 60 mm out-pool = 85 mm total.
// =====================================================================
const CLEAN_RATE = 3.0;           // seeds per second sucked out of pool
// v5.8.4: vac-tube re-added; mouth at hopper-pool (z=-34, y=-35), tube
// extends 60 mm at 80° elev tilting toward operator (-Y, +Z).
const VAC_CLEAN_MOUTH = new THREE.Vector3(0, -35, -34);
const VAC_CLEAN_DIR = new THREE.Vector3(
  0,
  -Math.cos(80 * Math.PI / 180),
  Math.sin(80 * Math.PI / 180),
).normalize();
const VAC_CLEAN_END = VAC_CLEAN_MOUTH.clone()
  .add(VAC_CLEAN_DIR.clone().multiplyScalar(60));

let cleanCycleActive = false;
let cleanAccumulator = 0;
let cleanedCount = 0;

// =====================================================================
//  Feeder seed-flow (v5.8.4) — visualises seeds entering the hopper
//  through the feeder tube instead of teleporting in. When refill
//  triggers, seeds drip in at FEED_RATE; each animates from the feeder
//  external end to its target pool position.
//
//  Feeder geometry (mirrors v5_7_housing.scad):
//    Anchor at world (15, -47.5, -15), tilted 60° elev (rotate([30,0,0])).
//    Connector body extends along (0, -sin30°, +cos30°) = (0, -0.5,
//    +0.866) for length 25 mm.
//    External tip = anchor + 25·dir = (15, -60, +6.65).
// =====================================================================
const FEED_RATE = 4.0;            // seeds per second entering via feeder
const FEEDER_DIR = new THREE.Vector3(
  0,
  -Math.sin(30 * Math.PI / 180),
  Math.cos(30 * Math.PI / 180),
).normalize();
const FEEDER_ANCHOR = new THREE.Vector3(15, -47.5, -15);
const FEEDER_EXT_END = FEEDER_ANCHOR.clone()
  .add(FEEDER_DIR.clone().multiplyScalar(25));

let feedAccumulator = 0;
let refillRemaining = 0;

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

function glideToThroat(seedMesh) {
  // Vacuum-respecting release: instead of free-falling (which clips through
  // the disc-body slab on the way to the geleider mouth), the seed slides
  // along the disc-front face from the rim inward to the central hole, then
  // drops vertically through the central hole into the geleider throat.
  //
  //   Phase 1: rim → above central axis. Seed stays at disc-local-Z = +3
  //            (3 mm above disc face) the whole slide, so it never enters
  //            the disc-body slab |Z|≤2 in the radial annulus [25,60].
  //   Phase 2: above central axis → throat. Vertical drop through the
  //            central 50 mm hole — clear air all the way down.
  //
  // Used for both the natural θ=90° release and the afstrijker-2 push.
  // The geleider catch-mouth is bypassed in vacuum-on mode (the seed is
  // routed straight into the central drop). The mouth still catches free-
  // falling seeds when vacuum is off mid-cycle (see updateFalling).
  seedMesh.material = glidingSeedMat;
  glidingGroup.attach(seedMesh);
  const p0 = seedMesh.position.clone();
  // Phase-1 endpoint: disc-local (R=0, Z=+3) = +3·FRONT_NORMAL in world.
  const pMid = new THREE.Vector3(0, FRONT_NORMAL.y * 3, FRONT_NORMAL.z * 3);
  const pEnd = new THREE.Vector3(0, 0, GELEIDER.throatZ + 1);
  savedCount++;
  glidingSeeds.push({
    mesh: seedMesh, t: 0,
    dur1: 0.45, dur2: 0.30, stage: 1,
    p0, pMid, pEnd,
  });
}

function pushToGliding(seedMesh) { glideToThroat(seedMesh); }

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

function suckPoolSeedToVacTube() {
  if (poolSeeds.length === 0) return;
  // Pop nearest pool seed to the vac-tube mouth so the visualisation
  // looks like the suction wins on proximity.
  let bestIdx = 0;
  let bestD = Infinity;
  for (let i = 0; i < poolSeeds.length; i++) {
    const d = poolSeeds[i].position.distanceToSquared(VAC_CLEAN_MOUTH);
    if (d < bestD) { bestD = d; bestIdx = i; }
  }
  const seed = poolSeeds.splice(bestIdx, 1)[0];
  poolGroup.remove(seed);
  seed.material = cleaningSeedMat;
  cleaningGroup.add(seed);
  cleaningSeeds.push({
    mesh: seed, t: 0, stage: 1,
    p0: seed.position.clone(),
    p1: VAC_CLEAN_MOUTH.clone(),
    p2: VAC_CLEAN_END.clone(),
  });
}

function spawnFeedingSeed() {
  const m = new THREE.Mesh(seedGeom, poolSeedMat);
  m.position.copy(FEEDER_EXT_END);
  feedingGroup.add(m);
  // Target: a pool position that accounts for current pool + seeds
  // already in flight (so we don't all aim at the same spot).
  const occupancy = poolSeeds.length + feedingSeeds.length;
  const target = computePoolSpawnPosition(occupancy);
  feedingSeeds.push({
    mesh: m, t: 0, dur: 0.55,
    p0: FEEDER_EXT_END.clone(),
    p1: target,
  });
}

function updateFeeding(dt) {
  for (let i = feedingSeeds.length - 1; i >= 0; i--) {
    const f = feedingSeeds[i];
    f.t += dt;
    const u = Math.min(f.t / f.dur, 1);
    const eased = u * u * (3 - 2 * u);
    f.mesh.position.lerpVectors(f.p0, f.p1, eased);
    if (u >= 1) {
      feedingGroup.remove(f.mesh);
      poolGroup.add(f.mesh);
      f.mesh.position.copy(f.p1);
      poolSeeds.push(f.mesh);
      feedingSeeds.splice(i, 1);
    }
  }
}

function updateCleaning(dt) {
  for (let i = cleaningSeeds.length - 1; i >= 0; i--) {
    const c = cleaningSeeds[i];
    c.t += dt;
    if (c.stage === 1) {
      const u = Math.min(c.t / 0.40, 1);
      const eased = u * u * (3 - 2 * u);
      c.mesh.position.lerpVectors(c.p0, c.p1, eased);
      if (u >= 1) { c.stage = 2; c.t = 0; }
    } else {
      const u = Math.min(c.t / 0.50, 1);
      c.mesh.position.lerpVectors(c.p1, c.p2, u);
      if (u >= 1) {
        cleaningGroup.remove(c.mesh);
        cleaningSeeds.splice(i, 1);
        cleanedCount++;
      }
    }
  }
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
    if (g.stage !== undefined) {
      // Two-stage vacuum-respecting glide: rim slide, then central drop.
      if (g.stage === 1) {
        const u = Math.min(g.t / g.dur1, 1);
        const eased = u * u * (3 - 2 * u);
        g.mesh.position.lerpVectors(g.p0, g.pMid, eased);
        if (u >= 1) { g.stage = 2; g.t = 0; }
      } else {
        const u = Math.min(g.t / g.dur2, 1);
        g.mesh.position.lerpVectors(g.pMid, g.pEnd, u);
        if (u >= 1) {
          glidingSeeds.splice(i, 1);
          captureToExiting({ mesh: g.mesh });
        }
      }
    } else {
      // Legacy single-stage glide (geleider catch from free-fall).
      const u = Math.min(g.t / g.dur, 1);
      const eased = u * u * (3 - 2 * u);
      g.mesh.position.lerpVectors(g.p0, g.p1, eased);
      if (u >= 1) {
        glidingSeeds.splice(i, 1);
        captureToExiting(g);
      }
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
const blowInput     = document.getElementById('blow');
const blowValue     = document.getElementById('blow-value');
const csInput       = document.getElementById('cross-section');
const markersInput  = document.getElementById('show-markers');
const poolFillInput = document.getElementById('show-pool-fill');
const seedsOnDiscInput = document.getElementById('show-seeds-on-disc');
const afstrijkerInput  = document.getElementById('show-afstrijker');
const afstrijker2Input = document.getElementById('show-afstrijker2');
const geleiderInput    = document.getElementById('show-geleider');
const dropTubeInput    = document.getElementById('show-drop-tube');
const vacGlowInput     = document.getElementById('show-vacuum-glow');
const discInput        = document.getElementById('show-disc');
const malPlateInput    = document.getElementById('show-mal-plate');
const oringInput       = document.getElementById('show-oring');
const gridInput        = document.getElementById('show-grid');
const partitionInput   = document.getElementById('show-partition');
const blowFittingInput = document.getElementById('show-blow-fitting');
const pinionInput      = document.getElementById('show-pinion');
const motorInput       = document.getElementById('show-motor');
const hopperInput      = document.getElementById('show-hopper');
const lidInput         = document.getElementById('show-lid');
const dustRingInput    = document.getElementById('show-dust-ring');
const vacTubeInput     = document.getElementById('show-vac-tube');
const cleanBtn         = document.getElementById('clean-cycle-btn');

const angleEl    = document.getElementById('info-angle');
const poolEl     = document.getElementById('info-pool');
const onDiscEl   = document.getElementById('info-on-disc');
const inGelEl    = document.getElementById('info-in-geleider');
const inTubeEl   = document.getElementById('info-in-tube');
const sownEl     = document.getElementById('info-sown');
const skipEl     = document.getElementById('info-skip');
const missEl     = document.getElementById('info-miss');
const cleanedEl  = document.getElementById('info-cleaned');

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
let blow = parseFloat(blowInput.value);
blowInput.addEventListener('input', () => {
  blow = parseFloat(blowInput.value);
  blowValue.textContent = blow.toFixed(0) + '%';
});
csInput.addEventListener('change', () => {
  const planes = csInput.checked ? [clipPlane] : [];
  for (const m of [discMat, afstrijkerMat, geleiderMat, dropTubeMat,
                   malPlateMat, pinionMat, motorMat,
                   hopperMat, lidMat, dustRingMat, vacTubeMat]) {
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
vacGlowInput.addEventListener('change', () => {
  holeGlowGroup.visible = vacGlowInput.checked;
});
discInput.addEventListener('change', () => {
  if (disc) disc.visible = discInput.checked;
});
malPlateInput.addEventListener('change', () => {
  if (malPlateMesh) malPlateMesh.visible = malPlateInput.checked;
});
oringInput.addEventListener('change', () => {
  oringGroup.visible = oringInput.checked;
});
gridInput.addEventListener('change', () => {
  grid.visible = gridInput.checked;
});
partitionInput.addEventListener('change', () => {
  partitionGroup.visible = partitionInput.checked;
});
blowFittingInput.addEventListener('change', () => {
  blowFittingGroup.visible = blowFittingInput.checked;
});
pinionInput.addEventListener('change', () => {
  if (pinionMesh) pinionMesh.visible = pinionInput.checked;
});
motorInput.addEventListener('change', () => {
  if (motorMesh) motorMesh.visible = motorInput.checked;
});
hopperInput.addEventListener('change', () => {
  if (hopperMesh) hopperMesh.visible = hopperInput.checked;
});
lidInput.addEventListener('change', () => {
  if (lidMesh) lidMesh.visible = lidInput.checked;
});
dustRingInput.addEventListener('change', () => {
  if (dustRingMesh) dustRingMesh.visible = dustRingInput.checked;
});
vacTubeInput.addEventListener('change', () => {
  if (vacTubeMesh) vacTubeMesh.visible = vacTubeInput.checked;
});
cleanBtn.addEventListener('click', () => {
  cleanCycleActive = !cleanCycleActive;
  if (cleanCycleActive) {
    cleanBtn.textContent = 'Stop clean cycle';
    cleanBtn.classList.add('active');
  } else {
    cleanBtn.textContent = 'Start clean cycle';
    cleanBtn.classList.remove('active');
    cleanAccumulator = 0;
  }
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
  // Pinion: 60T disc / 20T pinion = 3:1, opposite rotation direction
  // (external mesh).
  if (pinionMesh) pinionMesh.setRotationFromAxisAngle(
    DISC_AXIS, +rotationAngle * PINION_RATIO,
  );

  // Clean-cycle override: vacuum forced off (drops attached seeds via the
  // existing vacuum<5 path), refill suppressed (let the pool drain), and
  // pool seeds get sucked through the vac-cleanup tube at CLEAN_RATE.
  const effectiveVacuum = cleanCycleActive ? 0 : vacuum;
  if (cleanCycleActive) {
    cleanAccumulator += dt * CLEAN_RATE;
    while (cleanAccumulator >= 1 && poolSeeds.length > 0) {
      cleanAccumulator -= 1;
      suckPoolSeedToVacTube();
    }
  } else {
    refillPoolIfLow();
    pumpFeeder(dt);
  }

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
      if (effectiveVacuum < 5) {
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

      // Release at θ=90°. Vacuum is on (vacuum<5 path handled above), so
      // route the seed via the vacuum-respecting glide rather than free-
      // falling through the disc-body slab. See glideToThroat() comments.
      if (holeIsAt(n, rotationAngle, RELEASE_THETA, tol)) {
        glideToThroat(state.seed);
        holeState[n] = null;
        continue;
      }
    } else {
      // Pickup at θ=270° if vacuum on, hole empty, pool not empty.
      if (holeIsAt(n, rotationAngle, PICKUP_THETA, tol)) {
        if (effectiveVacuum > 5 && poolSeeds.length > 0) {
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
        } else if (effectiveVacuum > 5) {
          // Vacuum on but pool empty — count a skip per pass per hole.
          skippedCount++;
        }
      }
    }
  }

  // Per-hole vacuum glow — visible when hole is in the chamber sector
  // (world x ≤ 0) AND vacuum is on. Position rides the rotating hole.
  const glowVisible = effectiveVacuum > 5;
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
  updateCleaning(dt);
  updateFeeding(dt);

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
  cleanedEl.textContent = cleanedCount;

  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
animate();
