// dimensions in mm

// options
open_back = false;
truncated = false;
flat_bottom = false;

// Eurorack constants
HP = 5.08;
U = 1.25 * 25.4;

// measured
// "protrusion" means component height perpendicular to back of board
m_panel_width = 152.46;
m_panel_height = 128.48;
m_hole_width = 137.33;
m_hole_height = 122.33;
echo("hp panel", m_panel_width / HP, m_panel_height / U);
echo("hp hole", m_hole_width / HP, m_hole_height / U);
m_board_thick = 2.05;
m_max_thick = 13.52;
m_max_protrusion = m_max_thick - m_board_thick;
m_clearance_leftright = 2.5;
m_clearance_bottom = 8;
m_clearance_top = 7;
m_clearance_top_jack_leads = 3;  // how far in from edge you can go before hitting a lead
m_edge_to_bat_jack_far_edge = 83.5;  // includes SMD lead footprint area
m_right_edge_to_output_jack_center = 29.0;
m_top_to_output_jack_center = 4.52;
m_output_jack_smd_width = 10.3;  // includes SMD lead footprint area
m_output_jack_body_width = 6 + 1 /* slop */;
m_output_jack_protrusion = 7.44 + 0.5 /* slop */ - m_board_thick;
m_mounting_hole_diameter = 3.19;
m_hack_pad_to_top = 40.5;

// 9v battery compartment dimensions, semi-chosen
bat_width = 52.46 /* diagonal size of battery, to allow tilting it into the compartment */;
bat_frontback = 25.73 /* measured */ + 2 /* slop */;
bat_thick = 17.39 /* measured */ + 1 /* slop */;
bat_radius = 2.5;
bat_opening_width = 45.0;
bat_opening_offset = 10.0;

// chosen parameters
panel_tolerance = 0.12;
output_jack_clearance_dia = 10.0;
epsilon = 0.2;
extra_component_clearance = 2;
smd_lead_protrusion = 1;  // space to allow for thickness of smd leads above board
screw_diameter = 2.1;  // tapping size for #3 coarse screw (#4 will fit but requires perfect alignment and we can always drill out)
screw_min_length = 1/4 * 25.4;  // 1/4" screws
hack_pad_y_clearance = 20;
wiring_frontback = 22;

// derived parameters
used_panel_width = 30 * HP + panel_tolerance * 2;
used_panel_height = m_panel_height + panel_tolerance * 2;
case_wall_thick = m_board_thick;

module screw_hole() {
    translate([0, 0, -30])
    cylinder(r=screw_diameter / 2, h=999);
}

module slant_box(dx, dy, dz1, dz2) {
    rotate([0, 90, 0])
    linear_extrude(height=dx, center=false)
    polygon([[0, 0], [0, dy], [-dz2, dy], [-dz1, 0]]);
}

module rounded_box(r, xyz) {
    translate([r, r, r])
    minkowski() {
        // TODO: An octahedron would be more useful and accurate, because sphere() does not extend fully to top/bottom ends
        sphere(r=r, $fn=16);
        cube([xyz[0] - r*2, xyz[1] - r*2, xyz[2] - r*2]);
    }
}

main_body_dy = used_panel_height + bat_frontback;
main_body_dz1 = -(screw_min_length - 2 * case_wall_thick);
// ratio adjustment prevents slope from cutting off battery compartment entry
main_body_dz2 = -bat_thick * ((used_panel_height + bat_frontback) / used_panel_height);

rotate([
    flat_bottom ? atan2(main_body_dz1 - main_body_dz2, main_body_dy) : 0,
    0, 0])  
