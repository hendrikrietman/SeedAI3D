// PROTISEM V4 — Phase 1: parametric disc
// Disc OD 120 (excl teeth), 132 (incl), thickness 4, central hole 50,
// 40 pickup holes (Ø 2.5) on R=42, 60 trapezoidal teeth on rim.
// Disc tilted 45° around X axis -> normal = (0, -sin45°, cos45°).

include <lib/parameters.scad>;
use     <lib/helpers.scad>;

// Customizer: set true to render the disc with the +Y half cut away
ENABLE_CROSS_SECTION = false;
// Customizer: set true for clean STL export (strips debug markers/colors)
EXPORT_MODE = false;

// ----- one trapezoidal tooth, base on circle R=DISC_OD/2 -----
module tooth(angle_deg) {
    pitch_deg = 360 / TOOTH_COUNT;       // = 6°
    bw = pitch_deg * TOOTH_BASE_FRACTION;
    tw = pitch_deg * TOOTH_TIP_FRACTION;
    r0 = DISC_OD / 2;
    r1 = DISC_OD_WITH_TEETH / 2;
    rotate([0, 0, angle_deg])
        linear_extrude(height = DISC_THICKNESS, center = true)
            polygon(points = [
                [r0 * cos(-bw/2), r0 * sin(-bw/2)],
                [r0 * cos(+bw/2), r0 * sin(+bw/2)],
                [r1 * cos(+tw/2), r1 * sin(+tw/2)],
                [r1 * cos(-tw/2), r1 * sin(-tw/2)],
            ]);
}

module tooth_ring() {
    pitch_deg = 360 / TOOTH_COUNT;
    for (i = [0 : TOOTH_COUNT - 1])
        tooth(i * pitch_deg);
}

// ----- pickup hole pattern (in pre-tilt frame, holes along Z = disc normal) -----
module pickup_holes() {
    for (i = [0 : PICKUP_HOLE_COUNT - 1]) {
        a = i * 360 / PICKUP_HOLE_COUNT;
        translate([PICKUP_HOLE_RADIUS * cos(a),
                   PICKUP_HOLE_RADIUS * sin(a),
                   0])
            cylinder(d = PICKUP_HOLE_DIA,
                     h = DISC_THICKNESS + 2,
                     center = true);
    }
}

// ----- disc body (flat in XY plane, normal = +Z) -----
module disc_flat() {
    difference() {
        union() {
            cylinder(d = DISC_OD, h = DISC_THICKNESS, center = true);
            tooth_ring();
        }
        // central seed-drop hole
        cylinder(d = CENTRAL_HOLE_DIA,
                 h = DISC_THICKNESS + 2,
                 center = true);
        // 40 pickup holes, perpendicular to disc plane
        pickup_holes();
    }
}

// ----- disc tilted into final orientation -----
module disc() {
    rotate([DISC_TILT_DEG, 0, 0]) disc_flat();
}

// ----- main render -----
if (EXPORT_MODE) {
    disc();
} else {
    cross_section_y(ENABLE_CROSS_SECTION)
        petg_blue() disc();

    // Debug markers (only shown without cross section)
    if (!ENABLE_CROSS_SECTION) {
        color("red")    translate(PICKUP_POS)  sphere(d = 4);
        color("orange") translate(RELEASE_POS) sphere(d = 4);
    }
}
