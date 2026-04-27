// PROTISEM V4 — shared helpers
// Cross-section cuts, materials, debug markers.

// Cuts away the +Y half of children. Useful for revealing the disc cross
// section, since the disc tilts around X and so its principal section is
// the YZ plane.
module cross_section_y(enable=true) {
    if (enable) {
        difference() {
            children();
            translate([-1000, 0, -1000]) cube([2000, 2000, 2000]);
        }
    } else {
        children();
    }
}

// Cuts away the +X half (alternate view).
module cross_section_x(enable=true) {
    if (enable) {
        difference() {
            children();
            translate([0, -1000, -1000]) cube([2000, 2000, 2000]);
        }
    } else {
        children();
    }
}

// PETG translucent blue — used for printed plastic parts
module petg_blue() {
    color([0.40, 0.60, 0.85, 0.95]) children();
}

// PETG translucent grey — housing
module petg_grey() {
    color([0.75, 0.78, 0.82, 0.35]) children();
}

// Steel — bearings, shafts
module steel() {
    color([0.78, 0.80, 0.82, 1.0]) children();
}

// Small marker sphere (debug)
module marker(pos, d=3, c="red") {
    color(c) translate(pos) sphere(d=d);
}
