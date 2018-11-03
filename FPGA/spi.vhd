library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_slave is
	port(
		CLK 		: in std_logic;
		SCK		: in std_logic;
		MOSI		: in std_logic;
		MISO		: out std_logic;
		SSEL		: in std_logic;
		DATA_IN	: in std_logic_vector(7 downto 0);
		DATA_OUT	: out std_logic_vector(7 downto 0);
		RDY		: out std_logic
	);
end spi_slave;

architecture rtl of spi_slave is

signal ready		: std_logic;

signal SSELr : std_logic_vector(2 downto 0);
signal SSEL_active	: std_logic;
signal SSEL_endmessage	: std_logic;
signal SCKr : std_logic_vector(2 downto 0);
signal SCK_risingedge	: std_logic;
signal SCK_fallingedge	: std_logic;
signal MOSIr : std_logic_vector(1 downto 0);
signal MOSI_data	: std_logic;

signal bitcnt : std_logic_vector(3 downto 0);
signal byte_data_received : std_logic_vector(7 downto 0);
signal byte_data_sent : std_logic_vector(7 downto 0);

begin

process( CLK )
begin
	if rising_edge(CLK) then
		SSELr <= SSELr(1 downto 0) & SSEL;
		SCKr <= SCKr(1 downto 0) & SCK;
	end if;
end process;

SSEL_endmessage <= '1' when SSELr(2 downto 1) = "01" else '0';
SCK_risingedge <= '1' when SCKr(2 downto 1) = "01" else '0';


process( SSEL_endmessage,CLK )
begin
	if rising_edge(CLK) then
		if SSEL_endmessage = '1' then
		bitcnt <= (others => '0');
		ready <= '0';
		byte_data_sent <= DATA_IN;
		elsif SCK_risingedge = '1' then
			ready <= '0';
			bitcnt <= bitcnt + 1;
			byte_data_received <= byte_data_received(6 downto 0) & MOSI;
			if bitcnt = 7 then
				DATA_OUT <= byte_data_received(6 downto 0) & MOSI;
				bitcnt <= (others => '0');
				ready <= '1';
				byte_data_sent <= DATA_IN;
			end if;
		end if;
	end if;
end process;


MISO <= byte_data_sent(7-CONV_INTEGER(bitcnt));
RDY <= ready; 

end rtl;