// PROTISEM V5 — Phase 4: vacuum chamber (back of disc) + hose nipple.
//
// Why this part exists. The V5 vacuum-pickup architecture (D6) needs a
// physical chamber on the disc-BACK face to hold the suction. Without it,
// the vacuum has no enclosure — pickup-holes inside the chamber sector
// experience suction; holes outside it do not. The chamber's angular
// extent therefore defines WHERE on the disc rim a seed gets picked up
// and HOW LONG it stays attached:
//
//   sector start (θ=90°, world (0, +29.7, +29.7))   ← release point
//   sector end   (θ=270°, world (0, -29.7, -29.7))  ← pickup point
//   passing through θ=180° (world (-42, 0, 0))      ← back-arc of disc
//
// In disc-LOCAL angles the chamber covers [90°, 270°]; in world space, with
// disc tilted 45° around X, that maps to the half of the pickup-hole circle
// where x_world ≤ 0. The disc rotates THROUGH this fixed (housing-mounted)
// chamber — a hole becomes "active" when its current world x ≤ 0.
//
// Geometry (mm, all in disc-local frame before tilt):
//
//   - Annular sector body, R_in=30 .. R_out=50 (pickup-hole circle R=42 sits
//     inside this band), depth = 8 along +Z (back-normal direction).
//   - Hollow shell with 2 mm walls — outer cylinder, inner cylinder, back
//     plate, two end-walls at the sector's angular boundaries.
//   - Open against disc-back face (the disc itself forms the front cover).
//   - Hose nipple Ø12 × 30 mm at the centre of the arc (θ=180°, R=40),
//     pointing along +Z (out the back).
//
// After the SCAD `rotate([45, 0, 0])` is applied, the chamber sits behind
// the disc (in -Y, +Z direction relative to the disc plane). The nipple's
// far end ends up around world (-40, -25.5, +25.5).
//
// Sealing rings: the user-facing "O-ring grooves at R=30 and R=50" are
// implicit in this geometry — the chamber's outer and inner cylindrical
// walls meet the disc back face along those exact radii, providing the
// rotating-seal interface. Real hardware will need PTFE/rubber rings;
// here we just leave the wall edge at the disc surface.

include <lib/parameters.scad>;
use     <lib/helpers.scad>;
use     <v4_1_disc.scad>;
use     <v5_2_seed_pool.scad>;
use     <v5_3_barriere_geleider.scad>;

// ----- customizer flags -----
ENABLE_CROSS_SECTION = false;
EXPORT_MODE          = false;
EXPORT_PART          = "all";   // "vacuum_chamber" | "all" | sub-parts

EPS = 0.01;

// =====================================================================
//  Half-space x ≤ x_max — used to clip annular shapes into a sector.
//  Sector covers [90°, 270°] which is the x ≤ 0 half-plane in disc-local.
// =====================================================================
module sector_halfspace(x_max = 0) {
    translate([-1000 + x_max, -500, -500])
        cube([1000, 1000, 1000]);
}

// =====================================================================
//  Annular sector solid: R_in..R_out, height h, sector x ≤ x_max.
// =====================================================================
module annular_sector(r_in, r_out, h, x_max = 0) {
    intersection() {
        difference() {
            cylinder(r = r_out, h = h);
            translate([0, 0, -1]) cylinder(r = r_in, h = h + 2);
        }
        sector_halfspace(x_max);
    }
}

// =====================================================================
//  Vacuum chamber (pre-tilt frame). Hollow shell sealed by:
//      outer cylinder wall (at R_out)
//      inner cylinder wall (at R_in)
//      back plate (at z = DISC_THICKNESS/2 + DEPTH)
//      end walls at the sector boundaries (at x = 0)
//  Open on the disc side (z = DISC_THICKNESS/2) — the disc back face is
//  the front cover.
// =====================================================================
module vacuum_chamber_pretilt() {
    R_in  = VAC_CHAMBER_R_IN;
    R_out = VAC_CHAMBER_R_OUT;
    DEPTH = VAC_CHAMBER_DEPTH;
    WALL  = VAC_CHAMBER_WALL;

    // Sit chamber on disc-back face — z=DISC_THICKNESS/2 is disc back in
    // pre-tilt. Slight inset (-0.01) avoids zero-volume interface artefacts.
    translate([0, 0, DISC_THICKNESS / 2 - EPS]) {
        difference() {
            // Outer shell: full annular sector (R_in..R_out, depth DEPTH,
            // sector x ≤ 0).
            annular_sector(R_in, R_out, DEPTH, x_max = 0);

            // Cavity: smaller annular sector inset by WALL on every face.
            // Radii inset by WALL (so cavity is R_in+WALL .. R_out-WALL).
            // Sector inset by WALL in +X direction (so end walls at the
            // angular boundary, x=0, are filled — the cavity sits in
            // x ≤ -WALL). Z range from disc-side bottom +EPS upward to
            // DEPTH-WALL (so back plate is filled at top).
            translate([0, 0, -EPS])
                annular_sector(R_in + WALL,
                               R_out - WALL,
                               DEPTH - WALL + EPS,
                               x_max = -WALL);
        }

        // Nipple: Ø12 cylinder at sector centre (θ=180°, R=40),
        // pointing +Z (extends out the back), 30 mm long.
        nipple_x = -(R_in + R_out) / 2;
        translate([nipple_x, 0, DEPTH - EPS])
            cylinder(d = VAC_NIPPLE_DIA, h = VAC_NIPPLE_LENGTH);
    }
}

module vacuum_chamber() {
    rotate([DISC_TILT_DEG, 0, 0]) vacuum_chamber_pretilt();
}

// =====================================================================
//  Main render. Default: full V5 assembly with the new chamber.
// =====================================================================
if (EXPORT_MODE) {
    if      (EXPORT_PART == "vacuum_chamber") vacuum_chamber();
    else if (EXPORT_PART == "disc")           disc();
    else if (EXPORT_PART == "seed_pool")      seed_pool();
    else if (EXPORT_PART == "afstrijker")     afstrijker();
    else if (EXPORT_PART == "afstrijker2")    afstrijker2();
    else if (EXPORT_PART == "geleider")       geleider();
    else if (EXPORT_PART == "drop_tube")      drop_tube();
    else {
        // "all" — combined STL with every Phase-1..4 part for inspection.
        disc();
        seed_pool();
        afstrijker();
        afstrijker2();
        geleider();
        drop_tube();
        vacuum_chamber();
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
    }
    if (!ENABLE_CROSS_SECTION) {
        color("red")     translate(PICKUP_POS)      sphere(d = 4);
        color("orange")  translate(RELEASE_POS)     sphere(d = 4);
        color("magenta") translate(AFSTRIJKER_POS)  sphere(d = 3);
        color("cyan")    translate(AFSTRIJKER2_POS) sphere(d = 3);
    }
}
