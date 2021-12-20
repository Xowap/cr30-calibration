/**
 * CR-30 Calibration Bridge
 *
 * Since the CR-30 has a belt and a 45° nozzle, it's complicated to use
 * the standard calibration towers that you would use for another
 * printer. The goal of this file is to allow the generation of
 * adapted calibration bridges (we don't need to stack them up since
 * we've got an infinite Z-axis).
 *
 * Once generated and sliced you of course need to modify the gcode to
 * reflect the setting changes during the print. This can be done with
 * the regular Cura plugin by example.
 */


/*[ Print Settings ]*/

// Size of the layer you're going to print
layer_size = 0.2; // [0.1:0.01:0.4]

// Enable 45° inclination (makes overhang comparable to non-belt printer)
inclinate_45deg = true;


/*[ Tested Value ]*/

// First value
value_start = 1;

// Value increment between bridges
value_increment = 1;

// Do not go above this value
value_stop = 12;


/*[ Printed Text ]*/

// Top Text Prefix
text_prefix = "PLA/PHA ";

// Top Text Suffix
text_suffix = "mm";

// Text Font
font = "Liberation Sans:style=Bold";


/*[ Bridge Dimensions ]*/

width_layers = 210;
cube_layers = 40;
bridge_layers = 5;
text_layers = 2;
engravure_layers = 2;
margin_layers = 10;
plate_layers = 2;

width = width_layers * layer_size;
cube_size = cube_layers * layer_size;
bridge_thickness = bridge_layers * layer_size;
text_depth = text_layers * layer_size;
engravure_depth = engravure_layers * layer_size;
plate_height = plate_layers * layer_size;


build();
//retract_bridge_support_foot(true);
//corners_eater();


/**
 * Adds and repeats bridges for each configured value
 */
module build() {
    max_i = floor((value_stop - value_start) / value_increment);

    for (i = [0 : max_i]) {
        translate([
            0,
            (i + 1) * 2 * (cube_size + margin_layers * layer_size),
            0
        ])
        retract_bridge(i * value_increment + value_start);
    }

    clear();
}

/**
 * Builds up a bridge according to specifications, especially depending
 * on if the bridge should be inclined or not.
 */
module retract_bridge(value) {
    union() {
        translate([0, 0, plate_height]) {
            if (inclinate_45deg) {
                union() {
                    rotate([45, 0, 0])
                    retract_bridge_base(value);

                    retract_bridge_support();
                }
            } else {
                retract_bridge_base(value);
            }
        }

        retract_bridge_plate();
    }
}

/**
 * Generates the full support for the inclined bridge by putting two
 * support feet at the right location.
 */
module retract_bridge_support() {
    union() {
        retract_bridge_support_foot(false);

        translate([width - cube_size, 0, 0])
        retract_bridge_support_foot(true);
    }
}

module retract_bridge_support_foot(circular) {
    if (!circular) {
        retract_bridge_support_foot_base();
    } else {
        intersection() {
            rotate([45, 0, 0])
            translate([cube_size / 2, cube_size / 2, -cube_size])
            cylinder(h=cube_size * 2, r=cube_size / 2, $fn=cube_layers * 2);

            retract_bridge_support_foot_base();
        }
    }
}

/**
 * A support foot, which is just an extruded square and isosceles
 * triangle to incline the bridge by 45°
 */
module retract_bridge_support_foot_base() {
    side_size = cube_size / sqrt(2);

    translate([cube_size, side_size, 0])
    rotate([90, 0, 270])
    linear_extrude(cube_size)
    polygon([
        [0, 0],
        [0, side_size],
        [side_size, 0]
    ]);
}

/**
 * The plate that supports the bridge. It's thin but it's here to
 * maximize adhesion to the belt and keep the distance between the two
 * feet guarranteed.
 */
module retract_bridge_plate() {
    plate_width = cube_size;

    if (plate_height > 0) {
        if (inclinate_45deg) {
            cube([width, cube_size / sqrt(2), plate_height]);
        } else {
            cube([width, cube_size, plate_height]);
        }
    }
}

/**
 * Basic shape of the bridge, copied from one layer of a traditional
 * temperature tower.
 */
module retract_bridge_base(value) {
    difference() {
        union() {
            cube([cube_size, cube_size, cube_size]);

            translate([width - cube_size, 0, 0])
            translate([cube_size / 2, cube_size / 2, 0])
            cylinder(h=cube_size, r=cube_size/2, $fn=cube_layers * 2);

            translate([0, 0, cube_size - bridge_thickness])
            cube([width, cube_size, bridge_thickness]);

            translate([width / 2, cube_size / 2, cube_size])
            linear_extrude(text_depth)
            text(
                str(text_prefix, value, text_suffix), 
                size=cube_size * 0.45, 
                valign = "center",
                halign = "center",
                font = font,
                $fn = cube_layers
            );
        }

        translate([cube_size, cube_size - engravure_depth, cube_size / 2])
        rotate([90, 0, 180])
        translate([cube_size / 2, 0, 0])
        linear_extrude(engravure_depth + 1)
        text(
            str(value), 
            size = cube_size * 0.35,
            font = font,
            valign = "center",
            halign = "center",
            $fn = cube_layers
        );

        translate([width - cube_size, 0, 0])
        translate([cube_size, 0, 0])
        rotate([0, 0, 90])
        translate([0, 0, cube_size / 2 + plate_height])
        corners_eater();
    }
}

module corners_eater() {
    difference() {
        translate([-1, -1, 0])
        cube([cube_size + 2, cube_size + 2, cube_size + 1]);

        translate([cube_size / 2, cube_size / 2, -cube_size / 2])
        cylinder(h=cube_size * 2, r=cube_size / 2, $fn=cube_layers * 2);

        translate([-2, cube_size / 2, -4])
        cube([cube_size + 4, cube_size / 2 + 3, cube_size + 8]);
    }
}

/**
 * So apparently Cura doesn't want to print the last layer. By putting
 * this at the end of the print, it forces Cura to make the last layer
 * of the last bridge. And it doesn't get printed (because it becomes
 * itself the last layer and thus is ignored).
 */
module clear() {
    cube([width, layer_size, layer_size]);
}