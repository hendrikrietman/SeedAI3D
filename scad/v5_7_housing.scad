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
    // Funnel body: hull from a small box at the bottom narrow level to a
    // larger box at the top.
    hull() {
        // Bottom narrow rectangle (just above pool surface)
        translate([HOPPER_X_CENTRE - HOPPER_BOTTOM_X / 2,
                   HOPPER_Y_CENTRE - HOPPER_BOTTOM_Y / 2,
                   HOPPER_BOTTOM_Z])
            cube([HOPPER_BOTTOM_X, HOPPER_BOTTOM_Y, EPS]);
        // Top wide rectangle
        translate([HOPPER_X_CENTRE - HOPPER_TOP_X / 2,
                   HOPPER_Y_CENTRE - HOPPER_TOP_Y / 2,
                   HOPPER_TOP_Z])
            cube([HOPPER_TOP_X, HOPPER_TOP_Y, EPS]);
    }
    // Pool reservoir (rectangular box below the funnel narrow bottom)
    translate([HOPPER_X_CENTRE - HOPPER_BOTTOM_X / 2,
               HOPPER_Y_CENTRE - HOPPER_BOTTOM_Y / 2,
               HOPPER_POOL_FLOOR_Z])
        cube([HOPPER_BOTTOM_X, HOPPER_BOTTOM_Y, HOPPER_POOL_DEPTH]);
}

module hopper_cavity() {
    // Inner funnel cavity, inset by HOPPER_WALL on every face. Hull from
    // bottom narrow to top wide (top opens to the air, so the cavity
    // breaks through the top surface).
    hull() {
        translate([HOPPER_X_CENTRE - (HOPPER_BOTTOM_X / 2 - HOPPER_WALL),
                   HOPPER_Y_CENTRE - (HOPPER_BOTTOM_Y / 2 - HOPPER_WALL),
                   HOPPER_POOL_FLOOR_Z + HOPPER_WALL])
            cube([HOPPER_BOTTOM_X - 2 * HOPPER_WALL,
                  HOPPER_BOTTOM_Y - 2 * HOPPER_WALL,
                  EPS]);
        translate([HOPPER_X_CENTRE - (HOPPER_TOP_X / 2 - HOPPER_WALL),
                   HOPPER_Y_CENTRE - (HOPPER_TOP_Y / 2 - HOPPER_WALL),
                   HOPPER_TOP_Z + 1])
            cube([HOPPER_TOP_X - 2 * HOPPER_WALL,
                  HOPPER_TOP_Y - 2 * HOPPER_WALL,
                  EPS]);
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

// Vac-cleanup connector: cylindrical stub on the hopper-top-face.
// Tilted near-vertical (VAC_ELEV_DEG = 80° = 10° off vertical).
module vac_connector_outer() {
    translate([HOPPER_X_CENTRE,
               HOPPER_Y_CENTRE - 5,                 // slight -Y for operator reach
               HOPPER_TOP_Z])
        rotate([90 - VAC_ELEV_DEG, 0, 0])
            cylinder(d = VAC_CHANNEL_ID + 4,
                     h = VAC_CONNECTOR_LEN + 8 + EPS);
}

module vac_connector_bore() {
    // Bore extends from hopper-top down through the connector to inside
    // the hopper, ending at HOPPER_BOTTOM_Z + VAC_MOUTH_OFFSET_Z = -39.
    translate([HOPPER_X_CENTRE,
               HOPPER_Y_CENTRE - 5,
               HOPPER_TOP_Z])
        rotate([90 - VAC_ELEV_DEG, 0, 0])
            translate([0, 0, -50])
                cylinder(d = VAC_CHANNEL_ID,
                         h = VAC_CONNECTOR_LEN + 60);
}

module hopper() {
    difference() {
        union() {
            hopper_outer_solid();
            feeder_connector_outer();
            vac_connector_outer();
        }
        hopper_cavity();
        feeder_connector_bore();
        vac_connector_bore();
    }
}

// =====================================================================
//  PROTECTIVE LID + DUST-RING — built in disc-local pre-tilt frame.
//  Lid front face sits at disc-local Z = LID_FRONT_Z; lid back face
//  at Z = LID_FRONT_Z - LID_THICKNESS. Cutouts where geleider mouth,
//  pickup zone, and central drop-tube need to pass.
// =====================================================================
LID_FRONT_Z      = DISC_THICKNESS / 2 + LID_OFFSET_FROM_DISC;       // +10
LID_BACK_Z       = LID_FRONT_Z - LID_THICKNESS;                     // +6
DUST_RING_BACK_Z = LID_BACK_Z;
DUST_RING_FRONT_Z = LID_BACK_Z - DUST_RING_THICKNESS;               // +3 — sits inside disc-front clearance

module lid_solid() {
    translate([0, 0, LID_BACK_Z])
        cylinder(d = LID_OD, h = LID_THICKNESS);
}

// Cutouts: pickup zone (θ=270°), release / geleider mouth area (θ=90°),
// central drop-tube hole. Each is a small rectangle in disc-local X-Y.
module lid_cutouts() {
    // Pickup-zone window — 40×30 box at θ=270° (disc-local Y=-42 area)
    translate([-20, -55, LID_BACK_Z - 1])
        cube([40, 25, LID_THICKNESS + 2]);
    // Release-zone window — 40×20 box at θ=90° (disc-local Y=+42 area).
    // Offset slightly toward the geleider mouth (Y_centre=+30 on geleider).
    translate([-20, 30, LID_BACK_Z - 1])
        cube([40, 25, LID_THICKNESS + 2]);
    // Central hole for drop-tube
    translate([0, 0, LID_BACK_Z - 1])
        cylinder(d = CENTRAL_HOLE_DIA + 4, h = LID_THICKNESS + 2);
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
            cylinder(d = LID_OD, h = DUST_RING_THICKNESS);
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
