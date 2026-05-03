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
//  Generalised angular wedge / annular sector  (D14 — dual-sector chamber)
//  Implemented as the intersection of two half-spaces (each modelled by
//  a large translated+rotated cube). Avoids the apex-degenerate vertex
//  that a polygon-pie-slice creates at the origin, which caused the
//  CGAL output to be non-manifold.
//  Caller must supply theta_end > theta_start with range < 180°.
// =====================================================================
module wedge_3d(theta_start, theta_end, h, z) {
    L = 1000;
    intersection() {
        // Half-space whose kept-region angular range is [theta_start, theta_start+180°]
        rotate([0, 0, theta_start + 90])
            translate([0, -L, z - 1])
                cube([L, 2 * L, h + 2]);
        // Half-space whose kept-region angular range is [theta_end-180°, theta_end]
        rotate([0, 0, theta_end - 90])
            translate([0, -L, z - 1])
                cube([L, 2 * L, h + 2]);
    }
}

module annular_sector(r_in, r_out, h, theta_start, theta_end, z) {
    intersection() {
        translate([0, 0, z])
            difference() {
                cylinder(r = r_out, h = h);
                translate([0, 0, -1]) cylinder(r = r_in, h = h + 2);
            }
        wedge_3d(theta_start, theta_end, h, z);
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
//  Combined chamber cavity (D14): single 180° annular sector spanning
//  θ ∈ [SECTOR_BLOW_THETA_START, SECTOR_VACUUM_THETA_END] = [90°, 270°]
//  (= the full -X half, same footprint as pre-D14). The two sub-sectors
//  emerge as a CONSEQUENCE of the partition wall added inside this
//  cavity (see mal_partition_wall): air can't cross the partition,
//  so the [90°,110°] portion functions as the blow sub-sector and
//  the [110°,270°] portion as the vacuum sub-sector. This single
//  cavity boolean is more robust than subtracting two adjacent
//  sub-sectors (which leaves a non-manifold zero-thickness edge at
//  θ=110°).
// =====================================================================
module mal_chamber_cavity() {
    // Full chamber spans θ ∈ [90°, 270°] = the entire -X half-plane,
    // so use the original annular_sector_xneg helper for backward-compat
    // robustness (the generalised annular_sector helper produces an
    // identical but slightly noisier mesh due to wedge intersections).
    annular_sector_xneg(MAL_CHAMBER_R_IN, MAL_CHAMBER_R_OUT,
                        MAL_CHAMBER_DEPTH + EPS,
                        z = MAL_Z_CHAMBER_BK);
}

// =====================================================================
//  Partition wall (D14): radial slab at θ=PARTITION_THETA, between the
//  vacuum and blow sub-sectors. Thickness PARTITION_WALL_T (tangential),
//  radial extent slightly larger than chamber radii to seal the ends,
//  height = chamber depth + PARTITION_WALL_OVERSIZE so the top
//  protrudes past the chamber-front-wall and leaves a 0.1 mm gap to
//  the disc-back. NOT a cavity — this is solid plate material that
//  the cavity boolean leaves in place. Implemented as a positive
//  feature added back in `mal_plate_pretilt`.
// =====================================================================
module mal_partition_wall() {
    // Extend the partition's bottom 0.5 mm INTO the plate-back wall
    // material (Z < MAL_Z_CHAMBER_BK) to avoid a T-junction at the
    // chamber-bottom plane Z=MAL_Z_CHAMBER_BK where the partition's
    // bottom face would otherwise coincide with the chamber-bottom face.
    rotate([0, 0, PARTITION_THETA])
        translate([MAL_CHAMBER_R_IN - 0.5,
                   -PARTITION_WALL_T / 2,
                   MAL_Z_CHAMBER_BK - 0.5])
            cube([(MAL_CHAMBER_R_OUT - MAL_CHAMBER_R_IN) + 1.0,
                  PARTITION_WALL_T,
                  MAL_CHAMBER_DEPTH + PARTITION_WALL_OVERSIZE + 0.5]);
}

// =====================================================================
//  O-ring groove on the disc-side face of the recess-back-wall.
//  Per-sub-sector closed-loop racetrack groove: outer arc + inner arc +
//  2 radial end-caps. Each sub-sector seals independently against the
//  disc-back, isolating its pressure zone (D14).
// =====================================================================
module oring_groove_for_sector(theta_start, theta_end) {
    gw   = ORING_GROOVE_WIDTH;
    half = gw / 2;
    // Outer arc at R = ORING_OUTER_R
    annular_sector(ORING_OUTER_R - half,
                   ORING_OUTER_R + half,
                   ORING_GROOVE_DEPTH + 2 * EPS,
                   theta_start, theta_end,
                   z = MAL_Z_RECESS_BK - EPS);
    // Inner arc at R = ORING_INNER_R
    annular_sector(ORING_INNER_R - half,
                   ORING_INNER_R + half,
                   ORING_GROOVE_DEPTH + 2 * EPS,
                   theta_start, theta_end,
                   z = MAL_Z_RECESS_BK - EPS);
    // Two radial end-caps: each is a cube sized to span R ∈ [INNER-half,
    // OUTER+half] radially, gw tangentially, depth in Z. Built in disc-local
    // frame and rotated to the sector boundary.
    for (theta = [theta_start, theta_end])
        rotate([0, 0, theta])
            translate([ORING_INNER_R - half,
                       -gw / 2,
                       MAL_Z_RECESS_BK - EPS])
                cube([(ORING_OUTER_R - ORING_INNER_R) + gw,
                      gw,
                      ORING_GROOVE_DEPTH + 2 * EPS]);
}

module oring_groove_path() {
    // Two independent loops, one per sub-sector. Partition wall handles
    // sealing between sub-sectors so the cord doesn't need to cross it.
    oring_groove_for_sector(SECTOR_VACUUM_THETA_START,
                            SECTOR_VACUUM_THETA_END);
    oring_groove_for_sector(SECTOR_BLOW_THETA_START,
                            SECTOR_BLOW_THETA_END);
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
    // Restored to v5.8.5 EPS-overlap version — works in this position
    // (vacuum nipple at θ=180°) where the bore is well inside the
    // chamber's symmetry. Blow nipple uses a different approach (no
    // body in STL, see mal_blow_nipple).
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
//  Blow nipple (D14) — second hose port, on plate-back at the midangle
//  of the blow sub-sector (θ=100°, R=42). Smaller than the vacuum
//  nipple because the blow source only needs to push light seed off
//  the disc, not move bulk air.
// =====================================================================
// Blow nipple body is NOT modelled in the STL.  It's a sourced push-in
// fitting (e.g. Ø10/Ø6 PTC fitting, BOM item) that screws or press-fits
// into the bore. Modelling the body as part of the printed plate caused
// repeated CGAL non-manifold T-junctions at the body/plate-back/bore
// intersection — and the fitting needs to be a separate part anyway
// (it's not printable as one piece with the plate at FDM resolution).
// The viewer renders the fitting procedurally for visualization.
module mal_blow_nipple() {
    // Empty — placeholder so callers don't break.
}

module mal_blow_nipple_bore() {
    translate([BLOW_NIPPLE_X, BLOW_NIPPLE_Y, MAL_Z_BACK - 1])
        cylinder(d = BLOW_NIPPLE_ID,
                 h = MAL_CHAMBER_BACK_WALL + 2);
}

// =====================================================================
//  Passive bleed orifices (D14) — drilled straight through plate-back
//  wall to atmosphere. Acts as a max-pressure clamp: even with the
//  source wide open, the bleed flow caps the absolute pressure. Vacuum
//  bleed prevents disc face-loading; blow bleed prevents seed launch.
// =====================================================================
module mal_bleed_orifices() {
    translate([VAC_BLEED_X, VAC_BLEED_Y, MAL_Z_BACK - 1])
        cylinder(d = VAC_BLEED_DIA,
                 h = MAL_CHAMBER_BACK_WALL + 2);
    translate([BLOW_BLEED_X, BLOW_BLEED_Y, MAL_Z_BACK - 1])
        cylinder(d = BLOW_BLEED_DIA,
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
//  D14: chamber is two sub-sectors (vacuum + blow) separated by a
//  partition wall. Two nipples + two passive bleed orifices for
//  air-flow regulation.
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
            mal_blow_nipple_bore();
            mal_bleed_orifices();
        }
        mal_partition_wall();
        mal_hose_nipple();
        mal_blow_nipple();
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
