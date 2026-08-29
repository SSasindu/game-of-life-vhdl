LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY main IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        hsync : OUT STD_LOGIC;
        vsync : OUT STD_LOGIC;
        vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);

        up : IN STD_LOGIC;
        down : IN STD_LOGIC;
        left : IN STD_LOGIC;
        right : IN STD_LOGIC
    );
END ENTITY main;

ARCHITECTURE main_arch OF main IS
    SIGNAL state : state_type := IDLE;
    SIGNAL h_count : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;
    SIGNAL v_count : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;

    -- RAM 1
    SIGNAL we_1 : STD_LOGIC := '0';
    SIGNAL addr_1 : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL di_1 : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL do_1 : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- RAM 2
    SIGNAL we_2 : STD_LOGIC := '0';
    SIGNAL addr_2 : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL di_2 : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL do_2 : STD_LOGIC_VECTOR(1 DOWNTO 0);

    --  
    SIGNAL select_array : STD_LOGIC := '0'; -- select_array = '0' means arr_1 is being displayed
    SIGNAL fsm_b_we : STD_LOGIC;
    SIGNAL fsm_b_addr : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL fsm_b_di : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL fsm_d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL fsm_d_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL vga_addr : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL vga_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

BEGIN
    arr_1 : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => we_1,
            addr => addr_1,
            di => di_1,
            do => do_1
        );

    arr_2 : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => we_2,
            addr => addr_2,
            di => di_2,
            do => do_2
        );

    vga_timing_inst : ENTITY work.vga_timing
        PORT MAP(
            clk_100mhz => clk_100mhz,
            rst => rst,
            h_count => h_count,
            v_count => v_count,
            hsync => hsync,
            vsync => vsync
        );

    frame_update_inst : ENTITY work.frame_update
        PORT MAP(
            clk_100mhz => clk_100mhz,
            rst => rst,
            state => state,

            b_we => fsm_b_we,
            b_addr => fsm_b_addr,
            b_di => fsm_b_di,

            d_addr => fsm_d_addr,
            d_do => fsm_d_do,

            select_array => select_array
        );

    pixel_map_inst : ENTITY work.pixel_map
        PORT MAP(
            h_count => h_count,
            v_count => v_count,
            
            clk_100mhz => clk_100mhz,
            rst => rst,

            do => vga_do,
            vga_addr => vga_addr,

            up => up,
            down => up,
            left => left,
            right => right,

            vga_r => vga_r,
            vga_g => vga_g,
            vga_b => vga_b
        );

    we_1 <= fsm_b_we WHEN select_array = '1' ELSE
        '0';
    addr_1 <= fsm_b_addr WHEN select_array = '1' ELSE
        fsm_d_addr WHEN (state = WAIT_READ OR state = ACCUMULATE) ELSE
        vga_addr;
    di_1 <= fsm_b_di;

    we_2 <= fsm_b_we WHEN select_array = '0' ELSE
        '0';
    addr_2 <= fsm_b_addr WHEN select_array = '0' ELSE
        fsm_d_addr WHEN (state = WAIT_READ OR state = ACCUMULATE) ELSE
        vga_addr;
    di_2 <= fsm_b_di;

    fsm_d_do <= do_1 WHEN select_array = '0' ELSE
        do_2;
    vga_do <= do_1 WHEN select_array = '0' ELSE
        do_2;
END main_arch;