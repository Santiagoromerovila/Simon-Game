library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.trabajo_pkg.ALL;


entity Control is
    Port(
        clk            : in  std_logic;                     -- Señal de reloj
        reset          : in  std_logic;                     -- Señal de reinicio
        --START LA QUIERO PONER COMO UN BOTÓN DE LA PLACA DISTINTO A RESET
        start          : in  std_logic;                     -- Señal de inicio del juego (botón de la placa)
        B0, B1, B2, B3 : in  std_logic;                     -- Pulsadores de secuencia
        selector       : out std_logic_vector(3 downto 0);
        segments       : out std_logic_vector(6 downto 0);
        led            : out std_logic_vector(7 downto 0)
    );
end Control;


architecture Behavioral of Control is

    component Antirebotes is
        Port (clk      : in std_logic;
              reset    : in std_logic;
              boton    : in std_logic;
              filtrado : out std_logic);
    end component;

    component random_gen is 
        Port (clk     : in std_logic;
              reset   : in std_logic;
              start   : in std_logic;
              random  : out std_logic_array;
              finish  : out std_logic);
    end component; 
    
    component Display is
         Port (clk         : in std_logic;
               reset       : in std_logic;                      --Botón de la placa
               start       : in std_logic;                      --Solo al inicio (es un pulso o dura 1 seg)
               continue    : in std_logic;                      --Se envía cada vez que se sube de nivel (es un pulso o dura 1 seg)
               random      : in std_logic_array;
               level       : in integer range 1 to 8;
               error       : in std_logic;                      --Error en la secuencia
               win         : in std_logic;                      --Se termina el juego y se vuelve a empezar
               selector    : out std_logic_vector(3 downto 0);
               segments    : out std_logic_vector(6 downto 0);
               led         : out std_logic_vector(7 downto 0);
               finish      : out std_logic);                     --Cuando se termina de hacer la secuencia de nivel, es el continue del captador de end    
    end component;
    
    component DetectorSecuencia is
        Port(clk       : in  std_logic;              
             reset     : in  std_logic;                     -- Botón de la placa
             random    : in  std_logic_array;               -- Secuencia generada
             nivel     : in  integer range 1 to 8;          -- Nivel actual del juego (1 a 8)
             siguiente : in  std_logic;                     -- Indica cambio de secuencia (viene de detector de pulsos)
             secuencia : in  std_logic_vector(1 downto 0);  -- Secuencia ingresada por el jugador
             acierto   : out std_logic;                     -- Indica si la última secuencia es correcta
             fallo     : out std_logic;                     -- Indica que ha habido un error en la secuencia
             correcto  : out std_logic                      -- Indica si todo el nivel fue completado correctamente
        );
    end component;
    
    component signal_detector is
        Port(clk            : in std_logic;
             reset          : in std_logic;
             B0, B1, B2, B3 : in std_logic;         -- Botónes de la placa
             inicio         : in std_logic;         -- Inicio del bloque
             continue       : in std_logic;         -- Continua detectando
             timeout        : out std_logic;        -- Se pierde el juego
             secuencia      : out std_logic_vector; -- Botón pulsado (0, 1, 2, 3)
             comparar       : out std_logic         -- Señal para que DETECTOR DE SECUENCIA compare
        );
    end component;

    constant count_max      : integer := 125*(10**3)/2;  --Frecuencia de entrada del reloj 125MHz
    signal count            : integer range 0 to count_MAX-1;
    signal enable_count     : std_logic;
    signal enable_temp       : std_logic;

    signal start_filtrado : std_logic;
    
    signal random       : std_logic_array;          -- Vector generado por GENERACIÓN DE SEÑAL
    signal fin_GEN      : std_logic := '0';         -- Señal de fin de GENERACIÓN DE SEÑAL
    signal fin_DISP     : std_logic := '0';         -- Señal de fin de DIAPLAY e inicio de DETECTOR DE PULSOS
    signal fin_SECUEN   : std_logic := '0';         -- Señal del DETECTOR DE SECUENCIA indicando éxito (cambio de nivel)
    signal fallo        : std_logic;         -- Senal del DETECTOR DE SECUENCIA indicando fallo
    signal timeout      : std_logic := '0';
    signal error        : std_logic := '0';
    signal cont_PULSO   : std_logic := '0';         -- Indica a DETECTOR DE PULSOS que continue (NO pulso)
    signal cont_DISP    : std_logic := '0';         -- Indica a DISPLAY que continue (pulso)
    signal cont_SECUEN  : std_logic := '0';         -- Indica al DETECTOR DE SECUENCIA que continue (NO pulso)
    signal nivel        : integer range 1 to 8;     -- Nivel actual del juego (1 a 8)
    signal fin_JUEGO    : std_logic;                -- Señal de fin de todos los nieveles correctamente
    signal secuencia    : std_logic_vector(1 downto 0) := "00"; -- Señal que indica el botón pulsado

    signal random_actual   : std_logic_array := (others => "00");   -- Registro del vector random
    signal estado          : integer range 0 to 2 := 0;             -- FSM para el control del juego
    

