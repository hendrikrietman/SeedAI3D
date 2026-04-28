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
// PHASE 7 — TRANSPARENT HOUSING (hopper + integrated tubes + protective lid).
// Replaces archived v5_2_seed_pool.scad. Funnel-shaped hopper sits below
// the disc with disc-rim dipping into the pool at the narrow bottom.
// Feeder + vac-cleanup tubes are now channels through the housing wall
// (only short connector stubs protrude). Protective lid covers the disc
// front with a rubber dust-seal ring at the disc-OD radius.
// ==========================================================================

// --- Hopper (small cup at the pickup zone) — built in WORLD coords. ---
// v5.8.2: hopper repositioned from the disc-rim plan position
// (Y=-46.67) to the PICKUP-HOLE plan position (Y=-29.7), per Hendrik's
// feedback: "hopper should be close to pickup not the border of the
// disc". Also shrunk significantly (height 80→25, top 100×80→50×35,
// bottom 30×30→22×22). Pool surface raised from world z=-47 → -32 so
// pool sits just below the disc-back face at the pickup point. Pool
// floor at z=-42 (well above plate-front-edge z=-61.7).
HOPPER_TOP_X         = 50;
HOPPER_TOP_Y         = 35;
HOPPER_BOTTOM_X      = 22;
HOPPER_BOTTOM_Y      = 22;
HOPPER_HEIGHT        = 25;
HOPPER_WALL          = 2;
HOPPER_POOL_DEPTH    = 10;
HOPPER_BOTTOM_Z      = -32;          // pool surface, just below disc-back at pickup
HOPPER_TOP_Z         = HOPPER_BOTTOM_Z + HOPPER_HEIGHT;        // -7
HOPPER_POOL_FLOOR_Z  = HOPPER_BOTTOM_Z - HOPPER_POOL_DEPTH;    // -42
HOPPER_X_CENTRE      = 0;
HOPPER_Y_CENTRE      = -30;          // ≈ pickup hole plan position (world Y=-29.7)

// --- Feeder tube — channel cast into front-side housing wall ---
FEEDER_CHANNEL_ID    = 14;
FEEDER_CONNECTOR_LEN = 25;           // protruding stub for hose attach
FEEDER_ELEV_DEG      = 60;

// --- Vac-cleanup tube — channel cast into top side housing wall ---
VAC_CHANNEL_ID       = 22;
VAC_CONNECTOR_LEN    = 30;
VAC_ELEV_DEG         = 80;
VAC_MOUTH_OFFSET_Z   = 8;            // mouth above hopper-narrow-bottom

// --- Protective lid (annular ring) + rubber dust-seal ring ---
// v5.8.2: lid is now an ANNULAR RING covering only the outer 1-2 cm of
// the disc plus the teeth, per Hendrik's feedback ("cover should cover
// outer 1-2cm of the disc, so the teeth are not open, but closed").
// Ring inner Ø=112 (R=56, ~10 mm inside disc body OD at R=60), outer
// Ø=140 (R=70, ~4 mm bezel beyond teeth at R=66). The middle of the
// disc — where pickup holes and the hopper-pickup-zone live — stays
// open. Side rim removed (the ring itself sits 6 mm in front of the
// disc and provides physical retention without extra wraparound).
LID_OD               = 140;          // outer Ø, was 200
LID_INNER_DIA        = 112;          // inner Ø — ring opens here (R=56)
LID_ID_RING          = 130;          // dust-ring inner Ø, just inside disc OD
DUST_RING_OD         = 144;          // dust-ring outer Ø — disc OD + 12 mm
LID_THICKNESS        = 6;
LID_OFFSET_FROM_DISC = 8;            // 6 mm air gap to disc-front-face
DUST_RING_THICKNESS  = 3;
// Lid sits in disc-local (front side, +Z direction) at distance LID_OFFSET
// from disc-front face. Disc-front face at disc-local Z=+2. Lid front at
// disc-local Z = +2 + 8 = +10. Lid back at +10 - 6 = +4. Dust ring
// from +1 to +4 (sits inside the 6 mm front clearance).

// ==========================================================================
// PHASE 6 — DISC-MAL (integrated mal-plate). Replaces standalone Phase-4
// vacuum chamber (archived) by absorbing it as a cavity inside a flat
// structural plate that also holds the disc, mounts the motor, and
// provides attachment points for everything else. See D11 for rationale
// and D12 for the disc-retention scheme (no external bearings).
// ==========================================================================

