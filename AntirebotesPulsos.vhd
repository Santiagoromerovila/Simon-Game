library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

entity AntirebotesPulsos is
Port (clk : in std_logic;
    reset : in std_logic;
    boton : in std_logic;
    flanco : out std_logic);
end AntirebotesPulsos;

architecture Behavioral of AntirebotesPulsos is
    signal Q1, Q2, Q3 : std_logic;

begin
    
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
    
end Behavioral;
