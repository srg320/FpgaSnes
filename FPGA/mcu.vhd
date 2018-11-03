library STD;
use STD.TEXTIO.ALL;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_TEXTIO.all;

entity mcu is
	generic (
		STATUS  	: std_logic_vector(6 downto 0) := "0000001";
		CONTROL 	: std_logic_vector(6 downto 0) := "0000010";
		BUSADDR 	: std_logic_vector(6 downto 0) := "0000011";
		BUSDATA 	: std_logic_vector(6 downto 0) := "0000100";
		BUSRW   	: std_logic_vector(6 downto 0) := "0000101";
		LDADDR  	: std_logic_vector(6 downto 0) := "0000110";
		LDDATA  	: std_logic_vector(6 downto 0) := "0000111";
		DBGSEL  	: std_logic_vector(6 downto 0) := "0001000";
		DBGRD   	: std_logic_vector(6 downto 0) := "0001001";
		DBGCTL	: std_logic_vector(6 downto 0) := "0001010";
		DBGREG  	: std_logic_vector(6 downto 0) := "0001011";
		MAPCTL  	: std_logic_vector(6 downto 0) := "0001100";
		MAPRMASK	: std_logic_vector(6 downto 0) := "0001101";
		MAPBSMASK: std_logic_vector(6 downto 0) := "0001110";
		DBGWR		: std_logic_vector(6 downto 0) := "0001111";
		DBGRW		: std_logic_vector(6 downto 0) := "0010000"
	);
	port(
		CLK_SPI		: in std_logic;
		CLK 			: in std_logic;
		SCK			: in std_logic;
		MOSI			: in std_logic;
		MISO			: out std_logic;
		SS				: in std_logic;
		
		STAT 			: in std_logic_vector(7 downto 0);
		CTRL 			: out std_logic_vector(7 downto 0) := x"80";
		ADDR 			: out std_logic_vector(7 downto 0) := (others => '0');
		DATA_IN 		: in std_logic_vector(7 downto 0);
		DATA_OUT 	: out std_logic_vector(7 downto 0) := (others => '0');
		DATA_RD		: out std_logic := '0';
		DATA_WR		: out std_logic := '0';
		
		LD_ADDR 		: out std_logic_vector(23 downto 0) := (others => '0');
		LD_WR			: out std_logic := '0';
		
		DBG_SEL 		: out std_logic_vector(7 downto 0) := (others => '0');
		DBG_REG 		: out std_logic_vector(7 downto 0) := (others => '0');
		DBG_DAT_IN 	: in std_logic_vector(7 downto 0);
		DBG_DAT_OUT : out std_logic_vector(7 downto 0) := (others => '0');
		DBG_REG_WR	: out std_logic := '0';
		DBG_CTRL 	: out std_logic_vector(7 downto 0) := (others => '0');
		
		MAP_CTRL			: out std_logic_vector(7 downto 0) := (others => '0');
		MAP_ROM_MASK	: out std_logic_vector(23 downto 0) := (others => '0');
		MAP_BSRAM_MASK	: out std_logic_vector(23 downto 0) := (others => '0')
	);
end mcu;

architecture rtl of mcu is

	signal SPI_DIN : std_logic_vector(7 downto 0);
	signal SPI_DOUT : std_logic_vector(7 downto 0) := x"55";
	signal SPI_RDY : std_logic;

	signal CMD : std_logic_vector(6 downto 0);
	signal RW : std_logic;

	type step_t is (
		STEP0,
		STEP1,
		STEP2,
		STEP3
	);
	signal STEP	: step_t := STEP0; 

	signal RDYr : std_logic_vector(2 downto 0) := (others => '0');

	signal LOADER_ADDR : std_logic_vector(23 downto 0);
	signal LOADER_WR : std_logic := '0';
	signal REG_WR : std_logic := '0';

