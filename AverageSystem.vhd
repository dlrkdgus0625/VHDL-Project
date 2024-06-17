library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity stopwatch is
    GENERIC (
        clock_freq : INTEGER := 100000000
    );
    Port (
        Led : out STD_LOGIC_VECTOR (3 downto 0);
        sw : in STD_LOGIC_VECTOR (7 downto 0);
        an : out STD_LOGIC_VECTOR (3 downto 0) := "0000";
        seg : out STD_LOGIC_VECTOR (7 downto 0);
        btn : IN STD_LOGIC_VECTOR (3 downto 0);
        clk : in STD_LOGIC
    );
end stopwatch;

ARCHITECTURE Behavioral OF stopwatch IS
    -- Global Signals
    SIGNAL millis : INTEGER := 0;
    SIGNAL t_millis : INTEGER := 0;
    SIGNAL h_millis : INTEGER := 0;
    SIGNAL secs : INTEGER := 0;
    SIGNAL t_secs : INTEGER := 0;
    SIGNAL ssd_millis: STD_LOGIC_VECTOR (7 DOWNTO 0) := "11111111";
    SIGNAL ssd_t_millis: STD_LOGIC_VECTOR (7 DOWNTO 0) := "11111111";
    SIGNAL ssd_h_millis: STD_LOGIC_VECTOR (7 DOWNTO 0) := "11111111";
    SIGNAL ssd_secs: STD_LOGIC_VECTOR (7 DOWNTO 0) := "11111111";
    SIGNAL led_t_secs: STD_LOGIC_VECTOR (3 DOWNTO 0) := "0000";
    SIGNAL m_clk: STD_LOGIC := '0';
    SIGNAL millis_divisor : INTEGER := clock_freq/1000;
    SIGNAL clk_counter :INTEGER := 0;
    SIGNAL counter : INTEGER := 0;
    SIGNAL en : STD_LOGIC := '1';
    SIGNAL stop : STD_LOGIC := '0';
    SIGNAL start : STD_LOGIC := '0';
    SIGNAL avg : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL incstate : INTEGER := 0;

    -- RTM Signals
    SIGNAL react_led_on : BOOLEAN := FALSE;
    SIGNAL react_start_time : INTEGER := 0;
    SIGNAL react_time : INTEGER := 0;
    SIGNAL react_display_time : INTEGER := 0;

    -- Average Reaction Time
    SIGNAL react_time_1 : INTEGER := 0;
    SIGNAL react_time_2 : INTEGER := 0;
    SIGNAL react_time_3 : INTEGER := 0;
    SIGNAL avg_react_time : INTEGER := 0;
    SIGNAL avg_t : INTEGER := 0;
    SIGNAL avg_h : INTEGER := 0;
    SIGNAL avg_m : INTEGER := 0;
    SIGNAL avg_s : INTEGER := 0;
    SIGNAL avg_sample : INTEGER := 0;
    
    SIGNAL show_average : STD_LOGIC := '0';
    

    -- New Signals for Average Calculation
    SIGNAL avg_react_sum : INTEGER := 0;
    SIGNAL avg_react_count : INTEGER := 0;

    -- Function to Convert Integer to 7-Segment Display Code
    FUNCTION convert_to_7seg(value : INTEGER) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result : STD_LOGIC_VECTOR(7 DOWNTO 0);
    BEGIN
        CASE value IS
    WHEN 0 =>
        result := "11000000";
    WHEN 1 =>
        result := "11111001";
    WHEN 2 =>
        result := "10100100";
    WHEN 3 =>
        result := "10110000";
    WHEN 4 =>
        result := "10011001";
    WHEN 5 =>
        result := "10010010";
    WHEN 6 =>
        result := "10000010";
    WHEN 7 =>
        result := "11111000";
    WHEN 8 =>
        result := "10000000";
    WHEN 9 =>
        result := "10010000";
    WHEN OTHERS =>
        result := "11111111"; -- Display all segments if value is out of range
END CASE;


        RETURN result;
    END convert_to_7seg;

