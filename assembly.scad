// Assembly: gripperlite + mounting plate
// Gripper mating surface at Z=0, plate below

$fn = 120;

// --- Mounting plate (below Z=0) ---
module mounting_plate() {
    plate_thickness = 5;
    outer_radius = 38.75;

    translate([0, 0, -plate_thickness])
        cylinder(h = plate_thickness, r = outer_radius);
}

// --- Gripperlite reference part ---
module gripperlite() {
    color("SteelBlue", 0.7)
        import("gripperlite.stl", convexity=10);
}

// --- Camera1 (aimed at FocusPoint, 2mm clearance to rim) ---
module camera1() {
    cam_diameter = 7.25;
    cam_length = 38.44;
    cam_x = -38.13;
    tilt_angle = 36.94;  // degrees from vertical, aimed at FocusPoint

    color("OrangeRed")
        translate([cam_x, 0, 40.39])     // bottom center
            rotate([0, tilt_angle, 0])    // tilt toward FocusPoint
                cylinder(h = cam_length, d = cam_diameter);
}

// --- Holder1 (cylindrical sleeve around bottom 10mm of camera1) ---
module holder1() {
    cam_diameter = 7.25;
    holder_length = 10;
    wall_thickness = 4;
    holder_od = cam_diameter + 2 * wall_thickness;  // 15.25mm
    cam_x = -38.13;
    tilt_angle = 36.94;

    color("ForestGreen", 0.8)
        translate([cam_x, 0, 40.39])
            rotate([0, tilt_angle, 0])
                difference() {
                    cylinder(h = holder_length, d = holder_od);
                    translate([0, 0, -1])
                        cylinder(h = holder_length + 2, d = cam_diameter);
                }
}

// --- Arm (connects holder1 to plate edge, rectangular XY cross-section) ---
module arm_raw() {
    cam_x = -38.13;
    tilt_angle = 36.94;
    holder_od = 15.25;
    arm_width = holder_od;   // Y dimension, matches holder
    arm_depth = 8;           // X dimension
    outward_ext = 8;         // extra thickness on outer face near bottom

    hull() {
        // Top: block at holder1 base
        translate([cam_x, 0, 40.39])
            rotate([0, tilt_angle, 0])
                translate([0, 0, 5])  // midpoint of holder
                    cube([arm_depth, arm_width, 10], center = true);

        // Bottom: block at plate edge, extended outward by 8mm
        translate([-38.75 + arm_depth/2 - outward_ext/2, 0, -2.5])
            cube([arm_depth + outward_ext, arm_width, 5], center = true);
    }
}

// --- Cutcylinder (clearance cylinder on Z-axis, r = gripper base r - 5mm) ---
module cutcylinder() {
    cylinder(h = 20, r = 37);
}

// --- Half of combined solid (one side, before YZ mirror) ---
module combined_half() {
    cam_diameter = 7.25;
    holder_length = 10;
    wall_thickness = 4;
    holder_od = cam_diameter + 2 * wall_thickness;
    cam_x = -38.13;
    tilt_angle = 36.94;

    difference() {
        union() {
            difference() {
                arm_raw();
                import("gripperlite.stl", convexity=10);
                translate([-39.5, -8, 0])
                    cube([5, 16, 5]);
                cutcylinder();
            }

            // Holder1
            translate([cam_x, 0, 40.39])
                rotate([0, tilt_angle, 0])
                    difference() {
                        cylinder(h = holder_length, d = holder_od);
                        translate([0, 0, -1])
                            cylinder(h = holder_length + 2, d = cam_diameter);
                    }

            // Screw bosses (mirrored about XZ)
            for (sy = [12, -12])
                translate([-37.62, sy, 46.27])
                    rotate([0, -53.06, 0])
                        translate([0, 0, -10])
                            cylinder(h = 10, d = 12);
        }

        // Camera bore
        translate([cam_x, 0, 40.39])
            rotate([0, tilt_angle, 0])
                translate([0, 0, -200])
                    cylinder(h = 400, d = cam_diameter);

        // Screw boss holes (mirrored about XZ)
        for (sy = [12, -12])
            translate([-37.62, sy, 46.27])
                rotate([0, -53.06, 0]) {
                    translate([0, 0, -5])
                        cylinder(h = 6, d = 5.2);
                    translate([0, 0, -11])
                        cylinder(h = 6, d = 4.3);
                }
    }
}

// --- Combined solid: symmetric about both XZ and YZ planes ---
module combined_solid() {
    color("ForestGreen", 0.8)
    difference() {
        union() {
            mounting_plate();
            combined_half();
            mirror([1, 0, 0]) combined_half();
        }

        // Mounting bolt holes (cut last)
        translate([-31.5, 0, -6])
            cylinder(h = 50, r = 6.4 / 2);
        translate([31.5, 0, -6])
            cylinder(h = 50, r = 6.4 / 2);
    }
}

// --- Rim highlight (elliptical ring at top of bell) ---
module rim_highlight() {
    rim_z = 56.5;
    semi_x = 20.23;
    semi_y = 30.10;
    ring_thickness = 1.5;

    color("Lime")
        translate([0, 0, rim_z])
            scale([semi_x + ring_thickness, semi_y + ring_thickness, 1])
                difference() {
                    cylinder(h = 1.5, r = 1, center = true, $fn = 120);
                    cylinder(h = 2, r = 1 - ring_thickness / semi_x, center = true, $fn = 120);
                }
}

// --- Distance line: rim to camera1 (1.00 mm) ---
module distance_line() {
    rim_pt = [-20.23, 0, 56.50];
    cam_pt = [-21.03, 0, 57.10];

    color("Yellow")
        hull() {
            translate(rim_pt) sphere(r = 0.5, $fn = 16);
            translate(cam_pt) sphere(r = 0.5, $fn = 16);
        }

    // Endpoint markers
    color("Yellow") {
        translate(rim_pt) sphere(r = 1.0, $fn = 24);
        translate(cam_pt) sphere(r = 1.0, $fn = 24);
    }
}

// --- FocusPoint (on Z axis at height of tallest point of reference) ---
module focus_point() {
    color("Magenta")
        translate([0, 0, 91.10])
            sphere(r = 1.5, $fn = 24);
}

// --- Screw1 (simplified fan-mount self-tapping screw, no threads) ---
module screw1() {
    shaft_d = 5.0;       // major thread diameter (M5)
    shaft_l = 10;        // shaft length (standard M5x10mm fan screw)
    head_d = 9.2;        // head diameter (DIN 965 countersunk)
    head_h = 2.5;        // head height (DIN 965 M5 k=2.5mm)

    // Position: 1mm clearance from holder1 outer surface,
    // axis perpendicular to cut plane (normal = (-0.799, 0, 0.601))
    screw_x = -37.62;
    screw_y = 12;
    screw_z = 46.27;
    // Screw axis rotation: 53.06° from Z about Y, then flip so head is outward
    screw_axis_rot = -53.06;  // negative to align with cut plane normal (-0.799, 0, 0.601)

    color("Silver")
        translate([screw_x, screw_y, screw_z])
            rotate([0, screw_axis_rot, 0]) {
                // Shaft (extends in -Z direction toward holder)
                translate([0, 0, -shaft_l])
                    cylinder(h = shaft_l, d = shaft_d);
                // Head
                cylinder(h = head_h, d = head_d);
            }
}

// --- Assembly ---
gripperlite();
combined_solid();
camera1();
screw1();
rim_highlight();
distance_line();
focus_point();
