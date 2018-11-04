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
		RESET_N	: in std_logic;
		SCK		: in std_logic;
		MOSI		: in std_logic;
		MISO		: out std_logic;
		SS			: in std_logic;
		
		CART_SRAM_ADDR	: out std_logic_vector(21 downto 0);
		CART_SRAM_DQ	: inout std_logic_vector(7 downto 0);
		CART_SRAM_CE_N	: out std_logic;
		CART_SRAM_OE_N	: out std_logic;
		CART_SRAM_WE_N	: out std_logic;
		
		CART_SRAM2_ADDR	: out std_logic_vector(21 downto 0);
		CART_SRAM2_DQ	: inout std_logic_vector(7 downto 0);
		CART_SRAM2_CE_N	: out std_logic;
		CART_SRAM2_OE_N	: out std_logic;
		CART_SRAM2_WE_N	: out std_logic;
		
		WSRAM_ADDR	: out std_logic_vector(16 downto 0);
		WSRAM_DQ		: inout std_logic_vector(7 downto 0);
		WSRAM_CE_N	: out std_logic;
		WSRAM_OE_N	: out std_logic;
		WSRAM_WE_N	: out std_logic;
		WSRAM_BLE_N	: out std_logic;
		WSRAM_BHE_N	: out std_logic;
		
		VSRAM_ADDR	: out std_logic_vector(17 downto 0);
		VSRAM_DQ		: inout std_logic_vector(15 downto 0);
		VSRAM_CE_N	: out std_logic;
		VSRAM_OE_N	: out std_logic;
		VSRAM_WE_N	: out std_logic;
		VSRAM_BLE_N	: out std_logic;
		VSRAM_BHE_N	: out std_logic;
		
		ASRAM_ADDR	: out std_logic_vector(20 downto 0);
		ASRAM_DQ		: inout std_logic_vector(7 downto 0);
		ASRAM_CE_N	: out std_logic;
		ASRAM_OE_N	: out std_logic;
		ASRAM_WE_N	: out std_logic;
		
		LCD_R 		: out std_logic_vector(4 downto 0);
		LCD_G 		: out std_logic_vector(4 downto 0);
		LCD_B 		: out std_logic_vector(4 downto 0);
		LCD_DCLK		: out std_logic;
		LCD_DE		: out std_logic;
		LCD_HS		: out std_logic;
		LCD_VS		: out std_logic;
		LCD_DISP		: out std_logic;
		
		JOY1_DI		: in std_logic_vector(1 downto 0);
		JOY2_DI		: in std_logic_vector(1 downto 0);
		JOY_STRB		: out std_logic;
		JOY1_CLK		: out std_logic;
		JOY2_CLK		: out std_logic;
		
		LRCK			: out std_logic;
		BCK			: out std_logic;
		SDAT			: out std_logic
	);
end main;

