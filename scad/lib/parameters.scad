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
// Tilt around WORLD X-AXIS (rotate([45,0,0])) — disc-normal = (0,-sin45°,cos45°).
// See docs/decisions.md D1 for the rationale.
// ==========================================================================
DISC_TILT_DEG        = 45;     // rotate([DISC_TILT_DEG, 0, 0])
DISC_NORMAL          = [0, -sin(DISC_TILT_DEG), cos(DISC_TILT_DEG)];

// V5 architecture (vacuum pickup from bottom seed-pool).
// Pickup at θ=270° (LOWEST point on pickup circle) — disc dips into seed pool.
// Release at θ=90° (HIGHEST point) — directly above central drop hole.
// Seed travels 180° along the disc rim from pickup → release.
// World coords on pickup-hole circle for any θ:
//   x = R·cos(θ),  y = R·sin(θ)·cos(tilt),  z = R·sin(θ)·sin(tilt)
// See docs/decisions.md D6 for the V4→V5 architecture switch.
PICKUP_THETA_DEG     = 270;    // disc onderkant, dompelt in zaad-pool
RELEASE_THETA_DEG    =  90;    // disc bovenkant, recht boven centraal gat

PICKUP_POS           = [PICKUP_HOLE_RADIUS * cos(PICKUP_THETA_DEG),
                        PICKUP_HOLE_RADIUS * sin(PICKUP_THETA_DEG) * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(PICKUP_THETA_DEG) * sin(DISC_TILT_DEG)];
RELEASE_POS          = [PICKUP_HOLE_RADIUS * cos(RELEASE_THETA_DEG),
                        PICKUP_HOLE_RADIUS * sin(RELEASE_THETA_DEG) * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(RELEASE_THETA_DEG) * sin(DISC_TILT_DEG)];

// Disc FRONT face (the face whose normal has +Y component — seeds press
// against this face from the pool). Front-normal = -DISC_NORMAL.
DISC_FRONT_NORMAL    = [0, sin(DISC_TILT_DEG), -cos(DISC_TILT_DEG)];

// Disc TOP surface plane equation in world coords (within disc extent):
//     z = y + DISC_TOP_Z_OFFSET
// Derivation: pre-tilt top at z=+t/2 maps under rotate([45,0,0]) to
//     y_w = -t/2 · sin(tilt),   z_w = +t/2 · cos(tilt)
// hence z_w - y_w = t·cos(tilt). For t=4, tilt=45° → 2.828 mm.
DISC_TOP_Z_OFFSET    = DISC_THICKNESS * cos(DISC_TILT_DEG);

// ==========================================================================
// SEED POOL (Phase 2 V5) — open bowl at bottom of housing; disc dips in.
// ==========================================================================
SEED_POOL_X          = 60;     // pool footprint, X
SEED_POOL_Y          = 40;     // pool footprint, Y (front-back)
SEED_POOL_DEPTH      = 20;     // pool height, Z
SEED_POOL_Z_TOP      = -25;    // top of pool walls (just below disc-mid bottom @ -29.7)
SEED_POOL_Z_FLOOR    = SEED_POOL_Z_TOP - SEED_POOL_DEPTH;   // = -45
SEED_POOL_Y_CENTER   = -30;    // pool centred along disc-bottom Y line
SEED_POOL_WALL       = 2;
SEED_POOL_FILL_Z     = -32;    // approximate seed top when full (~12 mm bed)
// Bottom-strip width: V-shape narrows in X to gather seeds along the disc-rim
// dip line — like a Monosem V-trough.
SEED_POOL_BOTTOM_X   = 6;

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
