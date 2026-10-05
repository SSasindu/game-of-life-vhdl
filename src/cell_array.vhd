LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY cell_array IS
  GENERIC (
    ADDR_WIDTH : INTEGER := 10;
    DATA_WIDTH : INTEGER := 2
  );
  PORT (
    clk          : IN  STD_LOGIC;
    we           : IN  STD_LOGIC;
    addr         : IN  STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    di           : IN  STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    do           : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    
    -- Pure combinational neighbor output
    neighbor_count : OUT INTEGER RANGE -1 TO 9
  );
END ENTITY cell_array;

ARCHITECTURE cell_array_arch OF cell_array IS
  CONSTANT ROWS : INTEGER := 24;
  CONSTANT COLS : INTEGER := 32;

  -- 2D Grid stored in registers/signals for parallel multi-port access
  TYPE grid_type IS ARRAY (0 TO ROWS - 1, 0 TO COLS - 1) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL grid : grid_type := (OTHERS => (OTHERS => (OTHERS => '0')));

BEGIN

  -- 1. Synchronous Write Logic
  PROCESS (clk)
    VARIABLE w_row, w_col : INTEGER;
  BEGIN
    IF rising_edge(clk) THEN
      IF we = '1' THEN
        w_row := to_integer(unsigned(addr)) / COLS;
        w_col := to_integer(unsigned(addr)) MOD COLS;
        grid(w_row, w_col) <= di;
      END IF;
    END IF;
  END PROCESS;

  -- Read current address combinational
  do <= grid(to_integer(unsigned(addr)) / COLS, to_integer(unsigned(addr)) MOD COLS);

  -- 2. Pure Combinational Neighborhood Count Process
  PROCESS (addr, grid)
    VARIABLE row, col               : INTEGER := 0;
    VARIABLE target_row, target_col : INTEGER := 0;
    VARIABLE temp_sum               : INTEGER := 0;
  BEGIN
    temp_sum := 0;
    row := to_integer(unsigned(addr)) / COLS;
    col := to_integer(unsigned(addr)) MOD COLS;

    FOR i IN -1 TO 1 LOOP
      FOR j IN -1 TO 1 LOOP
        IF NOT (i = 0 AND j = 0) THEN
          target_row := row + i;
          target_col := col + j;

          IF (target_row >= 0 AND target_row < ROWS AND
              target_col >= 0 AND target_col < COLS) THEN

            IF grid(target_row, target_col) = "01" THEN
              temp_sum := temp_sum + 1;
            END IF;
          END IF;
        END IF;
      END LOOP;
    END LOOP;

    neighbor_count <= temp_sum;
  END PROCESS;

END ARCHITECTURE cell_array_arch;