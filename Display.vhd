--22h 30min (este documento + random + control + detector de secuencia + detector de pulsos)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.trabajo_pkg.ALL;

entity Display is

  Port (clk         : in std_logic;
        reset       : in std_logic;     --Botón de la placa
        start       : in std_logic;     --Solo al inicio, señal del botón (es un pulso o dura 1 seg)
        continue    : in std_logic;     --Se envía cada vez que se sube de nivel (es un pulso o dura 1 seg)
        random      : in std_logic_array;
        level       : in integer;       --Entrada range 1 to 8
        error       : in std_logic;     --Error en la secuencia
        win         : in std_logic;     --Se termina el juego y se vuelve a empezar
        selector    : out std_logic_vector(3 downto 0);
        segments    : out std_logic_vector(6 downto 0);
        led         : out std_logic_vector(7 downto 0);
        finish      : out std_logic);   --Cuando se termina de hacer la secuencia de nivel, es el continue del captador de pulsos
        
end Display;

architecture Behavioral of Display is

    constant count_max      : integer := 125*(10**3);  --Frecuencia de entrada del reloj 125MHz
    signal count            : integer range 0 to count_MAX-1;
    signal count_sec        : integer range 0 to 10;
    signal enable_count     : std_logic;
    signal enable_sec       : std_logic;
    signal enable_decSec    : std_logic;
    
    constant refresh_max    : integer := 200;  --Frecuencia de refresco de display de 200Hz
    signal refresh          : integer range 0 to refresh_MAX-1;
    signal enable_refresh   : std_logic;
    
    constant wait_max       : integer := 125*(10**3)*2/10;  --Frecuencia para tiempo de espera entre displays de 0.2 s
    signal espera           : integer range 0 to wait_MAX-1;
    signal enable_temp      : std_logic;
    signal reset_espera     : std_logic;
    signal reset_espera2     : std_logic;
    
    signal enable_sequence  : std_logic;
    signal aux_level        : integer range 0 to 8;
    signal aux_random       : std_logic_vector(2 downto 0);
    signal done             : std_logic;
    
    signal enable_all_display     : std_logic;
    
    signal aux_segments     : integer range 0 to 4;
    
    type State_t is (S_RESET, S_START, S_SEQUENCE, S_WAIT, S_FINAL);
    signal STATE : State_t;

