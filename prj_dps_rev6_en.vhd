LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY prj_dps IS
GENERIC(ClockFrequencyHz : integer := 50);-- clock frequency
	PORT(
		 Clk     : IN STD_LOGIC;	-- clock signal
		 Seconds : INOUT INTEGER := 0;	-- variable for seconds
		 Minutes : INOUT INTEGER := 0;	-- variable for minutes
		 Hours   : INOUT INTEGER := 0;	-- variable for hours
		 -- 7 SEGMENT DISPLAY
		 seg1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for units of seconds
		 seg2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for tens of seconds
		 seg3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for units of minutes
		 seg4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for tens of minutes
		 seg5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for units of hours
		 seg6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	-- 7 Segment Display for tens of hours
		 -- LCD DISPLAY
		 lcd_rw	: OUT STD_LOGIC := '0'; -- control read/write
		 lcd_e : OUT STD_LOGIC; 
		 lcd_rs : OUT STD_LOGIC; -- data or comand
       data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);	-- data line
       -- BUTTONS
       reset_button : INOUT STD_LOGIC := '0';  -- Button for reset
       button_out : INOUT STD_LOGIC;   -- stabilized state of the button
		 min_button : INOUT STD_LOGIC := '0'; -- button to increase the minutes
       button_out_min : INOUT STD_LOGIC;
       ore_button : INOUT STD_LOGIC := '0';	-- button to increase the hours
       button_out_ore : INOUT STD_LOGIC;
		 -- SWITCH
		 switch_sveglia : IN STD_LOGIC := '0';  -- switch to activate the function of digital alarm clock
		 cmd_sveglia : IN STD_LOGIC := '0';		 -- switch to activate the alarm
       -- LED
		 led : OUT STD_LOGIC := '0'
	 );
END ENTITY;
 
ARCHITECTURE rtl OF prj_dps IS

SIGNAL Ticks : INTEGER := 0; -- signal to count the clock periods
SIGNAL secondi7seg1 : INTEGER := 0;	-- signal to populate the 7 segments display with the value of the tens of seconds
SIGNAL secondi7seg : INTEGER := 0;	-- Signal to populate the 7 segments with the value of the units of the seconds
SIGNAL minuti7seg1 : INTEGER := 0;	-- Signal to populate the 7 segments with the value of the tens of minutes
SIGNAL minuti7seg : INTEGER := 0;	-- Signal to populate the 7 segments with the value of the units of minutes
SIGNAL ore7seg : INTEGER := 0;	-- Signal to populate the 7 segments with the value of the units of hours
SIGNAL ore7seg1 : INTEGER := 0;	-- Signal to populate the 7 segments with the value of the tens of hours

-- Variables for the display
CONSTANT N: INTEGER := 37;	-- array to hold the data to be passed to the LCD commands and data
CONSTANT MAX_COUNT : INTEGER := 20; -- Time to check the button press (debounce of the button)
TYPE arr IS ARRAY (1 TO N) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
-- up to X "38", X "0c", X "06", X "01", X "C0" are all LCD controls
CONSTANT datas : arr := (X"38", X"0C", X"06", X"01", X"C0", X"42", X"45", X"4E", X"56", X"45", X"4E", X"55", X"54", X"4F", X"20", X"49", X"4E", X"20", X"44", X"49", X"47", X"49", X"54", X"41", X"4C", X"20", X"41", X"4C", X"41", X"52", X"4D", X"20", X"43", X"4C", X"4F", X"43", X"4B");

-- Function for printing on 7 segments
FUNCTION stampa(numero : INTEGER) RETURN STD_LOGIC_VECTOR IS
VARIABLE seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
    CASE(numero) IS
        WHEN 0 => seg := "0111111";
        WHEN 1 => seg := "0000110";
        WHEN 2 => seg := "1011011";
        WHEN 3 => seg := "1001111";
        WHEN 4 => seg := "1100110";
        WHEN 5 => seg := "1101101";
        WHEN 6 => seg := "1111101";
        WHEN 7 => seg := "0000111";
        WHEN 8 => seg := "1111111";
        WHEN 9 => seg := "1101111";
        WHEN OTHERS => seg := "1000000";	
    END CASE;
