library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.trabajo_pkg.ALL;


entity DetectorSecuencia is
    Port(
        clk       : in  std_logic;              
        reset     : in  std_logic;                      -- Botón de la placa
        random    : in  std_logic_array;                -- Secuencia generada
        nivel     : in  integer range 1 to 8;           -- Nivel actual del juego (1 a 8)
        siguiente : in  std_logic;                      -- Indica cambio de secuencia (viene de detector de pulsos)
        secuencia : in  std_logic_vector(1 downto 0);   -- Secuencia ingresada por el jugador
        acierto   : out std_logic;                      -- Indica si la última secuencia es correcta
        fallo     : out std_logic;                      -- Indica que ha habido un error en la secuencia
        correcto  : out std_logic                       -- Indica si todo el nivel fue completado correctamente (pulso)
    );
end DetectorSecuencia;


architecture Behavioral of DetectorSecuencia is

    signal index : integer range 0 to 7 := 0;          -- Índice para comparar los vectores

    type State_t is (S_WAIT, S_COMP);
    signal STATE : State_t;

begin

    process(clk,reset)
    begin
        if (reset = '1') then
            STATE <= S_WAIT;
            acierto <= '0';
            fallo <= '0';
            correcto <= '0';
        elsif (clk'event and clk = '1') then
            case STATE is
                when S_WAIT =>
                    acierto <= '0';
                    fallo <= '0';
                    correcto <= '0';
                    if (siguiente = '1')then
                        STATE <= S_COMP;
                    end if;
                when S_COMP =>
                    if (index < nivel - 1) then
                        if (secuencia = random(index))then
                            acierto <= '1';
                            index <= index + 1;
                            STATE <= S_WAIT;
                        else
                            fallo <= '1';
                        end if;
                    elsif (index = nivel - 1) then
                        if (secuencia = random(index))then
                            correcto <= '1';
                            index <= 0;
                            STATE <= S_WAIT;
                        else
                            fallo <= '1';
                        end if;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;

