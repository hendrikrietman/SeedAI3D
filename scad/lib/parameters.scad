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

// Disc-local angle θ for pickup and release. Per the V4 drawing
// ("Vooraanzicht schijf" detail panel), pickup and release sit symmetrically
// around the top of the disc (θ=90°), both at HIGH world-Z. The seed travels
// the LONG way around (~320° CCW) along the outer rim: pickup → bottom → release.
// World coords on pickup-hole circle for any θ:
//   x = R·cos(θ)
//   y = R·sin(θ)·cos(tilt)
//   z = R·sin(θ)·sin(tilt)
// See docs/decisions.md D5 for the correction history.
PICKUP_THETA_DEG     = 110;    // pickup, left of top
RELEASE_THETA_DEG    =  70;    // release, right of top (symmetric)

PICKUP_POS           = [PICKUP_HOLE_RADIUS * cos(PICKUP_THETA_DEG),
                        PICKUP_HOLE_RADIUS * sin(PICKUP_THETA_DEG) * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(PICKUP_THETA_DEG) * sin(DISC_TILT_DEG)];
RELEASE_POS          = [PICKUP_HOLE_RADIUS * cos(RELEASE_THETA_DEG),
                        PICKUP_HOLE_RADIUS * sin(RELEASE_THETA_DEG) * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(RELEASE_THETA_DEG) * sin(DISC_TILT_DEG)];

// Disc TOP surface above PICKUP_POS = mid-plane offset by (t/2) along normal.
PICKUP_TOP_POS       = [PICKUP_POS[0],
                        PICKUP_POS[1] + DISC_THICKNESS/2 * DISC_NORMAL[1],
                        PICKUP_POS[2] + DISC_THICKNESS/2 * DISC_NORMAL[2]];

// Disc TOP surface plane equation in world coords (within disc extent):
//     z = y + DISC_TOP_Z_OFFSET
// Derivation: pre-tilt top at z=+t/2 maps under rotate([45,0,0]) to
//     y_w = -t/2 · sin(tilt),   z_w = +t/2 · cos(tilt)
// hence z_w - y_w = t·cos(tilt). For t=4, tilt=45° → 2.828 mm.
DISC_TOP_Z_OFFSET    = DISC_THICKNESS * cos(DISC_TILT_DEG);

// ==========================================================================
// RESERVOIR (Phase 2)
// ==========================================================================
RESERVOIR_TOP_X      = 60;   // top opening, X
RESERVOIR_TOP_Y      = 60;   // top opening, Y
RESERVOIR_OUTLET_DIA = 12;
RESERVOIR_HEIGHT     = 80;
RESERVOIR_WALL       = 2;

// Vertical clearance from outlet bottom to the disc-mid PICKUP_POS,
// directly above the pickup hole. Spec range 5–8 mm; 7.1 mm puts the
// outlet bottom at world z = 35.0. With the offset pickup (θ=110°),
// the +Y rim of a Ø16 outer reservoir wall still clips the disc body —
// see docs/decisions.md D4 for the trade-off and proposed mitigations.
RESERVOIR_OUTLET_CLEARANCE = 7.1;
RESERVOIR_OUTLET_POS = [PICKUP_POS[0],
                        PICKUP_POS[1],
                        PICKUP_POS[2] + RESERVOIR_OUTLET_CLEARANCE];

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
