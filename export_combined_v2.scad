$fn = 120;

module mounting_plate() {
    plate_thickness = 5;
    outer_radius = 38.75;
    translate([0, 0, -plate_thickness])
        cylinder(h = plate_thickness, r = outer_radius);
}

module arm_raw() {
    cam_x = -38.13; tilt_angle = 36.94;
    arm_width = 15.25; arm_depth = 8; outward_ext = 8;
    hull() {
        translate([cam_x, 0, 40.39]) rotate([0, tilt_angle, 0])
            translate([0, 0, 5]) cube([arm_depth, arm_width, 10], center = true);
        translate([-38.75 + arm_depth/2 - outward_ext/2, 0, -2.5])
            cube([arm_depth + outward_ext, arm_width, 5], center = true);
    }
}

module cutcylinder() {
    cylinder(h = 20, r = 37);
}

cam_x = -38.13;
tilt_angle = 36.94;

difference() {
    union() {
        mounting_plate();
        difference() {
            arm_raw();
            import("gripperlite.stl", convexity=10);
            translate([-39.5, -8, 0]) cube([5, 16, 5]);
            cutcylinder();
        }
        translate([cam_x, 0, 40.39]) rotate([0, tilt_angle, 0])
            difference() {
                cylinder(h = 10, d = 15.25);
                translate([0, 0, -1]) cylinder(h = 12, d = 7.25);
            }
    }

    // Camera bore for insertion clearance
    translate([cam_x, 0, 40.39])
        rotate([0, tilt_angle, 0])
            translate([0, 0, -200])
                cylinder(h = 400, d = 7.25);

    // Mounting bolt holes (cut last)
    translate([-31.5, 0, -6])
        cylinder(h = 50, r = 6.4 / 2);
    translate([31.5, 0, -6])
        cylinder(h = 50, r = 6.4 / 2);
}
