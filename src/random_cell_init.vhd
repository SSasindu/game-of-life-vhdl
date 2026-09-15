LIBRARY library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY random_cell_init IS

    GENERIC (
        ADDR_WIDTH : INTEGER := 10;
        DATA_WIDTH : INTEGER := 2
    );

    PORT (
        clk : IN STD_LOGIC;
        done : OUT STD_LOGIC := '0';
        we : OUT STD_LOGIC;

        addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        di : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );

END random_cell_init;

ARCHITECTURE random_cell_init_arch IS

    SIGNAL lfsr : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"ACE1";

    PROCESS (clk)
        VARIABLE cell_idx : INTEGER RANGE 0 TO TOTAL_CELLS - 1 := 0;
        VARIABLE feedback : STD_LOGIC;

    BEGIN
        IF rising_edge(clk) THEN
            IF cell_idx < TOTAL_CELLS THEN
                feedback :=
                    lfsr(15) XOR
                    lfsr(13) XOR
                    lfsr(12) XOR
                    lfsr(10);

                lfsr <= lfsr(14 DOWNTO 0) & feedback;

                we <= '1';
                addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, ADDR_WIDTH));

                IF feedback = '0' THEN
                    di <= "00";
                ELSE
                    di <= "01";
                END IF;

                cell_idx := cell_idx + 1;
            ELSE
                we <= '0';
                done <= '1';
            END IF;
        END IF;

    END PROCESS;

END random_cell_init_arch;