// --- Mal-plate body ---
MAL_PLATE_X            = 180;   // plate width (in plate-local X')
MAL_PLATE_Y            = 180;   // plate height (in plate-local Y')
MAL_PLATE_THICKNESS    = 15;    // total plate thickness along disc-axis (Z')
// Disc-recess: circular cut into plate-front-face. Disc OD with teeth = 132,
// recess inner Ø = 134 → 1 mm radial clearance.
MAL_DISC_RECESS_DIA    = 134;
MAL_DISC_RECESS_DEPTH  = 5;     // disc 4 mm + 0.5 mm clearance front + back
MAL_FRONT_CLEARANCE    = 0.5;   // disc-front to recess-opening (lip overlap)
MAL_BACK_CLEARANCE     = 0.5;   // disc-back to recess-back-wall (= O-ring compressed protrusion)

// --- Vacuum chamber, now integrated as cavity inside mal-plate ---
// Sector covers θ ∈ [90°, 270°] through θ=180° (world x_local ≤ 0), same
// as Phase 4. Radii moved 2 mm outward so the R=42 pickup circle sits
// centred (10 mm margin each side, was 12/8 in Phase 4).
MAL_CHAMBER_R_IN       = 32;
MAL_CHAMBER_R_OUT      = 52;
MAL_CHAMBER_DEPTH      = 8;     // along plate-Z, from recess-back-wall inward
MAL_CHAMBER_BACK_WALL  = 2;     // plate-back wall behind chamber
// Sanity: recess depth (5) + chamber depth (8) + chamber back wall (2) = 15 ✓

// --- O-ring groove on the recess-back-wall (= chamber-front-wall in chamber sector) ---
// ISO-3601 face-seal style for 2.5 mm round NBR cord. Groove width and
// depth picked from the spec: 1.27× cord = 3.2 wide, 0.76× cord = 1.9 deep.
ORING_CORD_DIA         = 2.5;
ORING_GROOVE_WIDTH     = 3.2;
ORING_GROOVE_DEPTH     = 1.9;
ORING_OUTER_R          = MAL_CHAMBER_R_OUT + 1;   // 53 — just outside chamber wall
ORING_INNER_R          = MAL_CHAMBER_R_IN  - 1;   // 31 — just inside chamber wall

// --- Motor (NEMA17 stepper, per Phase 6 spec) ---
MOTOR_BODY_SIZE        = 42;    // 42×42 NEMA17 flange
MOTOR_BODY_LENGTH      = 47;    // standard stepper length
MOTOR_SHAFT_DIA        = 5;     // motor output shaft
MOTOR_SHAFT_LENGTH     = 22;    // shaft protrudes 22 mm from flange
MOTOR_FLANGE_HOLE_PITCH = 31;   // M3 mounting holes on a 31 mm square pattern
MOTOR_SHAFT_BORE_DIA   = 7;     // hole through plate (5 mm shaft + 1 mm clearance × 2)

// --- Drive pinion ---
// 20 teeth at module 1.5 → pitch dia 30, OD ≈ 33. Engages the 60-tooth
// disc rim externally, 3:1 reduction. Pinion-disc centre distance:
// disc-rim outer R = 66 mm; with disc-OD-without-teeth at R = 60 the
// pinion pitch circle (R=15) sits at gear centre R = 60 + 15 = 75
// from disc centre. Pinion teeth tips reach 75 - 16.5 = 58.5 → poke
// 1.5 mm past disc R=60 into the tooth-rim band, where they mesh.
PINION_TEETH           = 20;
PINION_MODULE          = 1.5;
PINION_PITCH_DIA       = PINION_TEETH * PINION_MODULE;       // 30
PINION_PITCH_R         = PINION_PITCH_DIA / 2;               // 15
PINION_OD              = PINION_PITCH_DIA + 2 * PINION_MODULE;  // 33
PINION_THICKNESS       = 8;
PINION_BORE            = MOTOR_SHAFT_DIA;
// Pinion centre, in disc-local frame at θ=180° (world -X side):
PINION_CENTRE_X        = -(DISC_OD / 2 + PINION_PITCH_R);    // = -75

// --- Motor cut-out in mal-plate at θ=180° ---
// Wide enough to clear pinion OD (33) with 1 mm side clearance, tall
// enough (in plate-tangential Y) to clear pinion + housing.
MAL_MOTOR_CUTOUT_X     = 36;    // radial extent (along disc-local X)
MAL_MOTOR_CUTOUT_Y     = 36;    // tangential extent (along disc-local Y)
MAL_MOTOR_CUTOUT_X_CTR = PINION_CENTRE_X;   // -75
MAL_MOTOR_CUTOUT_Y_CTR = 0;

// --- Hose nipple, on plate-back at chamber midpoint (θ=180°, R=42) ---
MAL_NIPPLE_OD          = 12;
MAL_NIPPLE_ID          = 8;
MAL_NIPPLE_LENGTH      = 30;
MAL_NIPPLE_X           = -(MAL_CHAMBER_R_IN + MAL_CHAMBER_R_OUT) / 2;  // -42
MAL_NIPPLE_Y           = 0;

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
