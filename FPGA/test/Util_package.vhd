-------------------------------------------------------------------------
-- Design unit: Util package
-- Description: Package with some general functions/procedures
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

package Util_package is  
    
    -- Converts an hexadecimal string digit into a 4 bits std_logic_vector.
    function CharToStdLogicVector(digit: character) return std_logic_vector;
    
    -- Converts an hexadecimal string number into a std_logic_vector.
    -- The vector length depends on the number of string characteres (string length * 4).
    function StringToStdLogicVector(value: string) return std_logic_vector;
        
         
end Util_package;


package body Util_package is
	
	-- Converts an hexadecimal string digit into a std_logic_vector(3 downto 0).
    function CharToStdLogicVector(digit: character) return std_logic_vector is         
        
        variable binaryDigit: std_logic_vector(3 downto 0);
        
       begin
        
        case (digit) is  
            when '0'         => binaryDigit := "0000";
            when '1'         => binaryDigit := "0001";
            when '2'         => binaryDigit := "0010";
            when '3'         => binaryDigit := "0011";
            when '4'         => binaryDigit := "0100";
            when '5'         => binaryDigit := "0101";
            when '6'         => binaryDigit := "0110";
            when '7'         => binaryDigit := "0111";
            when '8'         => binaryDigit := "1000";
            when '9'         => binaryDigit := "1001";
            when 'A' | 'a'    => binaryDigit := "1010";
            when 'B' | 'b'     => binaryDigit := "1011";
            when 'C' | 'c'     => binaryDigit := "1100";
            when 'D' | 'd'     => binaryDigit := "1101";
            when 'E' | 'e'     => binaryDigit := "1110";
            when 'F' | 'f'     => binaryDigit := "1111";
            when others =>  binaryDigit := "0000";  
          end case;
      
         return binaryDigit;
  
    end function;
     
	  
    -- Converts an hexadecimal string number into a std_logic_vector.
    -- The vector length depends on the number of string characteres (string length * 4).
    function StringToStdLogicVector(value: string) return std_logic_vector is
  
          variable binaryValue: std_logic_vector(value'length*4-1 downto 0);
          variable vectorLength: integer;
          variable high, low: integer;
     
     begin
     
         -- Each string digits is converted into a 4 bits binary digit.
         vectorLength := value'length*4;
  
          
          -- String characters range from 1 to n.
          -- The left most character has the index 1.
          -- Ex: value: string:= "5496" -> value(1) = 5, value(2) = 4, value(3) = 9, value(4) = 6
          
          
          -- Converts the string number character by character.
          -- The left most character is placed at the right most 4 bits in the std_logic_vector.
          -- The right most character is placed at the left most 4 bits in the std_logic_vector.
          for i in value'range loop
              high := vectorLength - (4*(i-1)) - 1;
              low    := high-3;
              binaryValue(high downto low) := CharToStdLogicVector(value(i));        
          end loop;
          
            
          return binaryValue;
      
      end function;
      
      

end package body Util_package;

