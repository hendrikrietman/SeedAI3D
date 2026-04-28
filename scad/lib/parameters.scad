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
PICKUP_HOLE_DIA      = 4.0;   // 4 mm hole < 6 mm soybean → seed cannot pass through

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
// SEED POOL (Phase 2 V5, raised in Phase-3 visual fix) — open bowl at bottom
// of housing; disc dips in. Pool was raised 8 mm from the original Phase-2
// values (floor -45 → -37, top -25 → -17) so the seed mass sits visually
// above the tooth-rand sweep at θ=270°. Tooth-tip interference with floor
// (D6) grows from 3 mm to ~11 mm — to be resolved alongside D6.
// ==========================================================================
SEED_POOL_X          = 60;     // pool footprint, X
SEED_POOL_Y          = 40;     // pool footprint, Y (front-back)
// Floor lowered v5.5.1: -37 → -50 (10 mm below disc-with-teeth lowest at
// world z ≈ -48.1). This resolves the long-standing `disc_above_floor`
// validation failure (teeth used to penetrate the floor by ~11 mm and were
// only "hidden" by the disc_envelope_above_floor clip). With floor at -50
// the envelope-clip zone z=floor+1=-49 sits BELOW the actual disc lowest,
// so the disc no longer reaches the floor at all.
SEED_POOL_DEPTH      = 33;     // was 20; deepened to drop floor below disc
SEED_POOL_Z_TOP      = -17;    // top of pool walls (unchanged)
SEED_POOL_Z_FLOOR    = SEED_POOL_Z_TOP - SEED_POOL_DEPTH;   // = -50
SEED_POOL_Y_CENTER   = -30;    // pool centred along disc-bottom Y line
SEED_POOL_WALL       = 2;
SEED_POOL_FILL_Z     = -24;    // approximate seed top when full
// V-cone bottom: narrows in BOTH X and Y to a small floor patch (4×4 mm)
// so seeds gravity-feed to a single lowest point centred at
// (0, SEED_POOL_Y_CENTER, SEED_POOL_Z_FLOOR). Wall slope: top→floor in X
// is atan(33/(30-2)) ≈ 50°, in Y atan(33/(20-2)) ≈ 61° — both well over
// the ≥35° spec for self-feeding.
SEED_POOL_BOTTOM_X   = 4;
SEED_POOL_BOTTOM_Y   = 4;

// v5.5.2: half-disc footprint replaces rectangular pool. The body is now a
// half-cylinder of radius R_OUTER, opening at y=0 (footprint y ≤ 0). Wraps
// the disc bottom 180° in plan view → catches seeds detaching mid-travel
// from any rim-position whose XY-projection lies in the half-disc.
// R_OUTER = 55 is sized to keep the existing tube anchors INSIDE the body:
//   feeder anchor (15, -50, -22): radius √(15²+50²)=52.2 < 55 ✓
//   vac    anchor (0, -42, -43): radius 42 < 55 ✓
SEED_POOL_R_OUTER    = 55;
SEED_POOL_R_INNER    = SEED_POOL_R_OUTER - SEED_POOL_WALL;   // = 53

// --------------------------------------------------------------------------
// FRONT-FACE TUBE PORTS (2026-04-27) — two angled fittings on the operator-
// facing front face of the pool (y = -50). One is the FEEDER inlet (operator
// pours seeds in via this tube, ~60° elevation so seeds slide down by
// gravity); the other is the VAC-CLEANUP outlet (a shop vac is plugged in
// at end-of-run to suck the compartment empty, ~45° elevation, larger bore
// to pass entrained seeds). Both extend OUTWARD (-Y, +Z) from the front
// face; bores pierce the wall so the pool cavity connects through.
// --------------------------------------------------------------------------
// Feeder tube — front-mount, 60° elevation, gravity-fed seed supply.
// Widened from OD16/ID12 to OD18/ID14 (Hendrik 2026-04-27): bigger bore
// reduces bridging risk for soybean (Ø ~6 mm).
FEEDER_TUBE_OD       = 18;
FEEDER_TUBE_ID       = 14;
FEEDER_TUBE_LENGTH   = 50;
FEEDER_TUBE_ELEV_DEG = 60;
FEEDER_TUBE_X        =  15;    // x-offset on front face
FEEDER_TUBE_Z        = -22;    // 5 mm below pool top

