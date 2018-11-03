library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.CONV_STD_LOGIC_VECTOR; 
use ieee.numeric_std.all;


entity SNES_tb is
end SNES_tb;

architecture behavior of SNES_tb is
 
	signal CLK_21M, CLK_24M : std_logic;
	signal RST_N : std_logic := '0';

	signal CA : std_logic_vector(23 downto 0);
	signal CPURD_N	: std_logic;
	signal CPUWR_N	: std_logic;
	signal DI : std_logic_vector(7 downto 0);
	signal DO : std_logic_vector(7 downto 0);
	signal RAMSEL_N : std_logic;
	signal ROMSEL_N : std_logic;
	signal IRQ_N : std_logic;
	signal PA : std_logic_vector(7 downto 0);
	signal PARD_N : std_logic;
	signal PAWR_N : std_logic;
	signal SYSCLK : std_logic;
	signal REFRESH	: std_logic;
	
	signal DOTCLK : std_logic;
	signal HBLANK, VBLANK : std_logic;
	signal FRAME_OUT : std_logic;
	signal V224_MODE : std_logic;
	signal RGB_OUT : std_logic_vector(14 downto 0);
	signal X_OUT : std_logic_vector(8 downto 0);
	signal Y_OUT : std_logic_vector(8 downto 0);
	
	signal CART_SRAM1_ADDR, CART_SRAM2_ADDR : std_logic_vector(21 downto 0);
	signal CART_SRAM1_DQ, CART_SRAM2_DQ : std_logic_vector(7 downto 0);
	signal CART_SRAM1_WE_N, CART_SRAM2_WE_N : std_logic;
	signal ROM1_A, ROM2_A : std_logic_vector(15 downto 0);
	signal ROM1_DO, ROM2_DO : std_logic_vector(7 downto 0);
	
	signal WSRAM_ADDR	: std_logic_vector(16 downto 0);
	signal WSRAM_DQ : std_logic_vector(7 downto 0);
	signal WSRAM_WE_N	: std_logic;
	signal WRAM_DI, WRAM_DO : std_logic_vector(7 downto 0);
	signal WRAM_WE	: std_logic;
		
	signal VRAM_ADDRA, VRAM_ADDRB, VRAM_ADDR : std_logic_vector(15 downto 0);
	signal VRAM_DAO, VRAM_DBO : std_logic_vector(7 downto 0);
	signal VRAM_DAI, VRAM_DBI, VRAM_DBI_TEMP : std_logic_vector(7 downto 0);
	signal VRAM_RD_N : std_logic;
	signal VRAM_WRA_N, VRAM_WRB_N : std_logic;
	signal VRAM_WE_N : std_logic;
	signal VRAM1_WE, VRAM2_WE : std_logic;
	
	signal ARAM_ADDR : std_logic_vector(15 downto 0);
	signal ARAM_DQ : std_logic_vector(7 downto 0);
	signal ARAM_WE_N : std_logic;
	signal ARAM_DI, ARAM_DO : std_logic_vector(7 downto 0) := (others => '0');
	signal ARAM_WE	: std_logic;

