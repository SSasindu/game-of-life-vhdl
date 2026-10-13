LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY collision_detection IS
    PORT (
        clk           : IN  STD_LOGIC;
        rst           : IN  STD_LOGIC;
        player_x      : IN  INTEGER RANGE 0 TO 31;
        player_y      : IN  INTEGER RANGE 0 TO 23;
        vga_addr      : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        vga_do        : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        game_active   : IN  STD_LOGIC; -- '1' when grid init is done and sw1=1
        game_over     : OUT STD_LOGIC;
        survival_time : OUT INTEGER RANGE 0 TO 999;
        flash_state   : OUT STD_LOGIC
    );
END ENTITY collision_detection;

ARCHITECTURE Behavioral OF collision_detection IS
    SIGNAL game_over_reg   : STD_LOGIC := '0';
    SIGNAL time_sec        : INTEGER RANGE 0 TO 999 := 0;
    SIGNAL sec_clk_cnt     : INTEGER RANGE 0 TO 100_000_000 := 0;
    SIGNAL flash_clk_cnt   : INTEGER RANGE 0 TO 50_000_000 := 0;
    SIGNAL flash_reg       : STD_LOGIC := '0';
    SIGNAL player_ram_addr : STD_LOGIC_VECTOR(9 DOWNTO 0);
BEGIN
    game_over <= game_over_reg;
    survival_time <= time_sec;
    flash_state <= flash_reg;

    -- Calculate RAM address corresponding to the player's tile
    player_ram_addr <= STD_LOGIC_VECTOR(to_unsigned(player_y * GRID_WIDTH + player_x, 10));

    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            game_over_reg <= '0';
            time_sec <= 0;
            sec_clk_cnt <= 0;
            flash_clk_cnt <= 0;
            flash_reg <= '0';
        ELSIF rising_edge(clk) THEN
            -- Check for collision when VGA is scanning player's cell or during active gameplay
            IF game_active = '1' AND game_over_reg = '0' THEN
                IF (vga_addr = player_ram_addr AND vga_do = "01") THEN
                    game_over_reg <= '1';
                END IF;

                -- Survival Timer: 1 second clock divider
                IF sec_clk_cnt >= 100_000_000 - 1 THEN
                    sec_clk_cnt <= 0;
                    IF time_sec < 999 THEN
                        time_sec <= time_sec + 1;
                    END IF;
                ELSE
                    sec_clk_cnt <= sec_clk_cnt + 1;
                END IF;
            END IF;

            -- Alternating Flash Timer (0.5 second toggle when game_over is active)
            IF game_over_reg = '1' THEN
                IF flash_clk_cnt >= 50_000_000 - 1 THEN
                    flash_clk_cnt <= 0;
                    flash_reg <= NOT flash_reg;
                ELSE
                    flash_clk_cnt <= flash_clk_cnt + 1;
                END IF;
            ELSE
                flash_clk_cnt <= 0;
                flash_reg <= '0';
            END IF;
        END IF;
    END PROCESS;

END Behavioral;
