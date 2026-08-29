LIBRARY ieee;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY pixel_map IS
    PORT (
        h_count : IN INTEGER RANGE 0 TO H_TOTAL - 1;
        v_count : IN INTEGER RANGE 0 TO V_TOTAL - 1;
        do : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        clk_100mhz: in std_logic;
        rst : in std_logic;

        vga_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

        up : IN STD_LOGIC;
        down : IN STD_LOGIC;
        left : IN STD_LOGIC;
        right : IN STD_LOGIC;

        vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY pixel_map;

ARCHITECTURE pixel_map_arch OF pixel_map IS
    SIGNAL v_on : STD_LOGIC := '0';

    -- Player position and logic
    SIGNAL is_player_cell : STD_LOGIC;
    SIGNAL current_cell_x : INTEGER RANGE 0 TO 63;
    SIGNAL current_cell_y : INTEGER RANGE 0 TO 63;

    -- Border marking
    SIGNAL is_grid_line : STD_LOGIC;
    
        -- Player positions and status signals
    SIGNAL player_x : INTEGER RANGE 0 TO 31;
    SIGNAL player_y : INTEGER RANGE 0 TO 23;
BEGIN
    -- Player Entity
    player_inst : ENTITY work.player

        PORT MAP(
            clk => clk_100mhz,
            rst => rst,
            up => up,
            down => down,
            left => left,
            right => right,
            player_x_out => player_x,
            player_y_out => player_y
        );
    v_on <= '1' WHEN (h_count < H_ACTIVE) AND (v_count < V_ACTIVE) ELSE
        '0';

    -- 3. Read Address Lookup from Display Array (Scales 640x480 to 32x24 grid)
    current_cell_x <= h_count / 20;
    current_cell_y <= v_count / 20;
    -- Detect if VGA is scanning the player's cell
    is_player_cell <= '1' WHEN (v_on = '1' AND current_cell_x = player_x AND current_cell_y = player_y) ELSE
        '0';

    -- Cell is 20 by 20 px. So grid line is drawn every 20 px.
    is_grid_line <= '1' WHEN (v_on = '1' AND (h_count MOD 20 = 0 OR v_count MOD 20 = 0)) ELSE
        '0';

    -- Generate read address for VGA screen scanout
    vga_addr <= STD_LOGIC_VECTOR(to_unsigned(((v_count/20) * GRID_WIDTH) + (h_count / 20), 10));

    -- Green ---> Player
    -- White ---> Live cell
    -- Black ---> Dead cell
    vga_r <= "0000" WHEN (is_player_cell = '1') ELSE
        "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0010" WHEN (is_grid_line = '1') ELSE
        "0000";
    vga_g <= "1111" WHEN (is_player_cell = '1')  ELSE
        "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0010" WHEN (is_grid_line = '1') ELSE
        "0000";
    vga_b <= "0000" WHEN (is_player_cell = '1') ELSE
        "1111" WHEN (v_on = '1' AND do = "01") ELSE
        "0010" WHEN (is_grid_line = '1') ELSE
        "0000";
END ARCHITECTURE pixel_map_arch;