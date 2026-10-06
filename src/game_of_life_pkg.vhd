LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE game_of_life_pkg IS
    -- VGA Timing Constants (Default 640x480 @ 60 Hz)
    CONSTANT H_ACTIVE : INTEGER := 640;
    CONSTANT H_FRONT  : INTEGER := 16;
    CONSTANT H_SYNC   : INTEGER := 96;
    CONSTANT H_BACK   : INTEGER := 48;
    CONSTANT H_TOTAL  : INTEGER := H_ACTIVE + H_FRONT + H_SYNC + H_BACK;

    CONSTANT V_ACTIVE : INTEGER := 480;
    CONSTANT V_FRONT  : INTEGER := 10;
    CONSTANT V_SYNC   : INTEGER := 2;
    CONSTANT V_BACK   : INTEGER := 33;
    CONSTANT V_TOTAL  : INTEGER := V_ACTIVE + V_FRONT + V_SYNC + V_BACK;

    -- Grid Resolution Constants
    CONSTANT GRID_WIDTH  : INTEGER := 32;
    CONSTANT GRID_HEIGHT : INTEGER := 24;
    CONSTANT TOTAL_CELLS : INTEGER := GRID_WIDTH * GRID_HEIGHT;

    -- Dynamic Cell Size (adapts cell width/height automatically for any screen resolution)
    CONSTANT CELL_WIDTH  : INTEGER := H_ACTIVE / GRID_WIDTH;
    CONSTANT CELL_HEIGHT : INTEGER := V_ACTIVE / GRID_HEIGHT;

    CONSTANT TIME_LIMIT  : INTEGER := 100_000_000 - 1;

    TYPE state_type IS (
        IDLE,
        UPDATE_CELL,
        WRITE_RESULT,
        NEXT_CELL
    );
END PACKAGE;