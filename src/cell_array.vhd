LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

-- Size = 32*24 = 768
-- rows = 24 ~ 5 bit
-- cols = 32 ~ 5 bit

-- Data => Red or White or Black

ENTITY cell_array IS
    GENERIC (
        ADDR_WIDTH : INTEGER := 12;
        DATA_WIDTH : INTEGER := 2
    );
    PORT (
        clk : IN STD_LOGIC;
        we : IN STD_LOGIC;
        -- addr = row then col 
        addr : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        di : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
        do : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );
END cell_array;

ARCHITECTURE cell_array_arch OF cell_array IS
    TYPE ram_type IS ARRAY (0 TO (2 ** (ADDR_WIDTH - 2) - 1)) OF STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0);
    SIGNAL ram_block : ram_type := (OTHERS => (OTHERS => '0'));

    SIGNAL row : SIGNED(5 DOWNTO 0);
    SIGNAL col : SIGNED(5 DOWNTO 0);
    SIGNAL is_valid_addr : BOOLEAN;
    SIGNAL ram_index : unsigned(9 DOWNTO 0);

BEGIN
    -- Prepend '0' bit so range 0-31 is positive in Signed math
    row <= SIGNED('0' & addr(11 DOWNTO 6));
    col <= SIGNED('0' & addr(5 DOWNTO 0));

    ram_index <= unsigned(addr(10 downto 6) & addr(4 downto 0));

    -- Validates bounds (Row: 0..23, Col: 0..31)
    is_valid_addr <= (row >= 0 AND row < 24) AND (col >= 0 AND col < 32);

    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            -- check validity of the addr
            IF is_valid_addr THEN
                IF we = '1' THEN
                    ram_block(to_integer(unsigned(ram_index))) <= di;
                END IF;
                do <= ram_block(to_integer(unsigned(ram_index)));
            ELSE
                do <= (OTHERS => '0');
            END IF;
        END IF;
    END PROCESS;

END cell_array_arch;