architecture rtl of main is

	signal CLK_21M, CLK_LCD, CLK_24M, CLK_SPI : std_logic;
	signal RST_N, BRST_N : std_logic;
	signal LOADER_EN : std_logic;
	signal ENABLE : std_logic;

	signal CA : std_logic_vector(23 downto 0);
	signal CPURD_N	: std_logic;
	signal CPUWR_N	: std_logic;
	signal DI : std_logic_vector(7 downto 0);
	signal DO : std_logic_vector(7 downto 0);
	signal RAMSEL_N : std_logic;
	signal ROMSEL_N : std_logic;
	signal IRQ_N: std_logic;
	signal PA : std_logic_vector(7 downto 0);
	signal PARD_N : std_logic;
	signal PAWR_N : std_logic;
	signal SYSCLK : std_logic;
	signal REFRESH : std_logic;

	signal DOTCLK : std_logic;
	signal HBLANK, VBLANK : std_logic;
	signal FRAME_OUT : std_logic;
	signal V224_MODE : std_logic;
	signal RGB_OUT : std_logic_vector(14 downto 0);
	signal X_OUT : std_logic_vector(8 downto 0);
	signal Y_OUT : std_logic_vector(8 downto 0);

	signal VRAM_ADDRA, VRAM_ADDRB : std_logic_vector(15 downto 0);
	signal VRAM_DAO, VRAM_DBO : std_logic_vector(7 downto 0);
	signal VRAM_DAI, VRAM_DBI, VRAM_DBI_TEMP : std_logic_vector(7 downto 0);
	signal VRAM_RD_N : std_logic;
	signal VRAM_WRA_N, VRAM_WRB_N : std_logic;
	signal VRAM_WE_N : std_logic;

	signal ARAM_ADDR : std_logic_vector(15 downto 0);

	-- MCU
	signal MCU_STAT : std_logic_vector(7 downto 0);
	signal MCU_CTRL : std_logic_vector(7 downto 0);
	signal MCU_DATA_WR: std_logic;
	signal MCU_DI : std_logic_vector(7 downto 0);
	signal MCU_DO : std_logic_vector(7 downto 0);
	signal MCU_LD_ADDR: std_logic_vector(23 downto 0);
	signal MCU_LD_WR : std_logic;
	signal MCU_DBG_REG, MCU_DBG_SEL : std_logic_vector(7 downto 0);
	signal MCU_DBG_DAT_IN, MCU_DBG_DAT_OUT	: std_logic_vector(7 downto 0);
	signal MCU_DBG_REG_WR : std_logic;
	signal MCU_MAP_CTRL : std_logic_vector(7 downto 0);
	signal MCU_MAP_ROM_MASK, MCU_MAP_BSRAM_MASK : std_logic_vector(23 downto 0);
	signal CART_EN : std_logic;

	--LCD
	signal DDIO_OUT	: std_logic_vector(0 downto 0);

	-- DEBUG
	signal DBG_BREAK, SNES_BRK, MAP_BRK : std_logic;
	signal MAP_DBG_WR : std_logic;
	signal DBG_SNES_DAT, DBG_MAP_DAT : std_logic_vector(7 downto 0);

