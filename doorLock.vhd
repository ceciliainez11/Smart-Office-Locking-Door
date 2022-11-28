LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Entity
ENTITY doorLock IS
    GENERIC (freqdiv : integer := 30); --Periode Clock * freqdiv
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
END doorLock;

-- Architecture
ARCHITECTURE behavioral OF doorLock IS

    TYPE states IS (IDLE, WAIT_OPEN, OPEN_LOCK, NO_ACCESS, OFFICE, LIMIT, QUIT);

    SIGNAL timer : INTEGER := 0; --TH Timer Initial Value
    SIGNAL timer_c : INTEGER := 0; --TL Timer Counter
    SIGNAL timer_i : BOOLEAN := false; --TF Timer Flags
    SIGNAL timer_en : BOOLEAN := false; --TR Timer Enable
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
                IF (Akses_kartu(1 TO 8) = "12345678") THEN
                    Pintu <= '1';
                    LED_hijau <= '1';
                    LED_merah <= '0';
                    NS <= OPEN_LOCK;
                ELSE
                    NS <= NO_ACCESS;
                END IF;

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

    TIMERP : PROCESS (clk) -- timer jika 
    BEGIN
        IF (rising_edge(clk)) THEN
            IF (timer_en AND NOT timer_i) THEN
                timer_C <= timer_c + 1;
                IF (timer_c >= timer * freqdiv) THEN
                    timer_i <= true;
                END IF;
                IF (Pintu > 0) THEN
                    IF (timer_c MOD 20 >= Pintu) THEN
                        Pintu <= '0';
                    ELSE
                        Pintu <= '1';
                    END IF;
                END IF;
            ELSIF (timer_i AND Pintu > 0) THEN
                Pintu <= '0';
            END IF;
        END IF;
        IF (NOT timer_en) THEN
            timer_C <= 0;
            timer_i <= false;
            Pintu <= '0';
        END IF;
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
END behavioral;