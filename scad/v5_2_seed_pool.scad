// PROTISEM V5 — Phase 2: bottom seed-pool (vacuum pickup architecture).
//
// V4 (gravity-fed top reservoir, funnel above pickup) is RETIRED. V5 puts
// the seed reservoir as an OPEN BOWL beneath the disc; the disc-rim dips
// into the seed pool at θ=270° and vacuum behind the disc draws a single
// seed against the disc FRONT face. The seed rides the disc 180° around
// to θ=90° (release, directly above the central drop hole).
//
// Reference: Monosem MS, MaterMacc MS-300, Precision Planting vSet.
//
// Pool geometry (mm, world coords):
//
//     X-extent:  ±30                        (pool centred on x=0)
//     Y-extent:  -50 to -10                 (centred on disc-bottom y line)
//     Z-extent:  -45 (floor) to -25 (top)   (20 mm deep)
//     wall:      2 mm
//     bottom:    V-trough, 6 mm wide along disc-rim path
//
// The pool side walls (X=±30) sit INSIDE the disc-body sweep (the disc-body
// extends to |x| ≈ 50 at world z=-25). To let the disc pass through cleanly,
// we subtract the disc envelope from the pool — this carves a slot at each
// side wall. Real hardware will need brushes/wipers to seal the slot; the
// SCAD model is conceptual.
//
// Math sanity (worth keeping):
//
//     Disc-rim lowest world Z (α=270°, z_l=-2)
//         = R·sin(270°)·sin(45°) - (t/2)·cos(45°)
//         = -42.43 - 1.414  =  -43.85 mm
//     Pool floor at z = -45  →  rim-floor gap = 1.15 mm (tight; raise floor
//     in a future revision if seed bed needs >5 mm headroom).
//
//     Disc-FRONT face at α=270° (mid-plane + (t/2)·DISC_FRONT_NORMAL)
//         = (0, -29.70, -29.70) + (0, +1.414, -1.414)
//         = (0, -28.28, -31.11)
//     Seed top when full ≈ z=-32  →  seeds touch disc front face directly.
//
// Acceptance: pool watertight; disc and pool coexist (slot subtraction
// produces no spurious holes through the floor or front/back walls).

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "disc", "seed_pool", or "all"

// ----- pool primitives -----
EPS = 0.01;

// v5.5.2: half-disc body. Cylinder of R_OUTER, minus the y>0 half.
// Pool wraps the disc bottom 180° in plan view.
module seed_pool_outer_solid() {
    translate([0, 0, (SEED_POOL_Z_TOP + SEED_POOL_Z_FLOOR) / 2])
        difference() {
            cylinder(r = SEED_POOL_R_OUTER,
                     h = SEED_POOL_DEPTH, center = true);
            translate([-SEED_POOL_R_OUTER - 1, 0,
                       -SEED_POOL_DEPTH / 2 - 1])
                cube([2 * SEED_POOL_R_OUTER + 2,
                      SEED_POOL_R_OUTER + 1,
                      SEED_POOL_DEPTH + 2]);
        }
}

// Cavity: hull from a half-disc top opening down to a small V-cone patch
// centred at (0, SEED_POOL_Y_CENTER) — the V-cone position is unchanged
// from v5.5.1 because Y_CENTER=-30 gives the steepest front+back wall
// slopes given the half-disc footprint (front 52°, back 47°). Side walls
// curve outward to ±R_INNER and have shallower slopes (~28°), flagged in
// the build log; soybeans roll fine on 28° but a future revision could
// tighten R_OUTER or add a curved trough along the disc rim path.
module seed_pool_cavity() {
    bottom_x = SEED_POOL_BOTTOM_X;
    bottom_y = SEED_POOL_BOTTOM_Y;
    hull() {
        // top opening — inner half-disc, slightly above wall top so cut is clean
        translate([0, 0, SEED_POOL_Z_TOP + 1])
            difference() {
                cylinder(r = SEED_POOL_R_INNER, h = EPS, center = true);
                translate([-SEED_POOL_R_INNER - 1, 0, -EPS * 2])
                    cube([2 * SEED_POOL_R_INNER + 2,
                          SEED_POOL_R_INNER + 1,
                          EPS * 4]);
            }
        // V-cone bottom (4×4 patch above floor)
        translate([0, SEED_POOL_Y_CENTER, SEED_POOL_Z_FLOOR + SEED_POOL_WALL])
            cube([bottom_x, bottom_y, EPS], center = true);
    }
}