begin

	spi : entity work.spi_slave
	port map(
		CLK		=> CLK_SPI,
		SCK		=> SCK,
		MOSI		=> MOSI,
		MISO		=> MISO,
		SSEL		=> SS,
		DATA_IN	=> SPI_DOUT,
		DATA_OUT	=> SPI_DIN,
		RDY		=> SPI_RDY
	);


	process( CLK )
	begin
		if rising_edge(CLK) then
			RDYr <= RDYr(1 downto 0) & SPI_RDY;
		end if;
	end process;

	process( CLK )
	begin
		if rising_edge(CLK) then
			
			if LOADER_WR = '1' then
				LOADER_WR <= '0';
				LOADER_ADDR <= std_logic_vector(unsigned(LOADER_ADDR) + 1);
			end if;
			
			if RDYr(2 downto 1) = "01" then
				if REG_WR = '1' then
					REG_WR <= '0';
				end if;
				
				case STEP is
					when STEP0 =>
						CMD <= SPI_DIN(7 downto 1);
						RW <= SPI_DIN(0); 
						if SPI_DIN(0) = '1' then
							case SPI_DIN(7 downto 1) is
								when STATUS =>
									SPI_DOUT <= STAT;
								when BUSDATA =>
									SPI_DOUT <= DATA_IN;
								when LDDATA =>
									SPI_DOUT <= DATA_IN;
								when DBGRD =>
									SPI_DOUT <= DBG_DAT_IN;
								when others => null;
							end case;
							STEP <= STEP1;
						else
							case SPI_DIN(7 downto 1) is
								when others => null;
							end case;
							STEP <= STEP1;
						end if; 
					
					when STEP1 =>
						if RW = '1' then
							case CMD is
							when others => 
								STEP <= STEP0;
							end case;
						else
							case CMD is
							when CONTROL =>
								CTRL <= SPI_DIN;
								STEP <= STEP0;
							when BUSADDR =>
								ADDR <= SPI_DIN;
								STEP <= STEP0;
							when BUSDATA =>
								DATA_OUT <= SPI_DIN;
								STEP <= STEP0;
							when BUSRW =>
								DATA_RD <= SPI_DIN(0);
								DATA_WR <= SPI_DIN(1);
								STEP <= STEP0;
							when LDADDR =>
								LOADER_ADDR(7 downto 0) <= SPI_DIN;
								STEP <= STEP2;
							when LDDATA =>
								DATA_OUT <= SPI_DIN;
								LOADER_WR <= '1';
								STEP <= STEP0;
							when DBGREG =>
								DBG_REG <= SPI_DIN;
								STEP <= STEP0;
							when DBGSEL =>
								DBG_SEL <= SPI_DIN;
								STEP <= STEP0;
							when DBGCTL =>
								DBG_CTRL <= SPI_DIN;
								STEP <= STEP0;
							when DBGWR =>
								DBG_DAT_OUT <= SPI_DIN;
								REG_WR <= '1';
								STEP <= STEP0;
							when MAPCTL =>
								MAP_CTRL <= SPI_DIN;
								STEP <= STEP0;
							when MAPRMASK =>
								MAP_ROM_MASK(7 downto 0) <= SPI_DIN;
								STEP <= STEP2;
							when MAPBSMASK =>
								MAP_BSRAM_MASK(7 downto 0) <= SPI_DIN;
								STEP <= STEP2;
							when others => 
								STEP <= STEP0;
							end case;
						end if; 
					
					when STEP2 =>
						if RW = '1' then
							case CMD is
							when others => 
								STEP <= STEP0;
							end case;
						else
							case CMD is
							when LDADDR =>
								LOADER_ADDR(15 downto 8) <= SPI_DIN;
								STEP <= STEP3;
							when MAPRMASK =>
								MAP_ROM_MASK(15 downto 8) <= SPI_DIN;
								STEP <= STEP3;
							when MAPBSMASK =>
								MAP_BSRAM_MASK(15 downto 8) <= SPI_DIN;
								STEP <= STEP3;
							when others => 
								STEP <= STEP0;
							end case;
						end if;
						
					when STEP3 =>
						if RW = '1' then
							case CMD is
								when others => null;
							end case;
							STEP <= STEP0;
						else
							case CMD is
							when LDADDR =>
								LOADER_ADDR(23 downto 16) <= SPI_DIN;
								STEP <= STEP0;
							when MAPRMASK =>
								MAP_ROM_MASK(23 downto 16) <= SPI_DIN;
								STEP <= STEP0;
							when MAPBSMASK =>
								MAP_BSRAM_MASK(23 downto 16) <= SPI_DIN;
								STEP <= STEP0;
							when others => 
								STEP <= STEP0;
							end case;
						end if;
						
					when others =>
						STEP <= STEP0;
				end case;
			end if;
		end if;
	end process;

	LD_WR <= LOADER_WR;
	LD_ADDR <= LOADER_ADDR;
	DBG_REG_WR <= REG_WR;

end rtl;