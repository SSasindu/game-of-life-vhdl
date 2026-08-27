LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY main IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        up : IN STD_LOGIC;
        down : IN STD_LOGIC;
        left : IN STD_LOGIC;
        right : IN STD_LOGIC;
        hsync : OUT STD_LOGIC;
        vsync : OUT STD_LOGIC;
        vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY main;

ARCHITECTURE main_arch OF main IS

    -- VGA Timing Constants (640x480 @ 60 Hz)
    CONSTANT H_ACTIVE : INTEGER := 640;
    CONSTANT H_FRONT : INTEGER := 16;
    CONSTANT H_SYNC : INTEGER := 96;
    CONSTANT H_BACK : INTEGER := 48;
    CONSTANT H_TOTAL : INTEGER := H_ACTIVE + H_FRONT + H_SYNC + H_BACK; -- 800

    CONSTANT V_ACTIVE : INTEGER := 480;
    CONSTANT V_FRONT : INTEGER := 10;
    CONSTANT V_SYNC : INTEGER := 2;
    CONSTANT V_BACK : INTEGER := 33;
    CONSTANT V_TOTAL : INTEGER := V_ACTIVE + V_FRONT + V_SYNC + V_BACK; -- 525

    -- Grid Dimensions (32x24 = 768 cells)
    CONSTANT GRID_WIDTH : INTEGER := 32;
    CONSTANT GRID_HEIGHT : INTEGER := 24;
    CONSTANT TOTAL_CELLS : INTEGER := GRID_WIDTH * GRID_HEIGHT; -- 768

    -- Signals for Clocking & VGA Scan
    SIGNAL pix_clk : STD_LOGIC := '0';
    SIGNAL div_count : UNSIGNED(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL h_count : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;
    SIGNAL v_count : INTEGER RANGE 0 TO V_TOTAL - 1 := 0;
    SIGNAL video_on : STD_LOGIC := '0';

    -- Display Memory Signals (Read-only by VGA VGA)
    SIGNAL d_we : STD_LOGIC := '0';
    SIGNAL d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL d_di : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL d_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- Buffer Memory Signals (Written by Update FSM / Copied to Display)
    SIGNAL b_we : STD_LOGIC := '0';
    SIGNAL b_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_di : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

    -- FSM State Machine for Frame Updating & Copying
    TYPE state_type IS (IDLE, WRITE_BUFFER, COPY_TO_DISPLAY);
    SIGNAL state : state_type := IDLE;

    -- Timer & Animation Control Signals
    CONSTANT ONE_SEC_LIMIT : INTEGER := 100_000_000 - 1;
    SIGNAL sec_counter : INTEGER RANGE 0 TO ONE_SEC_LIMIT := 0;
    SIGNAL frame_color : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00"; -- "00" = Black, "11" = White
    SIGNAL cell_idx : INTEGER RANGE 0 TO 1023 := 0;

    SIGNAL fsm_d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vga_d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');

    -- Player positions and status signals
    SIGNAL player_x : INTEGER RANGE 0 TO 31;
    SIGNAL player_y : INTEGER RANGE 0 TO 23;
    SIGNAL is_player_cell : STD_LOGIC;
    SIGNAL current_cell_x : INTEGER RANGE 0 TO 63;
    SIGNAL current_cell_y : INTEGER RANGE 0 TO 63;
BEGIN

    -- Instantiate Display Memory Array
    display_arr : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => d_we,
            addr => d_addr,
            di => d_di,
            do => d_do
        );

    -- Instantiate Buffer Memory Array
    buffer_arr : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk => clk_100mhz,
            we => b_we,
            addr => b_addr,
            di => b_di,
            do => b_do
        );

    -- Instantiate Player Entity
    player_inst : ENTITY work.player
        PORT MAP(
            clk          => clk_100mhz,
            rst          => rst,
            up           => up,
            down         => down,
            left         => left,
            right        => right,
            player_x_out => player_x,
            player_y_out => player_y
        );

    -- 1. Clock Divider (100 MHz to 25 MHz Pixel Clock)
    PROCESS (clk_100mhz)
    BEGIN
        IF rising_edge(clk_100mhz) THEN
            IF rst = '1' THEN
                div_count <= (OTHERS => '0');
                pix_clk <= '0';
            ELSE
                div_count <= div_count + 1;
                pix_clk <= div_count(1);
            END IF;
        END IF;
    END PROCESS;

    -- 2. VGA Counters & Sync Signals
    PROCESS (pix_clk)
    BEGIN
        IF rising_edge(pix_clk) THEN
            IF rst = '1' THEN
                h_count <= 0;
                v_count <= 0;
                hsync <= '1';
                vsync <= '1';
            ELSE
                IF h_count = H_TOTAL - 1 THEN
                    h_count <= 0;
                    IF v_count = V_TOTAL - 1 THEN
                        v_count <= 0;
                    ELSE
                        v_count <= v_count + 1;
                    END IF;
                ELSE
                    h_count <= h_count + 1;
                END IF;

                -- Sync Signals
                IF (h_count >= H_ACTIVE + H_FRONT) AND (h_count < H_ACTIVE + H_FRONT + H_SYNC) THEN
                    hsync <= '0';
                ELSE
                    hsync <= '1';
                END IF;

                IF (v_count >= V_ACTIVE + V_FRONT) AND (v_count < V_ACTIVE + V_FRONT + V_SYNC) THEN
                    vsync <= '0';
                ELSE
                    vsync <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- 3. Read Address Lookup from Display Array (Scales 640x480 to 32x24 grid)
    current_cell_x <= h_count / 20;
    current_cell_y <= v_count / 20;

    -- Grid Cell Index = (v_count / 20) * 32 + (h_count / 20)
    vga_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED((current_cell_y * GRID_WIDTH) + current_cell_x, 10))
                  WHEN video_on = '1' ELSE (OTHERS => '0');
    d_addr <= fsm_d_addr WHEN state = COPY_TO_DISPLAY ELSE vga_d_addr;

    -- Detect if VGA is scanning the player's cell
    is_player_cell <= '1' WHEN (video_on = '1' AND current_cell_x = player_x AND current_cell_y = player_y) ELSE '0';

    -- 4. Update FSM: Writes buffer, then copies buffer to display array every 1 second
    PROCESS (clk_100mhz)
    BEGIN
        IF rising_edge(clk_100mhz) THEN
            IF rst = '1' THEN
                state <= IDLE;
                sec_counter <= 0;
                frame_color <= "00";
                cell_idx <= 0;
                b_we <= '0';
                d_we <= '0';
            ELSE
                CASE state IS
                    WHEN IDLE =>
                        b_we <= '0';
                        d_we <= '0';
                        IF sec_counter = ONE_SEC_LIMIT THEN
                            sec_counter <= 0;
                            frame_color <= NOT frame_color; -- Toggle between "00" (Black) and "11" (White)
                            b_di <= NOT frame_color; 
                            cell_idx <= 0;
                            b_we <= '1'; 
                            state <= WRITE_BUFFER;
                        ELSE
                            sec_counter <= sec_counter + 1;
                        END IF;

                    WHEN WRITE_BUFFER =>
                        -- Write frame_color to all 768 addresses in buffer_arr
                        b_we <= '1';
                        b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx, 10));
                        b_di <= frame_color;

                        IF cell_idx = TOTAL_CELLS - 1 THEN
                            cell_idx <= 0;
                            b_we <= '0'; -- Turn off write enable for next state
                            d_we <= '0'; -- Keep display write enable off
                            state <= COPY_TO_DISPLAY;
                        ELSE
                            cell_idx <= cell_idx + 1;
                        END IF;

                    WHEN COPY_TO_DISPLAY =>
                        -- Disable write to buffer, read from it
                        b_we <= '0'; 

                        IF cell_idx = 0 THEN
                            -- Read first address (0) from buffer array
                            b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 10));
                            d_we <= '0'; -- Data not ready yet
                            cell_idx <= cell_idx + 1;
                        ELSIF cell_idx < TOTAL_CELLS THEN
                                b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx, 10));
                            fsm_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx - 1, 10));
                            d_di <= b_do;
                            d_we <= '1';
                            cell_idx <= cell_idx + 1;
                        ELSIF cell_idx = TOTAL_CELLS THEN
                            -- Write the last read data (from address 767) to display_arr(767)
                            fsm_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(TOTAL_CELLS - 1, 10));
                            d_di <= b_do;
                            d_we <= '1';
                            cell_idx <= cell_idx + 1;
                        ELSE 
                            d_we <= '0'; -- Disable write on next cycle
                            cell_idx <= 0;
                            state <= IDLE;
                        END IF;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    -- 5. VGA Active Area Guard & Color Outputs from Display Memory
    video_on <= '1' WHEN (h_count < H_ACTIVE) AND (v_count < V_ACTIVE) ELSE
        '0';

    -- Green for player, White for living cells, Black for dead/inactive cells
    vga_r <= "0000" WHEN (is_player_cell = '1') ELSE
             "1111" WHEN (video_on = '1' AND d_do /= "00") ELSE
             "0000";
    vga_g <= "1111" WHEN (is_player_cell = '1') ELSE
             "1111" WHEN (video_on = '1' AND d_do /= "00") ELSE
             "0000";
    vga_b <= "0000" WHEN (is_player_cell = '1') ELSE
             "1111" WHEN (video_on = '1' AND d_do /= "00") ELSE
             "0000";

END ARCHITECTURE main_arch;