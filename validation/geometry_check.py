#!/usr/bin/env python3
"""PROTISEM V4 — geometry verification.

For each phase, loads the relevant STL(s), runs sanity checks (watertight,
expected bounding box, hole counts where derivable), and writes a
cross-section PNG into renders/.
"""
from __future__ import annotations

import math
import sys
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import trimesh

ROOT = Path(__file__).resolve().parent.parent

# Mirror values from scad/lib/parameters.scad
PARAMS = {
    "DISC_OD": 120.0,
    "DISC_OD_WITH_TEETH": 132.0,
    "DISC_THICKNESS": 4.0,
    "CENTRAL_HOLE_DIA": 50.0,
    "PICKUP_HOLE_COUNT": 40,
    "PICKUP_HOLE_RADIUS": 42.0,
    "PICKUP_HOLE_DIA": 2.5,
    "TOOTH_COUNT": 60,
    "DISC_TILT_DEG": 45.0,
    "SEED_POOL_X": 60.0,
    "SEED_POOL_Y": 40.0,
    "SEED_POOL_DEPTH": 20.0,
    "SEED_POOL_Z_TOP": -25.0,
    "SEED_POOL_Z_FLOOR": -45.0,
    "SEED_POOL_Y_CENTER": -30.0,
    "SEED_POOL_WALL": 2.0,
    "PICKUP_THETA_DEG": 270.0,
    "RELEASE_THETA_DEG": 90.0,
    "MIN_FLOOR_CLEARANCE_MM": 0.5,
}


@dataclass
class CheckResult:
    name: str
    passed: bool
    detail: str = ""

    def __str__(self) -> str:
        mark = "PASS" if self.passed else "FAIL"
        return f"[{mark}] {self.name}: {self.detail}"


def expected_disc_bbox() -> tuple[float, float, float]:
    """Bounding box of the tilted disc in world coordinates."""
    od = PARAMS["DISC_OD_WITH_TEETH"]
    th = PARAMS["DISC_THICKNESS"]
    tilt = math.radians(PARAMS["DISC_TILT_DEG"])
    # Disc lies in a plane tilted around X by 45°.
    # X extent unaffected by the tilt: simply OD.
    x = od
    # Y/Z extents: max projection of an OD-cylinder of thickness th,
    # tilted 45° around X.
    y = od * math.cos(tilt) + th * math.sin(tilt)
    z = od * math.sin(tilt) + th * math.cos(tilt)
    return x, y, z