begin

	process
	begin
		CLK_21M <= '0';
		wait for 24 ns;  --for 0.5 ns signal is '0'.
		CLK_21M <= '1';
		wait for 24 ns;  --for next 0.5 ns signal is '1'.
	end process;
  
	process
	begin
		CLK_24M <= '0';
		wait for 21 ns;  --for 0.5 ns signal is '0'.
		CLK_24M <= '1';
		wait for 21 ns;  --for next 0.5 ns signal is '1'.
	end process;
  
	process
	begin         
		RST_N <='0';
		wait for 100 ns;
		RST_N <='1';
		wait;
	end process;	


	SNES : entity work.SNES
	port map(
		MCLK				=> CLK_21M,
		DSPCLK			=> CLK_24M,
		RST_N				=> RST_N,
		ENABLE			=> '1',
		PAL				=> '0',
		
		CA     			=> CA,
		CPURD_N			=> CPURD_N,
		CPUWR_N			=> CPUWR_N,
			
		PA					=> PA,
		PARD_N			=> PARD_N,
		PAWR_N			=> PAWR_N,
		DI					=> DI,
		DO					=> DO,
			
		RAMSEL_N			=> RAMSEL_N,
		ROMSEL_N			=> ROMSEL_N,
			
		SYSCLK			=> SYSCLK,
		REFRESH			=> REFRESH,
			
		IRQ_N				=> IRQ_N,
			
		WSRAM_ADDR		=> WSRAM_ADDR,
		WSRAM_DQ			=> WSRAM_DQ,
		WSRAM_WE_N		=> WSRAM_WE_N,
			
		VRAM_ADDRA		=> VRAM_ADDRA,
		VRAM_ADDRB		=> VRAM_ADDRB,
		VRAM_DAI			=> VRAM_DAI,
		VRAM_DBI			=> VRAM_DBI,
		VRAM_DAO			=> VRAM_DAO,
		VRAM_DBO			=> VRAM_DBO,
		VRAM_RD_N		=> VRAM_RD_N,
		VRAM_WRA_N		=> VRAM_WRA_N,
		VRAM_WRB_N		=> VRAM_WRB_N,
			
		ARAM_ADDR		=> ARAM_ADDR,
		ARAM_DQ			=> ARAM_DQ,
		ARAM_WE_N		=> ARAM_WE_N,
			
		JOY1_DI			=> "11",
		JOY2_DI			=> "11",
		
		DOTCLK			=> DOTCLK,
		HBLANK			=> HBLANK,
		VBLANK			=> VBLANK,
			
		RGB_OUT			=> RGB_OUT,
		FRAME_OUT		=> FRAME_OUT,
		X_OUT				=> X_OUT,
		Y_OUT				=> Y_OUT,
		V224_MODE		=> V224_MODE,
		
		DBG_SEL			=> (others => '0'),
		DBG_REG			=> (others => '0'),
		DBG_REG_WR		=> '0',
		DBG_DAT_IN		=> (others => '0')
	);
	
	--WRAM
	WRAM: entity work.MemRam
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 13
	)
	port map (
		clk         => CLK_21M,
		we          => WRAM_WE,
		data_in     => WRAM_DI,
		data_out    => WRAM_DO,
		address     => WSRAM_ADDR(12 downto 0)
	);
	WRAM_WE <= not WSRAM_WE_N;
	WRAM_DI <= WSRAM_DQ;
	WSRAM_DQ	<= WRAM_DO when WSRAM_WE_N = '1' else "ZZZZZZZZ";
	
	--VRAM
	process( CLK_21M )
	begin
		if falling_edge( CLK_21M ) then
			if DOTCLK = '0' then
				VRAM_DBI <= VRAM_DBI_TEMP;
			end if;
		end if;
	end process;
	
	VRAM_ADDR <= VRAM_ADDRB when DOTCLK = '0' and VRAM_RD_N = '0' else VRAM_ADDRA; 
	
	VRAM1: entity work.MemRam
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 15
	)
	port map (
		clk         => CLK_21M,
		we          => VRAM1_WE,
		data_in     => VRAM_DAO,
		data_out    => VRAM_DAI,
		address     => VRAM_ADDR(14 downto 0)
	); 
	VRAM1_WE <= not VRAM_WRA_N;
	
	VRAM2: entity work.MemRam
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 15
	)
	port map (
		clk         => CLK_21M,
		we          => VRAM2_WE,
		data_in     => VRAM_DBO,
		data_out    => VRAM_DBI_TEMP,
		address     => VRAM_ADDR(14 downto 0)
	); 
	VRAM2_WE <= not VRAM_WRB_N;
	
	--ARAM
	ARAM: entity work.MemRam
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 16
	)
	port map (
		clk         => CLK_24M,
		we          => ARAM_WE,
		data_in     => ARAM_DI,
		data_out    => ARAM_DO,
		address     => ARAM_ADDR
	);
	ARAM_WE <= not ARAM_WE_N;
	ARAM_DI <= ARAM_DQ;
	ARAM_DQ	<= ARAM_DO when ARAM_WE_N = '1' else "ZZZZZZZZ";


	SMAP : entity work.LHRomMap
	--SMAP : entity work.SDD1Map
	--SMAP : entity work.DSPMap
	--SMAP : entity work.CX4Map
	port map(
		CLK100			=> CLK_21M,
		MCLK				=> CLK_21M,
		RST_N				=> RST_N,
		ENABLE			=> '1',
		
		CA					=> CA,
		DI					=> DO,
		DO					=> DI,
		CPURD_N			=> CPURD_N,
		CPUWR_N			=> CPUWR_N,
		
		PA					=> PA,
		PARD_N			=> PARD_N,
		PAWR_N			=> PAWR_N,
		
		ROMSEL_N			=> ROMSEL_N,
		RAMSEL_N			=> RAMSEL_N,
		
		SYSCLK			=> SYSCLK,
		REFRESH			=> REFRESH,

		IRQ_N				=> IRQ_N,
		
		SRAM1_ADDR		=> CART_SRAM1_ADDR,
		SRAM1_DQ			=> CART_SRAM1_DQ,
		SRAM1_WE_N		=> CART_SRAM1_WE_N,
		
		SRAM2_ADDR		=> CART_SRAM2_ADDR,
		SRAM2_DQ			=> CART_SRAM2_DQ,
		SRAM2_WE_N		=> CART_SRAM2_WE_N,
		
		MAP_CTRL			=> x"00",
		ROM_MASK			=> (others => '1'),
		BSRAM_MASK		=> (others => '0'),
		
		LD_ADDR     	=> (others => '0'),
		LD_DI     		=> (others => '0'),
		LD_WR     		=> '0',
		LD_EN     		=> '0',
		
		DBG_REG  		=> (others => '0'),
		DBG_DAT_IN		=> (others => '0'),
		DBG_DAT_WR		=> '0'
	);

	--CART ROM
	ROM1_A <= CART_SRAM1_ADDR(14 downto 0) & "0"; 
	ROM1: entity work.Memory
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 16,
		IMAGE         => "sdd1.txt"
	)
	port map (
		clk         => CLK_21M,
		we          => '0',
		data_in     => (others=>'0'),
		data_out    => ROM1_DO,
		address     => ROM1_A
	); 
	CART_SRAM1_DQ <= ROM1_DO;
	
	ROM2_A <= CART_SRAM1_ADDR(14 downto 0) & "1"; 
	ROM2: entity work.Memory
	generic map (
		DATA_WIDTH    => 8,
		ADDR_WIDTH    => 16,
		IMAGE         => "sdd1.txt"
	)
	port map (
		clk         => CLK_21M,
		we          => '0',
		data_in     => (others=>'0'),
		data_out    => ROM2_DO,
		address     => ROM2_A
	); 
	CART_SRAM2_DQ <= ROM2_DO;

end behavior;
