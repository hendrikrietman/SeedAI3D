// PROTISEM V5 — Phase 6: integrated disc-mal element.
//
// One 3D-printable plate that holds the disc, drives it (NEMA17 stepper +
// 20T pinion engaging the disc tooth-rim), and provides vacuum suction
// (180° arc-sector cavity inside the plate, sealed against the disc-back
// face by an O-ring in a groove). Replaces the standalone Phase-4 vacuum
// chamber, which is now archived in scad/archive/.
//
// Frame conventions (pre-tilt, plate-local = disc-local):
//   X axis  — radial across the plate, disc tilts around world-X
//   Y axis  — in-plane perpendicular
//   Z axis  — disc-axis-of-rotation (plate-back at Z<0, plate-front at Z>0)
//
// Disc occupies Z ∈ [-2, +2]. Plate occupies Z ∈ [-12.5, +2.5]:
//   plate-front-face        Z = +2.5
//   recess opening          Z = +2.5             (Ø 134, 5 mm deep)
//   disc front face         Z = +2.0    (0.5 mm front clearance)
//   disc back face          Z = -2.0    (4 mm thick disc)
//   recess back wall        Z = -2.5    (0.5 mm back clearance, O-ring sits here)
//   chamber cavity span     Z = -2.5 to -10.5    (8 mm deep, 180° sector)
//   plate back face         Z = -12.5            (2 mm chamber back wall)
//
// After rotate([45,0,0]) the plate's Z axis maps to world (0,-sin45°,+cos45°) —
// plate-back ends up in operator-far direction, just like the old standalone
// chamber post-FLIP (D8).
//
// Vacuum chamber sector covers θ_local ∈ [90°, 270°] through 180° (world
// x_local ≤ 0). Pickup circle (R=42) sits centred between R_in=32 and
// R_out=52 with 10 mm margin each side.
//
// O-ring groove (ISO-3601 style for 2.5 mm NBR cord) is cut into the
// recess-back-wall (Z = -2.5) on the disc-side face, following the chamber
// sector perimeter. Outer arc R=53, inner arc R=31, two end straights at
// θ=90° and θ=270°. Cord protrudes 0.6 mm uncompressed → ~0.5 mm under
// disc-back pressure, sealing the air gap to disc-back.
//
// Motor cut-out is a rectangular opening at θ=180° large enough to fit
// the 20-tooth pinion (OD≈33) with clearance. Motor mounts on plate-back,
// shaft passes through plate via Ø 7 hole at pinion centre (X=-75, Y=0).
//
// Hose nipple sticks out plate-back at chamber midpoint (X=-42, Y=0) along
// plate-Z direction; bores through plate to chamber cavity.

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;
// v5_2_seed_pool.scad archived in Phase 7 (replaced by housing).
use     <v5_3_barriere_geleider.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "mal_plate" | "pinion" | "motor" | "all" | sub-parts

EPS = 0.01;

// =====================================================================
//  Plate-Z reference points (pre-tilt). Defined here, not in parameters,
//  so the geometry is self-documenting in this file.
// =====================================================================
MAL_Z_FRONT      = MAL_DISC_RECESS_DEPTH - DISC_THICKNESS / 2 - MAL_FRONT_CLEARANCE;  // +2.5
MAL_Z_RECESS_BK  = MAL_Z_FRONT - MAL_DISC_RECESS_DEPTH;  // -2.5
MAL_Z_CHAMBER_BK = MAL_Z_RECESS_BK - MAL_CHAMBER_DEPTH;  // -10.5
MAL_Z_BACK       = MAL_Z_CHAMBER_BK - MAL_CHAMBER_BACK_WALL;  // -12.5

// =====================================================================
//  Half-space x ≤ 0 (chamber sector covers world-X negative half).
// =====================================================================
module sector_xneg() {
    translate([-1000, -500, -500])
        cube([1000, 1000, 1000]);
}

module annular_sector_xneg(r_in, r_out, h, z) {
    intersection() {
        translate([0, 0, z])
            difference() {
                cylinder(r = r_out, h = h);
                translate([0, 0, -1]) cylinder(r = r_in, h = h + 2);
            }
        sector_xneg();
    }
}

// =====================================================================
//  Mal-plate solid before any cuts.
// =====================================================================
module mal_plate_solid() {
    // v5.8.5: round plate (was 180×180 square), OD=152.
    translate([0, 0, MAL_Z_BACK])
        cylinder(d = MAL_PLATE_OD, h = MAL_PLATE_THICKNESS);
}

// =====================================================================
//  Disc-recess: cylindrical pocket in plate-front, Ø 134, depth 5.
// =====================================================================
module mal_disc_recess() {
    translate([0, 0, MAL_Z_RECESS_BK])
        cylinder(d = MAL_DISC_RECESS_DIA,
                 h = MAL_DISC_RECESS_DEPTH + 1);   // +1 to break top surface cleanly
}