BEGIN
    -- Clock Divider
    PROCESS (clk)
    BEGIN
        IF (clk'EVENT and clk = '1') THEN
            IF (clk_counter = millis_divisor) THEN
                clk_counter <= 0;
                m_clk <= '1';
            ELSE
                clk_counter <= clk_counter + 1;
                m_clk <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- Counters
    PROCESS (m_clk, en, rst)
    BEGIN
        IF (rst = '1') THEN
            millis <= 0;
            t_millis <= 0;
            h_millis <= 0;
            secs <= 0;
            t_secs <= 0;
        ELSIF(m_clk'EVENT and m_clk = '1') THEN
            IF (en = '1') THEN
                millis <= millis + 1;
                IF (millis = 9) THEN 
                    millis <= 0;
                    t_millis <= t_millis + 1;
                    IF (t_millis = 9) THEN
                        t_millis <= 0;
                        h_millis <= h_millis + 1;
                        IF (h_millis = 9) THEN
                            secs <= secs + 1;
                            h_millis <= 0;
                            IF (secs = 9) THEN
                                t_secs <= t_secs + 1;
                                secs <= 0;
                                IF (t_secs = 15) THEN
                                    t_secs <= 0; -- Max count reached, reset t_secs
                                END IF;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            ELSIF (avg = '1') THEN
                -- Display average when show_average is active
              --  avg_react_sum <= avg_react_sum + react_time;
            avg_react_count <= avg_react_count + 1;
            avg_react_sum <= avg_react_sum + millis + (t_millis * 10) + (h_millis *100) + (secs * 1000);
            avg_react_time <= avg_react_sum / avg_react_count;
            
            avg_sample <= avg_react_time;
            avg_m <= avg_sample mod 10;
            
             
            avg_t <= (avg_sample/10)mod 10;
            avg_h <= (avg_sample/100)mod 10;
            avg_s <= (avg_sample/1000)mod 10;
            
            millis <= avg_m;
            
            t_millis <= avg_t;
            h_millis <= avg_h;
            t_secs <= avg_s;
            
                -- Convert avg_react_time to 7-segment display code and update an and seg accordingly
                --an <= "1111";
                --seg <= convert_to_7seg(avg_react_time);
            END IF;
        END IF;
    END PROCESS;

    -- Decoders
    WITH millis SELECT
        ssd_millis <=
            "11000000" when 0,
            "11111001" when 1,
            "10100100" when 2,
            "10110000" when 3,
            "10011001" when 4,
            "10010010" when 5,
            "10000010" when 6,
            "11111000" when 7,
            "10000000" when 8,
            "10010000" when 9,
            "10000110" WHEN OTHERS;
    WITH t_millis SELECT
        ssd_t_millis <=
            "11000000" when 0,
            "11111001" when 1,
            "10100100" when 2,
            "10110000" when 3,
            "10011001" when 4,
            "10010010" when 5,
            "10000010" when 6,
            "11111000" when 7,
            "10000000" when 8,
            "10010000" when 9,
            "10000110" WHEN OTHERS;

    WITH h_millis SELECT
        ssd_h_millis <=
            "11000000" when 0,
            "11111001" when 1,
            "10100100" when 2,
            "10110000" when 3,
            "10011001" when 4,
            "10010010" when 5,
            "10000010" when 6,
            "11111000" when 7,
            "10000000" when 8,
            "10010000" when 9,
            "10000110" WHEN OTHERS;

    WITH secs SELECT
        ssd_secs <=
            "11000000" when 0,
            "11111001" when 1,
            "10100100" when 2,
            "10110000" when 3,
            "10011001" when 4,
            "10010010" when 5,
            "10000010" when 6,
            "11111000" when 7,
            "10000000" when 8,
            "10010000" when 9,
            "10000110" WHEN OTHERS;

    WITH t_secs SELECT
        led_t_secs <=
            "0000" when 0,
            "0001" when 1,
            "0010" when 2,
            "0011" when 3,
            "0100" when 4,
            "0101" when 5,
            "0110" when 6,
            "0111" when 7,
            "1000" when 8,
            "1001" when 9,
            "1010" when 10,
            "1011" when 11,
            "1100" when 12,
            "1101" when 13,
            "1110" when 14,
            "1111" when 15,
            "1111" WHEN OTHERS;
            
-- 7-Segment Display Driver
PROCESS(clk)
BEGIN
    an <= "1111";

    IF (clk'EVENT AND clk = '1') THEN
        counter <= counter + 1;

        CASE counter IS
            WHEN 150 TO 199 =>
                --seg <= "1111" & "0" & ssd_secs(6 DOWNTO 4);
                seg <= ssd_secs AND "01111111";
                an <= "0111";
            WHEN 250 TO 299 =>
                --seg <= (others => '0');
                seg <= ssd_h_millis;
                an <= "1011";
            WHEN 350 TO 399 =>
                --seg <= "1111" & ssd_secs(3 DOWNTO 0);
                seg <= ssd_t_millis;
                an <= "1101";
            WHEN 450 TO 499 =>
                --seg <= (others => '0');
                seg <= ssd_millis;
                an <= "1110";
            WHEN 500 =>
                counter <= 1;
            WHEN OTHERS =>
                an <= "1111";  -- Default value
                --seg <= (others => '0');
                seg <= "11111111";
        END CASE;
    --END IF;
    
     -- Add RTM display logic
        IF (react_led_on = TRUE) THEN
            CASE counter IS
                WHEN 150 TO 199 =>
                    --seg <= "1111" & ssd_secs(6 DOWNTO 4); -- Adjust the width
                    seg <= "1111" & "0" & ssd_secs(6 DOWNTO 4);
                    an <= "0111";
                WHEN 200 TO 249 =>
                    -- Additional case for values from 200 to 249
                    seg <= (others => '0');  -- You can modify this line based on your requirements
                    an <= "0111";
                WHEN 250 TO 299 =>
                    seg <= "1111" & ssd_secs(3 DOWNTO 0); -- Adjust the width
                    an <= "1011";
                WHEN 300 TO 349 =>
                    -- Additional case for values from 300 to 349
                    seg <= (others => '0');  -- You can modify this line based on your requirements
                    an <= "1011";
                WHEN 350 TO 399 =>
                    seg <= ssd_millis;
                    an <= "1101";
                WHEN 400 TO 449 =>
                    -- Additional case for values from 400 to 449
                    seg <= (others => '0');  -- You can modify this line based on your requirements
                    an <= "1101";
                WHEN 450 TO 499 =>
                    --seg <= "1" & (others => '0'); -- Adjust the width
                    seg <= (others => '0');
                    seg(seg'LEFT) <= '1';
                    an <= "1110";
                WHEN OTHERS =>
                    null;  -- No action for other values in the RTM case statement
            END CASE;
        END IF;
        END IF;
END PROCESS;

-- Input Logic
PROCESS (clk)
BEGIN
    IF (clk'EVENT AND clk = '1') THEN
        IF (start = '1' AND stop = '0') THEN
            en <= '1';
            react_led_on <= TRUE;  -- Turn on react LED and start RTM
            react_start_time <= react_time;
        ElSIF (stop = '1' AND start = '0') THEN
            en <= '0';
            react_led_on <= FALSE;  -- Turn off react LED and stop RTM
            react_display_time <= react_time;
        ELSE
            en <= en;
        END IF;

        -- Toggle show_average on btn(2) press
        --IF (btn(2) = '1' AND show_average = '0') THEN
        --    show_average <= '1';
        --    react_display_time <= avg_react_time;
        --ELSIF (btn(2) = '0' AND show_average = '1') THEN
        --    show_average <= '0';
        --END IF;
    END IF;
END PROCESS;


    -- Combinational Logic
    Led <= led_t_secs;
    start <= btn(0);
    stop <= btn(1);
    avg <= btn(2);
    
    rst <= btn(3);

END Behavioral;
