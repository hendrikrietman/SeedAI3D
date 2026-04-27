// PROTISEM V4 — Phase 2: spits reservoir + diagonale uitloop
//
// Funnel geometry: 60×60 mm rectangular open top -> Ø12 round outlet bottom.
// Height 80 mm, wall thickness 2 mm. Walls slope ~73° from horizontal
// (well above the 35° minimum and the ~28° rest angle of soya).
//
// Position: outlet centred above the disc-top pickup point (PICKUP_TOP_POS),
// raised by RESERVOIR_OUTLET_CLEARANCE so the +Y rim clears the rising disc
// surface. Seeds drop vertically from the outlet onto the highest pickup
// hole on the disc top.
//
// Math check (with current parameters, all in mm):
//
//     PICKUP_TOP_POS         = (0, 28.284, 31.113)
//     RESERVOIR_OUTLET_POS   = (0, 28.284, 48.113)        // = pickup_top + (0,0,17)
//     drop distance to disc  = 17.000 mm
//     Ø12 inner rim, +Y      = (0, 34.284, 48.113)
//     Ø16 outer rim, +Y      = (0, 36.284, 48.113)        // collision-critical
//     disc-top plane         z = y + 2.828
//     perpendicular distance, outer rim
//         = cos(45°) · (z - y - 2.828)
//         = 0.7071  · (48.113 - 36.284 - 2.828)
//         = 6.364 mm  ✓ (> 5 mm acceptance threshold)
//
// Acceptance: clearance > 5 mm everywhere (verified by validation script).

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "disc", "reservoir", or "all"

// ----- reservoir geometry, built locally with outlet bottom at z=0 -----
EPS = 0.01;

module reservoir_outer_solid() {
    hull() {
        // top: 60×60 thin slab
        translate([0, 0, RESERVOIR_HEIGHT - EPS])
            cube([RESERVOIR_TOP_X, RESERVOIR_TOP_Y, EPS], center = true);
        // bottom: Ø(D + 2·wall) thin disc — gives the 2 mm wall at the outlet rim
        cylinder(d = RESERVOIR_OUTLET_DIA + 2 * RESERVOIR_WALL, h = EPS);
    }
}

module reservoir_inner_cavity() {
    hull() {
        // top extends slightly above outer top so the cavity opens cleanly
        translate([0, 0, RESERVOIR_HEIGHT + 1])
            cube([RESERVOIR_TOP_X - 2 * RESERVOIR_WALL,
                  RESERVOIR_TOP_Y - 2 * RESERVOIR_WALL, EPS], center = true);
        // bottom extends slightly below 0 so the outlet hole is open
        translate([0, 0, -1])
            cylinder(d = RESERVOIR_OUTLET_DIA, h = 1 + EPS);
    }
}

module reservoir_local() {
    difference() {
        reservoir_outer_solid();
        reservoir_inner_cavity();
    }
}

// Reservoir placed in world coordinates: outlet bottom at RESERVOIR_OUTLET_POS
module reservoir() {
    translate(RESERVOIR_OUTLET_POS) reservoir_local();
}

// ----- main render -----
if (EXPORT_MODE) {
    if      (EXPORT_PART == "disc")       disc();
    else if (EXPORT_PART == "reservoir")  reservoir();
    else                                   { disc(); reservoir(); }
} else {
    // Phase-2 cross-section uses the X=0 plane: the reservoir sits in +Y,
    // so cutting +Y would erase it. Cutting +X instead reveals the YZ
    // profile of both disc and reservoir, showing the seed path cleanly.
    cross_section_x(ENABLE_CROSS_SECTION) {
        petg_blue() disc();
        petg_grey() reservoir();
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")    translate(PICKUP_POS)             sphere(d = 4);
        color("orange") translate(RELEASE_POS)            sphere(d = 4);
        color("yellow") translate(RESERVOIR_OUTLET_POS)   sphere(d = 4);
    }
}
