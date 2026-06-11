use <MCAD/regular_shapes.scad>

echo(version = version());

fn = 300; // sets the smoothness of the cylinder

// monitor_hook dimensions
monitor_hook_width = 45;
monitor_hook_front = 13;
section_height = 30;
section_z_trans = - 10;

// meaurements for the isight oval base:
isight_length = 37;
isight_width = 23;
isight_pizero_slot = 5;

module monitor_hook() {
    difference()
        {
            cube([monitor_hook_width, 25, monitor_hook_front], center = true);
            translate([0, 0, - 3]) cube([monitor_hook_width + 1, 20, monitor_hook_front], center = true);
        }
    translate([0, 11, section_z_trans]) cube([45, 3, section_height], center = true);
}


module my_tube() {
    color("green")
        translate([0, 20, - 10])
            rotate(a = [0, 90, 90])
                cube([30, 10, 15], center = true);
}


module rear_tube() {
    hull() {
        my_tube();
        translate([0, isight_length + 5, 0]) isight_base();
    }
    translate([0, isight_length + 5, 10]) isight_base();
}

module isight_base(extrude = 15) {
    difference() {
        linear_extrude(extrude)
            hull() {
                translate([0, isight_width / 2, 0]) circle(r = isight_width / 2);
                translate([0, isight_length - isight_width / 2, 0]) circle(r = isight_width / 2);
            };
        translate([- isight_pizero_slot / 2, 0, - 1]) cube([isight_pizero_slot, isight_length, extrude + 2]);
    }
}

// now build everything
color("blue")
    difference()
        {
            rear_tube();
            translate([- isight_pizero_slot / 2, 42, - 50]) cube([isight_pizero_slot, isight_length, 80]);
        };


monitor_hook();
