// dimensions in mm

// Eurorack constants
HP = 5.08;
U = 1.25 * 25.4;

// measured
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
m_output_jack_body_width = 8;  // includes SMD lead footprint area
m_output_jack_protrusion = 8 - m_board_thick;
m_mounting_hole_diameter = 3.19;

// 9v battery compartment dimensions
bat_width = 53.12 /* measured with extra for snap */;
bat_frontback = 25.73 /* measured */ + 2 /* slop */;
bat_thick = 17.39 /* measured */ + 2 /* slop */;
bat_radius = 2.5;

// chosen parameters
panel_tolerance = 0.1;
output_jack_clearance_dia = 10.0;
epsilon = 0.2;
extra_component_clearance = 2;
smd_lead_protrusion = 1;  // space to allow for thickness of smd leads above board
screw_diameter = 1;
screw_min_length = 5;

// derived parameters
used_panel_width = 30 * HP + panel_tolerance * 2;
used_panel_height = m_panel_height + panel_tolerance * 2;
case_wall_thick = m_board_thick;

module screw_hole() {
    // TODO: pick screw hole diameter -- is not the same as Hyve holes unless we decide to go for a bolt & nut instead of screwing into plastic
    translate([0, 0, -30])
    cylinder(r=screw_diameter, h=999);
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
            
difference() {
    color("gray")
    minkowski() {
        sphere(r=case_wall_thick, $fn=10);
        difference() {
            // main body shape
            translate([0, 0, 0])
            slant_box(
                dx=used_panel_width,
                dy=used_panel_height + bat_frontback,
                dz1=-screw_min_length,
                // ratio adjustment prevents slope from cutting off battery compartment entry
                dz2=-bat_thick * ((used_panel_height + bat_frontback) / used_panel_height));
            
            // remove material around non-battery edge, decoratively
            xstep = 5;
            ydist = bat_frontback;
            translate([
                m_edge_to_bat_jack_far_edge,
                used_panel_height,
                0])
            linear_extrude(height=999, center=true)
            polygon([
                [-999, 999],  // left end dummy point
                [xstep * 0, ydist * 1.0],
                [xstep * 1, ydist * 0.7],
                [xstep * 1, ydist * 0.3], 
                [xstep * 2, ydist * 0], 
                [used_panel_width + epsilon, 0],
                [999, 0]  // right end dummy point
            ]);
            
            // subtract output jack hole to make nice rounded area
            translate([
                used_panel_width - m_right_edge_to_output_jack_center,
                used_panel_height - m_clearance_top - case_wall_thick - epsilon,
                -m_top_to_output_jack_center])
            rotate([-90, 0, 0])
            cylinder(r=output_jack_clearance_dia / 2 + case_wall_thick, h=999, $fn=6);
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
        slant_box(
            dx=used_panel_width - m_clearance_leftright * 2,
            dy=used_panel_height - m_clearance_bottom - m_clearance_top,
            dz1=-(epsilon + extra_component_clearance + 0),
            dz2=-(epsilon + extra_component_clearance + m_max_protrusion)
        );
    }
    
    // battery compartment interior volume
    color("Green")
    translate([0, m_panel_height, -bat_thick])
    //cube([bat_width, bat_frontback, bat_thick]);
    rounded_box(r=bat_radius, xyz=[bat_width, bat_frontback, bat_thick]);
    
    // battery compartment opening
    translate([10, m_panel_height + bat_frontback - bat_radius * 2 - epsilon, -bat_thick])
    rounded_box(r=bat_radius, xyz=[bat_width - 10, 99, bat_thick]);
    
    // battery compartment wiring passage
    color("Goldenrod")
    translate([
        bat_width - epsilon,
        m_panel_height - m_clearance_top - epsilon,
        -bat_thick*0.9])
    cube([
        m_edge_to_bat_jack_far_edge - bat_width + epsilon,
        bat_frontback + m_clearance_top + epsilon,
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
    
    // mounting screw holes
    translate([used_panel_width / 2, used_panel_height / 2, 0]) {
        translate([m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
    }
};