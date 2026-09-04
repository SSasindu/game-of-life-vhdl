----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/03/2026 11:51:20 AM
-- Design Name: 
-- Module Name: cell_array_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity cell_array_tb is

end cell_array_tb;

architecture Behavioral of cell_array_tb is
signal clk : std_logic := '0';
signal we : std_logic := '0';
signal addr: std_logic_vector(9 downto 0):= (others => '0');
signal di : std_logic_vector(1 downto 0) := (others =>'0');
signal do : std_logic_vector(1 downto 0);
begin

cell_array_inst: entity work.cell_array
port map(
    clk => clk,
    we => we,
    addr => addr,
    di => di,
    do => do
);

process
begin

di <= "11";

wait for 10 ns;
we <= '1';
wait for 5 ns;
clk <= '1';

wait for 10 ns;
clk <= '0';

wait for 10 ns;
--we <= '0';
di <= "00";
wait for 5 ns;
clk <= '1';

wait for 10 ns;
clk <= '0';

wait for 10 ns;
clk <= '1';

wait for 10 ns;
clk <= '0';
wait;
end process;

end Behavioral;
