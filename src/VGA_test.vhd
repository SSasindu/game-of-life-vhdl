library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.game_of_life_pkg.ALL;

entity VGA_test is
	Port (
		clk_100mhz : in  STD_LOGIC;
		rst        : in  STD_LOGIC;
		hsync      : out STD_LOGIC;
		vsync      : out STD_LOGIC;
		vga_r      : out STD_LOGIC_VECTOR(3 downto 0);
		vga_g      : out STD_LOGIC_VECTOR(3 downto 0);
		vga_b      : out STD_LOGIC_VECTOR(3 downto 0)
	);
end VGA_test;

architecture Behavioral of VGA_test is

	-- VGA timing constants imported from game_of_life_pkg
	constant H_VISIBLE     : integer := H_ACTIVE;
	constant H_FRONT_PORCH : integer := H_FRONT;
	constant H_SYNC_PULSE  : integer := H_SYNC;
	constant H_BACK_PORCH  : integer := H_BACK;

	constant V_VISIBLE     : integer := V_ACTIVE;
	constant V_FRONT_PORCH : integer := V_FRONT;
	constant V_SYNC_PULSE  : integer := V_SYNC;
	constant V_BACK_PORCH  : integer := V_BACK;

	signal pix_clk         : STD_LOGIC := '0';
	signal div_count       : unsigned(1 downto 0) := (others => '0');

	signal h_count         : integer range 0 to H_TOTAL - 1 := 0;
	signal v_count         : integer range 0 to V_TOTAL - 1 := 0;
	signal video_on        : STD_LOGIC := '0';

	signal r_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	signal g_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	signal b_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

	-- Divide 100 MHz board clock down to pixel clock.
	process(clk_100mhz)
	begin
		if rising_edge(clk_100mhz) then
			if rst = '1' then
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
			if rst = '1' then
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

	-- Scalable 8-color vertical bars dynamically adapting to H_ACTIVE
	process(h_count, video_on)
		variable bar_w : integer;
	begin
		r_next <= (others => '0');
		g_next <= (others => '0');
		b_next <= (others => '0');
		bar_w  := H_VISIBLE / 8;

		if video_on = '1' then
			if h_count < bar_w then
				r_next <= "1111"; g_next <= "1111"; b_next <= "1111"; -- white
			elsif h_count < bar_w * 2 then
				r_next <= "1111"; g_next <= "1111"; b_next <= "0000"; -- yellow
			elsif h_count < bar_w * 3 then
				r_next <= "0000"; g_next <= "1111"; b_next <= "1111"; -- cyan
			elsif h_count < bar_w * 4 then
				r_next <= "0000"; g_next <= "1111"; b_next <= "0000"; -- green
			elsif h_count < bar_w * 5 then
				r_next <= "1111"; g_next <= "0000"; b_next <= "1111"; -- magenta
			elsif h_count < bar_w * 6 then
				r_next <= "1111"; g_next <= "0000"; b_next <= "0000"; -- red
			elsif h_count < bar_w * 7 then
				r_next <= "0000"; g_next <= "0000"; b_next <= "1111"; -- blue
			else
				r_next <= "0000"; g_next <= "0000"; b_next <= "0000"; -- black
			end if;
		end if;
	end process;

	vga_r <= r_next;
	vga_g <= g_next;
	vga_b <= b_next;

end Behavioral;
