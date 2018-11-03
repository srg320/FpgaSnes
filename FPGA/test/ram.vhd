library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
library work;

entity MemRam is
    generic (
        DATA_WIDTH  : integer := 8;         -- Data bus width
        ADDR_WIDTH  : integer := 8          -- Address bus width
    );
    port (  
        clk         : in std_logic;
        we          : in std_logic;        -- Write Enable
        address     : in std_logic_vector (ADDR_WIDTH-1 downto 0);
        data_in     : in std_logic_vector (DATA_WIDTH-1 downto 0);
        data_out    : out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end MemRam;

architecture rtl of MemRam is
    
    type RamType is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal RAM : RamType := (others => (others => '0'));
            
    begin
    -- Process to control the memory access
    process(clk)
    begin
        if rising_edge(clk) then    -- Memory writing        
            if we = '1' then
                RAM(TO_INTEGER(UNSIGNED(address))) <= data_in; 
            end if;
            -- Synchronous memory read (Block RAM)
            data_out <= RAM(TO_INTEGER(UNSIGNED(address)));
        end if;   
    end process;
    
end rtl;