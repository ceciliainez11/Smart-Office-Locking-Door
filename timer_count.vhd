library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_count is
    generic(
        Second : integer := 5);
    port(
        Clk     : in std_logic;
        START : in std_logic;
        DONE : out std_logic := '0'
    );
end entity;

architecture rtl of timer_count is

    -- Signal for counting clock periods
    signal Ticks : integer := 0;
    signal RST : std_logic := '0';

begin

    process(Clk, Rst, Ticks, START) is
    begin
        if rising_edge(Clk) then
            if (START = '1') then
                if (Rst = '1') then
                    Ticks   <= 0;
                else
                    if Ticks = Second - 1 then
                        Ticks <= 0;
                        DONE <= '1';
                    else
                        Ticks <= Ticks + 1;
                    end if;

                end if;
            end if;
        end if;
    end process;

end architecture;