RETURN seg;
END stampa;

BEGIN
	PROCESS(Clk) IS
	
	VARIABLE j : INTEGER := 1;	-- variables for printing on LCD
   VARIABLE i : INTEGER := 0;	-- variables for printing on LCD
   VARIABLE count : INTEGER := 0;
   VARIABLE count_min : INTEGER := 0;
   VARIABLE count_ore : INTEGER := 0;
   VARIABLE timer_min : INTEGER := 0;
   VARIABLE timer_min_d : INTEGER := 0;
   VARIABLE timer_min_u : INTEGER := 0;
   VARIABLE timer_ore : INTEGER := 0;
   VARIABLE timer_ore_d : INTEGER := 0;
   VARIABLE timer_ore_u : INTEGER := 0;

	BEGIN
		IF rising_edge(Clk) THEN
			IF(reset_button = '1') THEN --  verify that the reset button has been pressed
				IF(count < MAX_COUNT) THEN	--If the button has been pressed,  check that it remains active for 20 edges
					count := count + 1;	-- increase the relative counter
            ELSIF(count = MAX_COUNT) THEN	-- if it reaches the maximum value
               button_out <= '1'; -- set the high state of the button
            END IF;
            -- If the button has been pressed, it resets all the variables
            IF(button_out = '1') THEN
				  Ticks   <= 0;
				  Seconds <= 0;
				  Minutes <= 0;
				  Hours   <= 0;
				  secondi7seg1 <= 0;
				  secondi7seg <= 0;
				  minuti7seg1 <= 0;
				  minuti7seg <= 0;
				  ore7seg <= 0;
				  ore7seg1 <= 0;
				  timer_min := 0;
				  timer_min_d := 0;
				  timer_min_u := 0;
				  timer_ore := 0;
				  timer_ore_d := 0;
				  timer_ore_u :=0;
				  count := 0;
				  count_min := 0;
				  count_ore := 0;
				  seg1 <= stampa(10); -- in this way it prints the dash (-)
				  seg2 <= stampa(10);
				  seg3 <= stampa(10);
				  seg4 <= stampa(10);
				  seg5 <= stampa(10);
				  seg6 <= stampa(10);
			   END IF;
          ELSIF(reset_button = '0') THEN -- If the button is other than high
				IF(count > 0) THEN	
					count := 0;	-- resets the counter and the button state if it has been active for a period not sufficient to signal the key pressed
					button_out <= '0';	
				END IF;
          END IF;
          IF(switch_sveglia = '1') THEN
				IF(min_button = '1') THEN -- Check that the key has been pressed to set the minutes
					IF(count_min < MAX_COUNT) THEN	-- If the key has been pressed, check that it remains active
						count_min := count_min + 1;	-- Increase the relative counter
               ELSIF(count_min = MAX_COUNT) THEN	-- If it reaches the maximum value
						button_out_min <= '1'; -- Set the high state of the button
               END IF;
               IF(button_out_min = '1') THEN
						IF timer_min = 59 THEN	-- If it exceeds 59 minutes, print 00 on the 7th seg
						    timer_min := 0;
							 seg2 <= stampa(0);
							 seg1 <= stampa(0);
						ELSE
						    timer_min := timer_min + 1;	-- Otherwise increase the timer
                      timer_min_u := timer_min - ((timer_min / 10)*10);	-- Unit of minutes
                      timer_min_d := timer_min / 10;	-- To get the decimals
                      seg2 <= stampa(timer_min_d);	-- Print the decimals
                      seg1 <= stampa(timer_min_u);	-- Print the unit
						END IF;
					 ELSIF(min_button = '0') THEN -- If the button is other than high
						 IF(count_min > 0) THEN	
							 count_min := 0;	-- Reset the counter and button state if it was active For a period not sufficient to signal the key pressed
							 button_out_min <= '0';	
						 END IF;
					 END IF;
					 -- Reset seconds, minutes and hours to start with the alarm
					 Ticks   <= 0;
					 Seconds <= 0;
				    Minutes <= 0;
				    Hours   <= 0; 
				END IF;
				IF(ore_button = '1') THEN -- Check that the hour increase button has been pressed
					IF(count_ore < MAX_COUNT) THEN	-- If the key has been pressed, check that it remains active
						count_ore := count_ore + 1;	-- Increase the relative counter
					ELSIF(count_ore = MAX_COUNT) THEN	-- If It gets to the maximum value
						button_out_ore <= '1';	-- Set the high state of the button.
               END IF;
               IF(button_out_ore = '1') THEN
						IF timer_ore = 23 THEN	-- If it exceeds 23 hours I print 00 on the 7th seg
							timer_ore := 0;
							seg2 <= stampa(0);
							seg1 <= stampa(0);	
						ELSE
							timer_ore := timer_ore + 1;	-- Otherwise increase
                     timer_ore_u := timer_ore - ((timer_ore / 10)*10);	-- Unit of minutes
                     timer_ore_d := timer_ore / 10;	-- To get the decimals
                     seg2 <= stampa(timer_ore_d);	-- prints the decimals
                     seg1 <= stampa(timer_ore_u);	-- prints the unit
						END IF;
					 ELSIF(ore_button = '0') THEN -- If the button is other than high
						IF(count_ore > 0) THEN	
							count_ore := 0;	-- Reset the counter and button state if it was active For a period not sufficient to signal the key pressed
							button_out_ore <= '0';	
						END IF;
					 END IF;
					 -- Reset seconds, minutes and hours to start with the alarm
					 Ticks   <= 0;
					 Seconds <= 0;
					 Minutes <= 0;
					 Hours   <= 0;
				 END IF;
				END IF;
				-- Count the number of clock periods, if it exceeds 50 periods, increase the seconds by one, 
				-- If it exceeds 49, it increases the seconds by one, if it exceeds 59 minutes it increases the hours by 1
				IF Ticks = ClockFrequencyHz - 1 THEN
					Ticks <= 0;
					-- 
					IF Seconds = 59 THEN
						Seconds <= 0;
						-- 
						IF Minutes = 59 THEN
							Minutes <= 0;
							IF Hours = 23 THEN
								Hours <= 0;
							ELSE
								-- Increase hours and print on 7 segments
								Hours <= Hours + 1;
								ore7seg <= Hours - ((Hours / 10)*10);
								ore7seg1 <= Hours / 10;
								seg6 <= stampa(ore7seg1);
								seg5 <= stampa(ore7seg);
							END IF;
						 ELSE
							-- increase the minutes and print on the 7 segments
							Minutes <= Minutes + 1;
							minuti7seg <= Minutes - ((Minutes / 10)*10);	
							minuti7seg1 <= Minutes / 10;	
							seg4 <= stampa(minuti7seg1);
							seg3 <= stampa(minuti7seg);
						END IF;
					ELSE
						-- Increase seconds and print on 7 segments
						Seconds <= Seconds + 1;
						secondi7seg <= Seconds - ((Seconds / 10)*10);	
						secondi7seg1 <= Seconds / 10;	
						seg2 <= stampa(secondi7seg1);
						seg1 <= stampa(secondi7seg);
					END IF;
				ELSE
					Ticks <= Ticks + 1;	-- Increase the count of clock periods if <49
				END IF;
				-- If the timer function is active, check that the set minutes and hours have not passed
				IF(cmd_sveglia = '1') THEN
					IF Minutes = timer_min AND Hours = timer_ore THEN
						led <= '1';	-- Turns on the LED if true
					ELSE
						led <= '0';
					END IF;
				END IF;
				-- Section for printing the welcome message on the LCD display
				IF i <= 10 THEN
					i := i + 1;
					lcd_e <= '1';
					data <= datas(j)(7 DOWNTO 0);
				ELSIF i > 10 and i < 20 then
					i := i + 1;
					lcd_e <= '0';
				ELSIF i = 20 then
					j := j + 1;
					i := 0;
				END IF;
				IF j <= 5 THEN
					lcd_rs <= '0';    -- LCD control signal
				ELSIF j > 5 THEN
					lcd_rs <= '1';   -- LCD data signal
				END IF;
				IF j = 25 THEN  -- Repetition of the message 
					j := 5;
				END IF;
			END IF;
	END PROCESS;
END ARCHITECTURE;