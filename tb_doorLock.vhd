-- Libraries / Package
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Entity
ENTITY tb_doorLock IS
END tb_doorLock;
 
-- Architecture
ARCHITECTURE behavioral OF tb_doorLock IS
    component doorLock IS
    PORT (
        -- Input
        CLK : IN STD_LOGIC;
        Pintu_depan, Akses_depan, Akses_belakang : IN STD_LOGIC;
        Input_Pass : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
 
        -- Output
        Kunci_depan, Kunci_belakang : OUT STD_LOGIC;
        Segment1, Segment2 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        LED_hijau, LED_merah : OUT STD_LOGIC
    );
    end component;
 
    SIGNAL CLK : STD_LOGIC;
    SIGNAL Pintu_depan, Akses_depan, Akses_belakang : STD_LOGIC;
    Signal Input_Pass : STD_LOGIC_VECTOR (31 DOWNTO 0) := ("01101001001100001100110001110011"); --X"6930CC73";
   
    Signal Kunci_depan, Kunci_belakang : STD_LOGIC;
    Signal Segment1, Segment2 : STD_LOGIC_VECTOR (6 DOWNTO 0);
    Signal LED_hijau, LED_merah :  STD_LOGIC;
    SIGNAL Counter : INTEGER RANGE 0 TO 50;
    CONSTANT T : TIME := 50 ns;
    CONSTANT T2 : TIME := 6900 ns;
    CONSTANT max_clk : INTEGER := 200;
    SIGNAL i : INTEGER := 1;
    SiGNAL loop_counter : INTEGER := 0;
 
BEGIN
    uut : doorLock PORT MAP(
        CLK => CLK,
        Pintu_depan => Pintu_depan,
        Akses_depan => Akses_depan,
        Akses_belakang => Akses_belakang,
        Input_Pass => Input_Pass,
 
        Kunci_depan => Kunci_depan,
        Kunci_belakang => Kunci_belakang,
        Segment1 => Segment1,
        Segment2 => Segment2,
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
        constant Pintu_depan_stream : STD_LOGIC_VECTOR(0 TO 9) := ("1111111111");
        CONSTANT Akses_depan_stream : STD_LOGIC_VECTOR(0 TO 9) := ("1111100011");
        CONSTANT Akses_belakang_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000011100");
        CONSTANT LED_hijau_stream : STD_LOGIC_VECTOR(0 TO 9) := ("1101100011");
        CONSTANT LED_merah_stream : STD_LOGIC_VECTOR(0 TO 9) := ("0000001100");
    BEGIN
        FOR j IN 0 TO 9 LOOP
           
            loop_counter <= loop_counter + 1;
            Pintu_depan <= Pintu_depan_stream (j);
            Akses_depan <= Akses_depan_stream (j);
            Akses_belakang <= Akses_belakang_stream(j);
            if (j = 0) then
                WAIT for T2;
            else WAIT FOR 4*T;
            end if;
           
        END LOOP;
        WAIT;
    END PROCESS;
END behavioral;