library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_test is
	Generic (
		SIM_MODE : boolean := false
	);
	Port (
		clk_100mhz : in  STD_LOGIC;
		btnC       : in  STD_LOGIC; -- Play/Pause toggle
		btnU       : in  STD_LOGIC; -- Cursor Up
		btnD       : in  STD_LOGIC; -- Cursor Down
		btnL       : in  STD_LOGIC; -- Cursor Left
		btnR       : in  STD_LOGIC; -- Cursor Right
		sw         : in  STD_LOGIC_VECTOR(15 downto 0); -- Controls (draw, speed, reset)
		led        : out STD_LOGIC_VECTOR(15 downto 0); -- Status & Pop count
		seg        : out STD_LOGIC_VECTOR(6 downto 0);   -- 7-segment segments
		an         : out STD_LOGIC_VECTOR(3 downto 0);   -- 7-segment anodes
		dp         : out STD_LOGIC;                      -- Decimal point
		hsync      : out STD_LOGIC;
		vsync      : out STD_LOGIC;
		vga_r      : out STD_LOGIC_VECTOR(3 downto 0);
		vga_g      : out STD_LOGIC_VECTOR(3 downto 0);
		vga_b      : out STD_LOGIC_VECTOR(3 downto 0)
	);
end VGA_test;

architecture Behavioral of VGA_test is

	-- 640x480 @ 60 Hz VGA timing (25 MHz pixel clock)
	constant H_VISIBLE     : integer := 640;
	constant H_FRONT_PORCH : integer := 16;
	constant H_SYNC_PULSE  : integer := 96;
	constant H_BACK_PORCH  : integer := 48;
	constant H_TOTAL       : integer := H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE + H_BACK_PORCH;

	constant V_VISIBLE     : integer := 480;
	constant V_FRONT_PORCH : integer := 10;
	constant V_SYNC_PULSE  : integer := 2;
	constant V_BACK_PORCH  : integer := 33;
	constant V_TOTAL       : integer := V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE + V_BACK_PORCH;

	signal pix_clk         : STD_LOGIC := '0';
	signal div_count       : unsigned(1 downto 0) := (others => '0');

	signal h_count         : integer range 0 to H_TOTAL - 1 := 0;
	signal v_count         : integer range 0 to V_TOTAL - 1 := 0;
	signal video_on        : STD_LOGIC := '0';

begin

	-- Divide 100 MHz board clock down to 25 MHz pixel clock.
	process(clk_100mhz)
	begin
		if rising_edge(clk_100mhz) then
			if sw(15) = '1' then
				div_count <= (others => '0');
				pix_clk   <= '0';
			else
				div_count <= div_count + 1;
				pix_clk   <= div_count(1);
			end if;
		end if;
	end process;

	-- Horizontal/vertical pixel counters.
	process(pix_clk)
	begin
		if rising_edge(pix_clk) then
			if sw(15) = '1' then
				h_count <= 0;
				v_count <= 0;
			else
				if h_count = H_TOTAL - 1 then
					h_count <= 0;
					if v_count = V_TOTAL - 1 then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
		end if;
	end process;

	video_on <= '1' when (h_count < H_VISIBLE and v_count < V_VISIBLE) else '0';

	-- Active-low sync pulses.
	hsync <= '0' when (h_count >= H_VISIBLE + H_FRONT_PORCH and
					   h_count <  H_VISIBLE + H_FRONT_PORCH + H_SYNC_PULSE)
			 else '1';

	vsync <= '0' when (v_count >= V_VISIBLE + V_FRONT_PORCH and
					   v_count <  V_VISIBLE + V_FRONT_PORCH + V_SYNC_PULSE)
			 else '1';

	------------------------------------------------------------------
	-- Instantiate cell_array core logic and VGA renderer
	------------------------------------------------------------------
	cell_array_inst: entity work.cell_array
		generic map (
			SIM_MODE => SIM_MODE
		)
		port map (
			clk_100mhz => clk_100mhz,
			pix_clk    => pix_clk,
			sw         => sw,
			btnU       => btnU,
			btnD       => btnD,
			btnL       => btnL,
			btnR       => btnR,
			btnC       => btnC,
			h_count    => h_count,
			v_count    => v_count,
			video_on   => video_on,
			vga_r      => vga_r,
			vga_g      => vga_g,
			vga_b      => vga_b,
			led        => led,
			seg        => seg,
			an         => an,
			dp         => dp
		);

end Behavioral;
