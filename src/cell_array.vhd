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
        do : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END cell_array;

ARCHITECTURE cell_array_arch OF cell_array IS
    TYPE ram_type IS ARRAY (0 TO (2 ** ADDR_WIDTH - 1)) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL ram_block : ram_type := (OTHERS => (OTHERS => '0'));

BEGIN
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF we = '1' THEN
                ram_block(to_integer(unsigned(addr))) <= di;
            END IF;
            do <= ram_block(to_integer(unsigned(addr)));
        END IF;
    END PROCESS;
END cell_array_arch;