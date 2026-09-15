LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY frame_update IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        state : OUT state_type := IDLE;

        b_we : OUT STD_LOGIC;
        b_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        b_di : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        d_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        d_do : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        select_array : INOUT STD_LOGIC
    );
END ENTITY frame_update;

ARCHITECTURE frame_update_arch OF frame_update IS
    SIGNAL fsm_state : state_type := IDLE;
    SIGNAL cell_idx : INTEGER RANGE 0 TO 1023 := 0;
    SIGNAL sel_arr_reg : STD_LOGIC := '0';

    SIGNAL cur_row : INTEGER RANGE -1 TO 24 := 0;
    SIGNAL cur_col : INTEGER RANGE -1 TO 32 := 0;

    SIGNAL neighbor_id : INTEGER RANGE 0 TO 8 := 0;
    SIGNAL neighbor_count : INTEGER RANGE 0 TO 8 := 0;

    SIGNAL target_row : INTEGER RANGE -1 TO 24 := 0;
    SIGNAL target_col : INTEGER RANGE -1 TO 32 := 0;

    SIGNAL prng_done : STD_LOGIC := '0';
    SIGNAL prng_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL prng_di : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL prng_we : STD_LOGIC := '0';
BEGIN
    state <= fsm_state;
    select_array <= sel_arr_reg;

    PROCESS (clk_100mhz, rst)
        VARIABLE count : INTEGER RANGE 0 TO TIME_LIMIT + 1 := 0;
    BEGIN
        IF rst = '1' THEN
            fsm_state <= IDLE;
            cell_idx <= 0;
            b_we <= '0';
            sel_arr_reg <= '0';
            count := 0;
            -- prng_done <= '0';
            -- prng_we <= '1';

        ELSIF rising_edge(clk_100mhz) THEN
            b_we <= '0';

            CASE fsm_state IS
                WHEN IDLE =>
                    IF prng_done = '1' THEN
                        -- prng_we <= '0';
                        b_we <= '0';
                        cell_idx <= 0;
                        count := count + 1;
                        IF (count >= TIME_LIMIT) THEN
                            fsm_state <= UPDATE_CELL;
                            select_array <= NOT select_array;
                        END IF;
                    ELSE
                        b_we <= prng_we;
                        b_addr <= prng_addr;
                        b_di <= prng_di;
                    END IF;
                WHEN READ_SELF =>
                    d_addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, 10));
                    fsm_state <= UPDATE_CELL;
                WHEN UPDATE_CELL =>
                    IF cell_idx < TOTAL_CELLS THEN
                        cur_row <= cell_idx / 32;
                        cur_col <= cell_idx MOD 32;

                        neighbor_id <= 0;
                        neighbor_count <= 0;
                        fsm_state <= FETCH_NEIGHBOR;
                    ELSE
                        -- Here one array update is finished
                        cell_idx <= 0;
                        count := 0;
                        fsm_state <= IDLE;
                    END IF;
                    cur_col <= cell_idx MOD 32;

                    neighbor_id <= 0;
                    neighbor_count <= 0;
                    fsm_state <= FETCH_NEIGHBOR;
                ELSE
                    3
                    cell_idx <= 0;
                    count := 0;
                    fsm_state <= IDLE;
            END IF;
            WHEN FETCH_NEIGHBOR =>
            CASE neighbor_id IS
                WHEN 0 => target_row <= cur_row - 1;
                    target_col <= cur_col - 1;
                WHEN 1 => target_row <= cur_row - 1;
                    target_col <= cur_col;
                WHEN 2 => target_row <= cur_row - 1;
                    target_col <= cur_col + 1;
                WHEN 3 => target_row <= cur_row;
                    target_col <= cur_col - 1;
                WHEN 4 => target_row <= cur_row;
                    target_col <= cur_col + 1;
                WHEN 5 => target_row <= cur_row + 1;
                    target_col <= cur_col - 1;
                WHEN 6 => target_row <= cur_row + 1;
                    target_col <= cur_col;
                WHEN 7 => target_row <= cur_row + 1;
                    target_col <= cur_col + 1;
                WHEN OTHERS => NULL;
            END CASE;
            IF neighbor_id < 8 THEN
                fsm_state <= WAIT_READ;
            ELSE
                fsm_state <= WRITE_RESULT;
            END IF;
            WHEN WAIT_READ =>
            IF (target_row >= 0 AND target_row < 24 AND target_col >= 0 AND target_col < 32) THEN
                d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(target_row * 32 + target_col, 10));
            END IF;
            fsm_state <= ACCUMULATE;

            WHEN ACCUMULATE =>

            IF (target_row >= 0 AND target_row < 24 AND target_col >= 0 AND target_col < 32) THEN
                IF d_do = "01" THEN
                    neighbor_count <= neighbor_count + 1;
                END IF;
            END IF;

            neighbor_id <= neighbor_id + 1;
            fsm_state <= FETCH_NEIGHBOR;
            WHEN WRITE_RESULT =>
            b_addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, 10));

            IF (neighbor_count = 2 OR neighbor_count = 3) THEN
                b_di <= "01";
            ELSE
                b_di <= "00";
            END IF;

            b_we <= '1';
            fsm_state <= NEXT_CELL;

            WHEN NEXT_CELL =>
            b_we <= '0';
            cell_idx <= cell_idx + 1;
            fsm_state <= UPDATE_CELL;
        END CASE;
    END IF;
END PROCESS;

prng : ENTITY work.random_cell_init
    PORT MAP(
        clk => clk_100mhz,
        done => prng_done,
        we => prng_we,
        addr => prng_addr,
        di => prng_di
    );
END ARCHITECTURE frame_update_arch;