// PROTISEM V5 — Phase 3: afstrijker (singulator blade) + geleider (catch-chute)
//                       + drop-tube (vertical exit through central hole).
//
// V5 architecture (D6): vacuum picks seeds from bottom pool at θ=270°, seeds
// ride disc-front-face 180° to release at θ=90°, free-fall lands at world
// (~1.7, 29.7, 0) — completely outside the R=25 central hole. Without active
// redirection, every seed misses. The GELEIDER is therefore not ornamental:
// it physically catches seeds at the disc-top and routes them backward in
// -Y to a throat directly above the central drop hole.
//
// Three components in this phase:
//
//  AFSTRIJKER (Dutch: "stripper")
//      Flat blade just past pickup, mounted to housing, standing 8 mm proud
//      of the disc-front face. As a doubly-vacuumed seed (one in the hole,
//      one stacked on top) passes under it, the upper seed is knocked off.
//      Singulation function — without it, the disc would carry duplicates.
//
//  GELEIDER (Dutch: "guide")
//      Curved chute. Catch-mouth at (0, +30, 22) — just below the disc-top
//      release point — opens upward to receive falling seeds. Cavity
//      transitions (lofted hull) to a circular throat at (0, 0, 6), the
//      entrance to the drop-tube. Walls 2 mm.
//
//  DROP-TUBE
//      Vertical tube from geleider throat (z=6) down through disc central
//      hole (z=0) and out below the pool floor (z=-52). 30 mm OD, 24 mm ID.
//
// Critical clearances (computed below):
//
//      Disc-rim at θ=90°, R=66 (tooth tip): world (0, 46.67, 46.67).
//      Geleider catch-mouth -Y wall is at y=20, z=22-23. Closest disc point
//      sits at z=42, so vertical separation ≈19 mm — comfortable.
//
//      Drop-tube OD=30 vs central-hole ID=50 → 10 mm radial gap on each
//      side. Tube is loose-fit through the hole; no interference.
//
// Acceptance: all three parts watertight; no STL-level interference with
// disc or pool; geleider cavity reaches both openings (catch-mouth open,
// throat open).

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;
use     <v5_2_seed_pool.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "afstrijker", "geleider", "drop_tube", "all"

EPS = 0.01;

// =====================================================================
//  AFSTRIJKER — flat blade tangent to disc rim at θ=AFSTRIJKER_THETA_DEG.
// =====================================================================
//
// Construction: build the blade in disc-local frame (XY-plane), tangent to
// the rim at angle θ. Then apply the disc tilt (45° around X) and translate
// to the rim point. The blade extends 8 mm along the disc-normal direction
// (above the front face).

module afstrijker_blade() {
    // Pre-tilt frame: disc lies in XY plane, normal +Z.
    // Place a slab whose long axis is tangent to a circle at radius R, at
    // pre-tilt angle θ. Start with translate(0, R, h) — that puts the slab
    // at angle 90° on the circle. Rotate by (θ - 90°) around Z to swing it
    // to angle θ. The slab's local X-axis (length) is then tangent to the
    // rim at θ. Slab height range in Z = [t/2+1, t/2+1+H] sitting OUT of
    // the disc top face (will be mirrored to the FRONT face by caller).
    rotate([0, 0, AFSTRIJKER_THETA_DEG - 90])
        translate([0, PICKUP_HOLE_RADIUS,
                   DISC_THICKNESS / 2 + AFSTRIJKER_HEIGHT / 2 + 1])
            cube([AFSTRIJKER_LENGTH,
                  AFSTRIJKER_THICKNESS,
                  AFSTRIJKER_HEIGHT],
                 center = true);
}

module afstrijker() {
    // Mirror in Z to move the blade from the disc TOP face (+Z pre-tilt) to
    // the FRONT face (-Z pre-tilt). Then apply the disc tilt — the blade
    // ends up on the V5 front face (whose world-normal is +Y, -Z).
    rotate([DISC_TILT_DEG, 0, 0])
        mirror([0, 0, 1])
            afstrijker_blade();
}

// =====================================================================
//  AFSTRIJKER 2 — release-zone pusher at θ=95° (5° before release).
// =====================================================================
//
// Same construction principle as the first afstrijker, but at θ=95°,
// shorter (12 mm) and lower (6 mm) — well-attached seeds should already
// be releasing here, so this blade only has to nudge the stragglers off
// the disc into the geleider catch-mouth (which sits directly below at
// y∈[20,40], z∈[18,22]). The blade's tangent direction at θ=95° points
// roughly into +X, so a seed wiped off the disc gets a push in -Y/-Z
// (toward the geleider mouth), not flung outward.

