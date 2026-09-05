# SeedAI3D v7 — design proposal (unbuilt)

**Status:** proposal, September 2026. No parts printed. No SCAD yet; the geometry lives in the
parameter block of `viewer/v7/index.html` and is meant to be ported to `scad/` once the first
print of v5.8/v6.0 has answered the questions in §8.

Supersedes the v5.8.5 geometry in this repo. Carries over from v6.0 (June 2026, not pushed):
crop-swappable discs, the blow-off sector, the Ø20 vacuum nipple, 3 mm chamber back wall.

Interactive model: `viewer/v7/index.html` (seed physics, cut-away, explode, count mode).

## 1. Why revisit

v5.8 had 12 printed parts plus a lid ring, dust ring, O-ring cord, heat-set inserts and clip
posts. Most of them exist to fix problems the model itself introduced:

| v5.8 part | Why it existed | Why it goes |
|---|---|---|
| Geleider (catch chute), afstrijker 2, vertical drop tube | The viewer's free-fall model showed the seed missing the centre hole at θ=90° | On a 45° face, downhill at the top of the disc *is* radially inward. After vacuum cuts, a soybean rolls the 20 mm from the hole circle to the centre hole in ~0.1 s (a ≈ 4.5 m/s²). Tangential drift at 15 rpm is 4 mm. D9's "glide" already noticed this. |
| Lid ring, dust ring, 4 clip posts, M3 inserts | Cover the external teeth | Teeth move to an internal ring gear on the disc back; nothing on the front needs covering |
| Hopper, feeder tube, vac-cleanup tube | Seed supply and line change | Seeds rest on the 45° face; the pool is a collar around the bottom of the drum. Cleanout is by geometry (§4) or by the wall gate (field), not by a shop-vac 2000 times |
| NBR O-ring cord in a groove | Chamber seal | Static-seal geometry on a rotating face: line contact, high drag, wears the PETG disc. Replaced by a flat printed TPU gasket frame, as Monosem/MaterMacc do |

What was missing: a defined disc axis (v5 floats in a Ø134 recess), a seed sensor, a
singulator that can actually strip a double, chamfered holes, mounting bosses, a cover, and a
geometry that lets the *last* seed reach a hole.

## 2. Parts (nine)

1. **Disc** — Ø128 × 4, 32 holes Ø4 at R45 (pitch 8.8 mm; the v5 40 at R42 gave 6.6 mm, so
   adjacent soybeans touched), Ø50 centre hole, rim flange Ø133 × 2 on the front, internal ring
   gear (75 T, m1.5) on the back, 11.5 mm tall. Crop discs: swap hole count/diameter only.
2. **Plate** — Ø150 × 21. Back slab, ring-gear groove, full-360° seal land with the vacuum
   chamber (R41–49, θ 90–270) and blow-off pocket (θ 68–84) cut into it, outer wall, motor
   shaft bore, vacuum and blow-off nipples, dust drain slot under the ring cavity, two
   mounting bosses.
3. **Gasket** — TPU, two frames 2.5 mm wide, 1.5 mm thick, around chamber and blow-off.
4. **Funnel** — one lathe part: Ø54 front flange (retains the disc), Ø49.4 skirt (centre
   journal in the disc hole), cone Ø46→Ø24, bayonet flange behind the plate, exit tube.
5. **Pinion** — 25 T m1.5 on the NEMA17 shaft, sitting *behind* the seal land (z −16.5…−10.5)
   so no pickup hole ever passes over an open gear pocket.
6. **Collar** — static ring; flat underside 0.3 mm above the disc face (seals rim and
   flange), top face from R49 at the disc to R55 at the cover. See §4.
7. **Singulator finger** — hangs from the collar at θ≈232°, adjustable height.
8. **Cover** — clear PETG plate Ø144 × 3, three thumb screws.
9. **NEMA17 + TMC2208/2209** (bought).

Wall gate: the bottom 50° of the collar, hinged at its outer edge. Field mode only.

## 3. Z-stack (disc-local, front = +Z, mm)

