LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY prj_dps IS
GENERIC(ClockFrequencyHz : integer := 50);-- frequenza di clock della scheda 
	PORT(
		Clk     : IN STD_LOGIC;	-- Segnale di clock
		Seconds : INOUT INTEGER := 0;	-- Variabile per i secondi
		Minutes : INOUT INTEGER := 0;	-- Varibiale per i minuti
		Hours   : INOUT INTEGER := 0;	-- Variabile per le ore
		-- Disply 7 segmenti
		seg1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le unità dei secondi
		seg2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le decine dei secondi
		seg3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le unità dei minuti
		seg4 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le decine dei minuti
		seg5 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le unità delle ore
		seg6 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);	--display 7 segmenti per le decine delle ore
		-- Disply lcd
		lcd_rw	: OUT STD_LOGIC := '0'; -- controllo read/write
		lcd_e : OUT STD_LOGIC; --abilita il controllo?
		lcd_rs : OUT STD_LOGIC; -- dati o comandi
		data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);	--linea dati 
		-- Bottoni
		reset_button : INOUT STD_LOGIC := '0';  -- Bottone per reset
		button_out : INOUT STD_LOGIC;   -- Stato stabilizzato del pulsante
		min_button : INOUT STD_LOGIC := '0';
		button_out_min : INOUT STD_LOGIC;
		ore_button : INOUT STD_LOGIC := '0';
		button_out_ore : INOUT STD_LOGIC;
		-- Switch
		switch_sveglia : IN STD_LOGIC := '0';
		cmd_sveglia : IN STD_LOGIC := '0';
		-- LED
		led : OUT STD_LOGIC := '0'
	 );
END ENTITY;
 
ARCHITECTURE rtl OF prj_dps IS

SIGNAL Ticks : INTEGER := 0; -- Signale per contare i periodi di clock
SIGNAL secondi7seg1 : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle decine dei secondi 
SIGNAL secondi7seg : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle unità dei secondi
SIGNAL minuti7seg1 : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle decine dei minuti
SIGNAL minuti7seg : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle unità dei minuti
SIGNAL ore7seg : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle unità delle ore
SIGNAL ore7seg1 : INTEGER := 0;	-- Segnale per popolare il 7 segmenti con il valore delle decine delle ore

-- Variabili per il display
CONSTANT N: INTEGER := 37;	-- array per contenere i dati da passare all'LCD comandi e data
CONSTANT MAX_COUNT : INTEGER := 20; -- Tempo per verificare la pressione del pulsante 
TYPE arr IS ARRAY (1 TO N) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
-- fino a X"38",X"0c",X"06",X"01",X"C0" sono tutti comandi LCD
-- stampo il messaggio: Benvenuto in prj_dps
CONSTANT datas : arr := (X"38", X"0C", X"06", X"01", X"C0", X"42", X"45", X"4E", X"56", X"45", X"4E", X"55", X"54", X"4F", X"20", X"49", X"4E", X"20", X"44", X"49", X"47", X"49", X"54", X"41", X"4C", X"20", X"41", X"4C", X"41", X"52", X"4D", X"20", X"43", X"4C", X"4F", X"43", X"4B");

