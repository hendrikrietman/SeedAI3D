// SeedAI3D v7 — parametric OpenSCAD (CC-BY-SA 4.0)
// Disc-local frame: Z+ = front (seed side). The disc front face sits at z = -0.5.
// Every part is modelled in its assembly position; export() re-orients it for printing.
//
//   openscad -o disc.stl   -D 'EXPORT_PART="disc"'   seedai3d_v7.scad
//   parts: disc plate gasket funnel collar cover pinion singulator nipple blow_nipple
//          sensor_elbow hopper stand_bracket board_tray hall_carrier   |   assembly (default)

EXPORT_PART = "assembly";
EXPORT_POS = false;     // true: export the part in its assembly position instead of print orientation
$fn = 96;

// ---------------- parameters (mm) ----------------
disc_r        = 64;    disc_t = 4;    disc_front_z = -0.5;
flange_r      = 66.5;  flange_t = 2;                 // labyrinth lip over the wall top
hole_n        = 32;    hole_d = 4.0;  hole_circle_r = 45;  hole_chamfer = 1.0;
centre_hole_d = 50;
ring_z0 = -16;  ring_z1 = -4.5;  ring_outer_r = 63;  // internal ring gear on the disc back
gear_m = 1.5;   ring_N = 75;     pin_N = 25;   pressure_angle = 20;  backlash = 0.15;
ring_p  = ring_N*gear_m/2;       // 56.25
pin_p   = pin_N*gear_m/2;        // 18.75
pin_x   = ring_p - pin_p;        // 37.5 centre distance
magnet_d = 6.3;  magnet_h = 2.2;  index_theta = 45;  index_r = 60;

plate_r = 75;  plate_back_z = -21;  groove_floor_z = -16.5;  island_top_z = -10;
land_top_z = -6;  land_r_in = 38;  land_r_out = 53;
gasket_recess = 0.5;  gasket_t = 2.2;  gasket_w = 2.5;    // TPU 90A; 0.2 mm compression
cham_r_in = 41;  cham_r_out = 49;  cham_a0 = 90;  cham_a1 = 270;  cham_depth = 8;
blow_a0 = 68;  blow_a1 = 84;  blow_depth = 4;
wall_r_in = 65;  wall_top_z = -3;
island_r = 53.5;  pocket_r = 24;      // pocket clears the NEMA17 screw circle (r 21.9 + 1.7)
funnel_bore_d = 32;  lug_w = 4;  lug_r = 17;  lug_h = 3;
vac_r = 45;  vac_theta = 180;  vac_slot_w = 8;  vac_slot_deg = 19;      // slot 8 x ~30 mm = 240 mm2, stays inside the chamber annulus
vac_flange = [26, 44, 4];  vac_screw_r = [35, 55];  vac_plenum = [10, 32, 2];   // barb on a flange plate over the slot, 2x M3 inserts, TPU flat gasket
blow_r = 45;  blow_bore_d = 6;  blow_cb_d = 12.4;  blow_cb_depth = 4;
tap_theta = 135;  tap_d = 3;                        // chamber pressure tap
nema_square = 31;  nema_pilot_d = 22.5;  nema_pilot_depth = 2;
mount_holes = [[40,60],[-40,60],[40,-60],[-40,-60]];  mount_d = 6.4;
drain = [14, 5];  drain_y = -59.5;

collar_r_in = 49;  collar_r_top = 55;  collar_top_z = 20;  collar_r_out = 71;
collar_under_z = -0.2;
cover_r = 72;  cover_t = 3;  cover_screw_r = 69;  cover_screws = [30, 150, 270];
feed_theta = 305;  feed_r_mouth = 53;  feed_z_mouth = 11;  feed_dir = [0.6, 0.33, 0.73];  feed_tube_od = 25;  feed_bore = 21;   // mouth flush with the 73° collar face: the collar is the last 10 mm of the chute
sing_theta = 232;  sing_gap = 2.4;  seed_d = 6;

sensor_throat_d = 14;  sensor_led_d = 5.2;

