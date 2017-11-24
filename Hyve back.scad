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
m_edge_to_bat_jack_far_edge = 82;
m_right_edge_to_output_jack_center = 29.0;
m_top_to_output_jack_center = 4.52;

// 9v battery compartment dimensions -- TODO not measured
bat_width = 53.12 /* measured with extra for snap */;
bat_frontback = 25.73 /* measured */ + 2 /* slop */;
bat_thick = 17.39 /* measured */ + 2 /* slop */;

used_panel_width = 30 * HP;
used_panel_height = m_panel_height;

// chosen parameters
bat_wiring_width = 30;
output_jack_clearance_dia = 10.0;
epsilon = 0.5;

// derived parameters
case_wall_thick = m_board_thick;

module screw_hole() {
    // TODO: pick screw hole diameter -- is not the same as Hyve holes unless we decide to go for a bolt & nut instead of screwing into plastic
    translate([0, 0, -30])
    cylinder(r=1, h=999);
}

module slant_box(dx, dy, dz1, dz2) {
    rotate([0, 90, 0])
    linear_extrude(height=dx, center=false)
    polygon([[0, 0], [0, dy], [-dz2, dy], [-dz1, 0]]);
}
            
difference() {
    minkowski() {
        sphere(r=case_wall_thick, $fs=1);
        difference() {
            // main body shape
            translate([0, 0, 0])
            slant_box(
                dx=used_panel_width,
                dy=used_panel_height + bat_frontback,
                dz1=-m_max_protrusion,  // TODO not best choice
                dz2=-bat_thick);
            
            // subtract non-battery edge
            translate([
                m_edge_to_bat_jack_far_edge,
                used_panel_height,
                -100])
            cube([100, 100, 200]);
            
            // subtract output jack hole
            translate([
                used_panel_width - m_right_edge_to_output_jack_center,
                used_panel_height - m_clearance_top - case_wall_thick - epsilon,
                -m_top_to_output_jack_center])
            rotate([-90, 0, 0])
            cylinder(r=output_jack_clearance_dia / 2 + case_wall_thick, h=999, $fn=6);
        }
    }
     
    // cutout for board -- TODO add tolerance
    cube([used_panel_width, m_panel_height, 999]);
    
    // cutout for components
    translate([
        m_clearance_leftright,
        m_clearance_bottom,
        -m_max_protrusion  // TODO add tolerance
    ])
    cube([
        used_panel_width - m_clearance_leftright * 2,
        used_panel_height - m_clearance_bottom - m_clearance_top,
        999
    ]);
    
    // battery compartment interior volume
    translate([0, m_panel_height, -bat_thick])
    cube([bat_width, bat_frontback, bat_thick]);
    
    // battery compartment opening
    translate([10, m_panel_height, -bat_thick])
    cube([bat_width - 10, 999, bat_thick]);
    
    // battery compartment wiring passage
    translate([
        m_edge_to_bat_jack_far_edge - bat_wiring_width - epsilon,
        m_panel_height - m_clearance_top - epsilon,
        -bat_thick*0.9])
    cube([
        bat_wiring_width + epsilon,
        bat_frontback + m_clearance_top + epsilon,
        bat_thick*0.9 + epsilon]);
    
    // holes
    translate([used_panel_width / 2, used_panel_height / 2, 0]) {
        translate([m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
    }
};