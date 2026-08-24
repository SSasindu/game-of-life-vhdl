library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cell_array is
    Generic (
        SIM_MODE : boolean := false
    );
    Port (
        clk_100mhz : in  STD_LOGIC;
        pix_clk    : in  STD_LOGIC;
        sw         : in  STD_LOGIC_VECTOR(15 downto 0);
        btnU       : in  STD_LOGIC;
        btnD       : in  STD_LOGIC;
        btnL       : in  STD_LOGIC;
        btnR       : in  STD_LOGIC;
        btnC       : in  STD_LOGIC;
        h_count    : in  integer range 0 to 799;
        v_count    : in  integer range 0 to 524;
        video_on   : in  STD_LOGIC;
        vga_r      : out STD_LOGIC_VECTOR(3 downto 0);
        vga_g      : out STD_LOGIC_VECTOR(3 downto 0);
        vga_b      : out STD_LOGIC_VECTOR(3 downto 0);
        led        : out STD_LOGIC_VECTOR(15 downto 0);
        seg        : out STD_LOGIC_VECTOR(6 downto 0);
        an         : out STD_LOGIC_VECTOR(3 downto 0);
        dp         : out STD_LOGIC
    );
end cell_array;

architecture Behavioral of cell_array is

    -- Grid dimensions
    constant GRID_WIDTH  : integer := 32;
    constant GRID_HEIGHT : integer := 24;

    -- Grid storage type
    type grid_type is array (0 to GRID_HEIGHT - 1, 0 to GRID_WIDTH - 1) of STD_LOGIC;
    signal grid : grid_type := (others => (others => '0'));

    -- T-Shape Cursor Position tracking
    signal cursor_x : integer range 0 to GRID_WIDTH - 1 := 15;
    signal cursor_y : integer range 0 to GRID_HEIGHT - 1 := 11;

    -- Cursor T-Shape coordinates relative to (cursor_x, cursor_y)
    signal c_x0, c_x1, c_x2, c_x3 : integer range 0 to GRID_WIDTH - 1;
    signal c_y0, c_y1, c_y2, c_y3 : integer range 0 to GRID_HEIGHT - 1;

    -- Debouncer & Button rising edge pulse registers
    signal btn_div_counter : integer range 0 to 999_999 := 0;
    signal btn_tick        : STD_LOGIC := '0';
    
    signal btnU_reg, btnD_reg, btnL_reg, btnR_reg, btnC_reg   : STD_LOGIC := '0';
    signal btnU_prev, btnD_prev, btnL_prev, btnR_prev, btnC_prev : STD_LOGIC := '0';
    signal btnU_pulse, btnD_pulse, btnL_pulse, btnR_pulse, btnC_pulse : STD_LOGIC := '0';

    -- Live cell counter
    signal live_count : integer range 0 to GRID_WIDTH * GRID_HEIGHT := 0;

    -- 7-segment Display signals
    signal refresh_counter : unsigned(15 downto 0) := (others => '0');
    signal active_digit    : STD_LOGIC_VECTOR(1 downto 0);
    signal bcd_ones        : unsigned(3 downto 0) := (others => '0');
    signal bcd_tens        : unsigned(3 downto 0) := (others => '0');
    signal bcd_hundreds    : unsigned(3 downto 0) := (others => '0');

    -- Segment pattern lookup function for 7-segment decoder
    function get_seg_pattern(val : unsigned(3 downto 0)) return STD_LOGIC_VECTOR is
    begin
        case to_integer(val) is
            when 0 => return "1000000"; -- 0 (active low)
            when 1 => return "1111001"; -- 1
            when 2 => return "0100100"; -- 2
            when 3 => return "0110000"; -- 3
            when 4 => return "0011001"; -- 4
            when 5 => return "0010010"; -- 5
            when 6 => return "0000010"; -- 6
            when 7 => return "1111000"; -- 7
            when 8 => return "0000000"; -- 8
            when 9 => return "0010000"; -- 9
            when others => return "1111111"; -- Blank
        end case;
    end function;

    -- VGA Row/Col tracking registers (on pix_clk domain)
    signal cell_x : integer range 0 to GRID_WIDTH - 1 := 0;
    signal cell_y : integer range 0 to GRID_HEIGHT - 1 := 0;
    signal px_sub : integer range 0 to 19 := 0;
    signal py_sub : integer range 0 to 19 := 0;

