// Assembly: gripperlite + mounting plate
// Gripper mating surface at Z=0, plate below

$fn = 120;

// --- Mounting plate (below Z=0) ---
module mounting_plate() {
    plate_thickness = 5;
    outer_radius = 38.75;
    hole_radius = 6.4 / 2;
    hole_spacing = 31.5;

    translate([0, 0, -plate_thickness])
    difference() {
        cylinder(h = plate_thickness, r = outer_radius);

        translate([-hole_spacing, 0, -1])
            cylinder(h = plate_thickness + 2, r = hole_radius);

        translate([hole_spacing, 0, -1])
            cylinder(h = plate_thickness + 2, r = hole_radius);
    }
}

// --- Gripperlite reference part ---
module gripperlite() {
    color("SteelBlue", 0.7)
        import("gripperlite.stl", convexity=10);
}

// --- Assembly ---
gripperlite();
mounting_plate();