difference() {
    color("gray")
    minkowski() {
        sphere(r=case_wall_thick, $fn=10);
        difference() {
            // main body shape
            translate([0, 0, 0])
            slant_box(
                dx=used_panel_width,
                dy=main_body_dy,
                dz1=main_body_dz1,
                dz2=main_body_dz2);
            
            if (truncated) {
                translate([-epsilon, -epsilon, -500])
                cube([999, used_panel_height * 0.9, 1000]);
            }
            
            // remove material around non-battery edge, decoratively
            xstep = 8;
            ydist = bat_frontback;
            translate([
                m_edge_to_bat_jack_far_edge,
                used_panel_height,
                0])
            linear_extrude(height=999, center=true)
            polygon([
                [-999, 999],  // left end dummy point
                [xstep * -1, ydist * 1.0],
                [xstep * 0, ydist * 0.8],
                [xstep * 0, ydist * 0.2], 
                [xstep * 1, ydist * 0], 
                [used_panel_width + epsilon, 0],
                [999, 0]  // right end dummy point
            ]);
            
            // subtract output jack hole to make nice rounded area
            hexagon_inscribed = sqrt(3)/2;  // we're making a hexagon but want room for a circle
            translate([
                used_panel_width - m_right_edge_to_output_jack_center,
                used_panel_height - m_clearance_top - case_wall_thick - epsilon,
                m_board_thick - m_top_to_output_jack_center])
            rotate([-90, 0, 0])
            cylinder(
                d=output_jack_clearance_dia / hexagon_inscribed + case_wall_thick,
                h=999, $fn=6);
        }
    }
     
    color("RoyalBlue")
    union() {
        // cutout for board
        cube([used_panel_width, used_panel_height, 999]);
        
        // cutout for components
        translate([
            m_clearance_leftright,
            m_clearance_bottom,
            epsilon
        ])
        scale([1, 1, open_back ? 10 : 1])  // just punch through if option is set
        slant_box(
            dx=used_panel_width - m_clearance_leftright * 2,
            dy=used_panel_height - m_clearance_bottom - m_clearance_top,
            dz1=-max(
                // necessary clearance
                epsilon + extra_component_clearance + 0,
                // empirically set minimum-plastic-volume
                screw_min_length - case_wall_thick),
            dz2=-max(
                // necessary clearance
                epsilon + extra_component_clearance + m_max_protrusion,
                // empirically set minimum-plastic-volume
                bat_thick)
        );
        
        // cutout for "Hack" terminals (bigger than necessary, but would allow, like, connecting a jack there if we wanted)
        rounding = m_clearance_leftright * 2;
        extra_clearance = hack_pad_y_clearance + rounding * 2;
        translate([
            used_panel_width - rounding * 3,
            used_panel_height - m_hack_pad_to_top - extra_clearance / 2, 
            -13])
        rounded_box(r=rounding, xyz=[
            rounding * 3,
            extra_clearance,
            18]);
    }
    
    // battery compartment interior volume
    color("Green")
    translate([0, m_panel_height, -bat_thick])
    //cube([bat_width, bat_frontback, bat_thick]);
    rounded_box(r=bat_radius, xyz=[bat_width, bat_frontback, bat_thick]);
    
    // battery compartment opening
    translate([
        bat_opening_offset,
        m_panel_height + bat_frontback / 2,
        -bat_thick])
    rounded_box(r=bat_radius, xyz=[bat_opening_width, 99, bat_thick]);
    
    // battery compartment wiring passage
    color("Goldenrod")
    translate([
        bat_width - epsilon,
        m_panel_height - m_clearance_top - epsilon,
        -bat_thick*0.9])
    cube([
        m_edge_to_bat_jack_far_edge - bat_width + epsilon,
        wiring_frontback + m_clearance_top + epsilon,
        bat_thick*0.9 + epsilon]);
    
    // output jack clearance
    translate([
        used_panel_width - m_right_edge_to_output_jack_center,
        used_panel_height,
        0])
    union() {
        // SMD footprint
        translate([
            -m_output_jack_smd_width / 2,
            -m_clearance_top - epsilon,
            -smd_lead_protrusion])
        cube([
            m_output_jack_smd_width,
            m_clearance_top - m_clearance_top_jack_leads + epsilon,
            smd_lead_protrusion + epsilon]);
        // main body
        translate([
            - m_output_jack_body_width / 2,
            - m_clearance_top - epsilon,
            -m_output_jack_protrusion])
        cube([
            m_output_jack_body_width,
            m_clearance_top + epsilon,
            m_output_jack_protrusion + epsilon]);
    }
    
    // power switch mounting hole
    power_switch_body_clearance = 16;  // estimated
    power_switch_body_depth = 16;  // estimated
    power_switch_hole_diameter = 5.81;  // somewhat over 7/32"
    power_switch_key_depth = 0.69;
    power_switch_key_width = 1.0;
    // power_switch_washer_key_width = 2.2;
    // power_switch_washer_key_height = 1.45;
    translate([
        used_panel_width - m_right_edge_to_output_jack_center - 18,
        used_panel_height,
        -bat_thick / 2]) {
        // panel mount hole, with anti-rotation key
        rotate([-90, 0, 0])
        translate([0, 0, -epsilon])
        difference() {
            cylinder(d=power_switch_hole_diameter, h=99);
            translate([-power_switch_key_width / 2, -power_switch_hole_diameter / 2, 0])
            cube([power_switch_key_width, power_switch_key_depth, 99]);
        }
        
        // switch body clearance
        translate([
            -power_switch_body_clearance / 2,
            0,
            power_switch_body_clearance / 2])
        slant_box(
            dx=power_switch_body_clearance,
            dy=-max(m_clearance_top + epsilon, power_switch_body_depth),
            dz1=-power_switch_body_clearance,
            dz2=-power_switch_body_clearance);
    }
    
    // mounting screw holes
    translate([used_panel_width / 2, used_panel_height / 2, 0]) {
        translate([m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
    }
};