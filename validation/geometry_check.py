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
    "RESERVOIR_TOP_X": 60.0,
    "RESERVOIR_TOP_Y": 60.0,
    "RESERVOIR_OUTLET_DIA": 12.0,
    "RESERVOIR_HEIGHT": 80.0,
    "RESERVOIR_WALL": 2.0,
    "RESERVOIR_OUTLET_CLEARANCE": 17.0,
    "MIN_CLEARANCE_MM": 5.0,
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


def check_reservoir(stl_path: Path) -> list[CheckResult]:
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

    # Bounding box: 60×60 footprint × 80 tall, centred over PICKUP_TOP_POS
    extents = mesh.extents
    expected_extents = (60.0, 60.0, 80.0)
    diffs = [abs(extents[i] - expected_extents[i]) for i in range(3)]
    bbox_ok = all(d < 1.0 for d in diffs)
    results.append(CheckResult(
        "bounding_box",
        bbox_ok,
        f"got={extents.round(2).tolist()}, expected≈{list(expected_extents)}",
    ))

    # Outlet bottom should sit at z = PICKUP_TOP_POS_Z + clearance ≈ 45.11
    tilt = math.radians(PARAMS["DISC_TILT_DEG"])
    pickup_top_z = (
        PARAMS["PICKUP_HOLE_RADIUS"] * math.sin(tilt)
        + (PARAMS["DISC_THICKNESS"] / 2) * math.cos(tilt)
    )
    expected_z_min = pickup_top_z + PARAMS["RESERVOIR_OUTLET_CLEARANCE"]
    actual_z_min = float(mesh.bounds[0, 2])
    results.append(CheckResult(
        "outlet_height",
        abs(actual_z_min - expected_z_min) < 0.5,
        f"outlet z={actual_z_min:.2f}, expected={expected_z_min:.2f}",
    ))

    # Inner volume: enclosed cavity capacity. We can't easily measure cavity
    # alone, but mesh.volume is the SHELL volume. Sanity: shell ≈ surface_area * wall.
    shell_volume = mesh.volume
    surface_area = mesh.area
    expected_shell = surface_area / 2 * PARAMS["RESERVOIR_WALL"]  # rough
    results.append(CheckResult(
        "shell_volume_sane",
        0.5 * expected_shell < shell_volume < 2.0 * expected_shell,
        f"shell_volume={shell_volume:.0f} mm³, surface_area={surface_area:.0f} mm²",
    ))

    return results


def check_clearance(disc_stl: Path, reservoir_stl: Path,
                    min_mm: float = 5.0, n_samples: int = 4000) -> list[CheckResult]:
    if not (disc_stl.exists() and reservoir_stl.exists()):
        return [CheckResult("clearance_files", False,
                            f"missing inputs: {disc_stl}, {reservoir_stl}")]

    disc = trimesh.load(disc_stl, force="mesh")
    res = trimesh.load(reservoir_stl, force="mesh")

    # Sample the reservoir surface uniformly, find each point's nearest
    # point on the disc surface.
    pts, _ = trimesh.sample.sample_surface(res, n_samples)
    closest, distances, _ = trimesh.proximity.closest_point(disc, pts)
    min_dist = float(distances.min())
    mean_dist = float(distances.mean())

    # Index of the closest point — useful for diagnostics.
    idx = int(distances.argmin())
    near = pts[idx]

    return [CheckResult(
        "reservoir_disc_clearance",
        min_dist >= min_mm,
        f"min={min_dist:.2f} mm @ {near.round(2).tolist()}, mean={mean_dist:.2f} mm",
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
    print("=== Phase 2: reservoir ===")
    res_stl = ROOT / "stl" / "v4_2" / "reservoir.stl"
    disc_stl_v2 = ROOT / "stl" / "v4_2" / "disc.stl"
    res_results = check_reservoir(res_stl)
    for r in res_results:
        print(r)

    print()
    print("=== Phase 2: disc-reservoir clearance ===")
    clearance_results = check_clearance(
        disc_stl_v2, res_stl, min_mm=PARAMS["MIN_CLEARANCE_MM"]
    )
    for r in clearance_results:
        print(r)

    if disc_stl_v2.exists() and res_stl.exists():
        try:
            disc = trimesh.load(disc_stl_v2, force="mesh")
            res = trimesh.load(res_stl, force="mesh")
            combined = trimesh.util.concatenate([disc, res])
            render_cross_section_png(
                combined, ROOT / "renders" / "v4_2" / "assembly_cross_section.png"
            )
            print("→ renders/v4_2/assembly_cross_section.png")
        except Exception as exc:
            print(f"[WARN] assembly cross-section render failed: {exc}")

    all_results = disc_results + res_results + clearance_results
    failed = [r for r in all_results if not r.passed]
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
