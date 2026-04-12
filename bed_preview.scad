// Preview: WristCameraHolder sitting on Dremel 3D45 glass bed
$fn = 80;

// Dremel 3D45 build plate 254 x 152 mm
color([0.3, 0.5, 0.8, 0.5])
    translate([0, 0, -6])
        cube([254, 152, 1], center = true);

// Part, plate-down on bed (shift up so disc bottom rests at z=-5 -> on bed top z=-5)
color([0.85, 0.85, 0.9])
import_part();

module import_part() {
    // Inline copy of export_combined.scad geometry
    module mounting_plate() {
        translate([0, 0, -5])
        difference() {
            cylinder(h = 5, r = 38.75);
            translate([-31.5, 0, -1]) cylinder(h = 7, r = 3.2);
            translate([ 31.5, 0, -1]) cylinder(h = 7, r = 3.2);
        }
    }
    module arm_raw(mir=false) {
        cam_x = -38.13; tilt_angle = 36.94;
        hull() {
            translate([cam_x, 0, 40.39]) rotate([0, tilt_angle, 0])
                translate([0, 0, 5]) cube([8, 15.25, 10], center = true);
            translate([-38.75 + 4 - 4, 0, -2.5])
                cube([16, 15.25, 5], center = true);
        }
    }
    module holder() {
        translate([-38.13, 0, 40.39]) rotate([0, 36.94, 0])
            difference() {
                cylinder(h = 10, d = 15.25);
                translate([0, 0, -1]) cylinder(h = 12, d = 7.4);
            }
    }
    mounting_plate();
    arm_raw();
    mirror([1,0,0]) arm_raw();
    holder();
    mirror([1,0,0]) holder();
}
