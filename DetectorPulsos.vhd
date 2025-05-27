library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity signal_detector is
    Port (
        clk          : in  STD_LOGIC;  -- Señal de reloj de 125 MHz
        reset        : in  STD_LOGIC;  -- Reset global
        B0, B1, B2, B3 : in  STD_LOGIC; -- Botones de entrada
        inicio       : in  std_logic;  -- Señal que activa el detector para la primera pulsación (NO pulso)
        continue     : in  STD_LOGIC;  -- Señal que indica continuar
        timeout      : out std_logic;  -- Señal de timeout
        secuencia    : out STD_LOGIC_VECTOR(1 downto 0);  -- Salida de la variable
        comparar     : out STD_LOGIC  -- Señal de comprobación de nuevo dato (para DETECTOR DE SECUENCIA)
    );
end signal_detector;

architecture Behavioral of signal_detector is

    component AntirebotesPulsos is
        Port (clk      : in std_logic;
              reset    : in std_logic;
              boton    : in std_logic;
              flanco   : out std_logic);
    end component;

    -- Declaración de señales internas
    constant count_max      : integer := 125*(10**3);  --Frecuencia de entrada del reloj 125MHz
    signal count            : integer range 0 to count_MAX-1;
    signal count_sec        : integer range 0 to 2;
    signal enable_count     : std_logic;
    signal enable_sec       : std_logic;
    
    signal boton0, boton1, boton2, boton3 : std_logic;  -- Señales filtradas por antirebotes
    
    type State_t is (S_RESET, S_DETECT, S_WAIT);
    signal STATE : State_t;

begin

    --ANTIRREBOTES B0
    control_B0 : AntirebotesPulsos
       port map (clk      => clk,
                 reset    => reset,
                 boton    => B0,
                 flanco   => boton0);
                 
    --ANTIRREBOTES B1
    control_B1 : AntirebotesPulsos
       port map (clk      => clk,
                 reset    => reset,
                 boton    => B1,
                 flanco   => boton1);
                 
    --ANTIRREBOTES B2
    control_B2 : AntirebotesPulsos
       port map (clk      => clk,
                 reset    => reset,
                 boton    => B2,
                 flanco   => boton2);
                 
    --ANTIRREBOTES B3
    control_B3 : AntirebotesPulsos
       port map (clk      => clk,
                 reset    => reset,
                 boton    => B3,
                 flanco   => boton3);
                 
    process(clk,reset)
    begin
        if (reset = '1' or STATE = S_WAIT) then
            count <= 0;
        elsif  (clk'event and clk = '1') then
            if (inicio = '1') then
                if (enable_count = '1') then
                    if (count < count_MAX - 1) then
                        count <= count + 1;
                    else
                        count <= 0;
                    end if;
                end if;
            end if;
        end if;
    end process;

    enable_sec <= '1' when (count = count_MAX - 1) else '0';
    
    process (clk,reset)
    begin
        if (reset = '1' or STATE = S_WAIT) then
            count_sec <= 0;
        elsif  (clk'event and clk = '1') then
            if (enable_sec = '1') then
                if (count_sec < 1) then     -- Tiempo de timeout-1 (2-1 = 1)
                        count_sec <= count_sec + 1;
                else
                    count_sec <= 0;
                end if;
            end if;
        end if;
    end process;

    timeout <= '1' when (count_sec = 1 and enable_sec = '1') else '0';
    
    process(clk,reset)
    begin
        if (reset = '1') then
            STATE <= S_RESET;
            secuencia <= "00";
            comparar <= '0';
        elsif (clk'event and clk = '1') then
            case STATE is
                when S_RESET =>
                    if (inicio = '1')then
                        secuencia <= "00";
                        STATE <= S_DETECT;
                    end if;
                when S_DETECT =>
                    if (boton0 = '1') then
                        secuencia <= "00";
                        comparar <= '1';
                        STATE <= S_WAIT;
                    elsif (boton1 = '1') then
                        secuencia <= "01";
                        comparar <= '1';
                        STATE <= S_WAIT;
                    elsif (boton2 = '1') then
                        secuencia <= "10";
                        comparar <= '1';
                        STATE <= S_WAIT;
                    elsif (boton3 = '1') then
                        secuencia <= "11";
                        comparar <= '1';
                        STATE <= S_WAIT;
                    end if;
                    if (boton0 = '0' and boton1 = '0' and boton2 = '0' and boton3 = '0') then
                        comparar <= '0';
                    end if;
                when S_WAIT =>
                    comparar <= '0';
                    if (inicio = '0') then
                        STATE <= S_RESET;
                    end if;
                    if (continue = '1')then
                        STATE <= S_DETECT;
                    end if;
            end case;
        end if;
    end process;
    
    enable_count <= '1' when (STATE = S_DETECT) else '0';

end Behavioral;