// =====================================================================
//  Vacuum chamber cavity: 180° sector, R 32..52, Z -10.5..-2.5.
//  The cavity also extends UP through the recess-back-wall (no wall
//  between recess and chamber in the chamber sector — the disc-back IS
//  the chamber's front cover via the O-ring seal).
// =====================================================================
module mal_chamber_cavity() {
    // Chamber proper (inside plate, behind recess-back-wall)
    annular_sector_xneg(MAL_CHAMBER_R_IN, MAL_CHAMBER_R_OUT,
                        MAL_CHAMBER_DEPTH + EPS,
                        z = MAL_Z_CHAMBER_BK);
}

// =====================================================================
//  O-ring groove on the disc-side face of the recess-back-wall.
//  Path: outer arc R=53, inner arc R=31, two end-straights at θ=90°/270°.
//  Implemented as: outer half-annulus minus inner half-annulus, plus two
//  end-cap cubes — a single `linear_extrude` of the path cross-section
//  would be cleaner but OpenSCAD doesn't have an easy curved-extrude.
// =====================================================================
module oring_groove_path() {
    gw   = ORING_GROOVE_WIDTH;
    half = gw / 2;
    // Outer half-annulus at R = ORING_OUTER_R, x ≤ 0
    annular_sector_xneg(ORING_OUTER_R - half,
                        ORING_OUTER_R + half,
                        ORING_GROOVE_DEPTH + 2 * EPS,
                        z = MAL_Z_RECESS_BK - EPS);
    // Inner half-annulus at R = ORING_INNER_R, x ≤ 0
    annular_sector_xneg(ORING_INNER_R - half,
                        ORING_INNER_R + half,
                        ORING_GROOVE_DEPTH + 2 * EPS,
                        z = MAL_Z_RECESS_BK - EPS);
    // End straights at θ=90° (Y=+) and θ=270° (Y=-), X spanning [-OUTER, -INNER]
    for (sign = [-1, +1])
        translate([-(ORING_OUTER_R + half),
                   sign * ORING_INNER_R - half,
                   MAL_Z_RECESS_BK - EPS])
            cube([ORING_OUTER_R - ORING_INNER_R + gw,
                  gw,
                  ORING_GROOVE_DEPTH + 2 * EPS]);
}

// =====================================================================
//  Motor cut-out at θ=180° — rectangular hole from plate-back through
//  to disc-recess so the pinion can mesh with disc teeth.
// =====================================================================
module mal_motor_cutout() {
    translate([MAL_MOTOR_CUTOUT_X_CTR - MAL_MOTOR_CUTOUT_X / 2,
               MAL_MOTOR_CUTOUT_Y_CTR - MAL_MOTOR_CUTOUT_Y / 2,
               MAL_Z_BACK - 1])
        cube([MAL_MOTOR_CUTOUT_X,
              MAL_MOTOR_CUTOUT_Y,
              MAL_PLATE_THICKNESS + 2]);
}

// =====================================================================
//  Motor shaft bore — Ø 7 through plate at pinion centre.
//  Used both as a bore through the plate-back (for shaft) and as the
//  pinion's centre-line reference.
// =====================================================================
module mal_shaft_bore() {
    translate([PINION_CENTRE_X, 0, MAL_Z_BACK - 1])
        cylinder(d = MOTOR_SHAFT_BORE_DIA,
                 h = MAL_PLATE_THICKNESS + 2);
}

// =====================================================================
//  Hose nipple — Ø 12 OD × 30 mm long, sticks out plate-back at chamber
//  midpoint (-42, 0, plate-back). Bored through Ø 8 to chamber cavity.
// =====================================================================
module mal_hose_nipple() {
    translate([MAL_NIPPLE_X, MAL_NIPPLE_Y, MAL_Z_BACK - MAL_NIPPLE_LENGTH])
        difference() {
            cylinder(d = MAL_NIPPLE_OD, h = MAL_NIPPLE_LENGTH + EPS);
            translate([0, 0, -1])
                cylinder(d = MAL_NIPPLE_ID, h = MAL_NIPPLE_LENGTH + 2);
        }
}

module mal_hose_nipple_bore() {
    // Bore through plate-back wall to connect nipple to chamber cavity.
    translate([MAL_NIPPLE_X, MAL_NIPPLE_Y, MAL_Z_BACK - 1])
        cylinder(d = MAL_NIPPLE_ID,
                 h = MAL_CHAMBER_BACK_WALL + 2);
}

// =====================================================================
//  Lid retention clips (v5.8.5) — 4 cylindrical posts on plate-front,
//  each with an M3 clearance bore. Operator screws lid through these.
// =====================================================================
module mal_clips() {
    for (theta = MAL_CLIP_ANGLES)
        rotate([0, 0, theta])
            translate([MAL_CLIP_R, 0, MAL_Z_FRONT - EPS])
                difference() {
                    cylinder(d = MAL_CLIP_OD, h = MAL_CLIP_HEIGHT);
                    translate([0, 0, -1])
                        cylinder(d = MAL_CLIP_BORE,
                                 h = MAL_CLIP_HEIGHT + 2);
                }
}

