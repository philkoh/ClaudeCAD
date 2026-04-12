// Cross-section detail of one stepped screw hole in the base
$fn = 80;

// Show as if looking at the screw axis vertically.
// Boss: cylinder d=12, h=10. Hole: d=5.2 x 6 deep, then d=4.3 x 6 deep below it.
difference() {
    union() {
        // boss
        cylinder(h=10, d=12);
        // some surrounding material below to show full hole
        translate([0,0,-8]) cylinder(h=8, d=18);
    }
    // upper section: d=5.2, 6 deep, starting 5mm from top (matches "translate -5, h=6")
    translate([0,0,-1]) cylinder(h=6, d=5.2);
    // lower section: d=4.3, 6 deep, starting 11mm below top
    translate([0,0,-7]) cylinder(h=6, d=4.3);
    // Cut away front half to expose cross-section
    translate([-50,0,-20]) cube([100,50,40]);
}

// Dimension labels as thin colored markers
color([1,0,0]) translate([2.6,0.1,2]) cube([0.1,0.1,0.1]); // marker
