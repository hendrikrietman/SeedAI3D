# SeedAI3D v7 — print files, vacuum, electronics, counter robustness

Companion to `v7_proposal.md`. Everything here is in `scad/v7/seedai3d_v7.scad`; the STLs in
`stl/v7/` are exported from it in print orientation. All 17 meshes are watertight (trimesh);
the cross-sections in `v7_sections_chamber.png` and `v7_section_theta180.png` are cut from the
assembly-position exports and are what the z-stack claims were checked against.

## 1. Parts, orientation, material

| STL | Material | Orientation (as exported) | Notes |
|---|---|---|---|
| disc | PETG | front face on the bed, ring gear up | 32 × Ø4 holes with 1 mm chamfer; index magnet pocket Ø6.3×2.2 in the ring back |
| plate | PETG, 100 % infill, 4 perimeters | back face on the bed | every pocket opens upward, no support. Vacuum slot 8×30 mm, blow-off bore, pressure tap, NEMA17 pattern, 4 × M6 mounts at (±40, ±60), drain slot, hall pocket |
| gasket | TPU 90A | flat | two frames 2.5 wide × 2.2 thick in a 0.5 mm recess → 0.2 mm compression |
| funnel | PETG | front flange on the bed | inner cone 39° from vertical; two bayonet lugs behind the slab, quarter turn |
| collar | PETG (clear if you want to see the pool) | underside on the bed | inner edge R49, 73° face, orifice bore at 305°, two M3 for the singulator |
| cover | clear PETG | flat | Ø144 × 3, three M3×30 through collar into wall inserts |
| pinion | PETG or nylon | flat | 25 T m1.5 involute, 5 mm D bore, M3 grub |
| singulator | PETG | foot on the bed | finger 2.4 mm above a seated seed; shim under the foot to adjust |
| nipple + nipple_gasket | PETG + TPU | flange on the bed | flange plate with plenum over the slot, barb for 19 mm hose, 2 × M3 |
| blow_nipple | PETG | flange down | press-fit Ø12 spigot, glue |
| sensor_elbow | black PETG | socket on the bed | Ø28 socket, Ø14 throat with 4 × Ø5.2 pockets (2 crossed IR pairs), 45° bend to vertical |
| feed_tube | PETG | as exported | Ø25/21, glued into the collar bore |
| hopper | clear PETG | wide end on the bed | 70° walls, Ø25 outlet stub, no ledges |
| stand_bracket (×2) | PETG or plywood | flat | 45° tabs bolt to the plate mounts; base rail with two M6 |
| board_tray | PETG | flat | Mega 2560 and Raspberry Pi 3/4 hole patterns, cable window |

Print settings that matter for vacuum: 0.2 mm layers, 4 perimeters, 100 % infill on the plate
and disc, flow 102–104 % so perimeters fuse, no "gap fill" gaps. PETG, not PLA (creep under
the gasket load). Clean the disc back on 400-grit glass-backed paper so it is flat.

Not in this release: the field gate (hinged collar sector) and the row-unit bracket. The
bench collar is one piece.

## 2. Vacuum: tight where it matters, weak on purpose

**What holds a seed.** Holding force = Δp × hole area. Ø4 hole = 12.6 mm². At 30 mbar that
is 38 mN, about 20 × a soybean's weight (0.18 g). At 60 mbar it is 40 ×. Commercial soybean
discs run 40–55 mbar with the same hole size, but at 3–5 × our disc speed and with singulators
that push harder. For a bench counter at ≤ 20 rpm start at **25–30 mbar** and tune on the
doubles count; go up only if skips appear. The simulation in the viewer uses that assumption
(skips below ~25 mbar, doubles above ~40) as a placeholder until measured.

**How much air.** With no seeds seated, 16 holes are open over the chamber: 200 mm². At
30 mbar, air speed ≈ 70 m/s, Q ≈ 0.65 × 200 mm² × 70 m/s ≈ 9 L/s (550 L/min). With seeds
seated it drops to 2–3 L/s. So the blower must give 30–50 mbar at 5–10 L/s. That is a
12 V car-vacuum-class motor (60–100 W) or a small side-channel blower, throttled with a bleed
valve; a fan or a bilge blower (3–8 mbar) will not do, and a shop-vac (200 mbar) only with a
large bleed. The slot in the plate is 240 mm² so it never chokes.

**Where it leaks and what stops it.**

| Path | Measure |
|---|---|
| gasket → disc back | flat TPU frame in a 0.5 recess, 0.2 compression; vacuum itself pulls the disc onto the gasket with Δp × 1131 mm² ≈ 3.4 N at 30 mbar; extra drag torque < 0.01 N·m at the motor |
| chamber → ring-gear groove | island wall R49–53.5, 4.5 mm, solid from z −16.5 to −6 |
| chamber → centre | wall R38–41, 3 mm |
| chamber floor → pinion pocket | floor at z −14, pocket at ≤ −10.5, different radius |
| nipple → back face | flange plate with TPU flat gasket over the slot, 2 × M3 |
| print porosity | 4 perimeters, 100 % infill, over-extrusion; if the leak test fails, brush epoxy into the chamber and slot |
| pressure tap | Ø3 at θ=135°, silicone tube to a −10 kPa sensor (e.g. XGZP6847 class) or an analogue gauge |

