library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity player is
    Port (
        clk          : IN  STD_LOGIC;
        rst          : IN  STD_LOGIC;
        game_over    : IN  STD_LOGIC := '0';
        up           : IN  STD_LOGIC;
        down         : IN  STD_LOGIC;
        left         : IN  STD_LOGIC;
        right        : IN  STD_LOGIC;
        player_x_out : OUT INTEGER RANGE 0 TO 31;
        player_y_out : OUT INTEGER RANGE 0 TO 23
    );
end player;

architecture Behavioral of player is
    signal player_x : integer range 0 to 31 := 16;
    signal player_y : integer range 0 to 23 := 20;

    -- 100 Hz sampling clock divider
    signal sample_clk_div : integer range 0 to 999_999 := 0;
    signal sample_tick    : std_logic := '0';

    -- Synchronizer/Debouncer Shift Registers
    signal up_sync    : std_logic_vector(2 downto 0) := (others => '0');
    signal down_sync  : std_logic_vector(2 downto 0) := (others => '0');
    signal left_sync  : std_logic_vector(2 downto 0) := (others => '0');
    signal right_sync : std_logic_vector(2 downto 0) := (others => '0');

    -- Edge Detector History Registers
    signal up_deb_prev    : std_logic := '0';
    signal down_deb_prev  : std_logic := '0';
    signal left_deb_prev  : std_logic := '0';
    signal right_deb_prev : std_logic := '0';

    -- One-pulse edge detect signals
    signal up_pulse    : std_logic;
    signal down_pulse  : std_logic;
    signal left_pulse  : std_logic;
    signal right_pulse : std_logic;
begin

    -- Clock Divider (100 MHz to 100 Hz Sample Clock)
    process(clk)
    begin
        if rising_edge(clk) then
            if sample_clk_div = 999_999 then
                sample_clk_div <= 0;
                sample_tick <= '1';
            else
                sample_clk_div <= sample_clk_div + 1;
                sample_tick <= '0';
            end if;
        end if;
    end process;

    -- Button Synchronization and Debouncing
    process(clk)
    begin
        if rising_edge(clk) then
            if sample_tick = '1' then
                up_sync <= up_sync(1 downto 0) & up;
                down_sync <= down_sync(1 downto 0) & down;
                left_sync <= left_sync(1 downto 0) & left;
                right_sync <= right_sync(1 downto 0) & right;
            end if;
        end if;
    end process;

    -- Edge Detection Registers
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                up_deb_prev <= '0';
                down_deb_prev <= '0';
                left_deb_prev <= '0';
                right_deb_prev <= '0';
            elsif sample_tick = '1' then
                up_deb_prev <= up_sync(2);
                down_deb_prev <= down_sync(2);
                left_deb_prev <= left_sync(2);
                right_deb_prev <= right_sync(2);
            end if;
        end if;
    end process;

    -- Edge Detect Pulse Outputs (High for exactly 1 clock cycle)
    up_pulse <= '1' when (up_sync(2) = '1' and up_deb_prev = '0' and sample_tick = '1') else '0';
    down_pulse <= '1' when (down_sync(2) = '1' and down_deb_prev = '0' and sample_tick = '1') else '0';
    left_pulse <= '1' when (left_sync(2) = '1' and left_deb_prev = '0' and sample_tick = '1') else '0';
    right_pulse <= '1' when (right_sync(2) = '1' and right_deb_prev = '0' and sample_tick = '1') else '0';

    -- Position Registers and Boundary Checking (Clamped movements, disabled when game_over='1')
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                player_x <= 16;
                player_y <= 20;
            elsif game_over = '0' then
                if left_pulse = '1' then
                    if player_x > 0 then
                        player_x <= player_x - 1;
                    end if;
                elsif right_pulse = '1' then
                    if player_x < 31 then
                        player_x <= player_x + 1;
                    end if;
                end if;
                
                if up_pulse = '1' then
                    if player_y > 0 then
                        player_y <= player_y - 1;
                    end if;
                elsif down_pulse = '1' then
                    if player_y < 23 then
                        player_y <= player_y + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Output assignments
    player_x_out <= player_x;
    player_y_out <= player_y;

end Behavioral;
