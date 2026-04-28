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
    "PICKUP_HOLE_DIA": 4.0,
    "TOOTH_COUNT": 60,
    "DISC_TILT_DEG": 45.0,
    "SEED_POOL_X": 60.0,
    "SEED_POOL_Y": 40.0,
    "SEED_POOL_R_OUTER": 55.0,
    "SEED_POOL_DEPTH": 33.0,
    "SEED_POOL_Z_TOP": -17.0,
    "SEED_POOL_Z_FLOOR": -50.0,
    "SEED_POOL_Y_CENTER": -30.0,
    "SEED_POOL_WALL": 2.0,
    "PICKUP_THETA_DEG": 270.0,
    "RELEASE_THETA_DEG": 90.0,
    "MIN_FLOOR_CLEARANCE_MM": 0.5,
    "AFSTRIJKER_THETA_DEG": 250.0,
    "AFSTRIJKER_LENGTH": 18.0,
    "AFSTRIJKER_HEIGHT": 8.0,
    "AFSTRIJKER_THICKNESS": 2.0,
    "AFSTRIJKER2_THETA_DEG": 95.0,
    "AFSTRIJKER2_LENGTH": 12.0,
    "AFSTRIJKER2_HEIGHT": 6.0,
    "AFSTRIJKER2_THICKNESS": 2.0,
    "GELEIDER_MOUTH_X": 40.0,
    "GELEIDER_MOUTH_Y": 20.0,
    "GELEIDER_MOUTH_Z": 20.0,
    "GELEIDER_MOUTH_Y_CENTER": 30.0,
    "GELEIDER_THROAT_DIA": 30.0,
    "GELEIDER_THROAT_Z": -6.0,
    "GELEIDER_WALL": 2.0,
    "GELEIDER_DISC_CLEARANCE": 3.0,
    "DROP_TUBE_OD": 30.0,
    "DROP_TUBE_ID": 24.0,
    "DROP_TUBE_Z_TOP": -6.0,
    "DROP_TUBE_Z_BOTTOM": -52.0,
    "VAC_CHAMBER_R_IN": 30.0,
    "VAC_CHAMBER_R_OUT": 50.0,
    "VAC_CHAMBER_DEPTH": 8.0,
    "VAC_CHAMBER_WALL": 2.0,
    "VAC_NIPPLE_DIA": 12.0,
    "VAC_NIPPLE_LENGTH": 30.0,
    "VAC_SECTOR_START_DEG": 90.0,
    "VAC_SECTOR_END_DEG": 270.0,
    "RECOVERY_BOWL_R_OUTER": 55.0,
    "RECOVERY_BOWL_WALL": 2.0,
    "RECOVERY_BOWL_Z_FLOOR": 22.0,
    "RECOVERY_BOWL_Z_TOP": 50.0,
    "RECOVERY_BOWL_DISC_CLEARANCE": 3.0,
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

    # v5.5.2: pool body is a HALF-DISC of radius R_OUTER (=55), centred at
    # origin in XY, opening at y=0 (footprint y ≤ 0). x extent = 2·R_OUTER.
    # Tubes extend in -Y/+Z (feeder 60°, vac 80°), so y_min and z_max are
    # set by the tubes — validate body span, not total tube reach.
    extents = mesh.extents
    results.append(CheckResult(
        "x_extent_with_tubes",
        abs(extents[0] - 2 * PARAMS["SEED_POOL_R_OUTER"]) < 1.0,
        f"x_extent={extents[0]:.2f}, expected≈{2 * PARAMS['SEED_POOL_R_OUTER']} ±1.0",
    ))

    z_min, z_max = float(mesh.bounds[0, 2]), float(mesh.bounds[1, 2])
    results.append(CheckResult(
        "z_floor",
        abs(z_min - PARAMS["SEED_POOL_Z_FLOOR"]) < 0.5,
        f"z_min={z_min:.2f}, expected={PARAMS['SEED_POOL_Z_FLOOR']}",
    ))
    results.append(CheckResult(
        "z_top_or_higher",
        z_max >= PARAMS["SEED_POOL_Z_TOP"] - 0.5,
        f"z_max={z_max:.2f}, expected ≥ {PARAMS['SEED_POOL_Z_TOP']} (tubes extend higher)",
    ))

    # Half-disc opens at y=0 (back edge); curved front edge sits at
    # y = -R_OUTER (=−55) at x=0; tubes extend further negative.
    y_min, y_max = float(mesh.bounds[0, 1]), float(mesh.bounds[1, 1])
    results.append(CheckResult(
        "y_back_edge",
        abs(y_max - 0.0) < 0.5,
        f"y_max={y_max:.2f}, expected≈0 (half-disc opens at y=0)",
    ))
    results.append(CheckResult(
        "y_front_or_further",
        y_min <= -PARAMS["SEED_POOL_R_OUTER"] + 0.5,
        f"y_min={y_min:.2f}, expected ≤ -{PARAMS['SEED_POOL_R_OUTER']} (curved front + tubes)",
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


def check_afstrijker(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # FLIP (2026-04-27): rim offset along (0, -sin45°, +cos45°) — the
    # operator-visible (eq>0) side of the disc, where seeds now attach.
    R = PARAMS["PICKUP_HOLE_RADIUS"]
    th = math.radians(PARAMS["AFSTRIJKER_THETA_DEG"])
    tilt = math.radians(PARAMS["DISC_TILT_DEG"])
    rim = (R * math.cos(th), R * math.sin(th) * math.cos(tilt),
           R * math.sin(th) * math.sin(tilt))
    h = PARAMS["DISC_THICKNESS"] / 2 + PARAMS["AFSTRIJKER_HEIGHT"] / 2 + 1
    front = (0, -math.sin(tilt), math.cos(tilt))
    expected_c = (rim[0] + h * front[0],
                  rim[1] + h * front[1],
                  rim[2] + h * front[2])
    actual_c = mesh.centroid
    err = math.sqrt(sum((actual_c[i] - expected_c[i]) ** 2 for i in range(3)))
    results.append(CheckResult(
        "centroid_at_θ=250_on_seed_side",
        err < 1.0,
        f"got=({actual_c[0]:.2f},{actual_c[1]:.2f},{actual_c[2]:.2f}), "
        f"expected≈({expected_c[0]:.2f},{expected_c[1]:.2f},{expected_c[2]:.2f}), err={err:.2f}",
    ))
    return results


def check_afstrijker2(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    R = PARAMS["PICKUP_HOLE_RADIUS"]
    th = math.radians(PARAMS["AFSTRIJKER2_THETA_DEG"])
    tilt = math.radians(PARAMS["DISC_TILT_DEG"])
    rim = (R * math.cos(th), R * math.sin(th) * math.cos(tilt),
           R * math.sin(th) * math.sin(tilt))
    h = PARAMS["DISC_THICKNESS"] / 2 + PARAMS["AFSTRIJKER2_HEIGHT"] / 2 + 1
    front = (0, -math.sin(tilt), math.cos(tilt))
    expected_c = (rim[0] + h * front[0],
                  rim[1] + h * front[1],
                  rim[2] + h * front[2])
    actual_c = mesh.centroid
    err = math.sqrt(sum((actual_c[i] - expected_c[i]) ** 2 for i in range(3)))
    results.append(CheckResult(
        "centroid_at_θ=95_on_seed_side",
        err < 1.0,
        f"got=({actual_c[0]:.2f},{actual_c[1]:.2f},{actual_c[2]:.2f}), "
        f"expected≈({expected_c[0]:.2f},{expected_c[1]:.2f},{expected_c[2]:.2f}), err={err:.2f}",
    ))
    return results


def check_geleider(stl_path: Path, disc_stl: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # Z bounds: throat at GELEIDER_THROAT_Z (≈6) up to mouth top (≈MOUTH_Z+2).
    z_min, z_max = float(mesh.bounds[0, 2]), float(mesh.bounds[1, 2])
    expected_z_min = PARAMS["GELEIDER_THROAT_Z"]
    expected_z_max = PARAMS["GELEIDER_MOUTH_Z"] + 2
    results.append(CheckResult(
        "z_bounds",
        abs(z_min - expected_z_min) < 1.0 and abs(z_max - expected_z_max) < 1.5,
        f"z=[{z_min:.2f},{z_max:.2f}], expected≈[{expected_z_min},{expected_z_max}]",
    ))

    # X-extent: catch-mouth wide-side ≈ MOUTH_X + 2*WALL = 44; throat smaller.
    x_extent = mesh.extents[0]
    expected_x = PARAMS["GELEIDER_MOUTH_X"] + 2 * PARAMS["GELEIDER_WALL"]
    results.append(CheckResult(
        "mouth_x_extent",
        abs(x_extent - expected_x) < 1.0,
        f"x_extent={x_extent:.2f}, expected≈{expected_x}",
    ))

    # Catch-mouth must NOT clash with disc rotation envelope. Sample points
    # on geleider, find any closer than GELEIDER_DISC_CLEARANCE to the disc.
    if disc_stl.exists():
        disc = trimesh.load(disc_stl, force="mesh")
        pts, _ = trimesh.sample.sample_surface(mesh, 3000)
        _, dists, _ = trimesh.proximity.closest_point(disc, pts)
        min_d = float(dists.min())
        # Tolerance: SCAD subtraction nominally leaves exactly CLEARANCE mm
        # but trimesh sampling/proximity rounds at ~0.01 mm.
        results.append(CheckResult(
            "disc_clearance",
            min_d >= PARAMS["GELEIDER_DISC_CLEARANCE"] - 0.05,
            f"min={min_d:.3f} mm, required≥{PARAMS['GELEIDER_DISC_CLEARANCE']}",
        ))
    return results


def check_drop_tube(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    z_min, z_max = float(mesh.bounds[0, 2]), float(mesh.bounds[1, 2])
    results.append(CheckResult(
        "z_bounds",
        abs(z_min - PARAMS["DROP_TUBE_Z_BOTTOM"]) < 1.0
        and abs(z_max - PARAMS["DROP_TUBE_Z_TOP"]) < 1.0,
        f"z=[{z_min:.2f},{z_max:.2f}], "
        f"expected=[{PARAMS['DROP_TUBE_Z_BOTTOM']},{PARAMS['DROP_TUBE_Z_TOP']}]",
    ))

    # Tube fits through disc central hole (Ø50) with comfortable slop.
    od_ok = PARAMS["DROP_TUBE_OD"] < PARAMS["CENTRAL_HOLE_DIA"] - 5
    results.append(CheckResult(
        "tube_fits_central_hole",
        od_ok,
        f"OD={PARAMS['DROP_TUBE_OD']} vs central hole Ø{PARAMS['CENTRAL_HOLE_DIA']} "
        f"(needs ≥5 mm radial slop)",
    ))
    return results


def check_vacuum_chamber(stl_path: Path) -> list[CheckResult]:
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # Sector occupies x_world ≤ 0 (after disc tilt is applied; tilt is around
    # X so x is unaffected). The chamber's body sits in x ∈ [-R_out, 0].
    x_min, x_max = float(mesh.bounds[0, 0]), float(mesh.bounds[1, 0])
    results.append(CheckResult(
        "sector_x_range",
        abs(x_min + PARAMS["VAC_CHAMBER_R_OUT"]) < 1.0 and x_max < 1.0,
        f"x=[{x_min:.2f},{x_max:.2f}], expected≈"
        f"[-{PARAMS['VAC_CHAMBER_R_OUT']}, 0]",
    ))

    # Centroid sits on the operator-far side of the disc (post-FLIP):
    # y_world ≥ 0, z_world ≤ 0. The chamber's bulk is in +Y, -Z direction —
    # hidden behind the disc from the default viewer camera at -Y, +Z.
    # disc_plane_eq(centroid) < 0 (opposite side from the seeds, which sit
    # on the eq>0 side). With the chamber asymmetric in -X, centroid x is
    # well into negative.
    cx, cy, cz = mesh.centroid
    import math
    eq = -math.sin(math.radians(45)) * cy + math.cos(math.radians(45)) * cz
    results.append(CheckResult(
        "centroid_on_chamber_side",
        cx < -10.0 and cy > 0.0 and cz < 0.0 and eq < 0.0,
        f"centroid=({cx:.2f},{cy:.2f},{cz:.2f}), disc_plane_eq={eq:.2f}; "
        f"expected x<<0, y>0, z<0, eq<0 (chamber-side, opposite seeds)",
    ))
    return results


def check_recovery_bowl(stl_path: Path, disc_stl: Path) -> list[CheckResult]:
    """Phase-5 top-half recovery bowl: half-disc shell, footprint y ≥ 0,
    R_OUTER=55, z ∈ [22, 50]. Bowl floor must align with the geleider mouth
    drain. Disc-envelope subtraction must leave the bowl watertight."""
    results: list[CheckResult] = []
    if not stl_path.exists():
        return [CheckResult("file_exists", False, f"missing: {stl_path}")]

    mesh = trimesh.load(stl_path, force="mesh")
    results.append(CheckResult(
        "file_exists", True,
        f"{stl_path.name} ({len(mesh.vertices)} vertices, {len(mesh.faces)} faces)",
    ))
    results.append(CheckResult(
        "watertight", bool(mesh.is_watertight),
        f"is_watertight={mesh.is_watertight}",
    ))

    # X extent = 2 · R_OUTER = 110.
    extents = mesh.extents
    results.append(CheckResult(
        "x_extent",
        abs(extents[0] - 2 * PARAMS["RECOVERY_BOWL_R_OUTER"]) < 1.0,
        f"x_extent={extents[0]:.2f}, expected≈{2 * PARAMS['RECOVERY_BOWL_R_OUTER']}",
    ))

    # Y extent: half-disc opens at y=0, curves to y=R_OUTER. So y_min≈0,
    # y_max≈R_OUTER.
    y_min, y_max = float(mesh.bounds[0, 1]), float(mesh.bounds[1, 1])
    results.append(CheckResult(
        "y_opens_at_zero",
        abs(y_min) < 0.5,
        f"y_min={y_min:.2f}, expected≈0 (half-disc opens at y=0)",
    ))
    results.append(CheckResult(
        "y_max_at_R",
        abs(y_max - PARAMS["RECOVERY_BOWL_R_OUTER"]) < 0.5,
        f"y_max={y_max:.2f}, expected≈{PARAMS['RECOVERY_BOWL_R_OUTER']}",
    ))

    # Z range: floor at 22, top at 50.
    z_min, z_max = float(mesh.bounds[0, 2]), float(mesh.bounds[1, 2])
    results.append(CheckResult(
        "z_floor",
        abs(z_min - PARAMS["RECOVERY_BOWL_Z_FLOOR"]) < 0.5,
        f"z_min={z_min:.2f}, expected={PARAMS['RECOVERY_BOWL_Z_FLOOR']}",
    ))
    results.append(CheckResult(
        "z_top",
        abs(z_max - PARAMS["RECOVERY_BOWL_Z_TOP"]) < 0.5,
        f"z_max={z_max:.2f}, expected={PARAMS['RECOVERY_BOWL_Z_TOP']}",
    ))

    # Bowl must clear the disc envelope by ≥ DISC_CLEARANCE. The numeric
    # tolerance absorbs the chord-error of the OpenSCAD $fn=64 facets at
    # rim radius 66: R·(1 − cos(π/$fn)) ≈ 0.08 mm. We accept anything
    # within 0.15 mm of the nominal clearance — the geometric design is
    # correct, the gap is faceting noise.
    if disc_stl.exists():
        disc = trimesh.load(disc_stl, force="mesh")
        pts, _ = trimesh.sample.sample_surface(mesh, 3000)
        _, dists, _ = trimesh.proximity.closest_point(disc, pts)
        min_d = float(dists.min())
        results.append(CheckResult(
            "disc_clearance",
            min_d >= PARAMS["RECOVERY_BOWL_DISC_CLEARANCE"] - 0.15,
            f"min={min_d:.3f} mm, required≥{PARAMS['RECOVERY_BOWL_DISC_CLEARANCE']} "
            f"(0.15 mm tolerance for $fn=64 chord error)",
        ))

    return results


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

    print()
    print("=== Phase 3 V5: afstrijker ===")
    afstrijker_stl = ROOT / "stl" / "v5_3" / "afstrijker.stl"
    afstrijker_results = check_afstrijker(afstrijker_stl)
    for r in afstrijker_results:
        print(r)

    print()
    print("=== Phase 3 V5: afstrijker 2 (release-zone pusher) ===")
    afstrijker2_stl = ROOT / "stl" / "v5_3" / "afstrijker2.stl"
    afstrijker2_results = check_afstrijker2(afstrijker2_stl)
    for r in afstrijker2_results:
        print(r)

    print()
    print("=== Phase 3 V5: geleider ===")
    geleider_stl = ROOT / "stl" / "v5_3" / "geleider.stl"
    geleider_results = check_geleider(geleider_stl, disc_stl_v2)
    for r in geleider_results:
        print(r)

    print()
    print("=== Phase 3 V5: drop-tube ===")
    drop_tube_stl = ROOT / "stl" / "v5_3" / "drop_tube.stl"
    drop_tube_results = check_drop_tube(drop_tube_stl)
    for r in drop_tube_results:
        print(r)

    print()
    print("=== Phase 4 V5: vacuum chamber ===")
    vac_stl = ROOT / "stl" / "v5_4" / "vacuum_chamber.stl"
    vac_results = check_vacuum_chamber(vac_stl)
    for r in vac_results:
        print(r)

    print()
    print("=== Phase 5 V5: recovery bowl ===")
    bowl_stl = ROOT / "stl" / "v5_5" / "recovery_bowl.stl"
    bowl_results = check_recovery_bowl(bowl_stl, disc_stl_v2)
    for r in bowl_results:
        print(r)

    all_results = (disc_results + pool_results + clearance_results
                   + afstrijker_results + afstrijker2_results
                   + geleider_results + drop_tube_results
                   + vac_results + bowl_results)
    failed = [r for r in all_results if not r.passed]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
