-- Libraries / Package
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Entity
ENTITY Parkiran_tb IS
END Parkiran_tb;

-- Architecture
ARCHITECTURE behavioral OF Parkiran_tb IS
    COMPONENT Parkiran
    PORT (
        -- Input
        CLK : IN STD_LOGIC;
        Akses_kartu, Pintu_belakang : IN STD_LOGIC;
        -- Uang_A, Uang_B : IN STD_LOGIC; (GAPAKE)

        -- Output
        Pintu : OUT STD_LOGIC;
        Segment1, Segment2 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        Counter : INOUT INTEGER RANGE 0 TO 50;
        LED_hijau, LED_merah : OUT STD_LOGIC
    );
    end COMPONENT;

    SIGNAL CLK : STD_LOGIC;
    SIGNAL Akses_kartu, Pintu_belakang : STD_LOGIC;
    SIGNAL Uang_A, Uang_B : STD_LOGIC;
    SIGNAL Pintu : STD_LOGIC;
    SIGNAL Segment1, Segment2 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL Counter : INTEGER RANGE 0 TO 50;
    SIGNAL LED_hijau, LED_merah : STD_LOGIC;
    CONSTANT T : TIME := 20 ns;
    CONSTANT max_clk : INTEGER := 10;
    SIGNAL i : INTEGER := 1;

BEGIN
    UUT : Parkiran PORT MAP(
        CLK => CLK,
        Akses_kartu => Akses_kartu,
        Pintu_belakang => Pintu_belakang,
        Uang_A => Uang_A,
        Uang_B => Uang_B,
        Pintu => Pintu,
        Segment1 => Segment1,
        Segment2 => Segment2,
        Counter => Counter,
        LED_hijau => LED_hijau,
        LED_merah => LED_merah
    );
    
    clock_generator : PROCESS
    BEGIN
        CLK <= '1';
        WAIT FOR T/2;
        CLK <= '0';
        WAIT FOR T/2;
        IF (i < max_clk) THEN
            i <= i + 1;
        ELSE
            WAIT;
        END IF;
    END PROCESS;

    stim_proc : PROCESS
        CONSTANT Akses_kartu_stream : STD_LOGIC_VECTOR(0 TO 9) := ("1111100011");
        CONSTANT Pintu_belakang_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000011100");
        CONSTANT Uang_A_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000000100");
        CONSTANT Uang_B_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000001000");
        CONSTANT LED_hijau_stream : STD_LOGIC_VECTOR(0 TO 9) := ("1101100011");
        CONSTANT LED_merah_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000001100");
    BEGIN
        FOR j IN 0 TO 9 LOOP
            Akses_kartu <= Akses_kartu_stream(j);
            Pintu_belakang <= Pintu_belakang_stream(j);
            Uang_A <= Uang_A_stream(j);
            Uang_B <= Uang_B_stream(j);
            WAIT FOR T;
            ASSERT ((LED_hijau = LED_hijau_stream(j)) AND
            (LED_merah = LED_merah_stream(j)))
            REPORT "nyala lampu tidak sesuai pada looping ke " &
                INTEGER'image(j) SEVERITY error;
        END LOOP;
        WAIT;
    END PROCESS;
END behavioral;