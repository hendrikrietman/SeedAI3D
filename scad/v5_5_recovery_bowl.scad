// PROTISEM V5 — Phase 5a: top-half recovery bowl.
//
// Why this part exists. Phase 4 vacuum chamber covers θ ∈ [90°, 270°]
// (world x ≤ 0). A perfectly-attached seed releases at θ=90°, world
// (0, +29.7, +29.7), where the geleider catch-mouth catches it. Edge
// cases — mid-arc vacuum drop, afstrijker-2 push that overshoots, RPM/
// vacuum mismatch — release seeds elsewhere on the disc top half (any
// world position with y > 0 in plan view). Without a wider catch surface
// these seeds fly past the geleider and end up on the floor.
//
// The recovery bowl is a half-disc shell, footprint y ≥ 0, R_OUTER = 55,
// covering z ∈ [22, 50]. The floor at z = 22 sits flush on top of the
// geleider; a 40 × 20 mm rectangular drain in the floor at (0, 30) opens
// directly into the geleider catch-mouth. Open at the top (no roof).
// Outer curved wall at R = 55 retains seeds that bounce.
//
// Disc-envelope subtraction (with 3 mm clearance) carves a slot through
// the bowl wall + floor where the disc rim passes — same approach as the
// seed pool (D6) and geleider (D7). The slot leaks; physical hardware
// will need sealing brushes around the disc rim, deferred per D6/D7.
//
// Geometry sanity (keep):
//
//   Disc rim with teeth (R=66) crosses bowl outer wall (r²=55²) at
//       sin²α = (R²−R_outer²)·2/R² = (66²−55²)·2/66² = 0.611
//       α = 51.4° or 128.6°  →  world (±41.2, 36.5, 36.5)
//   Bowl floor at z=22 intersects disc body slab |z−y| ≤ 2.83 in
//       y ∈ [19.2, 24.8].  Slot is in this y range, x bounded by disc OD.
//   Drain hole 40×20 at y_centre=30 fully contains the geleider mouth
//       (same dims by construction). Bowl floor at z=22 = geleider top.
//
// Acceptance: bowl watertight, disc and bowl coexist (envelope slot leaves
// no spurious holes other than the intended slot + drain), drain hole
// aligns with geleider mouth.

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;
use     <v5_2_seed_pool.scad>;
use     <v5_3_barriere_geleider.scad>;
use     <v5_4_vacuum_chamber.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "recovery_bowl" | "all" | sub-parts

EPS = 0.01;

// =====================================================================
//  Half-cylinder solid body, footprint y ≥ 0, z ∈ [Z_FLOOR, Z_TOP].
// =====================================================================
module recovery_bowl_outer_solid() {
    H = RECOVERY_BOWL_Z_TOP - RECOVERY_BOWL_Z_FLOOR;
    translate([0, 0, (RECOVERY_BOWL_Z_FLOOR + RECOVERY_BOWL_Z_TOP) / 2])
        difference() {
            cylinder(r = RECOVERY_BOWL_R_OUTER, h = H, center = true);
            // Cut y < 0 half — keep only y ≥ 0 footprint.
            translate([-RECOVERY_BOWL_R_OUTER - 1,
                       -RECOVERY_BOWL_R_OUTER - 1,
                       -H / 2 - 1])
                cube([2 * RECOVERY_BOWL_R_OUTER + 2,
                      RECOVERY_BOWL_R_OUTER + 1,
                      H + 2]);
        }
}

// =====================================================================
//  Inner cavity. Half-cylinder of radius R_INNER, extending from
//  Z_FLOOR + WALL upward past Z_TOP (open top). Subtracting it from the
//  outer solid leaves the curved wall and the floor.
// =====================================================================
module recovery_bowl_cavity() {
    H_cav = (RECOVERY_BOWL_Z_TOP + 20) - (RECOVERY_BOWL_Z_FLOOR + RECOVERY_BOWL_WALL);
    translate([0, 0,
               (RECOVERY_BOWL_Z_FLOOR + RECOVERY_BOWL_WALL +
                RECOVERY_BOWL_Z_TOP + 20) / 2])
        difference() {
            cylinder(r = RECOVERY_BOWL_R_INNER, h = H_cav, center = true);
            translate([-RECOVERY_BOWL_R_OUTER - 1,
                       -RECOVERY_BOWL_R_OUTER - 1,
                       -H_cav / 2 - 1])
                cube([2 * RECOVERY_BOWL_R_OUTER + 2,
                      RECOVERY_BOWL_R_OUTER + 1,
                      H_cav + 2]);
        }
}

// =====================================================================
//  Drain hole in the floor — matches geleider mouth.
// =====================================================================
module recovery_bowl_drain() {
    translate([-GELEIDER_MOUTH_X / 2,
               GELEIDER_MOUTH_Y_CENTER - GELEIDER_MOUTH_Y / 2,
               RECOVERY_BOWL_Z_FLOOR - 1])
        cube([GELEIDER_MOUTH_X,
              GELEIDER_MOUTH_Y,
              RECOVERY_BOWL_WALL + 4]);
}

// =====================================================================
//  Disc-envelope-with-clearance, used to carve the slot where the disc
//  rim passes through the bowl wall + floor.
// =====================================================================
module recovery_bowl_disc_envelope() {
    rotate([DISC_TILT_DEG, 0, 0])
        cylinder(d = DISC_OD_WITH_TEETH + 2 * RECOVERY_BOWL_DISC_CLEARANCE,
                 h = DISC_THICKNESS + 2 * RECOVERY_BOWL_DISC_CLEARANCE,
                 center = true);
}

module recovery_bowl() {
    difference() {
        recovery_bowl_outer_solid();
        recovery_bowl_cavity();
        recovery_bowl_drain();
        recovery_bowl_disc_envelope();
    }
}

// =====================================================================
//  Main render. Default: full V5 assembly with the new bowl.
// =====================================================================
if (EXPORT_MODE) {
    if      (EXPORT_PART == "recovery_bowl")  recovery_bowl();
    else if (EXPORT_PART == "vacuum_chamber") vacuum_chamber();
    else if (EXPORT_PART == "disc")           disc();
    else if (EXPORT_PART == "seed_pool")      seed_pool();
    else if (EXPORT_PART == "afstrijker")     afstrijker();
    else if (EXPORT_PART == "afstrijker2")    afstrijker2();
    else if (EXPORT_PART == "geleider")       geleider();
    else if (EXPORT_PART == "drop_tube")      drop_tube();
    else {
        disc();
        seed_pool();
        afstrijker();
        afstrijker2();
        geleider();
        drop_tube();
        vacuum_chamber();
        recovery_bowl();
    }
} else {
    cross_section_x(ENABLE_CROSS_SECTION) {
        petg_blue() disc();
        petg_grey() seed_pool();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker2();
        color([0.65, 0.70, 0.78, 0.40]) geleider();
        color([0.70, 0.74, 0.80, 0.60]) drop_tube();
        color([0.55, 0.65, 0.85, 0.30]) vacuum_chamber();
        color([0.85, 0.78, 0.55, 0.45]) recovery_bowl();
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")     translate(PICKUP_POS)      sphere(d = 4);
        color("orange")  translate(RELEASE_POS)     sphere(d = 4);
        color("magenta") translate(AFSTRIJKER_POS)  sphere(d = 3);
        color("cyan")    translate(AFSTRIJKER2_POS) sphere(d = 3);
    }
}
