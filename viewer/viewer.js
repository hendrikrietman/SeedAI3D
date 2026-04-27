import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { STLLoader }     from 'three/addons/loaders/STLLoader.js';

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
camera.position.set(220, -240, 200);
camera.lookAt(0, 15, 30);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(host.clientWidth, host.clientHeight);
renderer.localClippingEnabled = true;
host.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.target.set(0, 15, 30);

// ----- lighting -----
scene.add(new THREE.AmbientLight(0xffffff, 0.55));
const key = new THREE.DirectionalLight(0xffffff, 0.95);
key.position.set(120, -180, 220);
scene.add(key);
const fill = new THREE.DirectionalLight(0xffffff, 0.35);
fill.position.set(-180, 120, -100);
scene.add(fill);

// ----- ground/grid for reference -----
const grid = new THREE.GridHelper(400, 20, 0xbbbbbb, 0xdddddd);
grid.rotation.x = Math.PI / 2;     // grid in XY plane (Z up)
grid.position.z = -50;
scene.add(grid);

// ----- geometric constants (mirror parameters.scad) -----
const TILT = Math.PI / 4;
const DISC_AXIS = new THREE.Vector3(0, -Math.sin(TILT), Math.cos(TILT)).normalize();
// Pickup θ=110°, release θ=70° → both at world-Z 27.907 (high, near top of disc).
// Seed travels CCW the long way (~320°) from pickup → bottom → release.
const PICKUP_POS  = new THREE.Vector3(-14.365, 27.907, 27.907);  // θ=110°
const RELEASE_POS = new THREE.Vector3( 14.365, 27.907, 27.907);  // θ=70°
const OUTLET_POS  = new THREE.Vector3(-14.365, 27.907, 35.000);  // 7.1 mm above pickup
const DISC_TOP_PLANE_OFFSET = 2.828;  // z = y + 2.828 on disc top surface
const DISC_OD_HALF = 60;              // disc body radius (no teeth)

// ----- clipping plane: cuts +X half so reservoir is preserved -----
const clipPlane = new THREE.Plane(new THREE.Vector3(-1, 0, 0), 0);

const discMat = new THREE.MeshPhongMaterial({
  color: 0x6699d4,
  specular: 0x111111,
  shininess: 28,
  side: THREE.DoubleSide,
  clippingPlanes: [],
});

const reservoirMat = new THREE.MeshPhongMaterial({
  color: 0xb6c0c8,
  specular: 0x222222,
  shininess: 18,
  side: THREE.DoubleSide,
  transparent: true,
  opacity: 0.45,
  clippingPlanes: [],
});

// ----- markers -----
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
  markerGroup.add(mk(PICKUP_POS,  0xd9342b));   // pickup  (red)   θ=110°
  markerGroup.add(mk(RELEASE_POS, 0xe89a2e));   // release (orange) θ=70°
  markerGroup.add(mk(OUTLET_POS,  0xf5d33b));   // outlet  (yellow)
}
scene.add(markerGroup);

// ----- load STLs -----
let disc = null;
let rotationAngle = 0;

const loader = new STLLoader();

loader.load('./models/disc.stl', (geometry) => {
  geometry.computeVertexNormals();
  disc = new THREE.Mesh(geometry, discMat);
  scene.add(disc);
}, undefined, (err) => console.error('disc load failed:', err));

loader.load('./models/reservoir.stl', (geometry) => {
  geometry.computeVertexNormals();
  const m = new THREE.Mesh(geometry, reservoirMat);
  scene.add(m);
}, undefined, (err) => console.error('reservoir load failed:', err));

// ----- seeds (yellow spheres dropping from outlet) -----
const SEED_RADIUS = 3;        // mm; soybean ~6 mm Ø
const GRAVITY    = 9810;      // mm/s² (real, will look fast — viewer scales below)
const TIME_SCALE = 0.18;      // visualisation slow-down
const seedGeom = new THREE.SphereGeometry(SEED_RADIUS, 16, 12);
const seedMat  = new THREE.MeshPhongMaterial({
  color: 0xe6c84d, specular: 0x333333, shininess: 40,
});
const seeds = [];
const seedsGroup = new THREE.Group();
scene.add(seedsGroup);

