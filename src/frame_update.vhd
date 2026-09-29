LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY frame_update IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        init_done : IN STD_LOGIC := '1';
        run : IN STD_LOGIC := '1';
        state : OUT state_type := IDLE;

        b_we : OUT STD_LOGIC;
        b_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        b_di : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);

        d_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        d_do : IN STD_LOGIC_VECTOR(1 DOWNTO 0);

        select_array : INOUT STD_LOGIC;

        neighbor_get_count : OUT STD_LOGIC;
        neighbor_count_from_array : IN INTEGER RANGE -1 TO 9;
        neighbor_count_available : IN STD_LOGIC;
        neighbor_read_count : OUT STD_LOGIC;
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

        ELSIF rising_edge(clk_100mhz) THEN
            b_we <= '0';

            CASE fsm_state IS
                WHEN IDLE =>
                    b_we <= '0';
                    cell_idx <= 0;
                    IF init_done = '1' AND run = '1' THEN
                        count := count + 1;
                        IF (count >= TIME_LIMIT) THEN
                            count := 0;
                            fsm_state <= UPDATE_CELL;
                            sel_arr_reg <= NOT sel_arr_reg;
                        END IF;
                    ELSE
                        count := 0;
                    END IF;

                WHEN READ_SELF =>
                    d_addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, 10));
                    fsm_state <= UPDATE_CELL;

                WHEN UPDATE_CELL =>
                    IF cell_idx < TOTAL_CELLS THEN

                        neighbor_get_count <= '1';
                        neighbor_read_count <= '0';
                        IF neighbor_count_available = '1' THEN
                            neighbor_count_from_array <= neighbor_count;
                            fsm_state <= WRITE_RESULT;
                            neighbor_read_count <= '1';
                        END IF;
                        IF neighbor_read_count = '1' THEN
                            fsm_state <= NEXT_CELL;
                        END IF;
                    END IF;
                ELSE
                    -- Here one array update is finished
                    cell_idx <= 0;
                    count := 0;
                    fsm_state <= IDLE;
            END IF;

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

END ARCHITECTURE frame_update_arch;