// ---------------- helpers ----------------
function unit(v) = v / norm(v);
module sector2d(r1, r2, a0, a1) {
    n = max(8, ceil((a1-a0)/3));
    polygon(concat([for (i=[0:n]) let(a=a0+(a1-a0)*i/n) [r2*cos(a), r2*sin(a)]],
                   [for (i=[n:-1:0]) let(a=a0+(a1-a0)*i/n) [r1*cos(a), r1*sin(a)]]));
}
module ring2d(r1, r2) { difference() { circle(r2); circle(r1); } }
module ring3d(r1, r2, z0, z1) { translate([0,0,z0]) linear_extrude(z1-z0) ring2d(r1, r2); }
module at_polar(r, a, z=0) { translate([r*cos(a), r*sin(a), z]) children(); }
// orient a +Z cylinder along direction d
module along(d) { v = unit(d); ax = cross([0,0,1], v); an = acos(v[2]); if (norm(ax) < 1e-6) children(); else rotate(a=an, v=ax) children(); }

// ---------------- involute gears ----------------
function invf(rb, r) = let(a = acos(min(1, rb/r))) tan(a)*180/PI - a;        // involute function, degrees
module tooth2d(N, m, ra, rf, half_deg, pa=pressure_angle) {
    p  = N*m/2;  rb = p*cos(pa);  r0 = max(rb, rf);  st = 10;
    fb = [for (i=[0:st]) let(r = r0 + (ra-r0)*i/st, ph = half_deg + invf(rb,p) - invf(rb,r)) [r*cos(-ph), r*sin(-ph)]];   // root -> tip, minus side
    fa = [for (i=[st:-1:0]) let(r = r0 + (ra-r0)*i/st, ph = half_deg + invf(rb,p) - invf(rb,r)) [r*cos(ph), r*sin(ph)]];    // tip -> root, plus side
    polygon(concat([[ (rf-1)*cos(-half_deg*1.5), (rf-1)*sin(-half_deg*1.5) ]], fb, fa,
                   [[ (rf-1)*cos(half_deg*1.5),  (rf-1)*sin(half_deg*1.5) ]]));
}
module gear2d(N, m, ra, rf, half_deg) {
    union() { circle(rf); for (k=[0:N-1]) rotate(k*360/N) tooth2d(N, m, ra, rf, half_deg); }
}
module pinion2d() { p = pin_p; gear2d(pin_N, gear_m, p + gear_m, p - 1.25*gear_m, 90/pin_N - (backlash/2)/p*180/PI); }
// internal ring: a ring minus an external-gear-shaped hole with addendum/dedendum swapped
module ring_gear2d() { p = ring_p; difference() { circle(ring_outer_r);
    gear2d(ring_N, gear_m, p + 1.25*gear_m, p - gear_m, 90/ring_N + (backlash/2)/p*180/PI); } }

// ---------------- disc ----------------
module disc() {
    difference() {
        union() {
            translate([0,0,disc_front_z - disc_t]) cylinder(r=disc_r, h=disc_t);
            translate([0,0,disc_front_z - flange_t]) cylinder(r=flange_r, h=flange_t);
            translate([0,0,ring_z0]) linear_extrude(ring_z1 - ring_z0) ring_gear2d();
        }
        translate([0,0,-30]) cylinder(d=centre_hole_d, h=60);
        for (i=[0:hole_n-1]) at_polar(hole_circle_r, i*360/hole_n, disc_front_z - disc_t - 1) {
            cylinder(d=hole_d, h=disc_t+2, $fn=32);
            translate([0,0,disc_t + 1 - hole_chamfer]) cylinder(d1=hole_d, d2=hole_d + 2*hole_chamfer, h=hole_chamfer + 0.01, $fn=32);
        }
        at_polar(index_r, index_theta, ring_z0 - 0.01) cylinder(d=magnet_d, h=magnet_h, $fn=32);   // index magnet in the ring back
    }
}

// ---------------- plate ----------------
module chamber2d()  { sector2d(cham_r_in, cham_r_out, cham_a0, cham_a1); }
module blowoff2d()  { sector2d(cham_r_in, cham_r_out, blow_a0, blow_a1); }
module gasket2d(a0, a1) { difference() { sector2d(cham_r_in - gasket_w, cham_r_out + gasket_w, a0 - gasket_w*180/PI/cham_r_in, a1 + gasket_w*180/PI/cham_r_in);
    sector2d(cham_r_in, cham_r_out, a0, a1); } }