// =====================================================================
//  Mal-plate complete (pre-tilt).
// =====================================================================
module mal_plate_pretilt() {
    union() {
        difference() {
            mal_plate_solid();
            mal_disc_recess();
            mal_chamber_cavity();
            oring_groove_path();
            mal_motor_cutout();
            mal_shaft_bore();
            mal_hose_nipple_bore();
        }
        mal_hose_nipple();
        mal_clips();
    }
}

module mal_plate() {
    rotate([DISC_TILT_DEG, 0, 0]) mal_plate_pretilt();
}

// =====================================================================
//  Drive pinion — 20T, module 1.5, simplified trapezoidal teeth (matches
//  the disc's trapezoid scheme rather than involute for visual coherence).
// =====================================================================
module pinion_pretilt() {
    pitch_deg  = 360 / PINION_TEETH;        // 18°
    base_frac  = 0.55;
    tip_frac   = 0.30;
    r_pitch    = PINION_PITCH_R;
    r_tip      = PINION_OD / 2;
    bw = pitch_deg * base_frac;
    tw = pitch_deg * tip_frac;
    translate([PINION_CENTRE_X, 0, -PINION_THICKNESS / 2])
        difference() {
            union() {
                cylinder(r = r_pitch, h = PINION_THICKNESS);
                for (i = [0 : PINION_TEETH - 1])
                    rotate([0, 0, i * pitch_deg])
                        linear_extrude(height = PINION_THICKNESS)
                            polygon([
                                [r_pitch * cos(-bw/2), r_pitch * sin(-bw/2)],
                                [r_pitch * cos(+bw/2), r_pitch * sin(+bw/2)],
                                [r_tip   * cos(+tw/2), r_tip   * sin(+tw/2)],
                                [r_tip   * cos(-tw/2), r_tip   * sin(-tw/2)],
                            ]);
            }
            // Bore for motor shaft
            translate([0, 0, -1])
                cylinder(d = PINION_BORE, h = PINION_THICKNESS + 2);
        }
}

module pinion() {
    rotate([DISC_TILT_DEG, 0, 0]) pinion_pretilt();
}

// =====================================================================
//  Motor body (visual placeholder) — NEMA17 box behind plate-back.
//  Body face flush against plate-back face; body extends along -Z (away
//  from disc); shaft is implicit (rendered as the pinion body up to plate).
// =====================================================================
module motor_pretilt() {
    translate([PINION_CENTRE_X - MOTOR_BODY_SIZE / 2,
               -MOTOR_BODY_SIZE / 2,
               MAL_Z_BACK - MOTOR_BODY_LENGTH])
        cube([MOTOR_BODY_SIZE, MOTOR_BODY_SIZE, MOTOR_BODY_LENGTH]);
}

module motor() {
    rotate([DISC_TILT_DEG, 0, 0]) motor_pretilt();
}

// =====================================================================
//  Main render
// =====================================================================
if (EXPORT_MODE) {
    if      (EXPORT_PART == "mal_plate")  mal_plate();
    else if (EXPORT_PART == "pinion")     pinion();
    else if (EXPORT_PART == "motor")      motor();
    else if (EXPORT_PART == "disc")       disc();
    else if (EXPORT_PART == "afstrijker") afstrijker();
    else if (EXPORT_PART == "afstrijker2") afstrijker2();
    else if (EXPORT_PART == "geleider")   geleider();
    else if (EXPORT_PART == "drop_tube")  drop_tube();
    else {
        // "all" — combined STL with every Phase 1-3 + 6 part for inspection.
        disc();
        afstrijker();
        afstrijker2();
        geleider();
        drop_tube();
        mal_plate();
        pinion();
        motor();
    }
} else {
    cross_section_x(ENABLE_CROSS_SECTION) {
        petg_blue() disc();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker();
        color([0.55, 0.55, 0.60, 0.85]) afstrijker2();
        color([0.65, 0.70, 0.78, 0.40]) geleider();
        color([0.70, 0.74, 0.80, 0.60]) drop_tube();
        color([0.30, 0.30, 0.32, 0.85]) mal_plate();
        color([0.40, 0.55, 0.85, 0.95]) pinion();
        color([0.65, 0.65, 0.68, 0.95]) motor();
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")     translate(PICKUP_POS)      sphere(d = 4);
        color("orange")  translate(RELEASE_POS)     sphere(d = 4);
        color("magenta") translate(AFSTRIJKER_POS)  sphere(d = 3);
        color("cyan")    translate(AFSTRIJKER2_POS) sphere(d = 3);
    }
}
