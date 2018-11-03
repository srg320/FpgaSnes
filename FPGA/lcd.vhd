library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;

entity lcd is
	port(
		CLK 		: in std_logic;
		LCDCLK 		: in std_logic;
		RST_N 		: in std_logic;
		FRAME		: in std_logic;
		PIX_IN		: in std_logic_vector(14 downto 0);
		PPU_X: in std_logic_vector(8 downto 0);
		PPU_Y: in std_logic_vector(8 downto 0);
		V224		: in std_logic;
		
		LCD_R : out std_logic_vector(4 downto 0);
		LCD_G : out std_logic_vector(4 downto 0);
		LCD_B : out std_logic_vector(4 downto 0);
		LCD_DE		: out std_logic;
		LCD_HS		: out std_logic;
		LCD_VS		: out std_logic;
		LCD_DISP		: out std_logic 
	);
end lcd;

architecture rtl of lcd is

constant THPW: integer := 48;
constant THBP: integer := 40;
constant THFP: integer := 40;
constant THD: integer := 800;

constant TVPW: integer := 3;
constant TVBP: integer := 29;
constant TVFP: integer := 13;
constant TVD: integer := 480;

signal Hcount: unsigned(10 downto 0) := (others => '0');
signal Vcount: unsigned(9 downto 0) := (others => '0');
signal Hcount2: unsigned(8 downto 0);

signal wrAddr: std_logic_vector(16 downto 0);
signal rdAddr: std_logic_vector(16 downto 0);
signal data, data2: std_logic_vector(14 downto 0);

signal reset, reset2: std_logic;

begin

wrAddr <= PPU_Y(7 downto 0) & PPU_X;
rdAddr <= std_logic_vector((239 - Vcount(8 downto 1)) & (not Hcount2));
	
lcdbuf : entity work.lcdbuf
port map(
	wrclock		=> CLK,
	wraddress	=> wrAddr(16 downto 0),
	data			=> PIX_IN,
	wren			=> FRAME,
	
	rdclock		=> LCDCLK,
	rdaddress	=> rdAddr(16 downto 0),
	q				=> data
);

process(LCDCLK, RST_N)
begin
	if RST_N = '0' then
		Hcount <= (others => '0');
		Vcount <= (others => '0');
		Hcount2 <= (others => '0');
	elsif rising_edge(LCDCLK) then
		if (Hcount < (THD+THFP+THPW+THBP)) then
			Hcount <= Hcount + 1;
			if (Hcount < 512) then
				Hcount2 <= Hcount2 + 1;
			else
				Hcount2 <= (others => '0');
			end if;
		else
			if (Vcount < (TVD+TVFP+TVPW+TVBP)) then
				Vcount <= Vcount + 1;
			else
				Vcount <= (others => '0');
			end if;
			Hcount <= (others => '0');
		end if;
	end if;
end process;


process(data, Hcount, Vcount, V224)
begin
	if Hcount >= 256*2 or (V224 = '1' and Vcount < 16*2) then
		LCD_R <= (others => '0');
		LCD_G <= (others => '0');
		LCD_B <= (others => '0');
	else
		LCD_R <= data(4 downto 0);
		LCD_G <= data(9 downto 5);
		LCD_B <= data(14 downto 10);
	end if;
end process;


LCD_HS <= '0' when Hcount >= THD+THFP and Hcount < THPW else '1';
LCD_VS <= '0' when Vcount >= TVD+TVFP and Vcount < TVPW else '1';
LCD_DE <= '1' when ((Hcount < THD) and (Vcount < TVD)) else '0';
 
LCD_DISP <= '1';


end rtl;