module afstrijker2_blade() {
    rotate([0, 0, AFSTRIJKER2_THETA_DEG - 90])
        translate([0, PICKUP_HOLE_RADIUS,
                   DISC_THICKNESS / 2 + AFSTRIJKER2_HEIGHT / 2 + 1])
            cube([AFSTRIJKER2_LENGTH,
                  AFSTRIJKER2_THICKNESS,
                  AFSTRIJKER2_HEIGHT],
                 center = true);
}

module afstrijker2() {
    rotate([DISC_TILT_DEG, 0, 0])
        mirror([0, 0, 1])
            afstrijker2_blade();
}

// =====================================================================
//  GELEIDER — lofted hull from rectangular catch-mouth to circular throat,
//  with cavity that punches through both ends.
// =====================================================================

module geleider_outer() {
    hull() {
        // Top ring: rectangular, slightly larger than the cavity opening so
        // the wall thickness is built in (cavity will inset by GELEIDER_WALL).
        translate([0,
                   GELEIDER_MOUTH_Y_CENTER,
                   GELEIDER_MOUTH_Z + 1])
            cube([GELEIDER_MOUTH_X + 2 * GELEIDER_WALL,
                  GELEIDER_MOUTH_Y + 2 * GELEIDER_WALL,
                  2],
                 center = true);
        // Bottom ring: circular, OD = throat + 2*wall.
        translate([0, 0, GELEIDER_THROAT_Z + 1])
            cylinder(d = GELEIDER_THROAT_DIA + 2 * GELEIDER_WALL,
                     h = 2,
                     center = true);
    }
}

module geleider_cavity() {
    // Cavity hull. Top inset (so walls have thickness), but extends UPWARD
    // above the catch-mouth to ensure the top is open. Bottom inset to throat,
    // extends DOWNWARD past the throat to ensure the bottom is open.
    hull() {
        // Top: rectangular inner opening, extended upward
        translate([0,
                   GELEIDER_MOUTH_Y_CENTER,
                   GELEIDER_MOUTH_Z + 30])
            cube([GELEIDER_MOUTH_X,
                  GELEIDER_MOUTH_Y,
                  EPS],
                 center = true);
        // Bottom: circular throat, extended downward
        translate([0, 0, GELEIDER_THROAT_Z - 30])
            cylinder(d = GELEIDER_THROAT_DIA, h = EPS, center = true);
    }
}

// Disc-envelope-with-clearance, used to carve a clean slot through the
// geleider so the disc passes through without interference. The lofted hull
// from a wide rectangular mouth to a narrow circular throat unavoidably
// crosses the disc body slab at intermediate z; carving the disc envelope
// out of the geleider opens a slot. The slot leaks seeds — same problem the
// seed pool has at its side walls — and the same fix applies in later
// phases (Monosem-style sealing brushes around the disc rim).
module disc_envelope_for_geleider() {
    rotate([DISC_TILT_DEG, 0, 0])
        cylinder(d = DISC_OD_WITH_TEETH + 2 * GELEIDER_DISC_CLEARANCE,
                 h = DISC_THICKNESS + 2 * GELEIDER_DISC_CLEARANCE,
                 center = true);
}

module geleider() {
    difference() {
        geleider_outer();
        geleider_cavity();
        disc_envelope_for_geleider();
    }
}

// =====================================================================
//  DROP-TUBE — straight vertical pipe.
// =====================================================================
module drop_tube() {
    h = DROP_TUBE_Z_TOP - DROP_TUBE_Z_BOTTOM;
    translate([0, 0, DROP_TUBE_Z_BOTTOM])
        difference() {
            cylinder(d = DROP_TUBE_OD, h = h);
            translate([0, 0, -1])
                cylinder(d = DROP_TUBE_ID, h = h + 2);
        }
}

// =====================================================================
//  Main render
// =====================================================================
if (EXPORT_MODE) {
    if      (EXPORT_PART == "afstrijker")  afstrijker();
    else if (EXPORT_PART == "afstrijker2") afstrijker2();
    else if (EXPORT_PART == "geleider")    geleider();
    else if (EXPORT_PART == "drop_tube")   drop_tube();
    else if (EXPORT_PART == "disc")        disc();
    else if (EXPORT_PART == "seed_pool")   seed_pool();
    else {
        // "all" → export everything as a single combined STL (for inspection)
        disc();
        seed_pool();
        afstrijker();
        afstrijker2();
        geleider();
        drop_tube();
    }
} else {
    cross_section_x(ENABLE_CROSS_SECTION) {
        petg_blue() disc();
        petg_grey() seed_pool();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker2();
        color([0.65, 0.70, 0.78, 0.40]) geleider();
        color([0.70, 0.74, 0.80, 0.60]) drop_tube();
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")    translate(PICKUP_POS)      sphere(d = 4);
        color("orange") translate(RELEASE_POS)     sphere(d = 4);
        color("magenta") translate(AFSTRIJKER_POS)  sphere(d = 3);
        color("cyan")   translate(AFSTRIJKER2_POS) sphere(d = 3);
    }
}