begin

    --Refresh del display
    process(clk,reset)
    begin
        if (reset = '1' or STATE = S_WAIT) then
            refresh <= 0;
        elsif  (clk'event and clk = '1') then
            if (enable_count = '1') then
                if (refresh < refresh_MAX - 1) then
                    refresh <= refresh + 1;
                else
                    refresh <= 0;
                end if;
            end if;
        end if;
    end process;

    enable_refresh <= '1' when (refresh = refresh_MAX - 1) else '0';
    
    --Tiempo de espera entre cada muestra de display
    process(clk,reset)
    begin
        if (reset = '1' or done = '1' or reset_espera = '1' or reset_espera2 = '1') then
            espera <= 0;
        elsif  (clk'event and clk = '1') then
            if (enable_temp = '1') then
                if (espera < wait_MAX - 1) then
                    espera <= espera + 1;
                end if;
            end if;
        end if;
    end process;

    enable_count <= '1' when (espera = wait_MAX - 1) else '0';
    
    -- Cuenta de tiempo de mostrar un display
    process(clk,reset)
    begin
        if (reset = '1' or done = '1') then
            count <= 0;
        elsif  (clk'event and clk = '1') then
            if (enable_count = '1') then
                if (count < count_MAX - 1) then
                    count <= count + 1;
                else
                    count <= 0;
                end if;
            end if;
        end if;
    end process;

    enable_sec <= '1' when (count = count_MAX - 1) else '0';
    
    process (clk,reset)
    begin
        if (reset = '1' or done = '1') then
            count_sec <= 0;
        elsif  (clk'event and clk = '1') then
            if (enable_sec = '1') then
                if (count_sec < 9) then
                        count_sec <= count_sec + 1;
                else
                    count_sec <= 0;
                end if;
            end if;
        end if;
    end process;

    enable_decSec <= '1' when (count_sec = 9 and enable_sec = '1') else '0';
    
    process(clk, reset)
    begin
        if(reset = '1') then
            aux_random <= (others => '0');
            aux_level <= 0;
            done <= '0';
            reset_espera <= '0';
        elsif(clk'event and clk = '1') then
            if(enable_all_display = '1') then
                aux_random <= "011";
            elsif (enable_sequence = '0') then
                aux_random <= (others => '0');
            end if;
            if(enable_sequence = '1') then
                reset_espera <= '0';
                if(aux_level < level) then
                    aux_random <= "000";
                    if (enable_count = '1') then
                        aux_random(2) <= '1';
                        aux_random(1 downto 0) <= random(aux_level);
                        if (enable_sec = '1') then
                            aux_level <= aux_level + 1;
                            reset_espera <= '1';
                        end if;
                    end if;
                else
                    aux_level <= 0;
                    reset_espera <= '0';
                    aux_random <= (others => '0');
                    done <= '1';
                end if;
            else
                done <= '0';
            end if;
        end if;
    end process;
    
    with aux_random select
        selector <= "0000" when "000",   --Todos los displays apagado
                    "0001" when "100",   --Display más derecha encendido
                    "0010" when "101",   --Display 2do derecha encendido
                    "0100" when "110",   --Display 3ro derecha encendido
                    "1000" when "111",   --Display 4to derecha encendido
                    "1111" when others;   --Todos los displays encendidos
    
    process(clk,reset)
    begin
        if (reset = '1') then
            STATE <= S_RESET;
            reset_espera2 <= '0';
        elsif (clk'event and clk = '1') then
            case STATE is
                when S_RESET =>
                    aux_segments <= 0;
                    reset_espera2 <= '0';
                    if (start = '1')then
                        STATE <= S_START;
                    end if;
                when S_START =>
                    if (enable_refresh /= '1') then
                        aux_segments <= 2;
                    else
                        aux_segments <= 0;
                    end if;
                    if (enable_decSec = '1')then
                        reset_espera2 <= '1';
                        STATE <= S_SEQUENCE;
                    end if;
                when S_SEQUENCE =>
                    reset_espera2 <= '0';
                    if (enable_refresh /= '1') then
                        aux_segments <= 2;
                    else
                        aux_segments <= 0;
                    end if;
                    if (done = '1')then
                        STATE <= S_WAIT;
                    end if;
                when S_WAIT =>
                    if (enable_refresh /= '1') then
                        aux_segments <= 3;
                    else
                        aux_segments <= 0;
                    end if;
                    if (continue = '1')then
                        STATE <= S_SEQUENCE;
                    elsif (error = '1' or win = '1') then
                        STATE <= S_FINAL;
                    end if;
                when S_FINAL =>
                    if (win = '1') then
                        if (enable_refresh /= '1') then
                            aux_segments <= 1;
                        else
                            aux_segments <= 0;
                        end if;
                    elsif (error = '1') then
                        if (enable_refresh /= '1') then
                            aux_segments <= 3;
                        else
                            aux_segments <= 0;
                        end if;
                    end if;
                    if (enable_decSec = '1') then
                        reset_espera2 <= '1';
                        STATE <= S_RESET;
                    end if;
            end case;
        end if;
    end process;
    
    enable_temp <= '1' when (STATE = S_START or STATE = S_SEQUENCE or STATE = S_FINAL) else '0';
    enable_sequence <= '1' when STATE = S_SEQUENCE else '0';
    enable_all_display <= '1' when (STATE = S_START or STATE = S_FINAL) else '0';
    finish <= '1' when State = S_WAIT else '0';
    
    with level select
        led <= "10000000" when 1,
               "11000000" when 2,
               "11100000" when 3,
               "11110000" when 4,
               "11111000" when 5,
               "11111100" when 6,
               "11111110" when 7,
               "11111111" when 8,
               "00000000" when others;
    
    with aux_segments select
        segments <= "0110000" when 1,  --Display E
                    "0000000" when 2,  --Display 8
                    "0000001" when 3,  --Display 0
                    "1111111" when others; --Display apagado


end Behavioral;
