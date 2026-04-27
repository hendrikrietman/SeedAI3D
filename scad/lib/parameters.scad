// PROTISEM V4 — central parameter file
// All dimensions in millimeters, all angles in degrees.
// Edit values here only. Never hardcode dimensions in geometry files.

// ==========================================================================
// DISC GEOMETRY
// ==========================================================================
DISC_OD              = 120;   // outer diameter excluding tooth tips
DISC_OD_WITH_TEETH   = 132;   // outer diameter including tooth tips
DISC_THICKNESS       = 4;     // disc thickness, perpendicular to disc plane
CENTRAL_HOLE_DIA     = 50;    // central seed-drop hole

// ==========================================================================
// PICKUP HOLES
// ==========================================================================
PICKUP_HOLE_COUNT    = 40;
PICKUP_HOLE_RADIUS   = 42;    // radial distance from disc centre
PICKUP_HOLE_DIA      = 2.5;

// ==========================================================================
// TEETH (rim of disc, engages 20-tooth pinion in Phase 6)
// ==========================================================================
TOOTH_COUNT          = 60;
TOOTH_MODULUS        = 1.5;
TOOTH_RADIAL_HEIGHT  = (DISC_OD_WITH_TEETH - DISC_OD) / 2;   // = 6 mm
TOOTH_BASE_FRACTION  = 0.55;   // tooth base width as fraction of pitch
TOOTH_TIP_FRACTION   = 0.30;   // tooth tip  width as fraction of pitch (trapezoid)

// ==========================================================================
// ORIENTATION
// --------------------------------------------------------------------------
// The CLAUDE.md spec lists pickup-zone = (0, 29.7, 29.7). That puts the
// high point of the disc on the +Y, +Z side of the world, which is only
// reachable if we tilt the disc around the WORLD X-AXIS (not Y as a naive
// reader of "disc-normal = (sin45°,0,cos45°)" might assume).
// We honour the pickup-zone coordinate -- it is the more specific and
// testable spec. See docs/decisions.md for the full rationale.
// ==========================================================================
DISC_TILT_DEG        = 45;     // rotate([DISC_TILT_DEG, 0, 0])

// Derived disc-frame vectors (after tilt)
DISC_NORMAL          = [0, -sin(DISC_TILT_DEG), cos(DISC_TILT_DEG)];
PICKUP_POS           = [0,
                        PICKUP_HOLE_RADIUS * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(DISC_TILT_DEG)];
RELEASE_POS          = [0,
                        -PICKUP_HOLE_RADIUS * cos(DISC_TILT_DEG),
                        -PICKUP_HOLE_RADIUS * sin(DISC_TILT_DEG)];

// ==========================================================================
// HOUSING (used in later phases, declared here for reference)
// ==========================================================================
HOUSING_X            = 180;
HOUSING_Y            = 180;
HOUSING_Z            = 60;
HOUSING_WALL         = 3;

// ==========================================================================
// RENDER QUALITY
// ==========================================================================
$fn = 64;
