library STD;
use STD.TEXTIO.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.all;

entity main is
	port(
		CLOCK_100	: in std_logic_vector(2 downto 0);
		RESET_N		: in std_logic;

		SCK			: in std_logic;
		MOSI			: in std_logic;
		MISO			: out std_logic;
		SS				: in std_logic;
		
		ASRAM_ADDR	: out std_logic_vector(20 downto 0);
		ASRAM_DQ		: inout std_logic_vector(7 downto 0);
		ASRAM_CE_N	: out std_logic;
		ASRAM_OE_N	: out std_logic;
		ASRAM_WE_N	: out std_logic;
		
		LRCK			: out std_logic;
		BCK			: out std_logic;
		SDAT			: out std_logic
	);
end main;

architecture rtl of main is
 
	signal CLK_24M, CLK_SPI : std_logic;
	signal RST_N : std_logic;
	signal LOADER_EN : std_logic; 
	
	signal SMP_CLK: std_logic; 
	signal SMP_A : std_logic_vector(15 downto 0);
	signal SMP_DI, SMP_DO : std_logic_vector(7 downto 0);
	signal SMP_EN, SMP_WE : std_logic;
	
	signal ARAM_ADDR : std_logic_vector(15 downto 0);
		
	-- MCU
	signal MCU_STAT : std_logic_vector(7 downto 0);
	signal MCU_CTRL : std_logic_vector(7 downto 0);
	signal MCU_DATA_WR: std_logic;
	signal MCU_DBG_WR: std_logic;
	signal MCU_DBG_REG, MCU_DBG_SEL : std_logic_vector(7 downto 0);
	signal MCU_DBG_DAT_IN, MCU_DBG_DAT_OUT	: std_logic_vector(7 downto 0);
	
	signal DBG_SMP_DAT, DBG_SPC700_DAT, DBG_DSP_DAT	: std_logic_vector(7 downto 0); 
	signal SPC700_DAT_WR, SMP_DAT_WR, DSP_DAT_WR	: std_logic; 	
	signal SMP_BRK	: std_logic; 	
	signal ENABLE : std_logic;
	signal DBG_BREAK: std_logic; 
	signal MCU_DBG_REG_WR : std_logic; 
	signal LD_ADDR: std_logic_vector(15 downto 0); 
	signal LD_DATA: std_logic_vector(7 downto 0); 
	signal LD_EN : std_logic; 
	
begin 

	-- PLL
	pll : entity work.pll
	port map(
		inclk0	=> CLOCK_100(0),
--		c0			=> CLK_21M,
--		c1			=> CLK_LCD,
		c2			=> CLK_SPI
	);

	apupll : entity work.apupll
	port map(
		inclk0	=> CLOCK_100(1),
		c0			=> CLK_24M
	);


	MCU : entity work.mcu
	port map(
		CLK_SPI		=> CLK_SPI,
		CLK			=> CLK_24M,
		
		SCK			=> SCK,
		MOSI 			=> MOSI,
		MISO 			=> MISO,
		SS 			=> SS,
		
		STAT 			=> MCU_STAT,
		CTRL 			=> MCU_CTRL,
		DATA_IN 		=> (others => '0'),
				
		DBG_SEL 		=> MCU_DBG_SEL, 
		DBG_REG 		=> MCU_DBG_REG,
		DBG_DAT_IN	=> MCU_DBG_DAT_IN,
		DBG_DAT_OUT	=> MCU_DBG_DAT_OUT,
		DBG_REG_WR	=> MCU_DBG_REG_WR
	);
	
	RST_N <= (not MCU_CTRL(0));
	LOADER_EN <= MCU_CTRL(7); 
	
	DBG_BREAK <= SMP_BRK;
	MCU_STAT <= "0000000" & DBG_BREAK; 

	SPC700_DAT_WR <= MCU_DBG_SEL(3) and MCU_DBG_REG_WR;
	SMP_DAT_WR <= MCU_DBG_SEL(4) and MCU_DBG_REG_WR;
	DSP_DAT_WR <= MCU_DBG_SEL(6) and MCU_DBG_REG_WR;

	MCU_DBG_DAT_IN <= DBG_SPC700_DAT when MCU_DBG_SEL(3) = '1' else 
							DBG_SMP_DAT when MCU_DBG_SEL(4) = '1' else 
							DBG_DSP_DAT when MCU_DBG_SEL(6) = '1' else 
							x"00"; 
	
	ENABLE <= not (LOADER_EN or DBG_BREAK);

   SMP: entity work.SMP 
	port map (
		CLK			=> SMP_CLK,
		CLK_24M		=> CLK_24M,
		RST_N			=> RST_N,
		ENABLE		=> SMP_EN,
		
		A 				=> SMP_A,
		DI     		=> SMP_DI,
		DO    		=> SMP_DO,
		WE				=> SMP_WE,
            
		PA				=> "00",
		PARD_N 		=> '1',
		PAWR_N 		=> '1',
		CPU_DI 		=> x"00",
		CS				=> '0',
		CS_N			=> '1', 
				
		DBG_REG			=> MCU_DBG_REG,
		DBG_DAT_IN		=> MCU_DBG_DAT_OUT,
		DBG_CPU_DAT 	=> DBG_SPC700_DAT,
		DBG_SMP_DAT		=> DBG_SMP_DAT,
		DBG_CPU_DAT_WR	=> SPC700_DAT_WR,
		DBG_SMP_DAT_WR	=> SMP_DAT_WR,
		BRK_OUT    		=> SMP_BRK
	);
    
    DSP: entity work.DSP 
	port map (
		CLK			=> CLK_24M,
		RST_N			=> RST_N,
		ENABLE		=> ENABLE,
				
		SMP_EN    	=> SMP_EN,
		SMP_A     	=> SMP_A,
		SMP_DO    	=> SMP_DO,
		SMP_DI 		=> SMP_DI,
		SMP_WE    	=> SMP_WE,
		SMP_CLK   	=> SMP_CLK,
            
		RAM_A 		=> ARAM_ADDR,
		RAM_DQ     	=> ASRAM_DQ,
		RAM_CE_N 	=> ASRAM_CE_N,
		RAM_OE_N 	=> ASRAM_OE_N,
		RAM_WE_N 	=> ASRAM_WE_N, 
				
		LRCK 			=> LRCK,
		BCK 			=> BCK,
		SDAT 			=> SDAT,
		
		DBG_REG		=> MCU_DBG_REG,
		DBG_DAT_IN  => MCU_DBG_DAT_OUT,
		DBG_DAT_OUT => DBG_DSP_DAT,
		DBG_DAT_WR	=> DSP_DAT_WR 
	);
	
	ASRAM_ADDR	<= "00000" & ARAM_ADDR;


end rtl;
