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

used_panel_width = 30 * HP;
used_panel_height = m_panel_height;


difference() {
    minkowski() {
        cube([used_panel_width, used_panel_height, 1]);
        sphere(2, $fs=0.1);
    }
    cube([m_panel_width, m_panel_height, 999]);
};