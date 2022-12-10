<<<<<<< HEAD
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Entity
ENTITY doorLock IS
    PORT (
        -- Input
        CLK : IN STD_LOGIC;
        Akses_kartu, Pintu_belakang : IN STD_LOGIC;
        Input_Pass : IN INTEGER;
        Pass : INOUT INTEGER := 12345678; --password default 12345678

        -- Uang_A, Uang_B : IN STD_LOGIC; (GAPAKE)

        -- Output
        Pintu : OUT STD_LOGIC;
        Segment1, Segment2 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
        Counter : INOUT INTEGER RANGE 0 TO 50;
        LED_hijau, LED_merah : OUT STD_LOGIC
    );
END doorLock;

-- Architecture
ARCHITECTURE behavioral OF doorLock IS
    TYPE states IS (IDLE, WAIT_OPEN, OPEN_LOCK, NO_ACCESS, OFFICE, LIMIT, S0, S1, S2, QUIT, CHANGE_PASS);
    SIGNAL CS, NS : states;
    SIGNAL X, Y : INTEGER RANGE 0 TO 50;
BEGIN
    sync_proc : PROCESS (CLK, NS)
    BEGIN
        IF (rising_edge(CLK)) THEN
            CS <= NS;
        END IF;
    END PROCESS;

    comb_proc : PROCESS (CS, Akses_kartu, Pintu_belakang)
        VARIABLE cnt : INTEGER RANGE 0 TO 150; --cnt = jumlah pegawai kantor??
    BEGIN
        CASE CS IS
            WHEN IDLE => -- terus looping jika tidak ada yang masuk/keluar office 
                IF (Akses_kartu = '1' AND Pintu_belakang = '0') THEN
                    IF (cnt = 150) THEN
                        Pintu <= '0';
                        LED_hijau <= '0';
                        LED_merah <= '1';
                        NS <= LIMIT;
                    ELSE
                        NS <= WAIT_OPEN;
                    END IF;
                ELSIF (Pintu_belakang = '1' AND Akses_kartu = '0') THEN
                    IF (cnt = 0) THEN
                        NS <= IDLE;
                    ELSE
                        NS <= QUIT;
                    END IF;
                ELSE
                    NS <= IDLE;
                END IF;

            WHEN WAIT_OPEN => -- mengecek kode akses kartu benar/tidak
                IF (Input_Pass = Pass) THEN
                    Pintu <= '1';
                    LED_hijau <= '1';
                    LED_merah <= '0';
                    NS <= OPEN_LOCK;
                ELSIF (Input_Pass = 00000000) THEN --000000000 master key buat ganti kode
                    NS <= CHANGE_PASS;
        
                ELSE
                    NS <= NO_ACCESS;
                END if;

            WHEN CHANGE_PASS => -- mengganti input password menjadi password yang baru
                Pass <= Input_Pass;
                NS <= IDLE;

            WHEN NO_ACCESS => -- kode salah, pintu tdk dibuka, led merah
                        Pintu <= '0';
                        LED_hijau <= '0';
                        LED_merah <= '1';
                        NS <= IDLE;
                
            WHEN OPEN_LOCK => -- pintu dibuka
                Pintu <= '1';
                LED_hijau <= '1';
                LED_merah <= '0';
                cnt := cnt + 1;
                NS <= OFFICE;

            WHEN OFFICE => -- sdh masuk di office
                Pintu <= '0';
                LED_merah <= '0';
                LED_hijau <= '0';
                IF (Pintu_belakang = '1') THEN
                    NS <= QUIT;
                ELSE
                    NS <= IDLE;
                END IF;

            WHEN QUIT => -- keluar dari office (tdk perlu akses kartu)
                LED_merah <= '0';
                LED_hijau <= '1';
                Pintu <= '1';
                cnt := cnt - 1;
                IF (Pintu_belakang = '1') THEN
                    IF (cnt = 0) THEN
                        NS <= IDLE;
                    ELSE
                        NS <= QUIT;
                    END IF;
                ELSE
                    NS <= IDLE;
                END IF;

            WHEN LIMIT => -- limit pegawai kantor dlm 1 ruangan? (perlu/gak?)
                LED_merah <= '1';
                LED_hijau <= '0';
                Pintu <= '0';
                NS <= IDLE;
            WHEN OTHERS =>
                NS <= IDLE;

        END CASE;
        Counter <= cnt;
    END PROCESS;

    -- menghitung jumlah pegawai kantor yang masuk ke office room
    Y <= Counter / 10;
    X <= Counter MOD 10;

    WITH X SELECT
        Segment1 <= "0111111" WHEN 0,
        "0000110" WHEN 1,
        "1011011" WHEN 2,
        "1001111" WHEN 3,
        "1100110" WHEN 4,
        "1101101" WHEN 5,
        "1111101" WHEN 6,
        "0000111" WHEN 7,
        "1111111" WHEN 8,
        "1101111" WHEN 9,
        "0000000" WHEN OTHERS;
    WITH Y SELECT
        Segment2 <= "0111111" WHEN 0,
        "0000110" WHEN 1,
        "1011011" WHEN 2,
        "1001111" WHEN 3,
        "1100110" WHEN 4,
        "1101101" WHEN 5,
        "1111101" WHEN 6,
        "0000111" WHEN 7,
        "1111111" WHEN 8,
        "1101111" WHEN 9,
        "0000000" WHEN OTHERS;
=======
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


-- Entity
ENTITY doorLock IS
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
END doorLock;