| z | what |
|---|---|
| 20 … 23 | cover |
| −3 … 20 | collar rim / drum wall |
| −2.5 … −0.5 | disc rim flange (over the wall top: labyrinth) |
| −4.5 … −0.5 | disc body |
| −6 … −4.5 | TPU gasket |
| −10 … −6 | seal land, full 360°, R38–53 |
| −16 … −4.5 | ring gear on the disc back, R54.75 (tips) – 63 |
| −16.5 … −10.5 | pinion, centre (37.5, 0) |
| −21 … −16 | back slab |
| < −21 | motor, nipples, bosses |

Assembly: disc drops in from the front; funnel goes through the centre hole and locks with a
quarter turn behind the plate; cover on. Crop change is tool-free.

## 4. The last seed (collar geometry)

On a 45° disc the lowest point in the drum is the corner between the disc face and the wall.
With holes at R45 and a wall at R65 that corner is 14 mm (world) below the lowest hole. Every
seed ends there and no hole ever passes: v5–v7a could not empty by design.

Fix: make the hole circle the lowest point. The collar's top face runs from the hole circle
(R49, 0.3 mm above the face) to the cover (R55, z 20) at 73° to the disc face, i.e. 28° below
horizontal in the world. A surface must be steeper than 45° + friction angle relative to the
disc face for seeds to slide *inward*; 73° gives ~25° margin for soybean on PETG. Every point
in the drum then has a downhill path into the V between disc face and collar, whose bottom line
is the hole circle. Held seeds (R42–48) clear the collar edge by 1 mm.

Pool capacity in the V is small (tens of seeds); bulk lives in the hopper (§5).

## 5. Hopper

Vertical axis, 70° walls, transparent, one orifice, no ledges. A Ø25 tube (bore ≥ 3× seed
diameter; the v5 Ø14 would bridge with edamame) at ≥45° discharges onto the disc face *inside*
the hole circle at θ≈305°, so everything it delivers also drains into the V. Flow is
self-regulating: when the V is full the pile backs up to the orifice.

## 6. Modes and firmware

Same board and code for bench and planter. Board: Arduino Mega 2560 + RAMPS 1.4 (5 driver
sockets, 6 endstop inputs for IR gates, servo headers for gates, MOSFET outputs for blowers,
12864 LCD with encoder, buzzer and SD). 32-bit BTT SKR or ESP32/Arduino framework are
equivalent routes. Step rate at 20 rpm disc: 200 full steps/s per motor; 1/4 µstep, four
motors = 3200 steps/s, within a Mega + AccelStepper.

- **COUNT** (bench): target N from the encoder; full speed until N − (in-flight + 2), where
  in-flight = rpm·32/60·0.35 s is the number of seeds already released but not yet at the
  gate; then 2 rpm (one seed per second); stop on the Nth gate pulse; vacuum off so held seeds
  slide back. No bag on the holder → no count.
- **EMPTY** (last bag): 30 rpm, vacuum on, stop when the gate has been silent for 2.5 s
  (40 empty hole passes). Display the line total.
- **SOW** (planter): row list (line, N) from SD; live count vs N; row-done; gate cycle on
  the button: vacuum off → held seeds slide back → gate open ~1.5 s → close.
- IR gate in the funnel tube on an interrupt; occlusion time distinguishes a double.
- The SD CSV is the whole data path from winter counting to spring sowing: the bag counted on
  this disc is the row this disc meters.

## 7. Blower

40–70 mbar at the chamber for soybean-size seed: a small 12/24 V centrifugal blower per element
on a MOSFET output, not a shop vac.

## 8. Open questions — what the first print has to answer

1. Does the V actually feed the last seed? Collar edge radius and angle are the numbers to
   vary.
2. Gap-seal leakage with the TPU gasket vs. none.
3. Does a 75 T internal ring print true enough in PETG to mesh without backlash noise?
4. Doubles rate at the gate with the singulator at 2.4 mm above seed height.
5. Rim labyrinth: does anything reach the ring cavity, and does the drain clear it?
6. Not modelled: curved seed tube from the 45° exit to the furrow; row-unit bracket.

Counting accuracy is a hypothesis until a real disc has run a few thousand soybeans past a
real gate.