-- Funzione per la stampa su 7 segmenti 
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
	
	VARIABLE j : INTEGER := 1;	-- variabili per la stampa su LCD
   	VARIABLE i : INTEGER := 0;	-- varibiali per la stampa su LCD
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
			IF(reset_button = '1') THEN -- Verifico che sia stato premuto il tasto di reset
				IF(count < MAX_COUNT) THEN	--Se il tasto e' stato premuto, verifico che rimanga attivo per 20 fronti
					count := count + 1;	--incremento il relativo contatore
            	ELSIF(count = MAX_COUNT) THEN	-- se arrivo al valore massimo
               		button_out <= '1'; -- setto lo stato alto del bottone
            	END IF;
            	-- Se il bottone e' stato premuto resetto tutte le variabili
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
					seg1 <= stampa(10); -- In questo modo stampa il  trattino
					seg2 <= stampa(10);
					seg3 <= stampa(10);
					seg4 <= stampa(10);
					seg5 <= stampa(10);
					seg6 <= stampa(10);
			   	END IF;
          	ELSIF(reset_button = '0') THEN -- Se il pulsante e' diverso da alto
				IF(count > 0) THEN	
					count := 0;	-- resetto il contattore e lo stato del pulsante se è stato attivo
					button_out <= '0';	-- per un periodo non sufficiente a segnalare tasto premuto
				END IF;
          END IF;
          IF(switch_sveglia = '1') THEN
				IF(min_button = '1') THEN -- Verifico che sia stato premuto il tasto per settare i minuti
					IF(count_min < MAX_COUNT) THEN	-- Se il tasto e' stato premuto, verifico che rimanga attivo
						count_min := count_min + 1;	-- Incremento il relativo contatore
               		ELSIF(count_min = MAX_COUNT) THEN	-- Se arrivo al valore massimo
						button_out_min <= '1'; -- Setto lo stato alto del bottone
               		END IF;
               		IF(button_out_min = '1') THEN
						IF timer_min = 59 THEN	-- Se supero i 59 minuti stampo 00 sul 7 seg
						    timer_min := 0;
							seg2 <= stampa(0);
							seg1 <= stampa(0);
						ELSE
						    timer_min := timer_min + 1;	-- Altrimenti incremento il timer
                      		timer_min_u := timer_min - ((timer_min / 10)*10);	-- Unita' dei minuti, utilizzo la funzione resto di vhdl
                      		timer_min_d := timer_min / 10;	-- Per ottenere i decimali
                      		seg2 <= stampa(timer_min_d);	-- Stampo le decine
                      		seg1 <= stampa(timer_min_u);	-- Stampo le unita'
						END IF;
					ELSIF(min_button = '0') THEN -- Se il pulsante e' diverso da alto
						IF(count_min > 0) THEN	
							count_min := 0;	-- Resetto il contattore e lo stato del pulsante se è stato attivo
							button_out_min <= '0';	-- Per un periodo non sufficiente a segnalare tasto premuto
						END IF;
					END IF;
					-- Resetto secondi, minuti e ore per partire con la sveglia
					Ticks   <= 0;
					Seconds <= 0;
				    Minutes <= 0;
				    Hours   <= 0; 
				END IF;
				IF(ore_button = '1') THEN -- Verifico che sia stato premuto il tasto di incremento delle ore
					IF(count_ore < MAX_COUNT) THEN	-- Se il tasto e' stato premuto, verifico che rimanga attivo
						count_ore := count_ore + 1;	-- Incremento il relativo contatore
					ELSIF(count_ore = MAX_COUNT) THEN	-- Se arrivo al valore massimo
						button_out_ore <= '1';	-- Setto lo stato alto del bottone
               		END IF;
					IF(button_out_ore = '1') THEN
						IF timer_ore = 23 THEN	-- Se supero le 23 ore stampo 00 sul 7 seg
							timer_ore := 0;
							seg2 <= stampa(0);
							seg1 <= stampa(0);	
						ELSE
							timer_ore := timer_ore + 1;	-- Altrimenti incremento
							timer_ore_u := timer_ore - ((timer_ore / 10)*10);	-- unita' dei minuti, utilizzo la funzione resto di vhdl
							timer_ore_d := timer_ore / 10;	-- per ottenere i decimale
							seg2 <= stampa(timer_ore_d);	-- Stampo le decine
							seg1 <= stampa(timer_ore_u);	-- Stampo le unita'
						END IF;
					ELSIF(ore_button = '0') THEN -- Se il pulsante e' diverso da alto
						IF(count_ore > 0) THEN	
							count_ore := 0;	-- Resetto il contattore e lo stato del pulsante se è stato attivo
							button_out_ore <= '0';	--Per un periodo non sufficiente a segnalare tasto premuto
						END IF;
					END IF;
						-- Resetto secondi, minuti e ore per partire con la sveglia
						Ticks   <= 0;
						Seconds <= 0;
						Minutes <= 0;
						Hours   <= 0;
					END IF;
				END IF;
				-- Contro il numero di periodi di clock, se supero i 50 periodi, incremento il secondo di uno, 
				-- Se ho superato 49 incrementi di uno i secondi, se supero 59 minuti incremento di 1 le ore
				IF Ticks = ClockFrequencyHz - 1 THEN
					Ticks <= 0;
					-- Vero ogni minuto
					IF Seconds = 59 THEN
						Seconds <= 0;
						-- Vero ogni ora
						IF Minutes = 59 THEN
							Minutes <= 0;
							IF Hours = 23 THEN
								Hours <= 0;
							ELSE
								-- Incremento le ore e stampo sul 7 segmenti
								Hours <= Hours + 1;
								ore7seg <= Hours - ((Hours / 10)*10);
								ore7seg1 <= Hours / 10;
								seg6 <= stampa(ore7seg1);
								seg5 <= stampa(ore7seg);
							END IF;
							ELSE
							-- Incremnto i minuti e stampo sul 7 segmenti
							Minutes <= Minutes + 1;
							minuti7seg <= Minutes - ((Minutes / 10)*10);	-- Unita' dei minuti, utilizzo la funzione resto di vhdl
							minuti7seg1 <= Minutes / 10;	-- Per ottenere i decimale
							seg4 <= stampa(minuti7seg1);
							seg3 <= stampa(minuti7seg);
						END IF;
					ELSE
						-- Incremento i secondi e stampo sul 7 segmenti
						Seconds <= Seconds + 1;
						secondi7seg <= Seconds - ((Seconds / 10)*10);	-- Sfrutto l'intero per ottenere i decimali
						secondi7seg1 <= Seconds / 10;	-- Ottengo le decine per la stampa su 7 seg
						seg2 <= stampa(secondi7seg1);
						seg1 <= stampa(secondi7seg);
					END IF;
				ELSE
					Ticks <= Ticks + 1;	-- Incremento il conteggio dei periodi di clock se < 49
				END IF;
				-- Se è attiva la funzione di timer verifico che non siano trascorsi i minuti e le ore impostate
				IF(cmd_sveglia = '1') THEN
					IF Minutes = timer_min AND Hours = timer_ore THEN
						led <= '1';	-- Accendo il LED se vero
					ELSE
						led <= '0';
					END IF;
				END IF;
				-- Sezione per stampare il messaggio di benvenuto sul display LCD
				-- Abilito il comando di stampa
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
					lcd_rs <= '0';    -- Segnale di comando LCD
				ELSIF j > 5 THEN
					lcd_rs <= '1';   -- Segnale di dati LCD
				END IF;
				IF j = 25 THEN  -- Ripetizione del messaggio 
					j := 5;
				END IF;
			END IF;
	END PROCESS;
END ARCHITECTURE;