library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity Antirebotes is
Port (clk : in std_logic;
    reset : in std_logic;
    boton : in std_logic;
    filtrado : out std_logic);
end Antirebotes;

architecture Behavioral of Antirebotes is
    signal en_temp, temp, Q1, Q2, Q3, flanco : std_logic;
    constant count_MAX    : integer := 125*(10**6);
    signal count          : integer range 0 to count_MAX-1;

    type State_t is (S_NADA, S_BOTON);
    signal STATE : State_t;

begin
    process(clk, reset)
    begin
        if(reset = '1') then
             count <= 0;
        elsif (clk = '1' and clk'event) then
            if (en_temp = '1') then
                if (count < count_MAX-1) then
                    count <= count + 1;
                else
                    count <= 0;
                end if;
            end if;
        end if;
    end process;
    
    temp <= '1' when (count = count_MAX -1) else '0';
    
    process(clk, reset)
    begin
        if(reset = '1') then
            Q1 <= '0';
            Q2 <= '0';
        elsif (clk = '1' and clk'event) then
            if(boton = '1') then
                Q1 <= '1';
            elsif (boton = '0') then
                Q1 <= '0';
            end if;
            if(Q1 = '1') then
                Q2 <= '1';
            elsif (Q1 = '0') then
                Q2 <= '0';
            end if;
         end if;
    end process;
    
    process(clk, reset)
    begin
        if(reset = '1') then
            Q3 <= '0';
        elsif (clk = '1' and clk'event) then
            if(Q2 = '1') then
                Q3 <= '1';
            elsif (Q2 = '0') then
                Q3 <= '0';
            end if;
        end if;
    end process;
    
    flanco <= not Q3 and Q2;

    process(clk, reset)
    begin
        if (reset = '1') then
            STATE <= S_NADA;
        elsif (clk'event and clk = '1') then
            case STATE is
                when S_NADA =>
                    if (flanco = '1')then
                        STATE <= S_BOTON;
                    elsif (flanco = '0') then
                        STATE <= S_NADA;
                    end if;
                when S_BOTON =>
                    if (temp = '0')then
                        STATE <= S_BOTON;
                    elsif (temp = '1') then
                        STATE <= S_NADA;
                    end if;
            end case;
        end if;
    end process;
    
    filtrado <= '1' when STATE = S_BOTON else '0';
    en_temp <= '1' when STATE = S_BOTON else '0';
    
end Behavioral;