module plate() {
    difference() {
        union() {
            translate([0,0,plate_back_z]) cylinder(r=plate_r, h=groove_floor_z - plate_back_z);           // back slab
            translate([0,0,groove_floor_z]) linear_extrude(island_top_z - groove_floor_z)                   // island with pinion bite
                difference() { circle(island_r); translate([pin_x,0]) circle(pocket_r); }
            ring3d(land_r_in, land_r_out, island_top_z, land_top_z);                                        // seal land, full 360°
            ring3d(wall_r_in, plate_r, groove_floor_z, wall_top_z);                                         // outer wall
        }
        // vacuum chamber and blow-off pockets, gasket seats
        translate([0,0,land_top_z - cham_depth]) linear_extrude(cham_depth + 1) chamber2d();
        translate([0,0,land_top_z - blow_depth]) linear_extrude(blow_depth + 1) blowoff2d();
        translate([0,0,land_top_z - gasket_recess]) linear_extrude(1) { gasket2d(cham_a0, cham_a1); gasket2d(blow_a0, blow_a1); }
        // funnel bore with bayonet notches
        translate([0,0,plate_back_z - 1]) cylinder(d=funnel_bore_d, h=40);
        for (a=[0,180]) rotate(a) translate([0, -lug_w/2 - 0.3, plate_back_z - 1]) cube([lug_r + 0.4, lug_w + 0.6, 40]);
        // vacuum bore + counterbore for the barb nipple; blow-off bore; pressure tap
        hull() for (da=[-vac_slot_deg, vac_slot_deg]) at_polar(vac_r, vac_theta + da, plate_back_z - 1) cylinder(d=vac_slot_w, h=30, $fn=32);
        for (r=vac_screw_r) at_polar(r, vac_theta, plate_back_z - 1) cylinder(d=4.0, h=6, $fn=24);      // M3 inserts for the nipple flange
        at_polar(blow_r, (blow_a0+blow_a1)/2, plate_back_z - 1) { cylinder(d=blow_bore_d, h=30); cylinder(d=blow_cb_d, h=blow_cb_depth + 1); }
        at_polar(vac_r, tap_theta, plate_back_z - 1) cylinder(d=tap_d, h=30, $fn=24);
        // NEMA17: shaft bore, pilot recess, 4x M3 through (screws from the front, inside the pocket)
        translate([pin_x,0,plate_back_z - 1]) { cylinder(d=7, h=10); cylinder(d=nema_pilot_d, h=nema_pilot_depth + 1); }
        for (sx=[-1,1], sy=[-1,1]) translate([pin_x + sx*nema_square/2, sy*nema_square/2, plate_back_z - 1]) cylinder(d=3.4, h=6.5, $fn=24);
        // mounting holes for the stand / row unit bracket
        for (h=mount_holes) translate([h[0], h[1], plate_back_z - 1]) cylinder(d=mount_d, h=30, $fn=32);
        // dust drain under the ring cavity
        translate([-drain[0]/2, drain_y - drain[1]/2, plate_back_z - 1]) cube([drain[0], drain[1], 10]);
        // hall sensor pocket (TO-92) under the ring, 1 mm wall to the magnet
        at_polar(index_r, index_theta, plate_back_z - 1) { cylinder(d=5, h=4.5); translate([-2.5,-8,0]) cube([5, 8, 3.5]); }   // 1 mm wall to the groove floor
        // cover screw / collar screw holes: M3 inserts in the wall top
        for (a=cover_screws) at_polar(cover_screw_r, a, wall_top_z - 8) cylinder(d=4.0, h=9, $fn=24);
    }
}

// ---------------- gasket (TPU) ----------------
module gasket() { translate([0,0,land_top_z - gasket_recess]) linear_extrude(gasket_t) { gasket2d(cham_a0, cham_a1); gasket2d(blow_a0, blow_a1); } }

// ---------------- funnel ----------------
module funnel() {
    prof = [[23,2.5],[27,2.5],[27,1],[24.7,1],[24.7,-5],[14,-16],[14,-50],[12,-50],[12,-17],[22.5,-4]];
    difference() {
        union() {
            rotate_extrude() polygon(prof);
            for (a=[0,180]) rotate(a) translate([12, -lug_w/2, -24.5]) cube([lug_r - 12, lug_w, lug_h]);   // bayonet lugs, behind the slab after a quarter turn
        }
        // 4 x IR windows are in the sensor elbow, not here
    }
}

