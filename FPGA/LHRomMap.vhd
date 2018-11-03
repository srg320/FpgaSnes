library STD;
use STD.TEXTIO.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.all;

entity LHRomMap is
	port(
		CLK100		: in std_logic;
		MCLK			: in std_logic;
		RST_N			: in std_logic;
		ENABLE		: in std_logic;
		
		CA   			: in std_logic_vector(23 downto 0);
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		CPURD_N		: in std_logic;
		CPUWR_N		: in std_logic;
		
		PA				: in std_logic_vector(7 downto 0);
		PARD_N		: in std_logic;
		PAWR_N		: in std_logic;
		
		ROMSEL_N		: in std_logic;
		RAMSEL_N		: in std_logic;
		
		SYSCLK		: in std_logic;
		REFRESH		: in std_logic;
		
		IRQ_N			: out std_logic;

		SRAM1_ADDR	: out std_logic_vector(21 downto 0);
		SRAM1_DQ		: inout std_logic_vector(7 downto 0);
		SRAM1_CE_N	: out std_logic;
		SRAM1_OE_N	: out std_logic;
		SRAM1_WE_N	: out std_logic;
		
		SRAM2_ADDR	: out std_logic_vector(21 downto 0);
		SRAM2_DQ		: inout std_logic_vector(7 downto 0);
		SRAM2_CE_N	: out std_logic;
		SRAM2_OE_N	: out std_logic;
		SRAM2_WE_N	: out std_logic;

		MAP_CTRL		: in std_logic_vector(7 downto 0);
		ROM_MASK		: in std_logic_vector(23 downto 0);
		BSRAM_MASK	: in std_logic_vector(23 downto 0);
		
		LD_ADDR   	: in std_logic_vector(23 downto 0);
		LD_DI			: in std_logic_vector(7 downto 0);
		LD_WR			: in std_logic;
		LD_EN			: in std_logic;
		
		BRK_OUT		: out std_logic;
		DBG_REG		: in std_logic_vector(7 downto 0);
		DBG_DAT_IN	: in std_logic_vector(7 downto 0);
		DBG_DAT_OUT	: out std_logic_vector(7 downto 0);
		DBG_DAT_WR	: in std_logic
	);
end LHRomMap;

architecture rtl of LHRomMap is

	signal CART_ADDR 	: std_logic_vector(22 downto 0);
	signal BSRAM_ADDR : std_logic_vector(19 downto 0);
	signal BSRAM_SEL 	: std_logic;
	
	signal SRAM1_DO, SRAM2_DO : std_logic_vector(7 downto 0);

begin
	
	process( CA, MAP_CTRL, ROMSEL_N, RAMSEL_N, BSRAM_MASK )
	begin
		case MAP_CTRL(3 downto 0) is
			when x"0" =>							-- LoROM
				CART_ADDR <= "0" & CA(22 downto 16) & CA(14 downto 0);
				BSRAM_ADDR <= CA(20 downto 16) & CA(14 downto 0);
				if CA(22 downto 20) = "111" and CA(15) = '0' and ROMSEL_N = '0' and BSRAM_MASK(10) = '1' then
					BSRAM_SEL <= '1';
				else
					BSRAM_SEL <= '0';
				end if;
			when x"1" =>							-- HiROM
				CART_ADDR <= "0" & CA(21 downto 0);
				BSRAM_ADDR <= "00" & CA(20 downto 16) & CA(12 downto 0);
				if CA(22 downto 21) = "01" and CA(15 downto 13) = "011" and BSRAM_MASK(10) = '1' then
					BSRAM_SEL <= '1';
				else
					BSRAM_SEL <= '0';
				end if;
			when x"5" =>							-- ExHiROM
				CART_ADDR <= (not CA(23)) & CA(21 downto 0);
				BSRAM_ADDR <= CA(19 downto 0);
				if CA(22 downto 21) = "01" and CA(15 downto 13) = "011" and BSRAM_MASK(10) = '1' then
					BSRAM_SEL <= '1';
				else
					BSRAM_SEL <= '0';
				end if;
			when others =>
				CART_ADDR <= (not CA(23)) & CA(21 downto 0);
				BSRAM_ADDR <= CA(19 downto 0);
				BSRAM_SEL <= '0';
		end case;
	end process;

	SRAM1_ADDR <= LD_ADDR(21 downto 0) when LD_EN = '1' else (CART_ADDR(21 downto 0) and ROM_MASK(21 downto 0));
	SRAM1_CE_N <= LD_ADDR(22) when LD_EN = '1' else ROMSEL_N or CART_ADDR(22);
	SRAM1_OE_N <= LD_WR when LD_EN = '1' else '0';
	SRAM1_WE_N <= not LD_WR when LD_EN = '1' else '1';
	SRAM1_DO <= SRAM1_DQ;
	SRAM1_DQ <= LD_DI when LD_EN = '1' and LD_WR = '1' else "ZZZZZZZZ";
	
	SRAM2_ADDR <= LD_ADDR(21 downto 0) when LD_EN = '1' else 
					  "10" & (BSRAM_ADDR and BSRAM_MASK(19 downto 0)) when BSRAM_SEL = '1' else 
					  (CART_ADDR(21 downto 0) and ROM_MASK(21 downto 0));
	SRAM2_CE_N <= not LD_ADDR(22) when LD_EN = '1' else 
					  '0' when BSRAM_SEL = '1' else 
					  ROMSEL_N or not (CART_ADDR(22) and ROM_MASK(22));
	SRAM2_OE_N <= LD_WR when LD_EN = '1' else 
					  CPURD_N when BSRAM_SEL = '1' else 
					  '0';
	SRAM2_WE_N <= not LD_WR when LD_EN = '1' else 
					  CPUWR_N when BSRAM_SEL = '1' else 
					  '1';
	SRAM2_DO <= SRAM2_DQ;
	SRAM2_DQ <= LD_DI when LD_EN = '1' and LD_WR = '1' else
					DI when BSRAM_SEL = '1' and CPUWR_N = '0' else 
					"ZZZZZZZZ";
	
	DO <= SRAM2_DO when CART_ADDR(22) = '1' or BSRAM_SEL = '1' else SRAM1_DO;

	IRQ_N <= '1';
	
	BRK_OUT <= '0';
	DBG_DAT_OUT <= (others => '0');
	
end rtl;