-- Architecture
ARCHITECTURE behavioral OF doorLock IS

    component timer_count is
        generic(
            Second : integer := 5
        );
        port(
            Clk     : in std_logic;
            START : in std_logic;
            DONE : out std_logic
        );
    end component;

    component md5_hash is
        Port ( 
            data_in:     in  STD_LOGIC_VECTOR (31 downto 0);
            data_out:    out STD_LOGIC_VECTOR (127 downto 0) := (others => '0');
            hash_done:   out STD_LOGIC;
            hash_start:  in  STD_LOGIC;
            clk:         in  STD_LOGIC;
            reset:       in  STD_LOGIC
        );
    end component;

    TYPE states IS (IDLE, WAIT_OPEN, OPEN_LOCK, NO_ACCESS, LIMIT, QUIT, TIMER);
    SIGNAL CS, NS : states;
    SIGNAL X, Y : std_logic_vector(7 downto 0) := X"00";
    SIGNAL CNT : std_logic_vector(3 downto 0) := x"0";
    SIGNAL Counter : std_logic_vector(7 downto 0) := x"00";
    SIGNAL START, DONE : std_logic := '0';

    SIGNAL data_in: STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
    SIGNAL data_out: STD_LOGIC_VECTOR (127 downto 0) := (others => '0');
    SIGNAL hash_start, reset: STD_LOGIC := '0';

    constant Pass : std_logic_vector(127 downto 0) := x"403AD5A2515657485E4C3AD825814D34";
    
BEGIN

    timer_proc: timer_count 
        generic map (
            Second => 5
        )
        port map(   
            CLK => CLK,
            START => START,
            DONE => DONE
        );

    hash_proc : md5_hash
        port map(   
            data_in => data_in,
            data_out => data_out,
            hash_start => hash_start,
            CLK => CLK,
            reset => reset
        );

    sync_proc : PROCESS (CLK, NS)
    BEGIN
        IF (rising_edge(CLK)) THEN
            CS <= NS;
        END IF;
    END PROCESS;

    comb_proc : PROCESS (CS, Akses_depan, Akses_belakang, CNT, Pintu_depan, DONE, START, data_out)
    BEGIN
        CASE CS IS
            WHEN IDLE => -- terus looping jika tidak ada yang masuk/keluar office 
                hash_start <= '0';
                START <= '0';

                Kunci_depan <= '0';
                Kunci_belakang <= '0';

                LED_hijau <= '0';
                LED_merah <= '0';
                IF (Akses_depan = '1' AND Akses_belakang = '0') THEN
                    data_in <= Input_Pass;
                    hash_start <= '1';
                    IF (Counter = "00110010") THEN
                        NS <= LIMIT;
                    ELSE
                        NS <= WAIT_OPEN;
                    END IF;
                ELSIF (Akses_belakang = '1' AND Akses_depan = '0') THEN
                    Counter <= std_logic_vector(unsigned(Counter) - to_unsigned(1, Counter'length));
                    NS <= QUIT;
                ELSE
                    NS <= IDLE;
                END IF;

            WHEN WAIT_OPEN => -- mengecek kode akses kartu benar/tidak
                if (NOT(data_out = x"00000000000000000000000000000000")) then
                    IF (data_out = Pass) THEN
                        Counter <= std_logic_vector(unsigned(Counter) + to_unsigned(1, Counter'length));
                        NS <= OPEN_LOCK;
                    ELSE
                        NS <= NO_ACCESS;
                    END if;
                else
                    NS <= WAIT_OPEN;
                end if;

            WHEN NO_ACCESS => -- kode salah, pintu tidak dibuka, led merah
                Kunci_depan <= '0';
                LED_hijau <= '0';
                LED_merah <= '1';
                NS <= IDLE;
                
            WHEN OPEN_LOCK => -- pintu dibuka
                X <= std_logic_vector(unsigned(Counter) / 10);
                Y <= std_logic_vector(unsigned(Counter) mod 10);
                Kunci_depan <= '1';
                LED_hijau <= '1';
                START <= '1';
                reset <= '1';
                NS <= TIMER;

            WHEN TIMER =>
                reset <= '0';
                if (DONE = '1' OR Pintu_depan = '1') then
                    NS <= IDLE;
                else 
                    NS <= TIMER;
                end if;

            WHEN LIMIT => -- limit pegawai kantor dalam 1 ruangan
                LED_merah <= '1';
                NS <= IDLE;

            WHEN QUIT => -- kondisi keluar ruangan tanpa akses kartu (otomatis terbuka)
                X <= std_logic_vector(unsigned(Counter) / 10);
                Y <= std_logic_vector(unsigned(Counter) mod 10);
                Kunci_belakang <= '1';
                NS <= IDLE;

            WHEN OTHERS =>
                NS <= IDLE;
        END CASE;
    END PROCESS;

    -- menghitung jumlah pegawai kantor yang masuk ke office room
    WITH X SELECT
        Segment1 <= "0111111" WHEN "00000000",
        "0000110" WHEN "00000001",
        "1011011" WHEN "00000010",
        "1001111" WHEN "00000011",
        "1100110" WHEN "00000100",
        "1101101" WHEN "00000101",
        "1111101" WHEN "00000110",
        "0000111" WHEN "00000111",
        "1111111" WHEN "00001000",
        "1101111" WHEN "00001001",
        "0000000" WHEN OTHERS;
    WITH Y SELECT
        Segment2 <= "0111111" WHEN "00000000",
        "0000110" WHEN "00000001",
        "1011011" WHEN "00000010",
        "1001111" WHEN "00000011",
        "1100110" WHEN "00000100",
        "1101101" WHEN "00000101",
        "1111101" WHEN "00000110",
        "0000111" WHEN "00000111",
        "1111111" WHEN "00001000",
        "1101111" WHEN "00001001",
        "0000000" WHEN OTHERS;
>>>>>>> 34eb69a (Update Proyek)
END behavioral;