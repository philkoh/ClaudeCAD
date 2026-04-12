// Export just the combined solid for interference check
$fn = 120;

module mounting_plate() {
    plate_thickness = 5;
    outer_radius = 38.75;
    hole_radius = 6.4 / 2;
    hole_spacing = 31.5;
    translate([0, 0, -plate_thickness])
    difference() {
        cylinder(h = plate_thickness, r = outer_radius);
        translate([-hole_spacing, 0, -1]) cylinder(h = plate_thickness + 2, r = hole_radius);
        translate([hole_spacing, 0, -1]) cylinder(h = plate_thickness + 2, r = hole_radius);
    }
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
    translate([-31.5, 0, 0]) cylinder(h = 20, d = 16);
}

// Combined solid
union() {
    mounting_plate();
    difference() {
        arm_raw();
        import("gripperlite.stl", convexity=10);
        cutcylinder();
    }
    translate([-38.13, 0, 40.39]) rotate([0, 36.94, 0])
        difference() {
            cylinder(h = 10, d = 15.25);
            translate([0, 0, -1]) cylinder(h = 12, d = 7.4);
        }
}
