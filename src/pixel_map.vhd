LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.game_of_life_pkg.ALL;

ENTITY pixel_map IS
    PORT (
        h_count     : IN  INTEGER RANGE 0 TO H_TOTAL - 1;
        v_count     : IN  INTEGER RANGE 0 TO V_TOTAL - 1;
        state       : IN  state_type;
        fsm_d_addr  : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        d_do        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        video_on    : OUT STD_LOGIC;
        vga_d_addr  : INOUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        d_addr      : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        vga_r       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY pixel_map;

ARCHITECTURE pixel_map_arch OF pixel_map IS

signal v_on : std_logic := '0';

BEGIN

    -- 3. Read Address Lookup from Display Array (Scales 640x480 to 32x24 grid)
    -- Grid Cell Index = (v_count / 20) * 32 + (h_count / 20)
    video_on <= '1' WHEN (h_count < H_ACTIVE) AND (v_count < V_ACTIVE) ELSE '0';

    vga_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(((v_count / 20) * GRID_WIDTH) + (h_count / 20), 10))
                  WHEN v_on = '1' ELSE (OTHERS => '0');

    d_addr <= fsm_d_addr WHEN state = COPY_TO_DISPLAY ELSE vga_d_addr;

    -- 5. VGA Active Area Guard & Color Outputs from Display Memory
    vga_r <= "1111" WHEN (v_on = '1' AND d_do /= "00") ELSE "0000";
    vga_g <= "1111" WHEN (v_on = '1' AND d_do /= "00") ELSE "0000";
    vga_b <= "1111" WHEN (v_on = '1' AND d_do /= "00") ELSE "0000";
    
    video_on <= v_on;

END ARCHITECTURE pixel_map_arch;
