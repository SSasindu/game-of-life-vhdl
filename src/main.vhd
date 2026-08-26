LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.game_of_life_pkg.ALL;

ENTITY main IS
    PORT (
        clk_100mhz : IN  STD_LOGIC;
        rst        : IN  STD_LOGIC;
        hsync      : OUT STD_LOGIC;
        vsync      : OUT STD_LOGIC;
        vga_r      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_g      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        vga_b      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY main;

ARCHITECTURE main_arch OF main IS

    SIGNAL pix_clk : STD_LOGIC := '0';
    SIGNAL h_count : INTEGER RANGE 0 TO H_TOTAL - 1 := 0;
    SIGNAL v_count : INTEGER RANGE 0 TO V_TOTAL - 1 := 0;
    SIGNAL video_on : STD_LOGIC := '0';

    SIGNAL d_we : STD_LOGIC := '0';
    SIGNAL d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL d_di : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL d_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL b_we : STD_LOGIC := '0';
    SIGNAL b_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_di : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
    SIGNAL b_do : STD_LOGIC_VECTOR(1 DOWNTO 0);

    SIGNAL state : state_type := IDLE;
    SIGNAL sec_counter : INTEGER RANGE 0 TO ONE_SEC_LIMIT := 0;
    SIGNAL frame_color : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL cell_idx : INTEGER RANGE 0 TO 1023 := 0;

    SIGNAL fsm_d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
    SIGNAL vga_d_addr : STD_LOGIC_VECTOR(9 DOWNTO 0) := (OTHERS => '0');
BEGIN

    -- Instantiate Display Memory Array
    display_arr : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk  => clk_100mhz,
            we   => d_we,
            addr => d_addr,
            di   => d_di,
            do   => d_do
        );

    -- Instantiate Buffer Memory Array
    buffer_arr : ENTITY work.cell_array
        GENERIC MAP(ADDR_WIDTH => 10, DATA_WIDTH => 2)
        PORT MAP(
            clk  => clk_100mhz,
            we   => b_we,
            addr => b_addr,
            di   => b_di,
            do   => b_do
        );

    vga_timing_inst : ENTITY work.vga_timing
        PORT MAP(
            clk_100mhz => clk_100mhz,
            rst        => rst,
            pix_clk    => pix_clk,
            h_count    => h_count,
            v_count    => v_count,
            hsync      => hsync,
            vsync      => vsync
        );

    frame_update_inst : ENTITY work.frame_update
        PORT MAP(
            clk_100mhz => clk_100mhz,
            rst        => rst,
            state      => state,
            sec_counter=> sec_counter,
            frame_color=> frame_color,
            cell_idx   => cell_idx,
            b_we       => b_we,
            b_addr     => b_addr,
            b_di       => b_di,
            d_we       => d_we,
            d_di       => d_di,
            fsm_d_addr => fsm_d_addr,
            b_do       => b_do
        );

    pixel_map_inst : ENTITY work.pixel_map
        PORT MAP(
            h_count    => h_count,
            v_count    => v_count,
            state      => state,
            fsm_d_addr => fsm_d_addr,
            d_do       => d_do,
            video_on   => video_on,
            vga_d_addr => vga_d_addr,
            d_addr     => d_addr,
            vga_r      => vga_r,
            vga_g      => vga_g,
            vga_b      => vga_b
        );

END ARCHITECTURE main_arch;