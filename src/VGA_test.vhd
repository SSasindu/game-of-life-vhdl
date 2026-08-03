----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/02/2026 02:02:42 PM
-- Design Name: 
-- Module Name: VGA_test - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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

	signal r_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	signal g_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	signal b_next          : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

	-- Divide 100 MHz board clock down to 25 MHz pixel clock.
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

	-- Simple 8-color vertical bars for monitor bring-up.
	process(h_count, video_on)
	begin
		r_next <= (others => '0');
		g_next <= (others => '0');
		b_next <= (others => '0');

		if video_on = '1' then
			if h_count < 80 then
				r_next <= "1111"; g_next <= "1111"; b_next <= "1111"; -- white
			elsif h_count < 160 then
				r_next <= "1111"; g_next <= "1111"; b_next <= "0000"; -- yellow
			elsif h_count < 240 then
				r_next <= "0000"; g_next <= "1111"; b_next <= "1111"; -- cyan
			elsif h_count < 320 then
				r_next <= "0000"; g_next <= "1111"; b_next <= "0000"; -- green
			elsif h_count < 400 then
				r_next <= "1111"; g_next <= "0000"; b_next <= "1111"; -- magenta
			elsif h_count < 480 then
				r_next <= "1111"; g_next <= "0000"; b_next <= "0000"; -- red
			elsif h_count < 560 then
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