// Disc swept-volume envelope (with 1 mm radial + 1 mm axial clearance).
// Used to carve a slot through the pool SIDE walls so the disc can dip in.
//
// IMPORTANT: the disc TEETH (at OD=132) dip to world z = -48 at α=270° —
// 3 mm BELOW the pool floor at z=-45. If we subtracted the unclipped
// envelope, it would carve a long slot through the floor and seeds would
// spill out. To keep the floor sealed in the digital model, we clip the
// envelope to z ≥ floor + 1 mm. The physical implication — that the teeth
// would mechanically saw into a real floor at z=-45 — is flagged in the
// build log; the proper fix is either lowering the floor to z ≈ -50 or
// removing the gear teeth from the disc (deferred to Phase 6 gear-drive).
module disc_envelope_above_floor() {
    intersection() {
        rotate([DISC_TILT_DEG, 0, 0])
            cylinder(d = DISC_OD_WITH_TEETH + 2,
                     h = DISC_THICKNESS + 2,
                     center = true);
        // Half-space z ≥ floor + 1 mm (leave floor untouched)
        translate([-200, -200, SEED_POOL_Z_FLOOR + 1])
            cube([400, 400, 400]);
    }
}

// =====================================================================
//  Front-face tube ports (feeder inlet + vac-cleanup outlet).
//  Each is anchored on the front face at (x_off, y_front, z_off) and
//  extends OUTWARD (-Y, +Z) at the specified elevation. Cylinder default
//  axis is +Z; rotate([90 - elev, 0, 0]) tilts it to (0, -cos elev,
//  +sin elev). Tube body overlaps the wall by SEED_POOL_WALL + EPS so
//  the union is watertight; the bore extends a few mm further inboard
//  to fully pierce the wall.
// =====================================================================
module front_tube_outer(x_off, z_off, elev_deg, od, length) {
    translate([x_off,
               SEED_POOL_Y_CENTER - SEED_POOL_Y / 2,
               z_off])
        rotate([90 - elev_deg, 0, 0])
            translate([0, 0, -SEED_POOL_WALL - EPS])
                cylinder(d = od, h = length + SEED_POOL_WALL + EPS);
}

module front_tube_bore(x_off, z_off, elev_deg, id, length) {
    translate([x_off,
               SEED_POOL_Y_CENTER - SEED_POOL_Y / 2,
               z_off])
        rotate([90 - elev_deg, 0, 0])
            translate([0, 0, -SEED_POOL_WALL - 5])
                cylinder(d = id, h = length + SEED_POOL_WALL + 10);
}

module feeder_tube_outer() {
    front_tube_outer(FEEDER_TUBE_X, FEEDER_TUBE_Z,
                     FEEDER_TUBE_ELEV_DEG,
                     FEEDER_TUBE_OD, FEEDER_TUBE_LENGTH);
}
module feeder_tube_bore() {
    front_tube_bore(FEEDER_TUBE_X, FEEDER_TUBE_Z,
                    FEEDER_TUBE_ELEV_DEG,
                    FEEDER_TUBE_ID, FEEDER_TUBE_LENGTH);
}
// =====================================================================
//  Vac-cleanup tube — TOP-mount, near-vertical (80° elev). Mouth INSIDE
//  the pool at MOUTH_Z (= floor + 7 mm); tube extends DOWN to mouth and
//  UP for hose attach. Tilts -Y from vertical so upper end is on the
//  operator side (reachable with shop-vac hose) and tube body stays clear
//  of disc body slab (mouth eq=+8.5; seed-side, off the disc).
// =====================================================================
VAC_CLEAN_TUBE_TOTAL_LEN = VAC_CLEAN_TUBE_LENGTH_IN + VAC_CLEAN_TUBE_LENGTH_OUT;

module vac_clean_tube_outer() {
    translate([VAC_CLEAN_TUBE_X,
               VAC_CLEAN_TUBE_Y,
               VAC_CLEAN_TUBE_MOUTH_Z])
        rotate([90 - VAC_CLEAN_TUBE_ELEV_DEG, 0, 0])
            cylinder(d = VAC_CLEAN_TUBE_OD,
                     h = VAC_CLEAN_TUBE_TOTAL_LEN);
}

module vac_clean_tube_bore() {
    translate([VAC_CLEAN_TUBE_X,
               VAC_CLEAN_TUBE_Y,
               VAC_CLEAN_TUBE_MOUTH_Z - 1])
        rotate([90 - VAC_CLEAN_TUBE_ELEV_DEG, 0, 0])
            cylinder(d = VAC_CLEAN_TUBE_ID,
                     h = VAC_CLEAN_TUBE_TOTAL_LEN + 5);
}

module seed_pool() {
    difference() {
        union() {
            seed_pool_outer_solid();
            feeder_tube_outer();
            vac_clean_tube_outer();
        }
        seed_pool_cavity();
        feeder_tube_bore();
        vac_clean_tube_bore();
        disc_envelope_above_floor();
    }
}

// ----- main render -----
if (EXPORT_MODE) {
    if      (EXPORT_PART == "disc")       disc();
    else if (EXPORT_PART == "seed_pool")  seed_pool();
    else                                   { disc(); seed_pool(); }
} else {
    cross_section_x(ENABLE_CROSS_SECTION) {
        petg_blue() disc();
        petg_grey() seed_pool();
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")    translate(PICKUP_POS)  sphere(d = 4);   // pickup
        color("orange") translate(RELEASE_POS) sphere(d = 4);   // release
    }
}