// ---------------- collar ----------------
module collar_profile() { polygon([[collar_r_in, collar_under_z],[collar_r_in, 0.3],[collar_r_top, collar_top_z],[collar_r_out, collar_top_z],
                                   [collar_r_out, wall_top_z],[flange_r + 0.5, wall_top_z],[flange_r + 0.5, collar_under_z]]); }   // clears the disc flange: labyrinth
module feed_tube_axis() { at_polar(feed_r_mouth, feed_theta, feed_z_mouth) along(feed_dir) children(); }
module collar() {
    difference() {
        rotate_extrude() collar_profile();
        feed_tube_axis() { cylinder(d=feed_tube_od + 0.4, h=200); translate([0,0,-0.01]) cylinder(d1=feed_bore + 4, d2=feed_bore, h=2); }   // bore from the collar face outward, chamfered mouth
        for (a=cover_screws) at_polar(cover_screw_r, a, -10) cylinder(d=3.4, h=40, $fn=24);       // cover screws pass, collar screws below
        // singulator mount: two M3 holes in the top face
        for (dr=[-6, 6]) at_polar(62, sing_theta + dr*180/PI/62, collar_top_z - 6) cylinder(d=2.6, h=7, $fn=24);
    }
}
// separate printed orifice tube (glued into the collar bore; bore >= 3x seed diameter)
module feed_tube() { feed_tube_axis() difference() { translate([0,0,2]) cylinder(d=feed_tube_od, h=70); translate([0,0,1]) cylinder(d=feed_bore, h=80); } }   // starts 2 mm behind the collar face

// ---------------- cover ----------------
module cover() { difference() { translate([0,0,collar_top_z]) cylinder(r=cover_r, h=cover_t);
    for (a=cover_screws) at_polar(cover_screw_r, a, collar_top_z - 1) cylinder(d=3.4, h=cover_t + 2, $fn=24);
    translate([cover_r - 6, 0, collar_top_z - 1]) cylinder(d=8, h=cover_t + 2, $fn=24); } }   // finger notch

// ---------------- pinion ----------------
module pinion() { translate([pin_x, 0, ring_z0 - 0.5]) difference() { linear_extrude(6) pinion2d();
    translate([0,0,-1]) difference() { cylinder(d=5.2, h=8, $fn=32); translate([2.0, -3, -1]) cube([3, 6, 10]); }   // 5 mm D-shaft
    translate([0,0,3]) rotate([0,90,0]) cylinder(d=2.6, h=20, $fn=20); } }                                          // M3 grub

// ---------------- singulator: bracket on the collar top, finger over the hole circle ----------------
module singulator() {
    zf = disc_front_z + seed_d + sing_gap;                       // underside of the finger
    rotate(sing_theta) difference() {
        union() {
            translate([58, -5, collar_top_z]) cube([12, 10, 3]);                          // foot on the collar
            hull() { translate([58, -2.5, collar_top_z]) cube([1, 5, 3]); translate([44, -2.5, zf]) cube([1, 5, 3.5]); }   // arm
            translate([40, -6, zf]) cube([10, 12, 3.5]);                                  // finger, tangential
        }
        for (dr=[-6,6]) translate([62, dr, collar_top_z - 1]) cylinder(d=3.4, h=6, $fn=24);
        translate([39, -7, zf - 0.01]) rotate([0,-30,0]) cube([6, 14, 3]);               // ramp on the leading edge
    }
}

// ---------------- barb nipples (separate so the plate prints flat on its back) ----------------
module barb(spigot_d, spigot_h, hose_od, bore, n=3) { difference() { union() { cylinder(d=spigot_d, h=spigot_h);
    for (i=[0:n-1]) translate([0,0,spigot_h + i*7]) { cylinder(d1=hose_od - 1.5, d2=hose_od + 1.2, h=4); translate([0,0,4]) cylinder(d=hose_od - 1.5, h=3); } }
    translate([0,0,-1]) cylinder(d=bore, h=spigot_h + n*7 + 2); } }
