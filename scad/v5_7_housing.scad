// PROTISEM V5 — Phase 7: integrated transparent housing.
//
// Three new parts, all rendered with subtle transparency so the existing
// disc + mal-plate + pinion + motor + geleider remain visible:
//   - Hopper:     funnel-shaped seed reservoir, wide on top, narrow at
//                 bottom (30×30 narrow, 100×80 wide, 80 mm tall).
//   - Lid:        circular cover Ø 144 × 4 mm thick, parallel to disc-front.
//   - Dust-ring:  rubber sealing ring on lid-bottom-face, at disc-OD radius.
//
// The hopper is built in WORLD coordinates (axis vertical, along -Z, the
// gravity direction). The lid + dust-ring are built in disc-local pre-tilt
// frame and then tilted with the disc.
//
// Integrated tubes (feeder + vac-cleanup): for the visualisation model,
// they're rendered as short connector stubs sticking out of the hopper
// wall — the "channel through the wall" is implied by the bore that
// connects connector to hopper interior. Simpler than carving a curved
// channel through the wall geometry; result is visually identical from
// the outside.
//
// All three parts are watertight unions of simple primitives. Disc-rim
// at θ=270° dips into the hopper top through the narrow opening's edge
// (visualisation accepts the disc-rim/hopper-wall overlap, same approach
// as the seed-pool / mal-plate overlap from D11; physical hardware
// would need rim-following sealing per D6/D7).

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "hopper" | "lid" | "dust_ring" | "all"

EPS = 0.01;

// =====================================================================
//  HOPPER — funnel from wide top to narrow bottom + closed pool floor.
//  Built directly in world coords (axis = world -Z).
// =====================================================================
module hopper_outer_solid() {
    // Pool reservoir: constant-cross-section box, extends 1 mm above
    // HOPPER_BOTTOM_Z to overlap with the funnel hull below.
    translate([HOPPER_X_CENTRE - HOPPER_BOTTOM_X / 2,
               HOPPER_Y_CENTRE - HOPPER_BOTTOM_Y / 2,
               HOPPER_POOL_FLOOR_Z])
        cube([HOPPER_BOTTOM_X, HOPPER_BOTTOM_Y, HOPPER_POOL_DEPTH + 1]);
    // Funnel body: hull from narrow box (1 mm below pool top, overlapping
    // pool) to wide box at the top.
    hull() {
        translate([HOPPER_X_CENTRE - HOPPER_BOTTOM_X / 2,
                   HOPPER_Y_CENTRE - HOPPER_BOTTOM_Y / 2,
                   HOPPER_BOTTOM_Z - 1])
            cube([HOPPER_BOTTOM_X, HOPPER_BOTTOM_Y, EPS]);
        translate([HOPPER_X_CENTRE - HOPPER_TOP_X / 2,
                   HOPPER_Y_CENTRE - HOPPER_TOP_Y / 2,
                   HOPPER_TOP_Z])
            cube([HOPPER_TOP_X, HOPPER_TOP_Y, EPS]);
    }
}

module hopper_cavity() {
    inner_bx = HOPPER_BOTTOM_X - 2 * HOPPER_WALL;
    inner_by = HOPPER_BOTTOM_Y - 2 * HOPPER_WALL;
    inner_tx = HOPPER_TOP_X - 2 * HOPPER_WALL;
    inner_ty = HOPPER_TOP_Y - 2 * HOPPER_WALL;
    // Pool cavity: constant cross-section, matches pool outer minus walls.
    translate([HOPPER_X_CENTRE - inner_bx / 2,
               HOPPER_Y_CENTRE - inner_by / 2,
               HOPPER_POOL_FLOOR_Z + HOPPER_WALL])
        cube([inner_bx, inner_by,
              HOPPER_POOL_DEPTH - HOPPER_WALL + 2]);
    // Funnel cavity: hull from pool top (narrow inner) up past hopper top
    // (wide inner). Slopes match the outer funnel so wall thickness stays
    // at HOPPER_WALL throughout.
    hull() {
        translate([HOPPER_X_CENTRE - inner_bx / 2,
                   HOPPER_Y_CENTRE - inner_by / 2,
                   HOPPER_BOTTOM_Z - EPS])
            cube([inner_bx, inner_by, EPS]);
        translate([HOPPER_X_CENTRE - inner_tx / 2,
                   HOPPER_Y_CENTRE - inner_ty / 2,
                   HOPPER_TOP_Z + 1])
            cube([inner_tx, inner_ty, EPS]);
    }
}

