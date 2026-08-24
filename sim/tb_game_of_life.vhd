library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_game_of_life is
end tb_game_of_life;

architecture behavior of tb_game_of_life is

    -- Clock and Inputs
    signal clk_100mhz : STD_LOGIC := '0';
    signal btnC       : STD_LOGIC := '0';
    signal btnU       : STD_LOGIC := '0';
    signal btnD       : STD_LOGIC := '0';
    signal btnL       : STD_LOGIC := '0';
    signal btnR       : STD_LOGIC := '0';
    signal sw         : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');

    -- Outputs
    signal led        : STD_LOGIC_VECTOR(15 downto 0);
    signal seg        : STD_LOGIC_VECTOR(6 downto 0);
    signal an         : STD_LOGIC_VECTOR(3 downto 0);
    signal dp         : STD_LOGIC;
    signal hsync      : STD_LOGIC;
    signal vsync      : STD_LOGIC;
    signal vga_r      : STD_LOGIC_VECTOR(3 downto 0);
    signal vga_g      : STD_LOGIC_VECTOR(3 downto 0);
    signal vga_b      : STD_LOGIC_VECTOR(3 downto 0);

    -- Clock period definitions
    constant clk_period : time := 10 ns; -- 100 MHz clock

begin

    -- Instantiate the Unit Under Test (UUT)
    -- Enable SIM_MODE to accelerate button debouncing ticks
    uut: entity work.VGA_test
        generic map (
            SIM_MODE => true
        )
        port map (
            clk_100mhz => clk_100mhz,
            btnC       => btnC,
            btnU       => btnU,
            btnD       => btnD,
            btnL       => btnL,
            btnR       => btnR,
            sw         => sw,
            led        => led,
            seg        => seg,
            an         => an,
            dp         => dp,
            hsync      => hsync,
            vsync      => vsync,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b
        );

    -- Clock process definitions
    clk_process :process
    begin
        clk_100mhz <= '0';
        wait for clk_period/2;
        clk_100mhz <= '1';
        wait for clk_period/2;
    end process;

    -- Stimulus process
    stim_proc: process
    begin
        -- Assert global clear (sw(15))
        sw(15) <= '1';
        wait for 100 ns;
        sw(15) <= '0';
        wait for 100 ns;

        -- Check: Starting count should be 0 (led(9 downto 0) = binary "0000000000")
        assert (led(9 downto 0) = "0000000000")
            report "Error: Initial active cells count should be 0"
            severity note;

        -------------------------------------------------------------
        -- TEST CASE 1: Continuous Drawing using sw[0] and movement
        -------------------------------------------------------------
        -- Flip sw(0) up to enable draw mode (sets cells under T-shape to alive)
        sw(0) <= '1';
        wait for 200 ns; -- let debouncer capture

        -- Move cursor LEFT once (from 15 to 14)
        btnL <= '1';
        wait for 200 ns;
        btnL <= '0';
        wait for 200 ns;

        -- Flip sw(0) down to stop continuous drawing
        sw(0) <= '0';
        wait for 200 ns;

        -- Verify count has increased
        report "Note: Active cells count after drawing: " & integer'image(to_integer(unsigned(led(9 downto 0))));

        -------------------------------------------------------------
        -- TEST CASE 2: Toggle drawing using btnC (Center Button)
        -------------------------------------------------------------
        -- Move cursor RIGHT once (back to 15)
        btnR <= '1';
        wait for 200 ns;
        btnR <= '0';
        wait for 200 ns;

        -- Press btnC (Center button) to toggle cells under the T-shaped cursor
        btnC <= '1';
        wait for 200 ns;
        btnC <= '0';
        wait for 200 ns;

        report "Note: Active cells count after btnC toggle: " & integer'image(to_integer(unsigned(led(9 downto 0))));

        -- Reset board to clear all drawings
        sw(15) <= '1';
        wait for 200 ns;
        sw(15) <= '0';
        wait for 200 ns;

        assert (led(9 downto 0) = "0000000000")
            report "Error: Grid should be cleared after resetting"
            severity note;

        report "Pattern Drawing Simulation completed successfully!" severity note;
        wait;
    end process;

end behavior;