// Vac-cleanup tube — relocated 2026-04-27 from FRONT-mount/45° to TOP-mount
// near-vertical (80° elevation = 10° off vertical). Mouth sits INSIDE the
// pool at ~7 mm above the floor; the tube extends DOWN from the housing
// top into the pool, and UP outside for shop-vac hose. Tilts toward
// operator (-Y) so the hose connection is reachable without fouling the
// disc upper-half. Mouth offset in -Y from disc plane (eq>0 seed side)
// keeps tube body clear of the rotating disc.
VAC_CLEAN_TUBE_OD          = 26;   // matches Ø22 shop-vac hose + 2 mm wall
VAC_CLEAN_TUBE_ID          = 22;
VAC_CLEAN_TUBE_LENGTH_OUT  = 60;   // outside pool top wall, for hose attach
VAC_CLEAN_TUBE_LENGTH_IN   = 25;   // inside pool, mouth-to-top-wall span
VAC_CLEAN_TUBE_ELEV_DEG    = 80;   // from horizontal (10° off vertical)
VAC_CLEAN_TUBE_X           = 0;    // centred above pool lowest line
VAC_CLEAN_TUBE_Y           = -42;  // -Y of disc plane at z=-30 → eq=+8.5
VAC_CLEAN_TUBE_MOUTH_Z     = SEED_POOL_Z_FLOOR + 7;   // = -30, 7 mm above floor

// ==========================================================================
// AFSTRIJKER (Phase 3 V5) — singulator blade just past pickup zone.
// Strips off excess seeds that aren't securely seated in their vacuum hole.
// θ=235° puts it at the pool-exit lip (where the disc rim crosses pool top).
// ==========================================================================
AFSTRIJKER_THETA_DEG = 250;   // 20° past pickup (per Phase-3 spec)
AFSTRIJKER_POS       = [PICKUP_HOLE_RADIUS * cos(AFSTRIJKER_THETA_DEG),
                        PICKUP_HOLE_RADIUS * sin(AFSTRIJKER_THETA_DEG) * cos(DISC_TILT_DEG),
                        PICKUP_HOLE_RADIUS * sin(AFSTRIJKER_THETA_DEG) * sin(DISC_TILT_DEG)];
AFSTRIJKER_LENGTH    = 18;     // arc-length along disc rim (mm)
AFSTRIJKER_HEIGHT    = 8;      // standoff above disc face (one soybean dia + clearance)
AFSTRIJKER_THICKNESS = 2;
AFSTRIJKER_SLIP_PROB = 0.05;   // 5% of attached seeds get knocked off (singulator action)

// ==========================================================================
// AFSTRIJKER 2 (Phase 3 visual fix) — release-zone pusher.
// Sits 5° before the release point and physically pushes any seed that
// hasn't released cleanly into the geleider catch-mouth. Acts as redundancy
// against imperfect vacuum cutoff timing.
// ==========================================================================
AFSTRIJKER2_THETA_DEG = 95;    // 5° before release at θ=90° (in rotation direction)
AFSTRIJKER2_POS       = [PICKUP_HOLE_RADIUS * cos(AFSTRIJKER2_THETA_DEG),
                         PICKUP_HOLE_RADIUS * sin(AFSTRIJKER2_THETA_DEG) * cos(DISC_TILT_DEG),
                         PICKUP_HOLE_RADIUS * sin(AFSTRIJKER2_THETA_DEG) * sin(DISC_TILT_DEG)];
AFSTRIJKER2_LENGTH    = 12;    // shorter — covers ~10° arc
AFSTRIJKER2_HEIGHT    = 6;     // lower than first; well-attached seeds should already be releasing
AFSTRIJKER2_THICKNESS = 2;
AFSTRIJKER2_PUSH_PROB = 0.10;  // 10% of seeds passing here get pushed into geleider (visual redundancy)

