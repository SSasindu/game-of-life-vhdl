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

    neighbor_count_from_array : IN INTEGER RANGE 0 TO 8
  );
END ENTITY frame_update;

ARCHITECTURE frame_update_arch OF frame_update IS
  SIGNAL fsm_state : state_type := IDLE;
  SIGNAL cell_idx : INTEGER RANGE 0 TO 1023 := 0;
  SIGNAL frame_delay : INTEGER RANGE 0 TO TIME_LIMIT := TIME_LIMIT;
  SIGNAL sel_arr_reg : STD_LOGIC := '0';
BEGIN
  state <= fsm_state;
  select_array <= sel_arr_reg;

  PROCESS (clk_100mhz, rst)
  BEGIN
    IF rst = '1' THEN
      fsm_state <= IDLE;
      cell_idx <= 0;
      frame_delay <= TIME_LIMIT;
      b_we <= '0';
      sel_arr_reg <= '0';

    ELSIF rising_edge(clk_100mhz) THEN
      b_we <= '0';

      CASE fsm_state IS
        WHEN IDLE =>
          cell_idx <= 0;
          IF init_done = '1' AND run = '1' THEN
            IF frame_delay = TIME_LIMIT THEN
              frame_delay <= 0;
              fsm_state <= UPDATE_CELL;
            ELSE
              frame_delay <= frame_delay + 1;
            END IF;
          ELSE
            frame_delay <= TIME_LIMIT;
          END IF;

        WHEN UPDATE_CELL =>
          IF cell_idx < TOTAL_CELLS THEN
            d_addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, 10));
            b_addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, 10));
            fsm_state <= WRITE_RESULT;
          ELSE
            sel_arr_reg <= NOT sel_arr_reg;
            fsm_state <= IDLE;
          END IF;

        WHEN WRITE_RESULT =>
          IF neighbor_count_from_array = 3 OR
            (neighbor_count_from_array = 2 AND d_do = "01") THEN
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

        WHEN OTHERS =>
          fsm_state <= IDLE;
      END CASE;
    END IF;
  END PROCESS;
END ARCHITECTURE frame_update_arch;