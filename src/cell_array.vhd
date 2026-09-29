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
END cell_array;

ARCHITECTURE cell_array_arch OF cell_array IS
  TYPE ram_type IS ARRAY (0 TO (2 ** ADDR_WIDTH - 1)) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
  SIGNAL ram_block : ram_type := (OTHERS => (OTHERS => '0'));

  SIGNAL cur_row : INTEGER RANGE -1 TO 24 := 0;
  SIGNAL cur_row : INTEGER RANGE -1 TO 24 := 0;

  SIGNAL target_col : INTEGER RANGE -1 TO 32 := 0;
  SIGNAL target_col : INTEGER RANGE -1 TO 32 := 0;
BEGIN
  PROCESS (clk)
    VARIABLE temp_sum : INTEGER;
  BEGIN
    IF rising_edge(clk) THEN
      IF we = '1' THEN
        ram_block(to_integer(unsigned(addr))) <= di;
      END IF;
      do <= ram_block(to_integer(unsigned(addr)));
    END IF;
  END PROCESS;

  PROCESS (neighbor_get_count)
  BEGIN
    IF rising_edge(neighbor_get_count) THEN
      neighbor_count_available <= '0';
      FOR i IN -1 TO 1 LOOP
        target_row <= cur_row + i;
        FOR j IN -1 TO 1 LOOP
          target_col <= cur_col + j;
          IF (target_row >= 0 AND target_row < 24 AND target_col >= 0 AND target_col < 32) THEN
            IF ram_block(to_integer(target_row * 32 + target_col)) = '1' THEN
              temp_sum <= temp_sum + 1;
            END IF;
          END IF;
        END LOOP;
      END LOOP;
      neighbor_count_available <= '1';
      neighbor_count <= temp_sum;
    END IF;
  END IF;
END PROCESS;

PROCESS (neighbor_read_count)
BEGIN
  IF rising_edge(neighbor_get_count) THEN
    neighbor_count_available = '0';
  END IF;
END PROCESS;

cur_col <= addr/32;
cur_row <= addr MOD 32;

END cell_array_arch;