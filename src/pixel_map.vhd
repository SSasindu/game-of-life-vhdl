LIBRARY ieee;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY pixel_map IS
    PORT (
        h_count : IN INTEGER RANGE 0 TO H_TOTAL - 1;
        v_count : IN INTEGER RANGE 0 TO V_TOTAL - 1;
        do : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        vga_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

        vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY pixel_map;

ARCHITECTURE pixel_map_arch OF pixel_map IS
    SIGNAL v_on : STD_LOGIC := '0';
BEGIN
    v_on <= '1' WHEN (h_count < H_ACTIVE) AND (v_count < V_ACTIVE) ELSE
        '0';
    -- Generate read address for VGA screen scanout
    vga_addr <= STD_LOGIC_VECTOR(to_unsigned(((v_count/20) * GRID_WIDTH) + (h_count / 20), 10));
    
    vga_r <= "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0000";
    vga_g <= "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0000";
    vga_b <= "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0000";
END ARCHITECTURE pixel_map_arch;