// Feeder connector: short cylindrical stub on the hopper-front-face
// (the +Y face of the hopper, since hopper is centred at Y=-46.67 and
// extends to Y=-46.67-HOPPER_TOP_Y/2 = -86.67 on the front side).
// Tilted up at FEEDER_ELEV_DEG from horizontal.
module feeder_connector_outer() {
    front_y = HOPPER_Y_CENTRE - HOPPER_TOP_Y / 2;   // -86.67
    feeder_z = HOPPER_TOP_Z - 8;                    // 8 mm below top edge
    translate([HOPPER_X_CENTRE + 15, front_y, feeder_z])
        rotate([90 - FEEDER_ELEV_DEG, 0, 0])
            cylinder(d = FEEDER_CHANNEL_ID + 4,
                     h = FEEDER_CONNECTOR_LEN + HOPPER_WALL + EPS);
}

module feeder_connector_bore() {
    front_y = HOPPER_Y_CENTRE - HOPPER_TOP_Y / 2;
    feeder_z = HOPPER_TOP_Z - 8;
    translate([HOPPER_X_CENTRE + 15, front_y, feeder_z])
        rotate([90 - FEEDER_ELEV_DEG, 0, 0])
            translate([0, 0, -HOPPER_WALL - 5])
                cylinder(d = FEEDER_CHANNEL_ID,
                         h = FEEDER_CONNECTOR_LEN + HOPPER_WALL + 10);
}

// Vac-cleanup connector retired in v5.8.2 — with the hopper now small and
// positioned at the pickup zone, the vac-stub anchor would land inside
// the open hopper-top cavity, breaking 2-manifoldness. Re-add when /
// if a top-mount cleanup is reinstated (probably as a separate module
// not booleaned with the hopper).

module hopper() {
    difference() {
        union() {
            hopper_outer_solid();
            feeder_connector_outer();
        }
        hopper_cavity();
        feeder_connector_bore();
    }
}

// =====================================================================
//  PROTECTIVE LID + DUST-RING — built in disc-local pre-tilt frame.
//  Lid front face sits at disc-local Z = LID_FRONT_Z; lid back face
//  at Z = LID_FRONT_Z - LID_THICKNESS. Cutouts where geleider mouth,
//  pickup zone, and central drop-tube need to pass.
// =====================================================================
// v5.8.2: lid is an ANNULAR RING (no full disc, no side rim).
// Ring covers from R=56 (inner edge) to R=70 (outer edge), 6 mm thick.
// The disc's pickup-hole circle (R=42) and central area stay fully
// open in front view — that's where the hopper sits.
LID_FRONT_Z       = DISC_THICKNESS / 2 + LID_OFFSET_FROM_DISC;      // +10
LID_BACK_Z        = LID_FRONT_Z - LID_THICKNESS;                     // +4
DUST_RING_FRONT_Z = LID_BACK_Z - DUST_RING_THICKNESS;                // +1

module lid_solid() {
    translate([0, 0, LID_BACK_Z])
        difference() {
            cylinder(d = LID_OD, h = LID_THICKNESS);
            translate([0, 0, -1])
                cylinder(d = LID_INNER_DIA, h = LID_THICKNESS + 2);
        }
}

// Cutouts in the ring at θ=270° (hopper access) and θ=90° (geleider
// release window). Each is a small radial slot through the ring so the
// disc-rim teeth are exposed at those angular positions for hopper /
// geleider access. The rest of the ring covers the disc teeth.
module lid_cutouts() {
    // Pickup-zone slot — radial gap at θ=270° (disc-local Y < 0 area).
    // Width 30 mm tangentially (X), depth fully through ring radially (Y).
    translate([-15, -LID_OD / 2 - 1, LID_BACK_Z - 1])
        cube([30, LID_OD, LID_THICKNESS + 2]);
    // Release-zone slot — at θ=90°. Wider (40 mm) to clear geleider mouth.
    translate([-20, LID_INNER_DIA / 2 - 1, LID_BACK_Z - 1])
        cube([40, LID_OD / 2 - LID_INNER_DIA / 2 + 2, LID_THICKNESS + 2]);
}

module lid() {
    rotate([DISC_TILT_DEG, 0, 0])
        difference() {
            lid_solid();
            lid_cutouts();
        }
}

module dust_ring_solid() {
    translate([0, 0, DUST_RING_FRONT_Z])
        difference() {
            cylinder(d = DUST_RING_OD, h = DUST_RING_THICKNESS);
            translate([0, 0, -1])
                cylinder(d = LID_ID_RING, h = DUST_RING_THICKNESS + 2);
        }
}

module dust_ring() {
    rotate([DISC_TILT_DEG, 0, 0]) dust_ring_solid();
}

// =====================================================================
//  Main render
// =====================================================================
if (EXPORT_MODE) {
    if      (EXPORT_PART == "hopper")    hopper();
    else if (EXPORT_PART == "lid")       lid();
    else if (EXPORT_PART == "dust_ring") dust_ring();
    else { hopper(); lid(); dust_ring(); }
} else {
    cross_section_x(ENABLE_CROSS_SECTION) {
        color([0.72, 0.72, 0.80, 0.35]) hopper();
        color([0.72, 0.72, 0.80, 0.30]) lid();
        color([0.55, 0.10, 0.10, 0.85]) dust_ring();
        petg_blue() disc();
    }
}
