library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_player_logic is
end tb_player_logic;

architecture Behavioral of tb_player_logic is

    constant CLK_PERIOD : time := 10 ns;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal up           : std_logic := '0';
    signal down         : std_logic := '0';
    signal left         : std_logic := '0';
    signal right        : std_logic := '0';
    signal player_x_out : integer range 0 to 31;
    signal player_y_out : integer range 0 to 23;

    signal sim_finished : boolean := false;

begin

    dut : entity work.player
        port map (
            clk          => clk,
            rst          => rst,
            up           => up,
            down         => down,
            left         => left,
            right        => right,
            player_x_out => player_x_out,
            player_y_out => player_y_out
        );

    clk_process : process
    begin
        while not sim_finished loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_proc : process

        variable curr_x : integer := 16;
        variable curr_y : integer := 20;

        procedure press_button(
            signal btn : out std_logic;
            constant press_time   : in time := 35 ms;
            constant release_time : in time := 25 ms
        ) is
        begin
            btn <= '1';
            wait for press_time;
            btn <= '0';
            wait for release_time;
        end procedure;

        procedure check_pos(
            constant exp_x : in integer;
            constant exp_y : in integer
        ) is
        begin
            if (player_x_out = exp_x and player_y_out = exp_y) then
                report "pass";
            else
                report "fail: expected (" & integer'image(exp_x) & "," & integer'image(exp_y) & 
                       "), got (" & integer'image(player_x_out) & "," & integer'image(player_y_out) & ")"
                       severity error;
            end if;
        end procedure;

        procedure move_up(
            variable x : inout integer;
            variable y : inout integer
        ) is
        begin
            press_button(up);
            if y > 0 then
                y := y - 1;
            end if;
            check_pos(x, y);
        end procedure;

        procedure move_down(
            variable x : inout integer;
            variable y : inout integer
        ) is
        begin
            press_button(down);
            if y < 23 then
                y := y + 1;
            end if;
            check_pos(x, y);
        end procedure;

        procedure move_left(
            variable x : inout integer;
            variable y : inout integer
        ) is
        begin
            press_button(left);
            if x > 0 then
                x := x - 1;
            end if;
            check_pos(x, y);
        end procedure;

        procedure move_right(
            variable x : inout integer;
            variable y : inout integer
        ) is
        begin
            press_button(right);
            if x < 31 then
                x := x + 1;
            end if;
            check_pos(x, y);
        end procedure;

    begin
        rst <= '1';
        up <= '0'; down <= '0'; left <= '0'; right <= '0';
        wait for 100 ns;
        rst <= '0';
        wait for 100 ns;

        curr_x := 16;
        curr_y := 20;
        check_pos(curr_x, curr_y);

--        move_up(curr_x, curr_y);
--        move_down(curr_x, curr_y);
--        move_left(curr_x, curr_y);
--        move_right(curr_x, curr_y);

        for i in 1 to 3 loop
            move_left(curr_x, curr_y);
        end loop;

        for i in 1 to 3 loop
            move_up(curr_x, curr_y);
        end loop;

        for i in 1 to 3 loop
            move_right(curr_x, curr_y);
        end loop;

        for i in 1 to 3 loop
            move_down(curr_x, curr_y);
        end loop;

        sim_finished <= true;
        wait;
    end process;

end Behavioral;
