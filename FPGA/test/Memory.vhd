-------------------------------------------------------------------------
-- Design unit: Memory
-- Description: Parametrizable memory
--      Synchronous read and write
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
library work;
use work.Util_package.all;


entity Memory is
    generic (
        DATA_WIDTH  : integer := 8;         -- Data bus width
        ADDR_WIDTH  : integer := 8;         -- Address bus width
        IMAGE       : string := "UNUSED"    -- Memory content to be loaded    (text file)
    );
    port (  
        clk         : in std_logic;
        we          : in std_logic;        -- Write Enable
        address     : in std_logic_vector (ADDR_WIDTH-1 downto 0);
        data_in     : in std_logic_vector (DATA_WIDTH-1 downto 0);
        data_out    : out std_logic_vector (DATA_WIDTH-1 downto 0)
    );
end Memory;

architecture rtl of Memory is
    
    type RamType is array (0 to (2**ADDR_WIDTH)-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    impure function InitRamFromFile (RamFileName : in string) return RamType is
        FILE RamFile : text is in RamFileName;
        variable RamFileLine : line;
        variable RAM : RamType;
        variable str : string(1 to 2);
    begin   
        for I in RamType'range loop
            readline (RamFile, RamFileLine);
            read (RamFileLine, str);
            RAM(I) := StringToStdLogicVector(str);
        end loop;
        return RAM;
    end function;
    
    signal RAM : RamType := InitRamFromFile(IMAGE);
            
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