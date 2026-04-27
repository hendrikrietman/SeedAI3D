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
camera.position.set(180, -220, 160);
camera.lookAt(0, 0, 0);

const renderer = new THREE.WebGLRenderer({ antialias: true });
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setSize(host.clientWidth, host.clientHeight);
renderer.localClippingEnabled = true;
host.appendChild(renderer.domElement);

const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true;
controls.dampingFactor = 0.08;
controls.target.set(0, 0, 0);

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

// ----- disc rotation axis -----
// Disc tilted 45° around world X. After tilt, disc-normal = (0, -sin45°, cos45°).
const TILT = Math.PI / 4;
const DISC_AXIS = new THREE.Vector3(0, -Math.sin(TILT), Math.cos(TILT)).normalize();

// ----- clipping plane for cross-section (cuts away +Y) -----
const clipPlane = new THREE.Plane(new THREE.Vector3(0, -1, 0), 0);

// ----- materials -----
const discMat = new THREE.MeshPhongMaterial({
  color: 0x6699d4,
  specular: 0x111111,
  shininess: 28,
  side: THREE.DoubleSide,
  clippingPlanes: [],
});

// ----- markers (pickup + release) -----
const markerGroup = new THREE.Group();
{
  const r = 2.0;
  const pickup = new THREE.Mesh(
    new THREE.SphereGeometry(r, 24, 16),
    new THREE.MeshBasicMaterial({ color: 0xd9342b }),
  );
  pickup.position.set(0, 29.698, 29.698);
  markerGroup.add(pickup);

  const release = new THREE.Mesh(
    new THREE.SphereGeometry(r, 24, 16),
    new THREE.MeshBasicMaterial({ color: 0xe89a2e }),
  );
  release.position.set(0, -29.698, -29.698);
  markerGroup.add(release);
}
scene.add(markerGroup);

// ----- load disc STL -----
let disc = null;
let rotationAngle = 0;

const loader = new STLLoader();
loader.load(
  './models/disc.stl',
  (geometry) => {
    geometry.computeVertexNormals();
    disc = new THREE.Mesh(geometry, discMat);
    scene.add(disc);
  },
  undefined,
  (err) => {
    console.error('STL load failed:', err);
    const msg = document.createElement('div');
    msg.textContent = 'Failed to load disc.stl';
    msg.style.cssText = 'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);background:#fff;padding:20px;border-radius:8px;color:#c0392b;';
    document.body.appendChild(msg);
  },
);

// ----- UI hookup -----
const rpmInput     = document.getElementById('rpm');
const rpmValue     = document.getElementById('rpm-value');
const csInput      = document.getElementById('cross-section');
const markersInput = document.getElementById('show-markers');
const angleEl      = document.getElementById('info-angle');

let rpm = parseFloat(rpmInput.value);
rpmInput.addEventListener('input', () => {
  rpm = parseFloat(rpmInput.value);
  rpmValue.textContent = rpm.toFixed(1) + ' rpm';
});

csInput.addEventListener('change', () => {
  discMat.clippingPlanes = csInput.checked ? [clipPlane] : [];
  discMat.needsUpdate = true;
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
function animate() {
  const dt = clock.getDelta();
  rotationAngle += (rpm / 60) * 2 * Math.PI * dt;
  rotationAngle %= 2 * Math.PI;

  if (disc) disc.setRotationFromAxisAngle(DISC_AXIS, rotationAngle);

  angleEl.textContent = (rotationAngle * 180 / Math.PI).toFixed(1) + '°';

  controls.update();
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
animate();
