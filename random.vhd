library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.trabajo_pkg.ALL;

entity random_gen is
    port (  clk     : in std_logic;
            reset   : in std_logic;
            start   : in std_logic;
            random  : out std_logic_array;
            finish  : out std_logic);
end random_gen;

architecture Behavioral of random_gen is
    
    signal Q : std_logic_vector(8 downto 0) := "001001001";
    
    signal aux_random : std_logic_array;
    
    type estados is (S_ESPERA, S_GENERANDO);
    signal estado : estados := S_ESPERA;
    
    signal index : integer range 0 to 8 := 0;
begin
    
    process(clk, reset)
    begin
        if reset = '1' then
            Q <= "001001001";
        elsif rising_edge(clk) then
            Q(8) <= Q(0) xor Q(1) xor Q(3) xor Q(5);
            Q(7) <= Q(8);
            Q(6) <= Q(7) xor Q(4) xor Q(2);
            Q(5) <= Q(6);
            Q(4) <= Q(8) xor Q(6) xor Q(5);
            Q(3) <= Q(4);
            Q(2) <= Q(4) xor Q(3);
            Q(1) <= Q(2);
            Q(0) <= Q(5) xor Q(1);
        end if;
    end process;

    process(clk, reset)
    begin
        if reset = '1' then
            estado <= S_ESPERA;
            aux_random <= (others => (others => '0'));
            index <= 0;
            finish <= '0';
        elsif rising_edge(clk) then
            case estado is            
                when S_ESPERA =>
                    if start = '1' then
                        estado <= S_GENERANDO;
                        aux_random <= (others => (others => '0'));
                    end if;
                    index <= 0;
                    finish <= '0';

                when S_GENERANDO =>
                    if index < 8 then
                        aux_random(index) <= Q(index + 1 downto index);
                        index <= index + 1;
                    else
                        estado <= S_ESPERA;
                        finish <= '1';
                    end if;
            end case;
        end if;
    end process;

    random <= aux_random;

end Behavioral;


