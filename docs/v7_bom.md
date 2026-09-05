# SeedAI3D v7 bench seed counter — bill of materials

Quantities for one element on the bench stand. Prices are indicative September 2026 ranges from
hobby suppliers, not quotes.

## A. Printed parts (stl/v7/)

| Part | Qty | Material | Volume at 100 % | Notes |
|---|---|---|---|---|
| plate | 1 | PETG, 100 % infill | 178 cm³ (~225 g) | vacuum part |
| disc | 1 per crop | PETG, 100 % | 72 cm³ (~90 g) | 32 × Ø4 for soybean; edamame/snap bean discs differ only in hole count/diameter |
| collar | 1 | PETG (clear optional), 30 % infill fine | 152 cm³ | not a vacuum part |
| cover | 1 | clear PETG | 49 cm³ | |
| funnel | 1 | PETG | 11 cm³ | |
| pinion | 1 | PETG or nylon | 6 cm³ | |
| gasket | 1 | TPU 90A | 2 cm³ | chamber + blow-off frames |
| nipple + nipple_gasket | 1 + 1 | PETG + TPU | 4 cm³ | |
| blow_nipple | 1 | PETG | 1 cm³ | |
| sensor_elbow | 1 | black PETG | 17 cm³ | |
| feed_tube | 1 | PETG | 11 cm³ | |
| hopper | 1 | clear PETG | 47 cm³ | |
| singulator | 1 | PETG | 1 cm³ | |
| stand_bracket | 2 | PETG or 8 mm plywood | 86 cm³ each | |
| board_tray | 1 | PETG | 31 cm³ | |

Filament: ~0.8 kg PETG (100 % on plate and disc, 30 % elsewhere), ~10 g TPU. About 45 h
of printing at 0.2 mm; the plate alone is 10–12 h.

## B. Drive and vacuum

| Item | Qty | Spec | ~€ |
|---|---|---|---|
| NEMA17 stepper | 1 | 1.5–1.7 A, 40 mm body, 5 mm D shaft (e.g. 17HS4401 class) | 10–15 |
| Blower | 1 | 12 V car-vacuum-class motor (60–100 W) or small side-channel blower: 30–50 mbar at 5–10 L/s | 20–60 |
| Bleed valve | 1 | ball valve or gate valve on a 19 mm tee | 5 |
| Vacuum hose | 1 m | 19 mm ID, reinforced | 5 |
| Blow-off hose | 0.5 m | 8 mm ID, to a tee on the blower exhaust, or left open to atmosphere for the first build | 2 |
| Pressure sensor | 1 | 0–10 kPa differential/vacuum, analogue or I2C (MPXV5010DP / XGZP6847 class) | 5–12 |
| Tap tubing | 0.3 m | 3 mm silicone | 1 |

## C. Sensing

| Item | Qty | Spec | ~€ |
|---|---|---|---|
| IR emitter, 5 mm, 940 nm | 2 | 20 mA class | 1 |
| IR receiver, 5 mm | 2 | phototransistor, or TSSP4038-class modulated receivers (then drive the LEDs at 38 kHz) | 2–4 |
| Resistors | 4 | 150 Ω (LED), 10 kΩ (pull-up) | – |
| Hall sensor | 1 | SS49E (analogue) or A3144 (switch), TO-92 | 1 |
| Magnet | 1 | Ø6 × 2 mm neodymium, in the disc ring | 1 |
| Bag switch | 1 | miniature microswitch with lever | 1 |
| Load cell + amplifier (recommended) | 1 | 500 g bar cell + HX711 | 5–8 |

## D. Electronics

| Item | Qty | Spec | ~€ |
|---|---|---|---|
| Controller | 1 | FYSETC E4 (ESP32, 4 × TMC2209, BLE/Wi-Fi, 12–24 V). Alternatives: MKS TinyBee; Mega 2560 + RAMPS 1.4 + 4 × TMC2208 + 12864 LCD | 40–55 |
| Blower switch | 1 | 30 A automotive relay or 15 A MOSFET module driven from the board fan output | 3–6 |
| Power supply | 1 | 12 V 15 A (board + motor + blower), or 12 V 3 A for the board and a separate 12 V 10 A for the blower | 20–35 |
| TF card | 1 | 8–32 GB, for the bag log and sowing list | 5 |
| Push buttons | 2 | 22 mm panel buttons, green (start) and orange (empty), with LED ring if you like | 6 |
| Wiring | – | XH2.54 leads for motor and endstops, 0.5 mm² for the blower, 5 V and 12 V distribution | 10 |
| Console (option A) | 1 | any phone/laptop with Chrome or Edge; the viewer page over Web Bluetooth | 0 |
| Console (option B) | 1 | Raspberry Pi 4 + official 7" touchscreen, kiosk browser, USB serial or BLE to the board | 120–150 |

## E. Hardware and consumables

| Item | Qty | Use |
|---|---|---|
| M3 heat-set inserts | 7 | 3 in the wall top (cover/collar), 2 in the collar top (singulator), 2 in the plate back (nipple flange) |
| M3 × 8 | 4 | motor to plate, from inside the pinion pocket |
| M3 × 30 | 3 | cover through collar into the wall inserts |
| M3 × 10 | 4 | nipple flange (2), singulator (2) |
| M3 × 5 grub | 1 | pinion on the D shaft |
| M3 × 6 + standoffs | 4–6 | board on the tray |
| M6 × 25 bolts, washers, nyloc nuts | 4 | plate to stand brackets |
| M6 × 40 or wood screws | 4 | brackets to base |
| M4 × 16 wood screws | 4 | board tray to base |
| Plywood | 1 | 300 × 250 × 18 mm base |
| Hose clamps 19 mm | 2–3 | blower, tee, nipple |
| CA glue | – | feed tube into collar, blow nipple |
| Epoxy (thin) | – | only if the leak test fails: brush the chamber and slot |
| Sandpaper 400 grit + glass plate | – | flatten the disc back |
| Soapy water, 0.01 g balance, 20 seed bags | – | leak test and the 20 × 100-seed accuracy test |

Indicative total without the Pi console: €180–260 plus filament and plywood.
