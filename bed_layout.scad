// Bed layout: base + 2 clamps on Dremel 3D45 254x152 plate
$fn = 60;

// Bed
color([0.3,0.5,0.8,0.4]) translate([0,0,-1]) cube([254,152,1], center=true);

// Base: disc already sits with bottom at z=-5; shift up by 5 so z=0 is bed.
color([0.85,0.85,0.9])
  translate([-40, 0, 5]) import("base.stl");

// Clamp: cut-plane normal is (cos36.94, 0, sin36.94). Rotate by 126.94 about Y
// to lay flat face down. Then translate to bed.
// Two copies, side by side.
color([0.9,0.7,0.7])
  translate([70, -25, 0]) rotate([0,53.06,0]) translate([38.13,0,-40.39]) import("clamp.stl");
color([0.9,0.7,0.7])
  translate([70,  25, 0]) rotate([0,53.06,0]) translate([38.13,0,-40.39]) import("clamp.stl");
