LIBRARY ieee;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.game_of_life_pkg.ALL;

ENTITY pixel_map IS
    PORT (
        h_count : IN INTEGER RANGE 0 TO H_TOTAL - 1;
        v_count : IN INTEGER RANGE 0 TO V_TOTAL - 1;
        do : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        clk_100mhz : IN STD_LOGIC;
        rst : IN STD_LOGIC;

        vga_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);

        up : IN STD_LOGIC;
        down : IN STD_LOGIC;
        left : IN STD_LOGIC;
        right : IN STD_LOGIC;

        game_over     : IN STD_LOGIC := '0';
        survival_time : IN INTEGER RANGE 0 TO 999 := 0;
        flash_state   : IN STD_LOGIC := '0';

        player_x_out : OUT INTEGER RANGE 0 TO 31;
        player_y_out : OUT INTEGER RANGE 0 TO 23;

        vga_r : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY pixel_map;

ARCHITECTURE pixel_map_arch OF pixel_map IS
    SIGNAL v_on : STD_LOGIC := '0';

    -- Player position and logic
    SIGNAL is_player_cell : STD_LOGIC;
    SIGNAL current_cell_x : INTEGER RANGE 0 TO 127;
    SIGNAL current_cell_y : INTEGER RANGE 0 TO 127;

    -- Border marking
    SIGNAL is_grid_line : STD_LOGIC;

    -- Player positions and status signals
    SIGNAL player_x : INTEGER RANGE 0 TO 31;
    SIGNAL player_y : INTEGER RANGE 0 TO 23;

    -- BCD Digits for Survival Time
    SIGNAL dig_hundreds : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL dig_tens     : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL dig_ones     : INTEGER RANGE 0 TO 9 := 0;

    -- Font ROM Function (8x8 Font for numbers 0-9, G, A, M, E, O, V, R, T, I, S, :, ' ')
    FUNCTION get_char_row(code : INTEGER; row : INTEGER) RETURN STD_LOGIC_VECTOR IS
    BEGIN
        CASE code IS
            WHEN 0 => -- '0'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"6E"; WHEN 3 => RETURN x"76";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 1 => -- '1'
                CASE row IS
                    WHEN 0 => RETURN x"18"; WHEN 1 => RETURN x"38"; WHEN 2 => RETURN x"18"; WHEN 3 => RETURN x"18";
                    WHEN 4 => RETURN x"18"; WHEN 5 => RETURN x"18"; WHEN 6 => RETURN x"7E"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 2 => -- '2'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"0C"; WHEN 3 => RETURN x"18";
                    WHEN 4 => RETURN x"30"; WHEN 5 => RETURN x"60"; WHEN 6 => RETURN x"7E"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 3 => -- '3'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"0C"; WHEN 3 => RETURN x"1C";
                    WHEN 4 => RETURN x"0C"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 4 => -- '4'
                CASE row IS
                    WHEN 0 => RETURN x"0C"; WHEN 1 => RETURN x"1C"; WHEN 2 => RETURN x"3C"; WHEN 3 => RETURN x"6C";
                    WHEN 4 => RETURN x"7E"; WHEN 5 => RETURN x"0C"; WHEN 6 => RETURN x"0C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 5 => -- '5'
                CASE row IS
                    WHEN 0 => RETURN x"7E"; WHEN 1 => RETURN x"60"; WHEN 2 => RETURN x"7C"; WHEN 3 => RETURN x"06";
                    WHEN 4 => RETURN x"06"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 6 => -- '6'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"60"; WHEN 3 => RETURN x"7C";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 7 => -- '7'
                CASE row IS
                    WHEN 0 => RETURN x"7E"; WHEN 1 => RETURN x"06"; WHEN 2 => RETURN x"0C"; WHEN 3 => RETURN x"18";
                    WHEN 4 => RETURN x"30"; WHEN 5 => RETURN x"30"; WHEN 6 => RETURN x"30"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 8 => -- '8'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"3C";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 9 => -- '9'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"3E";
                    WHEN 4 => RETURN x"06"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 10 => -- 'G'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"60"; WHEN 3 => RETURN x"6E";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3E"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 11 => -- 'A'
                CASE row IS
                    WHEN 0 => RETURN x"18"; WHEN 1 => RETURN x"3C"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"66";
                    WHEN 4 => RETURN x"7E"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"66"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 12 => -- 'M'
                CASE row IS
                    WHEN 0 => RETURN x"63"; WHEN 1 => RETURN x"77"; WHEN 2 => RETURN x"7F"; WHEN 3 => RETURN x"6B";
                    WHEN 4 => RETURN x"63"; WHEN 5 => RETURN x"63"; WHEN 6 => RETURN x"63"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 13 => -- 'E'
                CASE row IS
                    WHEN 0 => RETURN x"7E"; WHEN 1 => RETURN x"60"; WHEN 2 => RETURN x"60"; WHEN 3 => RETURN x"7C";
                    WHEN 4 => RETURN x"60"; WHEN 5 => RETURN x"60"; WHEN 6 => RETURN x"7E"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 14 => -- 'O'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"66";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 15 => -- 'V'
                CASE row IS
                    WHEN 0 => RETURN x"66"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"66";
                    WHEN 4 => RETURN x"66"; WHEN 5 => RETURN x"3C"; WHEN 6 => RETURN x"18"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 16 => -- 'R'
                CASE row IS
                    WHEN 0 => RETURN x"7C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"66"; WHEN 3 => RETURN x"7C";
                    WHEN 4 => RETURN x"6C"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"66"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 17 => -- 'T'
                CASE row IS
                    WHEN 0 => RETURN x"7E"; WHEN 1 => RETURN x"18"; WHEN 2 => RETURN x"18"; WHEN 3 => RETURN x"18";
                    WHEN 4 => RETURN x"18"; WHEN 5 => RETURN x"18"; WHEN 6 => RETURN x"18"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 18 => -- 'I'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"18"; WHEN 2 => RETURN x"18"; WHEN 3 => RETURN x"18";
                    WHEN 4 => RETURN x"18"; WHEN 5 => RETURN x"18"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 19 => -- 'S'
                CASE row IS
                    WHEN 0 => RETURN x"3C"; WHEN 1 => RETURN x"66"; WHEN 2 => RETURN x"60"; WHEN 3 => RETURN x"3C";
                    WHEN 4 => RETURN x"06"; WHEN 5 => RETURN x"66"; WHEN 6 => RETURN x"3C"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN 20 => -- ':'
                CASE row IS
                    WHEN 0 => RETURN x"00"; WHEN 1 => RETURN x"18"; WHEN 2 => RETURN x"18"; WHEN 3 => RETURN x"00";
                    WHEN 4 => RETURN x"18"; WHEN 5 => RETURN x"18"; WHEN 6 => RETURN x"00"; WHEN OTHERS => RETURN x"00";
                END CASE;
            WHEN OTHERS => -- ' '
                RETURN x"00";
        END CASE;
    END FUNCTION;

    SIGNAL text_pixel_red    : STD_LOGIC := '0';
    SIGNAL text_pixel_yellow : STD_LOGIC := '0';

