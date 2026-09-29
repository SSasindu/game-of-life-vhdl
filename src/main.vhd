LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY main IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        sw0 : IN STD_LOGIC := '0';
        sw1 : IN STD_LOGIC := '0';
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

    -- Random Cell Initialization
    SIGNAL init_done : STD_LOGIC := '1';
    SIGNAL init_we : STD_LOGIC := '0';
    SIGNAL init_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL init_di : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');

    -- Switch 0 edge detector to trigger randomization when turned ON
    SIGNAL sw0_reg1 : STD_LOGIC := '0';
    SIGNAL sw0_reg2 : STD_LOGIC := '0';
    SIGNAL start_init : STD_LOGIC := '0';
    -- Neighbor counting
    n_g_a_1 : IN STD_LOGIC;
    n_c_1 : OUT INTEGER RANGE -1 TO 9;
    n_c_a_1 : OUT STD_LOGIC;

    n_g_a_2 : IN STD_LOGIC;
    n_c_2 : OUT INTEGER RANGE -1 TO 9;
    n_c_a_2 : OUT STD_LOGIC;

    -- For the frame_update
    n_g_a : IN STD_LOGIC;
    n_c : OUT INTEGER RANGE -1 TO 9;
    n_c_a : OUT STD_LOGIC;
BEGIN
    -- Switch edge detection process
    PROCESS (clk_100mhz, rst)
    BEGIN
        IF rst = '1' THEN
            sw0_reg1 <= '0';
            sw0_reg2 <= '0';
            start_init <= '0';
        ELSIF rising_edge(clk_100mhz) THEN
            sw0_reg1 <= sw0;
            sw0_reg2 <= sw0_reg1;
            IF sw0_reg1 = '1' AND sw0_reg2 = '0' THEN
                start_init <= '1';
            ELSE
                start_init <= '0';
            END IF;
        END IF;
    END PROCESS;

    random_init_inst : ENTITY work.random_cell_init
        GENERIC MAP(
            ADDR_WIDTH => 10,
            DATA_WIDTH => 2,
            PLAYER_START_X => 16,
            PLAYER_START_Y => 20
        )
        PORT MAP(
            clk => clk_100mhz,
            rst => rst,
            done => init_done,
            we => init_we,
            addr => init_addr,
            di => init_di,
            start => start_init
        );

    arr_1 : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => we_1,
            addr => addr_1,
            di => di_1,
            do => do_1,

            neighbor_get_count => n_g_a_1,
            neighbor_count => n_c_1,
            neighbor_count_available => n_c_a_1
        );

    arr_2 : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => we_2,
            addr => addr_2,
            di => di_2,
            do => do_2,

            neighbor_get_count => n_g_a_2,
            neighbor_count => n_c_2,
            neighbor_count_available => n_c_a_2
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
            init_done => init_done,
            run => sw1,
            state => state,

            b_we => fsm_b_we,
            b_addr => fsm_b_addr,
            b_di => fsm_b_di,

            d_addr => fsm_d_addr,
            d_do => fsm_d_do,

            select_array => select_array,
            neighbor_get_count => n_g_a,
            neighbor_count => n_c,
            neighbor_count_available => n_c_a
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
            down => down,
            left => left,
            right => right,

            vga_r => vga_r,
            vga_g => vga_g,
            vga_b => vga_b
        );

    -- RAM 1 Multiplexing
    we_1 <= init_we WHEN init_done = '0' ELSE
        fsm_b_we WHEN select_array = '1' ELSE
        '0';

    addr_1 <= init_addr WHEN init_done = '0' ELSE
        fsm_b_addr WHEN select_array = '1' ELSE
        fsm_d_addr WHEN (state = WAIT_READ OR state = ACCUMULATE) ELSE
        vga_addr;

    di_1 <= init_di WHEN init_done = '0' ELSE
        fsm_b_di;

    -- RAM 2 Multiplexing
    we_2 <= init_we WHEN init_done = '0' ELSE
        fsm_b_we WHEN select_array = '0' ELSE
        '0';

    addr_2 <= init_addr WHEN init_done = '0' ELSE
        fsm_b_addr WHEN select_array = '0' ELSE
        fsm_d_addr WHEN (state = WAIT_READ OR state = ACCUMULATE) ELSE
        vga_addr;

    di_2 <= init_di WHEN init_done = '0' ELSE
        fsm_b_di;

    fsm_d_do <= do_1 WHEN select_array = '0' ELSE
        do_2;

    vga_do <= do_1 WHEN select_array = '0' ELSE
        do_2;

    n_c_a <= n_c_a_1 WHEN select_array = '0' ELSE
        n_c_a_2;
    n_g_a <= n_g_a_1 WHEN select_array = '0' ELSE
        n_g_a_2;
    n_c <= n_c_1 WHEN select_array = '0' ELSE
        n_c_2;
END main_arch;