def check_disc(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []

    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists",
        True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))

    # Watertight
    results.append(CheckResult(
        "watertight",
        bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # Bounding box
    extents = mesh.extents
    expected = expected_disc_bbox()
    diffs = [abs(extents[i] - expected[i]) for i in range(3)]
    bbox_ok = all(d < 1.0 for d in diffs)  # 1 mm tolerance
    results.append(CheckResult(
        "bounding_box",
        bbox_ok,
        f"got={extents.round(2).tolist()}, expected≈{[round(v, 2) for v in expected]}",
    ))

    # Centroid near origin
    centroid_dist = float(np.linalg.norm(mesh.centroid))
    results.append(CheckResult(
        "centred_at_origin",
        centroid_dist < 1.0,
        f"|centroid|={centroid_dist:.3f} mm",
    ))

    # Volume: rough sanity check (disc body cylinder minus central hole)
    od_body = PARAMS["DISC_OD"]
    th = PARAMS["DISC_THICKNESS"]
    central = PARAMS["CENTRAL_HOLE_DIA"]
    body_vol = math.pi * (od_body / 2) ** 2 * th
    hole_vol = math.pi * (central / 2) ** 2 * th
    pickup_vol = (
        PARAMS["PICKUP_HOLE_COUNT"]
        * math.pi
        * (PARAMS["PICKUP_HOLE_DIA"] / 2) ** 2
        * th
    )
    expected_vol_low = body_vol - hole_vol - pickup_vol  # without teeth
    # Teeth add roughly: 60 * (avg width × radial × thickness)
    pitch_mm = math.pi * od_body / PARAMS["TOOTH_COUNT"]
    tooth_avg_width = pitch_mm * (0.55 + 0.30) / 2 / 2  # rough trapezoid avg
    teeth_vol = (
        PARAMS["TOOTH_COUNT"]
        * tooth_avg_width
        * (PARAMS["DISC_OD_WITH_TEETH"] - od_body) / 2
        * th
    )
    expected_vol_high = expected_vol_low + teeth_vol * 1.5  # generous upper bound
    actual = mesh.volume
    vol_ok = expected_vol_low * 0.85 < actual < expected_vol_high * 1.2
    results.append(CheckResult(
        "volume_in_range",
        vol_ok,
        f"actual={actual:.0f} mm³, expected∈[{expected_vol_low:.0f},{expected_vol_high:.0f}]",
    ))

    return results


def render_cross_section_png(mesh: trimesh.Trimesh, out_path: Path) -> None:
    """Cheap matplotlib cross-section through the YZ plane (X=0)."""
    import matplotlib

    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    section = mesh.section(plane_origin=[0, 0, 0], plane_normal=[1, 0, 0])
    fig, ax = plt.subplots(figsize=(8, 8))
    if section is not None:
        planar, _ = section.to_planar()
        for entity in planar.entities:
            pts = planar.vertices[entity.points]
            ax.plot(pts[:, 0], pts[:, 1], "b-", linewidth=1.0)
    ax.set_aspect("equal")
    ax.set_xlabel("Y (mm)")
    ax.set_ylabel("Z (mm)")
    ax.set_title("Disc cross-section at X = 0 (YZ plane)")
    ax.grid(True, alpha=0.3)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_path, dpi=120, bbox_inches="tight")
    plt.close(fig)


def check_seed_pool(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []

    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists",
        True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))

    results.append(CheckResult(
        "watertight",
        bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # Bounding box: 60 × 40 × 20 (X × Y × Z). Slot subtraction may shave
    # off small chunks of the side walls but the outer extents stay.
    extents = mesh.extents
    expected_extents = (PARAMS["SEED_POOL_X"], PARAMS["SEED_POOL_Y"], PARAMS["SEED_POOL_DEPTH"])
    diffs = [abs(extents[i] - expected_extents[i]) for i in range(3)]
    bbox_ok = all(d < 1.0 for d in diffs)
    results.append(CheckResult(
        "bounding_box",
        bbox_ok,
        f"got={extents.round(2).tolist()}, expected≈{list(expected_extents)}",
    ))

    # Floor at SEED_POOL_Z_FLOOR, top at SEED_POOL_Z_TOP.
    z_min, z_max = float(mesh.bounds[0, 2]), float(mesh.bounds[1, 2])
    results.append(CheckResult(
        "z_bounds",
        abs(z_min - PARAMS["SEED_POOL_Z_FLOOR"]) < 0.5
        and abs(z_max - PARAMS["SEED_POOL_Z_TOP"]) < 0.5,
        f"z=[{z_min:.2f}, {z_max:.2f}], expected=[{PARAMS['SEED_POOL_Z_FLOOR']}, {PARAMS['SEED_POOL_Z_TOP']}]",
    ))

    # Centred along disc-bottom Y line.
    y_center_actual = float((mesh.bounds[0, 1] + mesh.bounds[1, 1]) / 2)
    results.append(CheckResult(
        "y_centred_on_disc_bottom",
        abs(y_center_actual - PARAMS["SEED_POOL_Y_CENTER"]) < 0.5,
        f"y_center={y_center_actual:.2f}, expected={PARAMS['SEED_POOL_Y_CENTER']}",
    ))

    return results


def check_disc_floor_clearance(disc_stl: Path, pool_stl: Path,
                               min_mm: float = 0.5,
                               n_samples: int = 4000) -> list[CheckResult]:
    """Disc must not break through the pool FLOOR. (Side walls are slotted
    by design — disc dips in there — so we ignore those.)"""
    if not (disc_stl.exists() and pool_stl.exists()):
        return [CheckResult("clearance_files", False,
                            f"missing inputs: {disc_stl}, {pool_stl}")]

    disc = trimesh.load(disc_stl, force="mesh")
    pool = trimesh.load(pool_stl, force="mesh")

    # Sample disc surface, keep only points BELOW the floor's Z.
    pts, _ = trimesh.sample.sample_surface(disc, n_samples)
    z_floor = PARAMS["SEED_POOL_Z_FLOOR"]
    below_floor = pts[pts[:, 2] < z_floor + 1.0]   # 1 mm above floor & lower
    if len(below_floor) == 0:
        return [CheckResult(
            "disc_above_floor",
            True,
            f"no disc surface samples within 1 mm of pool floor (z={z_floor})",
        )]

    # Lowest disc point in world frame
    z_min_disc = float(below_floor[:, 2].min())
    clearance = z_min_disc - z_floor

    return [CheckResult(
        "disc_above_floor",
        clearance >= min_mm,
        f"disc lowest z={z_min_disc:.2f}, floor z={z_floor}, gap={clearance:.2f} mm",
    )]


def main() -> int:
    print("=== Phase 1: disc ===")
    disc_stl_v1 = ROOT / "stl" / "v4_1" / "disc.stl"
    disc_results = check_disc(disc_stl_v1)
    for r in disc_results:
        print(r)
    if disc_stl_v1.exists():
        try:
            mesh = trimesh.load(disc_stl_v1, force="mesh")
            render_cross_section_png(
                mesh, ROOT / "renders" / "v4_1" / "disc_cross_section.png"
            )
            print("→ renders/v4_1/disc_cross_section.png")
        except Exception as exc:
            print(f"[WARN] disc cross-section render failed: {exc}")

    print()
    print("=== Phase 2 V5: seed pool ===")
    pool_stl = ROOT / "stl" / "v5_2" / "seed_pool.stl"
    disc_stl_v2 = ROOT / "stl" / "v5_2" / "disc.stl"
    pool_results = check_seed_pool(pool_stl)
    for r in pool_results:
        print(r)

    print()
    print("=== Phase 2 V5: disc-pool floor clearance ===")
    clearance_results = check_disc_floor_clearance(
        disc_stl_v2, pool_stl, min_mm=PARAMS["MIN_FLOOR_CLEARANCE_MM"]
    )
    for r in clearance_results:
        print(r)

    if disc_stl_v2.exists() and pool_stl.exists():
        try:
            disc = trimesh.load(disc_stl_v2, force="mesh")
            pool = trimesh.load(pool_stl, force="mesh")
            combined = trimesh.util.concatenate([disc, pool])
            render_cross_section_png(
                combined, ROOT / "renders" / "v5_2" / "assembly_cross_section.png"
            )
            print("→ renders/v5_2/assembly_cross_section.png")
        except Exception as exc:
            print(f"[WARN] assembly cross-section render failed: {exc}")

    all_results = disc_results + pool_results + clearance_results
    failed = [r for r in all_results if not r.passed]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
