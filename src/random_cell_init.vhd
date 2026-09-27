LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY random_cell_init IS

    GENERIC (
        ADDR_WIDTH : INTEGER := 10;
        DATA_WIDTH : INTEGER := 2;
        PLAYER_START_X : INTEGER := 16;
        PLAYER_START_Y : INTEGER := 20
    );

    PORT (
        clk   : IN STD_LOGIC;
        rst   : IN STD_LOGIC := '0';
        start : IN STD_LOGIC := '0';
        done  : OUT STD_LOGIC := '1';
        we    : OUT STD_LOGIC := '0';

        addr : OUT STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
        di : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0)
    );

END random_cell_init;

ARCHITECTURE Behavioral OF random_cell_init IS

    SIGNAL lfsr : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"ACE1";
    SIGNAL busy : STD_LOGIC := '0';
BEGIN
    CLOCK : PROCESS (clk, rst)
        VARIABLE cell_idx : INTEGER RANGE 0 TO TOTAL_CELLS := 0;
        VARIABLE cell_x   : INTEGER;
        VARIABLE cell_y   : INTEGER;
        VARIABLE feedback : STD_LOGIC;

    BEGIN
        IF rst = '1' THEN
            cell_idx := 0;
            done     <= '1';
            we       <= '0';
            busy     <= '0';
            lfsr     <= x"ACE1";
        ELSIF rising_edge(clk) THEN
            IF start = '1' THEN
                cell_idx := 0;
                done     <= '0';
                busy     <= '1';
                we       <= '0';
            ELSIF busy = '1' THEN
                IF cell_idx < TOTAL_CELLS THEN
                feedback :=
                    lfsr(15) XOR
                    lfsr(13) XOR
                    lfsr(12) XOR
                    lfsr(10);

                    lfsr <= lfsr(14 DOWNTO 0) & feedback;

                    we   <= '1';
                    addr <= STD_LOGIC_VECTOR(to_unsigned(cell_idx, ADDR_WIDTH));

                    cell_x := cell_idx MOD GRID_WIDTH;
                    cell_y := cell_idx / GRID_WIDTH;

                    -- Clear player starting area (3x3 zone centered at player start position 16, 20)
                    IF (cell_x >= PLAYER_START_X - 1 AND cell_x <= PLAYER_START_X + 1 AND
                        cell_y >= PLAYER_START_Y - 1 AND cell_y <= PLAYER_START_Y + 1) THEN
                        di <= "00";
                    ELSIF feedback = '1' THEN
                        di <= "01"; -- Live cell (~50% density)
                    ELSE
                        di <= "00"; -- Dead cell
                    END IF;

                    cell_idx := cell_idx + 1;
                ELSE
                    we   <= '0';
                    done <= '1';
                    busy <= '0';
                END IF;
            ELSE
                we <= '0';
            END IF;
        END IF;
    END PROCESS CLOCK;

END Behavioral;