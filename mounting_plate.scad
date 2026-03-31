// Mounting plate for gripperlite
// Matches the mating surface outline at Z=0
// Outer: circle r=38.75mm, two bolt holes d=6.4mm at X=±31.5

$fn = 120;  // smooth circles

plate_thickness = 5;  // mm
outer_radius = 38.75;
hole_diameter = 6.4;
hole_radius = hole_diameter / 2;
hole_spacing = 31.5;  // from center

difference() {
    // Main disc
    cylinder(h = plate_thickness, r = outer_radius, center = false);

    // Bolt hole 1 (X = -31.5, Y = 0)
    translate([-hole_spacing, 0, -1])
        cylinder(h = plate_thickness + 2, r = hole_radius);

    // Bolt hole 2 (X = +31.5, Y = 0)
    translate([hole_spacing, 0, -1])
        cylinder(h = plate_thickness + 2, r = hole_radius);
}