// vacuum nipple: flange plate with a plenum over the slot, barb for 19 mm hose. Flange face at z=0, barb along +z.
module nipple_local() { f = vac_flange; difference() {
    union() { translate([-f[0]/2, -f[1]/2, 0]) cube(f); translate([0,0,f[2]]) barb(20, 2, 19.5, 15); }
    translate([-vac_plenum[0]/2, -vac_plenum[1]/2, -1]) cube([vac_plenum[0], vac_plenum[1], vac_plenum[2] + 1]);
    translate([0,0,-1]) cylinder(d=15, h=f[2] + 4);
    for (r=vac_screw_r) translate([r - vac_r, 0, -1]) cylinder(d=3.4, h=f[2] + 2, $fn=24); } }
module nipple_gasket_local() { f = vac_flange; linear_extrude(1.0) difference() { square([f[0], f[1]], center=true); square([vac_plenum[0], vac_plenum[1]], center=true);
    for (r=vac_screw_r) translate([r - vac_r, 0]) circle(d=3.4, $fn=24); } }
module nipple()        { at_polar(vac_r, vac_theta, plate_back_z - 1.0) mirror([0,0,1]) rotate(vac_theta) nipple_local(); }
module nipple_gasket() { at_polar(vac_r, vac_theta, plate_back_z) mirror([0,0,1]) rotate(vac_theta) nipple_gasket_local(); }
module blow_nipple() { at_polar(blow_r, (blow_a0+blow_a1)/2, plate_back_z) mirror([0,0,1]) barb(12, blow_cb_depth, 8, 5.5, 2); }

// ---------------- sensor elbow: socket on the funnel tube, Ø14 throat with 2 crossed IR pairs, 45° bend to vertical ----------------
module sensor_elbow() {
    translate([0,0,-50]) mirror([0,0,1]) difference() {
        union() {
            cylinder(d=36, h=12);                                   // socket over the Ø28 tube
            translate([0,0,12]) cylinder(d1=36, d2=sensor_throat_d + 8, h=10);
            translate([0,0,22]) cylinder(d=sensor_throat_d + 10, h=20);   // throat block with IR pockets
            translate([0,0,42]) rotate([0,0,0]) cylinder(d=sensor_throat_d + 6, h=1);
            // 45° bend: torus segment, bend radius 25, then vertical outlet
            translate([0,25,43]) rotate([90,0,0]) rotate_extrude(angle=45) translate([25,0]) circle(d=sensor_throat_d + 6);
        }
        translate([0,0,-1]) cylinder(d=28.3, h=13.1);
        translate([0,0,11.9]) cylinder(d1=24, d2=sensor_throat_d, h=10.2);
        translate([0,0,21.9]) cylinder(d=sensor_throat_d, h=21.2);
        translate([0,25,43]) rotate([90,0,0]) rotate_extrude(angle=45.5) translate([25,0]) circle(d=sensor_throat_d);
        for (a=[0,90,180,270]) rotate(a) translate([sensor_throat_d/2 - 1, 0, 32]) rotate([0,90,0]) { cylinder(d=2.5, h=10, $fn=20); translate([0,0,2]) cylinder(d=sensor_led_d, h=12, $fn=24); }
    }
}

// ---------------- bulk hopper: vertical, 70° walls, one orifice, prints wide end down ----------------
module hopper() { rotate_extrude() polygon([[12.5,-10],[14.5,-10],[14.5,0],[52,103],[52,106],[48,106],[48,103.5],[50,103],[12.5,0]]); }

// ---------------- stand bracket (x2): flat plate with two 45° tabs that bolt to the plate back at (±40, ±60) ----------------
// Bracket plane is perpendicular to X. In world coordinates (y up): the plate back runs from local y=+60 to -60.
module stand_bracket() {
    t = 8;
    p1 = [-57.3, 27.6]; p2 = [27.6, -57.3];         // [z_world, y_world] of the two bolt holes on the plate back
    base_y = -132;
    difference() {
        union() {
            linear_extrude(t) difference() {
                offset(r=6) polygon([p1, p2, [p2[0]+40, base_y], [p1[0]-40, base_y]]);
                offset(r=-16) polygon([p1, p2, [p2[0]+40, base_y], [p1[0]-40, base_y]]);
            }
            linear_extrude(t) translate([p1[0]-46, base_y-6]) square([p2[0]-p1[0]+92, 12]);          // foot rail
            for (p=[p1,p2]) translate([p[0], p[1], t/2]) rotate([0,0,-45]) translate([-6, -12, -t/2]) cube([12, 24, t]);   // tabs along the 45° edge
        }
        for (p=[p1,p2]) translate([p[0], p[1], -1]) cylinder(d=mount_d, h=t + 2, $fn=32);
        for (x=[p1[0]-30, p2[0]+30]) translate([x, base_y, -1]) cylinder(d=6.4, h=t + 2, $fn=32);
    }
}

