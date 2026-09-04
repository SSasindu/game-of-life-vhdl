----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2026 08:13:20 PM
-- Design Name: 
-- Module Name: vga_timing_tb - Behavioral
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
use ieee.numeric_std.all;
use work.game_of_life_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity vga_timing_tb is
end vga_timing_tb;

architecture Behavioral of vga_timing_tb is

signal clk : std_logic:= '0';
signal rst: std_logic:= '0';
 signal h_count : INTEGER RANGE 0 TO H_TOTAL;
  signal     v_count : INTEGER RANGE 0 TO V_TOTAL - 1;
 signal      hsync : STD_LOGIC;
  signal     vsync : STD_LOGIC;

begin
 vga_timing_inst : ENTITY work.vga_timing
        PORT MAP(
            clk_100mhz => clk,
            rst => rst,
            h_count => h_count,
            v_count => v_count,
            hsync => hsync,
            vsync => vsync
        );
        
process
        begin
            clk <= '0';
        
            while true loop
                wait for 10 ns;
                clk <= not clk;
            end loop;
        end process;


end Behavioral;
