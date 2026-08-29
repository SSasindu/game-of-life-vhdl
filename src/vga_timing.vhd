LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY vga_timing IS
    PORT (
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        h_count : OUT INTEGER RANGE 0 TO H_TOTAL - 1;
        v_count : OUT INTEGER RANGE 0 TO V_TOTAL - 1;
        hsync : OUT STD_LOGIC;
        vsync : OUT STD_LOGIC
    );
END ENTITY;

ARCHITECTURE vga_timing_arch OF vga_timing IS
    SIGNAL pix_clk : STD_LOGIC := '0';
    SIGNAL h_reg : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;
    SIGNAL v_reg : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;
BEGIN

    h_count <= h_reg;
    v_count <= v_reg;

    PROCESS (clk_100mhz)
        VARIABLE div_count : unsigned(1 DOWNTO 0) := (OTHERS => '0');
    BEGIN
        IF rising_edge(clk_100mhz) THEN
            IF rst = '1' THEN
                div_count := (OTHERS => '0');
                pix_clk <= '0';
            ELSE
                div_count := div_count + 1;
                pix_clk <= div_count(1);
            END IF;
        END IF;
    END PROCESS;

    PROCESS (pix_clk)
    BEGIN
        IF rising_edge(pix_clk) THEN
            IF rst = '1' THEN
                h_reg <= 0;
                v_reg <= 0;
                hsync <= '1';
                vsync <= '1';
            ELSE
                IF h_reg = H_TOTAL - 1 THEN
                    h_reg <= 0;
                    IF v_reg = V_TOTAL - 1 THEN
                        v_reg <= 0;
                    ELSE
                        v_reg <= v_reg + 1;
                    END IF;
                ELSE
                    h_reg <= h_reg + 1;
                END IF;

                -- Sync signals
                IF (h_reg >= H_ACTIVE + H_FRONT) AND (h_reg < H_ACTIVE + H_FRONT + H_SYNC) THEN
                    hsync <= '0';
                ELSE
                    hsync <= '1';
                END IF;

                IF (v_reg >= V_ACTIVE + V_FRONT) AND (v_reg < V_ACTIVE + V_FRONT + V_SYNC) THEN
                    vsync <= '0';
                ELSE
                    vsync <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;
END vga_timing_arch;