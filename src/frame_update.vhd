LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.game_of_life_pkg.ALL;

ENTITY frame_update IS
    PORT (
        clk_100mhz : IN  STD_LOGIC;
        rst        : IN  STD_LOGIC;
        state      : INOUT state_type;
        sec_counter: INOUT INTEGER RANGE 0 TO ONE_SEC_LIMIT;
        frame_color: INOUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        cell_idx   : INOUT INTEGER RANGE 0 TO 1023;
        b_we       : OUT STD_LOGIC;
        b_addr     : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        b_di       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        d_we       : OUT STD_LOGIC;
        d_di       : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        fsm_d_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
        b_do       : IN  STD_LOGIC_VECTOR(1 DOWNTO 0)
    );
END ENTITY frame_update;

ARCHITECTURE frame_update_arch OF frame_update IS
BEGIN

    -- 4. Update FSM: Writes buffer, then copies buffer to display array every 1 second
    PROCESS (clk_100mhz)
    BEGIN
        IF rising_edge(clk_100mhz) THEN
            IF rst = '1' THEN
                state       <= IDLE;
                sec_counter <= 0;
                frame_color <= "00";
                cell_idx    <= 0;
                b_we        <= '0';
                d_we        <= '0';
            ELSE
                CASE state IS
                    WHEN IDLE =>
                        b_we <= '0';
                        d_we <= '0';
                        IF sec_counter = ONE_SEC_LIMIT THEN
                            sec_counter <= 0;
                            frame_color <= NOT frame_color; -- Toggle between "00" (Black) and "11" (White)
                            b_di <= NOT frame_color;
                            cell_idx <= 0;
                            b_we <= '1';
                            state <= WRITE_BUFFER;
                        ELSE
                            sec_counter <= sec_counter + 1;
                        END IF;

                    WHEN WRITE_BUFFER =>
                        -- Write frame_color to all 768 addresses in buffer_arr
                        b_we <= '1';
                        b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx, 10));
                        b_di <= frame_color;

                        IF cell_idx = TOTAL_CELLS - 1 THEN
                            cell_idx <= 0;
                            b_we <= '0'; -- Turn off write enable for next state
                            d_we <= '0'; -- Keep display write enable off
                            state <= COPY_TO_DISPLAY;
                        ELSE
                            cell_idx <= cell_idx + 1;
                        END IF;

                    WHEN COPY_TO_DISPLAY =>
                        -- Disable write to buffer, read from it
                        b_we <= '0';

                        IF cell_idx = 0 THEN
                            -- Read first address (0) from buffer array
                            b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(0, 10));
                            d_we <= '0'; -- Data not ready yet
                            cell_idx <= cell_idx + 1;
                        ELSIF cell_idx < TOTAL_CELLS THEN
                            b_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx, 10));
                            fsm_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(cell_idx - 1, 10));
                            d_di <= b_do;
                            d_we <= '1';
                            cell_idx <= cell_idx + 1;
                        ELSIF cell_idx = TOTAL_CELLS THEN
                            -- Write the last read data (from address 767) to display_arr(767)
                            fsm_d_addr <= STD_LOGIC_VECTOR(TO_UNSIGNED(TOTAL_CELLS - 1, 10));
                            d_di <= b_do;
                            d_we <= '1';
                            cell_idx <= cell_idx + 1;
                        ELSE
                            d_we <= '0'; -- Disable write on next cycle
                            cell_idx <= 0;
                            state <= IDLE;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

END ARCHITECTURE frame_update_arch;