function spawnSeed() {
  const m = new THREE.Mesh(seedGeom, seedMat);
  // small random offset within the inner Ø12 outlet
  const r = Math.random() * (6 - SEED_RADIUS - 0.5);
  const a = Math.random() * Math.PI * 2;
  m.position.set(
    OUTLET_POS.x + r * Math.cos(a),
    OUTLET_POS.y + r * Math.sin(a),
    OUTLET_POS.z - SEED_RADIUS,
  );
  m.userData.vz = 0;
  m.userData.t  = 0;
  seedsGroup.add(m);
  seeds.push(m);
}

function updateSeeds(dt) {
  const sdt = dt * TIME_SCALE;
  for (let i = seeds.length - 1; i >= 0; i--) {
    const s = seeds[i];
    s.userData.vz -= GRAVITY * sdt;
    s.position.z  += s.userData.vz * sdt;
    s.userData.t  += dt;

    // Land on the disc top plane: z = y + 2.828, but only over disc body.
    // Disc-frame radius = |inverse-rotate(point) projected onto disc plane|.
    const yPre = s.position.y * Math.cos(TILT) + s.position.z * Math.sin(TILT);
    const discR = Math.hypot(s.position.x, yPre);
    // Skip the central drop-hole (R≤25) — seeds there fall straight through.
    const onDisc = discR <= DISC_OD_HALF && discR >= 25 + SEED_RADIUS;
    const landZ = s.position.y + DISC_TOP_PLANE_OFFSET + SEED_RADIUS;
    if (onDisc && s.position.z <= landZ) {
      s.position.z = landZ;
      s.userData.vz = 0;
      // Remove seed shortly after landing — vacuum in later phase will pick it up.
      if (s.userData.t > 1.5) {
        seedsGroup.remove(s);
        seeds.splice(i, 1);
      }
    } else if (s.position.z < -80) {
      // Failsafe: missed the disc, fell off the bottom
      seedsGroup.remove(s);
      seeds.splice(i, 1);
    }
  }
}

// ----- UI -----
const rpmInput      = document.getElementById('rpm');
const rpmValue      = document.getElementById('rpm-value');
const seedRateInput = document.getElementById('seed-rate');
const seedRateValue = document.getElementById('seed-rate-value');
const csInput       = document.getElementById('cross-section');
const markersInput  = document.getElementById('show-markers');
const angleEl       = document.getElementById('info-angle');
const seedsEl       = document.getElementById('info-seeds');

let rpm = parseFloat(rpmInput.value);
let seedRate = parseFloat(seedRateInput.value);

rpmInput.addEventListener('input', () => {
  rpm = parseFloat(rpmInput.value);
  rpmValue.textContent = rpm.toFixed(1) + ' rpm';
});

seedRateInput.addEventListener('input', () => {
  seedRate = parseFloat(seedRateInput.value);
  seedRateValue.textContent = seedRate.toFixed(1) + '/s';
});

csInput.addEventListener('change', () => {
  const planes = csInput.checked ? [clipPlane] : [];
  discMat.clippingPlanes = planes;
  reservoirMat.clippingPlanes = planes;
  discMat.needsUpdate = true;
  reservoirMat.needsUpdate = true;
});

markersInput.addEventListener('change', () => {
  markerGroup.visible = markersInput.checked;
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

// ----- animation -----
const clock = new THREE.Clock();
let spawnAccumulator = 0;

function animate() {
  const dt = Math.min(clock.getDelta(), 0.05);

  // Disc rotation
  rotationAngle += (rpm / 60) * 2 * Math.PI * dt;
  rotationAngle %= 2 * Math.PI;
  if (disc) disc.setRotationFromAxisAngle(DISC_AXIS, rotationAngle);

  // Seed spawning at configured rate
  if (seedRate > 0) {
    spawnAccumulator += seedRate * dt;
    while (spawnAccumulator >= 1) {
      spawnSeed();
      spawnAccumulator -= 1;
    }
  } else {
    spawnAccumulator = 0;
  }
  updateSeeds(dt);

  // HUD
  angleEl.textContent = (rotationAngle * 180 / Math.PI).toFixed(1) + '°';
  seedsEl.textContent = seeds.length;

  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
animate();