begin

    --ANTIRREBOTES
    control_start : Antirebotes
       port map (clk      => clk,
                 reset    => reset,
                 boton    => start,
                 filtrado => start_filtrado);
    
    --GENERACIÓN DE SEÑAL 
    control_random : random_gen
        port map (clk     => clk,
                  reset   => reset,
                  start   => start_filtrado,
                  finish  => fin_GEN ,
                  random  => random);
                  
    --DISPLAYS              
    control_displays : Display 
        port map (clk       => clk,
                  reset     => reset,
                  start     => start_filtrado,
                  continue  => cont_DISP,    -- Es un pulso o dura 1 seg
                  random    => random_actual, 
                  level     => nivel, 
                  error     => error,        -- Error en la secuencia
                  win       => fin_JUEGO,    -- Se termina el juego y se vuelve a empezar
                  selector  => selector,
                  segments  => segments,
                  led       => led,
                  finish    => fin_DISP);
                  
    --DETECTOR DE SECUENCIA
    control_secuencia : DetectorSecuencia 
        port map (clk       => clk,
                  reset     => reset,
                  random    => random_actual, 
                  nivel     => nivel,
                  siguiente => cont_SECUEN,  -- Viene de detector de pulsos para que empiece a comprobar
                  secuencia => secuencia,    -- Secuencia pasada por el detector de pulsos
                  acierto   => cont_PULSO,   -- Indica si la última secuencia es correcta
                  fallo     => fallo,        -- Indica que ha habido un error en la secuencia
                  correcto  => fin_SECUEN);  -- Indica que ha terminado el nivel correctamente
                  
    -- DETECTOR DE PULSOS
    control_pulsos : signal_detector
        port map (clk       => clk,
                  reset     => reset,
                  B0        => B0,
                  B1        => B1,
                  B2        => B2,
                  B3        => B3,
                  inicio    => fin_DISP, -- Termina el DISPLAY y empieza a captar
                  continue  => cont_PULSO,
                  timeout   => timeout,        -- Se tarda demasiado en pulsar un botón
                  secuencia => secuencia,    -- Secuencia a comparar
                  comparar  => cont_SECUEN); -- Indica a DETECTOR DE SECUENCIA que compare el valor que acaba de pasar

    error <= '1' when (timeout = '1' or fallo = '1') else '0';
    
    process(clk,reset)
    begin
        if (reset = '1' or estado = 1) then
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

    enable_temp <= '1' when (count = count_MAX - 1) else '0';
    
    process(clk, reset)
    begin
        if (reset = '1') then
            -- Reinicio de señales y estados
            nivel <= 1;
            random_actual <= (others => "00");
            estado <= 0;        --Indica el inicio del juego
            fin_JUEGO <= '0';
            enable_count <= '0';
        elsif (clk'event and clk = '1') then
            case estado is
                when 0 =>  -- Espera de la señal de fin de GENERACIÓN DE SEÑAL
                    if (fin_GEN = '1') then
                        random_actual <= random;  -- Almacenar el vector random (sin modificarlo)
                        estado <= 1;
                    end if;
                    
                when 1 =>
                    cont_DISP <= '0';  -- Pulso
                    enable_count <= '0';
                    if (fin_DISP = '1') then
                        estado <= 2;
                    end if;

                when 2 =>  -- Verificar si el nivel fue completado correctamente
                    if (fin_SECUEN = '1') then
                        enable_count <= '1';
                    end if;
                    if (enable_temp = '1') then
                        if (nivel < 8) then
                            nivel <= nivel + 1; -- Aumentar nivel
                            cont_DISP <= '1';
                            estado <= 1;
                        elsif (nivel = 8) then
                            fin_JUEGO <= '1';  -- Juego terminado correctamente
                        end if;
                    end if;
            end case;
        end if;
    end process;
    
end Behavioral;
