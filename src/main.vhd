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
    SIGNAL v_count : INTEGER RANGE 0 TO V_TOTAL - 1 := 0;

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

    -- Ping-pong buffer signals
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

    SIGNAL n_c_1 : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL n_c_2 : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL n_c   : INTEGER RANGE 0 TO 8 := 0;

    -- Collision Detection and Game Over Signals
    SIGNAL game_over_sig     : STD_LOGIC := '0';
    SIGNAL survival_time_sig : INTEGER RANGE 0 TO 999 := 0;
    SIGNAL flash_state_sig   : STD_LOGIC := '0';
    SIGNAL player_x_sig      : INTEGER RANGE 0 TO 31 := 16;
    SIGNAL player_y_sig      : INTEGER RANGE 0 TO 23 := 20;
    SIGNAL effective_run     : STD_LOGIC := '0';
    SIGNAL game_active_sig   : STD_LOGIC := '0';

BEGIN
    -- Enable Game of Life evolution only when sw1=1 and no collision has occurred
    game_active_sig <= init_done AND sw1;
    effective_run   <= sw1 AND (NOT game_over_sig);

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
            neighbor_count => n_c_1
        );

    arr_2 : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => we_2,
            addr => addr_2,
            di => di_2,
            do => do_2,
            neighbor_count => n_c_2
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
            run => effective_run,
            state => state,

            b_we => fsm_b_we,
            b_addr => fsm_b_addr,
            b_di => fsm_b_di,

            d_addr => fsm_d_addr,
            d_do => fsm_d_do,

            select_array => select_array,
            neighbor_count_from_array => n_c
        );

    collision_inst : ENTITY work.collision_detection
        PORT MAP(
            clk           => clk_100mhz,
            rst           => rst,
            player_x      => player_x_sig,
            player_y      => player_y_sig,
            vga_addr      => vga_addr,
            vga_do        => vga_do,
            game_active   => game_active_sig,
            game_over     => game_over_sig,
            survival_time => survival_time_sig,
            flash_state   => flash_state_sig
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

            game_over     => game_over_sig,
            survival_time => survival_time_sig,
            flash_state   => flash_state_sig,

            player_x_out  => player_x_sig,
            player_y_out  => player_y_sig,

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
        fsm_d_addr WHEN (state = UPDATE_CELL OR state = WRITE_RESULT) ELSE
        vga_addr;

    di_1 <= init_di WHEN init_done = '0' ELSE
        fsm_b_di;

    -- RAM 2 Multiplexing
    we_2 <= init_we WHEN init_done = '0' ELSE
        fsm_b_we WHEN select_array = '0' ELSE
        '0';

    addr_2 <= init_addr WHEN init_done = '0' ELSE
        fsm_b_addr WHEN select_array = '0' ELSE
        fsm_d_addr WHEN (state = UPDATE_CELL OR state = WRITE_RESULT) ELSE
        vga_addr;

    di_2 <= init_di WHEN init_done = '0' ELSE
        fsm_b_di;

    fsm_d_do <= do_1 WHEN select_array = '0' ELSE
        do_2;

    vga_do <= do_1 WHEN select_array = '0' ELSE
        do_2;

    n_c <= n_c_1 WHEN select_array = '0' ELSE
        n_c_2;
END main_arch;