begin

	-- PLL
	pll : entity work.pll
	port map(
		inclk0	=> CLOCK_100(0),
		c0		=> CLK_21M,
		c1		=> CLK_LCD,
		c2		=> CLK_SPI
	);

	apupll : entity work.apupll
	port map(
		inclk0	=> CLOCK_100(1),
		c0		=> CLK_24M
	);

	-- MCU
	MCU : entity work.mcu
	port map(
		CLK_SPI		=> CLK_SPI,
		CLK		=> CLK_21M,
		SCK		=> SCK,
		MOSI 		=> MOSI,
		MISO 		=> MISO,
		SS 		=> SS,
		STAT 		=> MCU_STAT,
		CTRL 		=> MCU_CTRL,
		DATA_IN 	=> MCU_DI,
		DATA_OUT 	=> MCU_DO,
		
		LD_ADDR 	=> MCU_LD_ADDR,
		LD_WR 		=> MCU_LD_WR,
		
		DBG_SEL 	=> MCU_DBG_SEL,
		DBG_REG 	=> MCU_DBG_REG,
		DBG_DAT_IN 	=> MCU_DBG_DAT_IN,
		DBG_DAT_OUT	=> MCU_DBG_DAT_OUT,
		DBG_REG_WR 	=> MCU_DBG_REG_WR,
		
		MAP_CTRL 	=> MCU_MAP_CTRL,
		MAP_ROM_MASK 	=> MCU_MAP_ROM_MASK,
		MAP_BSRAM_MASK 	=> MCU_MAP_BSRAM_MASK
	);

	MCU_DI <= (others => '0');

	MCU_STAT <= "0000000" & DBG_BREAK;

	DBG_BREAK <= SNES_BRK or MAP_BRK;

	MCU_DBG_DAT_IN <= DBG_MAP_DAT when MCU_DBG_SEL(7) = '1' else DBG_SNES_DAT;

	process( CLK_21M )
	begin
		if rising_edge( CLK_21M ) then
			BRST_N <= RESET_N;
		end if;
	end process;

	RST_N <= (not MCU_CTRL(0));-- and BRST_N

	LOADER_EN <= MCU_CTRL(7);

	ENABLE <= not (LOADER_EN or DBG_BREAK);

	SNES : entity work.SNES
	port map(
		MCLK		=> CLK_21M,
		DSPCLK		=> CLK_24M,
		RST_N		=> RST_N,
		ENABLE		=> ENABLE,
		PAL		=> MCU_MAP_CTRL(7),
		
		CA     		=> CA,
		CPURD_N		=> CPURD_N,
		CPUWR_N		=> CPUWR_N,
			
		PA		=> PA,
		PARD_N		=> PARD_N,
		PAWR_N		=> PAWR_N,
		DI		=> DI,
		DO		=> DO,
			
		RAMSEL_N	=> RAMSEL_N,
		ROMSEL_N	=> ROMSEL_N,
			
		SYSCLK		=> SYSCLK,
		REFRESH		=> REFRESH,
			
		IRQ_N		=> IRQ_N,
			
		WSRAM_ADDR	=> WSRAM_ADDR,
		WSRAM_DQ	=> WSRAM_DQ,
		WSRAM_CE_N	=> WSRAM_CE_N,
		WSRAM_OE_N	=> WSRAM_OE_N,
		WSRAM_WE_N	=> WSRAM_WE_N,
			
		VRAM_ADDRA	=> VRAM_ADDRA,
		VRAM_ADDRB	=> VRAM_ADDRB,
		VRAM_DAI	=> VRAM_DAI,
		VRAM_DBI	=> VRAM_DBI,
		VRAM_DAO	=> VRAM_DAO,
		VRAM_DBO	=> VRAM_DBO,
		VRAM_RD_N	=> VRAM_RD_N,
		VRAM_WRA_N	=> VRAM_WRA_N,
		VRAM_WRB_N	=> VRAM_WRB_N,
			
		ARAM_ADDR	=> ARAM_ADDR,
		ARAM_DQ		=> ASRAM_DQ,
		ARAM_CE_N	=> ASRAM_CE_N,
		ARAM_OE_N	=> ASRAM_OE_N,
		ARAM_WE_N	=> ASRAM_WE_N,
			
		JOY1_DI		=> JOY1_DI,
		JOY2_DI		=> JOY2_DI,
		JOY_STRB	=> JOY_STRB,
		JOY1_CLK	=> JOY1_CLK,
		JOY2_CLK	=> JOY2_CLK,
		
		DOTCLK		=> DOTCLK,
		HBLANK		=> HBLANK,
		VBLANK		=> VBLANK,
			
		RGB_OUT		=> RGB_OUT,
		FRAME_OUT	=> FRAME_OUT,
		X_OUT		=> X_OUT,
		Y_OUT		=> Y_OUT,
		V224_MODE	=> V224_MODE,
			
		LRCK		=> LRCK,
		BCK		=> BCK,
		SDAT		=> SDAT,
		
		DBG_SEL		=> MCU_DBG_SEL,
		DBG_REG		=> MCU_DBG_REG,
		DBG_REG_WR	=> MCU_DBG_REG_WR,
		DBG_DAT_IN	=> MCU_DBG_DAT_OUT,
		DBG_DAT_OUT	=> DBG_SNES_DAT,
		DBG_BREAK	=> SNES_BRK
	);

			  
	WSRAM_BLE_N <= '0';
	WSRAM_BHE_N <= '1';

	VSRAM_ADDR	<= "000" & VRAM_ADDRB(14 downto 0) when DOTCLK = '0' and VRAM_RD_N = '0' and VRAM_ADDRA(13 downto 0) /= VRAM_ADDRB(13 downto 0) else "000" & VRAM_ADDRA(14 downto 0);--
	VSRAM_CE_N	<= '0';
	VSRAM_OE_N	<= VRAM_RD_N;
	VSRAM_WE_N	<= VRAM_WRA_N and VRAM_WRB_N;
	VSRAM_BLE_N <= VRAM_WRA_N and VRAM_RD_N;
	VSRAM_BHE_N <= VRAM_WRB_N and VRAM_RD_N;
	VSRAM_DQ <= VRAM_DBO & VRAM_DAO when VRAM_WRA_N = '0' or VRAM_WRB_N = '0' else "ZZZZZZZZZZZZZZZZ";
	VRAM_DAI <= VSRAM_DQ(7 downto 0);
	VRAM_DBI <= VRAM_DBI_TEMP when VRAM_ADDRA(13 downto 0) /= VRAM_ADDRB(13 downto 0) else VSRAM_DQ(15 downto 8);

	process( DOTCLK )
	begin
		if rising_edge( DOTCLK ) then
			VRAM_DBI_TEMP <= VSRAM_DQ(15 downto 8);
		end if;
	end process;


	ASRAM_ADDR	<= "00000" & ARAM_ADDR;


	--Cartridge
	CART_EN <= MCU_CTRL(6);
	MAP_DBG_WR <= MCU_DBG_SEL(7) and MCU_DBG_REG_WR;

	SMAP : entity work.LHRomMap
	--SMAP : entity work.SDD1Map
	--SMAP : entity work.DSPMap
	--SMAP : entity work.CX4Map
	port map(
		CLK100		=> CLOCK_100(2),
		MCLK		=> CLK_21M,
		RST_N		=> RST_N,
		ENABLE		=> ENABLE,
		
		CA		=> CA,
		DI		=> DO,
		DO		=> DI,
		CPURD_N		=> CPURD_N,
		CPUWR_N		=> CPUWR_N,
		
		PA		=> PA,
		PARD_N		=> PARD_N,
		PAWR_N		=> PAWR_N,
		
		ROMSEL_N	=> ROMSEL_N,
		RAMSEL_N	=> RAMSEL_N,
		
		SYSCLK		=> SYSCLK,
		REFRESH		=> REFRESH,

		IRQ_N		=> IRQ_N,
		
		SRAM1_ADDR	=> CART_SRAM_ADDR,
		SRAM1_DQ	=> CART_SRAM_DQ,
		SRAM1_CE_N	=> CART_SRAM_CE_N,
		SRAM1_OE_N	=> CART_SRAM_OE_N,
		SRAM1_WE_N	=> CART_SRAM_WE_N,
		
		SRAM2_ADDR	=> CART_SRAM2_ADDR,
		SRAM2_DQ	=> CART_SRAM2_DQ,
		SRAM2_CE_N	=> CART_SRAM2_CE_N,
		SRAM2_OE_N	=> CART_SRAM2_OE_N,
		SRAM2_WE_N	=> CART_SRAM2_WE_N,
		
		MAP_CTRL	=> MCU_MAP_CTRL,
		ROM_MASK	=> MCU_MAP_ROM_MASK,
		BSRAM_MASK	=> MCU_MAP_BSRAM_MASK,
		
		LD_ADDR     	=> MCU_LD_ADDR,
		LD_DI     	=> MCU_DO,
		LD_WR     	=> MCU_LD_WR,
		LD_EN     	=> CART_EN,
		
		BRK_OUT		=> MAP_BRK,
		DBG_REG  	=> MCU_DBG_REG,
		DBG_DAT_IN	=> MCU_DBG_DAT_OUT,
		DBG_DAT_OUT	=> DBG_MAP_DAT,
		DBG_DAT_WR	=> MAP_DBG_WR
	);


	lcd : entity work.lcd
	port map(
		CLK		=> CLK_21M,
		LCDCLK		=> CLK_LCD,
		RST_N		=> RST_N,
		FRAME		=> FRAME_OUT,
		PIX_IN		=> RGB_OUT,
		PPU_X		=> X_OUT,
		PPU_Y		=> Y_OUT,
		V224		=> V224_MODE,
			
		LCD_R		=> LCD_R,
		LCD_G		=> LCD_G,
		LCD_B		=> LCD_B,
		LCD_DE		=> LCD_DE,
		LCD_HS		=> LCD_HS,
		LCD_VS		=> LCD_VS,
		LCD_DISP	=> LCD_DISP
	);


	ddio1 : entity work.ddio
	port map(
		datain_h	=> "1",
		datain_l	=> "0",
		outclock	=> CLK_LCD,
		dataout		=> DDIO_OUT
	);

	LCD_DCLK <= DDIO_OUT(0);

end rtl;