// ==========================================================================
// GELEIDER (Phase 3 V5) — curved chute that catches released seeds at the
// disc-top and routes them to the central drop-tube. STRUCTURALLY MANDATORY:
// at release, the seed retains tangential velocity ~22 mm/s in +X (5 RPM)
// AND its Y-coordinate stays at +29.7. Without active redirection, the seed
// falls at (X≈1.7, Y≈29.7) — completely missing the central hole at (0,0).
// The geleider catches the falling seed and slides it backward in -Y to
// throat (0, 0, GELEIDER_THROAT_Z).
// ==========================================================================
GELEIDER_MOUTH_X        = 40;     // catch-mouth width (X-extent)
GELEIDER_MOUTH_Y        = 20;     // catch-mouth depth (Y-extent: y∈[20,40])
GELEIDER_MOUTH_Z        = 20;     // catch-mouth opening at z=20 (10 mm below release at z=29.7)
GELEIDER_MOUTH_Y_CENTER = 30;     // centred on release Y line
GELEIDER_THROAT_DIA     = 30;     // throat (entry to drop-tube) diameter
// Throat must sit BELOW the disc-body slab |z-y| ≤ 2.83 mm. With y=0 at the
// throat, this means z < -2.83. We use z = -6 so the throat is fully under
// the disc body and the lofted hull never crosses the disc volume.
GELEIDER_THROAT_Z       = -6;
GELEIDER_WALL           = 2;
GELEIDER_DISC_CLEARANCE = 3;      // min gap between geleider surface and disc envelope

// ==========================================================================
// DROP-TUBE (Phase 3 V5) — vertical pipe through central disc hole.
// Continues from geleider throat down through the housing.
// ==========================================================================
DROP_TUBE_OD       = 30;
DROP_TUBE_ID       = 24;
DROP_TUBE_Z_TOP    = GELEIDER_THROAT_Z;     // joins geleider throat (z=-6)
DROP_TUBE_Z_BOTTOM = -52;                    // exits below pool floor (-45)

// ==========================================================================
// VACUUM CHAMBER (Phase 4 V5) — annular sector sealed against disc back face
// covering pickup-to-release zone (θ ∈ [90°, 270°] going through θ=180°,
// i.e. world x_local ≤ 0). Without a chamber, the vacuum has nowhere to
// pull from; this is the missing structural element behind the disc.
// ==========================================================================
VAC_CHAMBER_R_IN     = 30;    // just inside the pickup-hole circle (R=42)
VAC_CHAMBER_R_OUT    = 50;    // just outside the pickup-hole circle
VAC_CHAMBER_DEPTH    = 8;     // back from disc-back face
VAC_CHAMBER_WALL     = 2;     // shell wall thickness (chamber is hollow inside)
VAC_NIPPLE_DIA       = 12;    // Ø12 hose connection
VAC_NIPPLE_LENGTH    = 30;    // sticks out 30 mm along disc-back-normal
VAC_SECTOR_START_DEG = 90;    // sector angular range (disc-local), inclusive
VAC_SECTOR_END_DEG   = 270;   // sector covers [90°, 270°] going through 180°

// ==========================================================================
// RECOVERY BOWL (Phase 5) — half-disc shell on the disc TOP half (footprint
// y ≥ 0). Catches seeds that release outside the θ=90° window (e.g. mid-arc
// vacuum drop, afstrijker-2 push that overshoots) and funnels them down
// through a rectangular drain that aligns with the geleider catch-mouth
// (40 × 20 mm at y_centre = 30, z = 22). R_OUTER mirrors the bottom pool
// for visual symmetry; the bowl is open at the top (z > Z_TOP is just air).
// Disc-envelope subtraction with 3 mm clearance carves the slot where the
// disc rim crosses the bowl outer wall (at world (±41.2, 36.5, 36.5)) —
// same trick as the bottom pool side walls (D6) and the geleider (D7).
// ==========================================================================
RECOVERY_BOWL_R_OUTER       = 55;
RECOVERY_BOWL_WALL          = 2;
RECOVERY_BOWL_R_INNER       = RECOVERY_BOWL_R_OUTER - RECOVERY_BOWL_WALL;
// Floor sits flush on top of the geleider (mouth top at z = 22). Top is
// 20 mm above release point (z = 29.7) so the bowl walls are tall enough
// to retain a bouncing seed.
RECOVERY_BOWL_Z_FLOOR       = 22;
RECOVERY_BOWL_Z_TOP         = 50;
RECOVERY_BOWL_DISC_CLEARANCE = 3;

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
