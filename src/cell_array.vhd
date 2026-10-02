LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

-- Size = 32*24 = 768
-- rows = 24 ~ 5 bit
-- cols = 32 ~ 5 bit

-- Data => Red or White or Black

ENTITY cell_array IS
  GENERIC (
    ADDR_WIDTH : INTEGER := 10;
    DATA_WIDTH : INTEGER := 2
  );
  PORT (
    clk : IN STD_LOGIC;
    we : IN STD_LOGIC;
    addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
    di : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    do : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);

    neighbor_get_count : IN STD_LOGIC;
    neighbor_count : OUT INTEGER RANGE -1 TO 9;
    neighbor_count_available : OUT STD_LOGIC;
    neighbor_read_count : IN STD_LOGIC
  );
END ENTITY cell_array;

ARCHITECTURE cell_array_arch OF cell_array IS
  CONSTANT ROWS : INTEGER := 24;
  CONSTANT COLS : INTEGER := 32;

  TYPE ram_type IS ARRAY (0 TO (2 ** ADDR_WIDTH - 1)) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL ram_block : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN
  PROCESS (clk)
    VARIABLE row : INTEGER := 0;
    VARIABLE col : INTEGER := 0;
    VARIABLE target_row : INTEGER := 0;
    VARIABLE target_col : INTEGER := 0;
    VARIABLE temp_sum : INTEGER := 0;
  BEGIN
    IF rising_edge(clk) THEN
      IF we = '1' THEN
        ram_block(to_integer(unsigned(addr))) <= di;
      END IF;

      do <= ram_block(to_integer(unsigned(addr)));

      IF neighbor_get_count = '1' THEN
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

                IF ram_block(target_row * COLS + target_col) = "01" THEN
                  temp_sum := temp_sum + 1;
                END IF;
              END IF;
            END IF;
          END LOOP;
        END LOOP;

        neighbor_count <= temp_sum;
        neighbor_count_available <= '1';
      ELSIF neighbor_read_count = '1' THEN
        neighbor_count_available <= '0';
      END IF;
    END IF;
  END PROCESS;
END ARCHITECTURE cell_array_arch;