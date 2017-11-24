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
m_clearance_leftright = 2.75;
m_clearance_bottom = 9;
m_clearance_top = 8;

// 9v battery compartment dimensions -- TODO not measured
bat_width = 53.12 /* measured with extra */;
bat_frontback = 25.73 /* measured */ + 2 /* slop */;
bat_thick = 17.39 /* measured */ + 2 /* slop */;

used_panel_width = 30 * HP;
used_panel_height = m_panel_height;

module screw_hole() {
    // TODO: pick screw hole diameter -- is not the same as Hyve holes unless we decide to go for a bolt & nut instead of screwing into plastic
    translate([0, 0, -30])
    cylinder(r=1, h=999);
}

difference() {
    minkowski() {
        translate([0, 0, -bat_thick])
        cube([used_panel_width, used_panel_height + bat_frontback, bat_thick]);
        sphere(r=m_board_thick, $fs=0.1);
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
    
    // holes
    translate([used_panel_width / 2, used_panel_height / 2, 0]) {
        translate([m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, m_hole_height / 2, 0]) screw_hole();
        translate([-m_hole_width / 2, -m_hole_height / 2, 0]) screw_hole();
    }
};