begin

    ------------------------------------------------------------------
    -- 1. Button Debouncing and Pulse Generator (100 Hz Sample Rate)
    ------------------------------------------------------------------
    process(clk_100mhz)
        variable btn_div_limit : integer;
    begin
        if rising_edge(clk_100mhz) then
            if SIM_MODE then
                btn_div_limit := 9; -- 10 clock cycles per button sample in simulation
            else
                btn_div_limit := 999_999; -- 10 ms in hardware
            end if;

            if btn_div_counter >= btn_div_limit then
                btn_div_counter <= 0;
                btn_tick <= '1';
            else
                btn_div_counter <= btn_div_counter + 1;
                btn_tick <= '0';
            end if;
        end if;
    end process;

    process(clk_100mhz)
    begin
        if rising_edge(clk_100mhz) then
            btnU_pulse <= '0';
            btnD_pulse <= '0';
            btnL_pulse <= '0';
            btnR_pulse <= '0';
            btnC_pulse <= '0';

            if btn_tick = '1' then
                -- Shift sample registers
                btnU_reg <= btnU;
                btnD_reg <= btnD;
                btnL_reg <= btnL;
                btnR_reg <= btnR;
                btnC_reg <= btnC;

                btnU_prev <= btnU_reg;
                btnD_prev <= btnD_reg;
                btnL_prev <= btnL_reg;
                btnR_prev <= btnR_reg;
                btnC_prev <= btnC_reg;

                -- Detect rising edges
                if btnU_reg = '1' and btnU_prev = '0' then
                    btnU_pulse <= '1';
                end if;
                if btnD_reg = '1' and btnD_prev = '0' then
                    btnD_pulse <= '1';
                end if;
                if btnL_reg = '1' and btnL_prev = '0' then
                    btnL_pulse <= '1';
                end if;
                if btnR_reg = '1' and btnR_prev = '0' then
                    btnR_pulse <= '1';
                end if;
                if btnC_reg = '1' and btnC_prev = '0' then
                    btnC_pulse <= '1';
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 2. T-Shape Cursor Coordinate Mapping
    -- Coordinates:
    --   Top middle cell: (cursor_x + 1, cursor_y)
    --   Bottom row: (cursor_x, cursor_y+1), (cursor_x+1, cursor_y+1), (cursor_x+2, cursor_y+1)
    ------------------------------------------------------------------
    c_x0 <= (cursor_x + 1) mod GRID_WIDTH;
    c_y0 <= cursor_y;

    c_x1 <= cursor_x;
    c_y1 <= (cursor_y + 1) mod GRID_HEIGHT;

    c_x2 <= (cursor_x + 1) mod GRID_WIDTH;
    c_y2 <= (cursor_y + 1) mod GRID_HEIGHT;

    c_x3 <= (cursor_x + 2) mod GRID_WIDTH;
    c_y3 <= (cursor_y + 1) mod GRID_HEIGHT;

    ------------------------------------------------------------------
    -- 3. Cursor Movement and Drawing Logic
    ------------------------------------------------------------------
    process(clk_100mhz)
    begin
        if rising_edge(clk_100mhz) then
            -- Global Reset/Clear (sw(15) high resets everything)
            if sw(15) = '1' then
                cursor_x <= 15;
                cursor_y <= 11;
                for r in 0 to GRID_HEIGHT - 1 loop
                    for c in 0 to GRID_WIDTH - 1 loop
                        grid(r, c) <= '0';
                    end loop;
                end loop;
            else
                -- Vertical Movement (wrap-around limits)
                if btnU_pulse = '1' then
                    if cursor_y = 0 then
                        cursor_y <= GRID_HEIGHT - 1;
                    else
                        cursor_y <= cursor_y - 1;
                    end if;
                elsif btnD_pulse = '1' then
                    if cursor_y = GRID_HEIGHT - 1 then
                        cursor_y <= 0;
                    else
                        cursor_y <= cursor_y + 1;
                    end if;
                end if;

                -- Horizontal Movement (wrap-around limits)
                if btnL_pulse = '1' then
                    if cursor_x = 0 then
                        cursor_x <= GRID_WIDTH - 1;
                    else
                        cursor_x <= cursor_x - 1;
                    end if;
                elsif btnR_pulse = '1' then
                    if cursor_x = GRID_WIDTH - 1 then
                        cursor_x <= 0;
                    else
                        cursor_x <= cursor_x + 1;
                    end if;
                end if;

                -- Draw cells under T-shaped cursor
                if sw(0) = '1' then
                    grid(c_y0, c_x0) <= '1';
                    grid(c_y1, c_x1) <= '1';
                    grid(c_y2, c_x2) <= '1';
                    grid(c_y3, c_x3) <= '1';
                -- Erase cells under T-shaped cursor
                elsif sw(1) = '1' then
                    grid(c_y0, c_x0) <= '0';
                    grid(c_y1, c_x1) <= '0';
                    grid(c_y2, c_x2) <= '0';
                    grid(c_y3, c_x3) <= '0';
                -- Toggle cells under T-shaped cursor on Center button
                elsif btnC_pulse = '1' then
                    grid(c_y0, c_x0) <= not grid(c_y0, c_x0);
                    grid(c_y1, c_x1) <= not grid(c_y1, c_x1);
                    grid(c_y2, c_x2) <= not grid(c_y2, c_x2);
                    grid(c_y3, c_x3) <= not grid(c_y3, c_x3);
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 4. Live Cell Combinational Counter
    ------------------------------------------------------------------
    process(grid)
        variable sum : integer range 0 to GRID_WIDTH * GRID_HEIGHT;
    begin
        sum := 0;
        for r in 0 to GRID_HEIGHT - 1 loop
            for c in 0 to GRID_WIDTH - 1 loop
                if grid(r, c) = '1' then
                    sum := sum + 1;
                end if;
            end loop;
        end loop;
        live_count <= sum;
    end process;

    -- Output live count in binary to low LEDs, light led(15) to show drawing board is active
    led(15) <= '1';
    led(14 downto 10) <= (others => '0');
    led(9 downto 0) <= STD_LOGIC_VECTOR(to_unsigned(live_count, 10));

    ------------------------------------------------------------------
    -- 5. Double-Dabble Binary to BCD Converter (10-bit integer to 3 digits)
    -- Converts cell count up to 768.
    ------------------------------------------------------------------
    process(live_count)
        variable temp : unsigned(9 downto 0);
        variable bcd  : unsigned(11 downto 0);
    begin
        temp := to_unsigned(live_count, 10);
        bcd  := (others => '0');
        for i in 0 to 9 loop
            if bcd(3 downto 0) >= 5 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            if bcd(7 downto 4) >= 5 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            if bcd(11 downto 8) >= 5 then
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            bcd  := bcd(10 downto 0) & temp(9);
            temp := temp(8 downto 0) & '0';
        end loop;
        bcd_ones     <= bcd(3 downto 0);
        bcd_tens     <= bcd(7 downto 4);
        bcd_hundreds <= bcd(11 downto 8);
    end process;

    ------------------------------------------------------------------
    -- 6. 7-Segment Multiplexed Display Driver (scans at ~1.5 kHz)
    ------------------------------------------------------------------
    process(clk_100mhz)
    begin
        if rising_edge(clk_100mhz) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    active_digit <= STD_LOGIC_VECTOR(refresh_counter(15 downto 14));

    process(active_digit, bcd_ones, bcd_tens, bcd_hundreds)
    begin
        an  <= "1111";
        seg <= "1111111";
        dp  <= '1'; -- decimal point off

        case active_digit is
            when "00" => -- Digit 0 (Rightmost)
                an  <= "1110";
                seg <= get_seg_pattern(bcd_ones);

            when "01" => -- Digit 1
                an  <= "1101";
                seg <= get_seg_pattern(bcd_tens);

            when "10" => -- Digit 2
                an  <= "1011";
                seg <= get_seg_pattern(bcd_hundreds);

            when "11" => -- Digit 3 (Leftmost)
                an  <= "0111";
                seg <= "0100001"; -- lower-case 'd' for Drawing mode

            when others =>
                null;
        end case;
    end process;

    ------------------------------------------------------------------
    -- 7. VGA Frame-Scan Cell Tracker (pix_clk domain)
    -- Increments horizontal/vertical cell indexes dynamically.
    ------------------------------------------------------------------
    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            -- Horizontal Cell Scan
            if h_count < 640 then
                if h_count = 0 then
                    cell_x <= 0;
                    px_sub <= 0;
                else
                    if px_sub = 19 then
                        px_sub <= 0;
                        cell_x <= cell_x + 1;
                    else
                        px_sub <= px_sub + 1;
                    end if;
                end if;
            else
                cell_x <= 0;
                px_sub <= 0;
            end if;

            -- Vertical Cell Scan
            if v_count < 480 then
                if v_count = 0 then
                    cell_y <= 0;
                    py_sub <= 0;
                else
                    if h_count = 0 then
                        if py_sub = 19 then
                            py_sub <= 0;
                            cell_y <= cell_y + 1;
                        else
                            py_sub <= py_sub + 1;
                        end if;
                    end if;
                end if;
            else
                cell_y <= 0;
                py_sub <= 0;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- 8. VGA Color Multiplexing Pipeline
    ------------------------------------------------------------------
    process(pix_clk)
    begin
        if rising_edge(pix_clk) then
            vga_r <= (others => '0');
            vga_g <= (others => '0');
            vga_b <= (others => '0');

            if video_on = '1' then
                -- Draw thin, dark-grey grid lines separating cells
                if px_sub = 0 or py_sub = 0 then
                    vga_r <= "0011";
                    vga_g <= "0011";
                    vga_b <= "0011";
                -- Draw RED cursor (upside-down T-shape)
                elsif ((cell_x = c_x0) and (cell_y = c_y0)) or
                      ((cell_x = c_x1) and (cell_y = c_y1)) or
                      ((cell_x = c_x2) and (cell_y = c_y2)) or
                      ((cell_x = c_x3) and (cell_y = c_y3)) then
                    vga_r <= "1111";
                    vga_g <= "0000";
                    vga_b <= "0000";
                -- Draw active grid Cells (White)
                else
                    if grid(cell_y, cell_x) = '1' then
                        vga_r <= "1111";
                        vga_g <= "1111";
                        vga_b <= "1111";
                    else
                        vga_r <= "0000";
                        vga_g <= "0000";
                        vga_b <= "0000";
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