BEGIN
    player_x_out <= player_x;
    player_y_out <= player_y;

    -- BCD Decomposition for survival_time (0..999)
    dig_hundreds <= (survival_time / 100) MOD 10;
    dig_tens     <= (survival_time / 10) MOD 10;
    dig_ones     <= survival_time MOD 10;

    -- Player Entity
    player_inst : ENTITY work.player
        PORT MAP(
            clk => clk_100mhz,
            rst => rst,
            game_over => game_over,
            up => up,
            down => down,
            left => left,
            right => right,
            player_x_out => player_x,
            player_y_out => player_y
        );

    v_on <= '1' WHEN (h_count < H_ACTIVE) AND (v_count < V_ACTIVE) ELSE
        '0';

    -- Read Address Lookup dynamically calculated using CELL_WIDTH & CELL_HEIGHT
    current_cell_x <= h_count / CELL_WIDTH;
    current_cell_y <= v_count / CELL_HEIGHT;

    -- Detect if VGA is scanning the player's cell
    is_player_cell <= '1' WHEN (v_on = '1' AND current_cell_x = player_x AND current_cell_y = player_y 
                               AND current_cell_x < GRID_WIDTH AND current_cell_y < GRID_HEIGHT) ELSE
        '0';

    -- Grid lines dynamically drawn every CELL_WIDTH / CELL_HEIGHT pixels
    is_grid_line <= '1' WHEN (v_on = '1' AND (h_count MOD CELL_WIDTH = 0 OR v_count MOD CELL_HEIGHT = 0)) ELSE
        '0';

    -- Generate read address for VGA screen scanout, safely clamped to GRID_WIDTH * GRID_HEIGHT
    vga_addr <= STD_LOGIC_VECTOR(to_unsigned(((v_count / CELL_HEIGHT) * GRID_WIDTH) + (h_count / CELL_WIDTH), 10))
                WHEN (current_cell_x < GRID_WIDTH AND current_cell_y < GRID_HEIGHT) ELSE
                (OTHERS => '0');

    -- Text Overlay Pixel Renderer
    PROCESS (h_count, v_count, v_on, dig_hundreds, dig_tens, dig_ones)
        VARIABLE char_code   : INTEGER := 21;
        VARIABLE char_idx    : INTEGER := 0;
        VARIABLE row_in_char : INTEGER := 0;
        VARIABLE col_in_char : INTEGER := 0;
        VARIABLE row_bits    : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        text_pixel_red    <= '0';
        text_pixel_yellow <= '0';

        IF v_on = '1' THEN
            -- Line 1: "GAME OVER" centered at Y=190..205, X=248..391 (16x16 font size)
            IF v_count >= 190 AND v_count < 206 AND h_count >= 248 AND h_count < 392 THEN
                char_idx    := (h_count - 248) / 16;
                col_in_char := ((h_count - 248) MOD 16) / 2;
                row_in_char := (v_count - 190) / 2;

                CASE char_idx IS
                    WHEN 0 => char_code := 10; -- 'G'
                    WHEN 1 => char_code := 11; -- 'A'
                    WHEN 2 => char_code := 12; -- 'M'
                    WHEN 3 => char_code := 13; -- 'E'
                    WHEN 4 => char_code := 21; -- ' '
                    WHEN 5 => char_code := 14; -- 'O'
                    WHEN 6 => char_code := 15; -- 'V'
                    WHEN 7 => char_code := 13; -- 'E'
                    WHEN 8 => char_code := 16; -- 'R'
                    WHEN OTHERS => char_code := 21;
                END CASE;

                row_bits := get_char_row(char_code, row_in_char);
                IF row_bits(7 - col_in_char) = '1' THEN
                    text_pixel_red <= '1';
                END IF;

            -- Line 2: "TIME: XXX S" centered at Y=230..245, X=232..407 (16x16 font size)
            ELSIF v_count >= 230 AND v_count < 246 AND h_count >= 232 AND h_count < 408 THEN
                char_idx    := (h_count - 232) / 16;
                col_in_char := ((h_count - 232) MOD 16) / 2;
                row_in_char := (v_count - 230) / 2;

                CASE char_idx IS
                    WHEN 0 => char_code := 17; -- 'T'
                    WHEN 1 => char_code := 18; -- 'I'
                    WHEN 2 => char_code := 12; -- 'M'
                    WHEN 3 => char_code := 13; -- 'E'
                    WHEN 4 => char_code := 20; -- ':'
                    WHEN 5 => char_code := 21; -- ' '
                    WHEN 6 => char_code := dig_hundreds; -- '0'..'9'
                    WHEN 7 => char_code := dig_tens;     -- '0'..'9'
                    WHEN 8 => char_code := dig_ones;     -- '0'..'9'
                    WHEN 9 => char_code := 21; -- ' '
                    WHEN 10 => char_code := 19; -- 'S'
                    WHEN OTHERS => char_code := 21;
                END CASE;

                row_bits := get_char_row(char_code, row_in_char);
                IF row_bits(7 - col_in_char) = '1' THEN
                    text_pixel_yellow <= '1';
                END IF;
            END IF;
        END IF;
    END PROCESS;

    -- Color Multiplexing Process:
    -- When game_over = '1':
    --   Renders a solid black box card in the center of the frozen collided game screen
    --   Inside box: "GAME OVER" in Red, "TIME: XXX S" in Yellow, background in Black
    --   Outside box: Frozen collided game board (Live cells, Player, Grid lines)
    PROCESS (game_over, is_player_cell, v_on, do, is_grid_line, text_pixel_red, text_pixel_yellow, h_count, v_count)
        VARIABLE in_box : BOOLEAN;
    BEGIN
        in_box := (h_count >= 212 AND h_count <= 427 AND v_count >= 175 AND v_count <= 260);

        IF game_over = '1' AND in_box THEN
            -- Centered Game Over Card Overlay
            IF text_pixel_red = '1' THEN
                vga_r <= "1111"; -- Red text "GAME OVER"
                vga_g <= "0000";
                vga_b <= "0000";
            ELSIF text_pixel_yellow = '1' THEN
                vga_r <= "1111"; -- Yellow text "TIME: XXX S"
                vga_g <= "1111";
                vga_b <= "0000";
            ELSE
                vga_r <= "0000"; -- Solid Black Card Background
                vga_g <= "0000";
                vga_b <= "0000";
            END IF;
        ELSE
            -- Normal Game Board / Collided Game Board Background
            IF is_player_cell = '1' THEN
                vga_r <= "0000"; -- Green Player
                vga_g <= "1111";
                vga_b <= "0000";
            ELSIF v_on = '1' AND do = "01" THEN
                vga_r <= "1000"; -- 50% White Live Cell
                vga_g <= "1000";
                vga_b <= "1000";
            ELSIF is_grid_line = '1' THEN
                vga_r <= "0010"; -- Subtle Grid Lines
                vga_g <= "0010";
                vga_b <= "0010";
            ELSE
                vga_r <= "0000"; -- Black Dead Cell
                vga_g <= "0000";
                vga_b <= "0000";
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE pixel_map_arch;