// ---------------- board tray: Mega 2560 (+RAMPS) and Raspberry Pi hole patterns, 4 base screws ----------------
module board_tray() {
    mega = [[14.0,2.5],[15.3,50.7],[66.1,7.6],[66.1,35.5],[90.2,50.7],[96.5,2.5]];
    pi   = [[3.5,3.5],[61.5,3.5],[3.5,52.5],[61.5,52.5]];
    difference() {
        union() { cube([125, 95, 3]);
            for (h=mega) translate([h[0]+12, h[1]+20, 3]) cylinder(d=6, h=6, $fn=24);
            for (h=pi)   translate([h[0]+12, h[1]+20, 3]) cylinder(d=6, h=6, $fn=24); }
        for (h=mega) translate([h[0]+12, h[1]+20, -1]) cylinder(d=2.6, h=12, $fn=20);
        for (h=pi)   translate([h[0]+12, h[1]+20, -1]) cylinder(d=2.6, h=12, $fn=20);
        for (x=[6,119], y=[6,89]) translate([x, y, -1]) cylinder(d=4.4, h=5, $fn=24);
        translate([30, 40, -1]) cube([65, 30, 5]);                                        // cable window
    }
}

// ---------------- print orientation ----------------
module export(part) {
    if (EXPORT_POS) {
        if (part == "disc") disc(); else if (part == "plate") plate(); else if (part == "gasket") gasket(); else if (part == "funnel") funnel();
        else if (part == "collar") collar(); else if (part == "cover") cover(); else if (part == "pinion") pinion(); else if (part == "singulator") singulator();
        else if (part == "nipple") nipple(); else if (part == "nipple_gasket") nipple_gasket(); else if (part == "sensor_elbow") sensor_elbow(); else if (part == "feed_tube") feed_tube(); else assembly();
    }
    else if (part == "disc")          mirror([0,0,1]) disc();                       // front face on the bed, ring gear up
    else if (part == "plate")    plate();                                      // back face on the bed, all pockets open upward
    else if (part == "gasket")   gasket();
    else if (part == "funnel")   mirror([0,0,1]) translate([0,0,-2.5]) funnel();  // flange on the bed
    else if (part == "collar")   collar();                                     // flat underside on the bed
    else if (part == "cover")    cover();
    else if (part == "pinion")   translate([-pin_x, 0, -ring_z0 + 0.5]) pinion();
    else if (part == "singulator") translate([0,0,-collar_top_z - 3]) mirror([0,0,1]) singulator();   // foot on the bed
    else if (part == "nipple")   nipple_local();
    else if (part == "nipple_gasket") nipple_gasket_local();
    else if (part == "blow_nipple") translate([-blow_r*cos((blow_a0+blow_a1)/2), -blow_r*sin((blow_a0+blow_a1)/2), 0]) mirror([0,0,1]) translate([0,0,-plate_back_z]) blow_nipple();
    else if (part == "sensor_elbow") translate([0,0,50]) sensor_elbow();       // socket on the bed
    else if (part == "hopper")   translate([0,0,106]) mirror([0,0,1]) hopper();  // wide end on the bed
    else if (part == "feed_tube") feed_tube();
    else if (part == "stand_bracket") stand_bracket();
    else if (part == "board_tray") board_tray();
    else assembly();
}

module assembly() {
    color("gainsboro") disc();
    color("dimgray") plate();
    color("black") gasket();
    color("lightsteelblue", 0.6) funnel();
    color("lightblue", 0.5) collar();
    color("lightcyan", 0.3) cover();
    color("burlywood") pinion();
    color("coral") singulator();
    color("dimgray") { nipple(); blow_nipple(); feed_tube(); }
    color("black") nipple_gasket();
    color("black") sensor_elbow();
}

export(EXPORT_PART);