**Leak test before anything else.** Print the plate and gasket only. Clamp a flat plate
(glass or the cover) over the land with the gasket in place, connect the blower through the
bleed valve, read the tap. If you cannot reach 40 mbar with the bleed closed, find the leak
with soapy water on the back face. Then fit the disc and read the drop with all holes open
versus all holes taped: that ratio is your seated-vs-open leakage and tells you the blower
margin. Log both numbers; they are the acceptance test for the print settings.

## 3. Electronics

**Board.** FYSETC E4: ESP32 with built-in Wi-Fi and Bluetooth, 4 × TMC2209, 12–24 V,
90 × 67 mm, TF card, 3 endstop inputs, one controllable fan output. One board covers the
bench counter (1 element) and, with the endstops used as IR gate inputs, up to 3 elements; the
MKS TinyBee (5 drivers, more inputs, also ESP32) covers a 4-element bar. Both run Arduino
framework code. The tray in `board_tray.stl` takes a Mega + RAMPS or a Raspberry Pi as well;
the E4 is small enough to sit on it with two extra holes.

**Blower.** On the fan MOSFET (12/24 V) or an external relay if the motor draws more than the
output rating. Bleed valve in the hose sets the pressure; the tap sensor displays it.

**Sensor.** Two crossed IR pairs (5 mm LED + phototransistor) in the Ø14 throat of the sensor
elbow. A Ø6 seed in a Ø14 bore cannot pass either beam without breaking it. Drive the LEDs
with a 10 kHz square wave and AC-couple the receivers (or use a modulated receiver like the
TSSP4038 family): ambient light and sunlight through the clear parts then do not matter, and
the black elbow already shades the throat. **It does not need darkness**; a plain unmodulated
phototransistor in a clear tube would, which is why the throat is black and separate.
Occlusion time at ~1 m/s is 5–8 ms for one seed; two seeds stacked give > 12 ms → counted as a
double and flagged.

**Index.** Ø6 × 2 magnet in the ring back, hall sensor (SS49E / A3144) in the plate pocket.
With it the firmware knows which hole is at the release point at every step and expects a gate
pulse in a ±10 ms window per hole: a missing pulse is a skip, a pulse outside any window is
noise, two in one window is a double. The Contador has no such reference; this is the single
biggest accuracy lever we have over a vibratory counter.

**Console.** No LCD on the board. The display is `viewer/v7/index.html` itself, connected over
Web Bluetooth (Chrome/Edge on Android, Windows, macOS, ChromeOS), or the same page in kiosk mode
on a Raspberry Pi with the 7" touchscreen, connected to the E4 over USB serial or BLE. The
card on the right of the page mirrors what the firmware sends and its buttons send the commands
below. The physical buttons on the stand are optional: Start (green), Empty (orange).

BLE protocol (Nordic UART UUIDs):
- service `6e400001-…`, command characteristic `6e400002-…` (write), status `6e400003-…` (notify)
- commands, JSON: `{"cmd":"count","n":30}`, `{"cmd":"empty"}`, `{"cmd":"stop"}`, `{"cmd":"gate"}`,
  `{"cmd":"rpm","v":12}`, `{"cmd":"target","n":30}`, `{"cmd":"vac_set","mbar":30}`
- status, JSON, 5 Hz: `{"mode":"COUNT","bag":12,"n":17,"target":30,"total":377,"rpm":12,"vac":1,"mbar":31,"doubles":2,"skips":1,"gate":0}`

Firmware modes are as in `v7_proposal.md` §6. Add: bag-presence switch on an endstop input
(no bag, no count), and log one CSV line per bag to the TF card: line, bag, n, doubles, skips,
mbar, timestamp.

## 4. Is the counting already robust enough?

What we have: singulation before the gate, two crossed beams, pulse-width doubles detection,
index-referenced expectation windows, a throat narrow enough that nothing passes unseen, and
a slow-down that leaves nothing in flight at the stop. That is more than the Contador's single
channel has. What we do not have is a measurement. The test is 20 runs of 100 counted seeds
weighed on a 0.01 g balance against the known thousand-kernel weight; the residual is the
error. Until then the accuracy is a design argument.

## 5. Ideas to reach parity with commercial counters

1. **Weigh the bag.** A 500 g load cell + HX711 under the bag holder (€5). Every bag gets a
   count *and* a mass, so TKW comes free and a bag whose mass is off by one seed is flagged.
   No commercial counter under €3000 does both.
2. **Bag carousel.** Eight bag holders on a servo-indexed ring under the exit, like the
   Contafill. "Next bag" then needs no hands at all; a line of 8 rows is one button.
3. **Line ID by barcode.** A USB barcode scanner into the Pi; the bag label is printed on a
   small thermal printer with line, N, mass, date. The SD CSV becomes the sowing plan.
4. **Crop presets.** Disc, mbar, rpm, singulator shim, throat insert, stored per crop and
   recalled by name; the console refuses to start if the index sees the wrong disc (hole count
   read from the pulse pattern in one empty revolution).
5. **Self-test at start.** One empty revolution with vacuum on: no gate pulses (noise check),
   pressure within band (leak check), index seen (disc seated). Three seconds, every session.
6. **Purge revolution between lines.** After EMPTY: vacuum off, one revolution with the
   blow-off pocket on positive pressure (reverse the blower or a second small pump) to clear
   any seed stuck in a hole.
7. **Auto-vacuum.** Servo on the bleed valve, closed loop on the tap sensor; the doubles and
   skips counters nudge the setpoint (skips → +2 mbar, doubles → −2 mbar) within limits.
8. **Two elements on one stand.** The board has four drivers; two elements side by side double
   the throughput and let one count while the other is being bagged.
