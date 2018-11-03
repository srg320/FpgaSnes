library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library STD;
use IEEE.NUMERIC_STD.ALL;
use work.PPU_PKG.all;

entity SPPU is
	port(
		RST_N			: in std_logic;
		CLK			: in std_logic;
		
		ENABLE		: in std_logic;
		
		PA				: in std_logic_vector(7 downto 0);
		PARD_N		: in std_logic;
		PAWR_N		: in std_logic;
		DI				: in std_logic_vector(7 downto 0);
		DO				: out std_logic_vector(7 downto 0);
		
		VRAM_ADDRA	: out std_logic_vector(15 downto 0);
		VRAM_ADDRB	: out std_logic_vector(15 downto 0);
		VRAM_DAI		: in std_logic_vector(7 downto 0);
		VRAM_DBI		: in std_logic_vector(7 downto 0);
		VRAM_DAO		: out std_logic_vector(7 downto 0);
		VRAM_DBO		: out std_logic_vector(7 downto 0);
		VRAM_WRA_N	: out std_logic;
		VRAM_WRB_N	: out std_logic;
		VRAM_RD_N	: out std_logic;
		
		EXTLATCH		: in std_logic;
		
		PAL			: in std_logic;
		
		DOTCLK		: out std_logic;
		
		HBLANK		: out std_logic;
		VBLANK		: out std_logic;

		COLOR_OUT	: out std_logic_vector(14 downto 0);	-- RGB 5:5:5
		X_OUT			: out std_logic_vector(8 downto 0);
		Y_OUT			: out std_logic_vector(8 downto 0);
		FRAME_OUT	: out std_logic;
		V224			: out std_logic;
		
		--debug
		DBG_REG		: in std_logic_vector(7 downto 0);
		DBG_DAT_OUT	: out std_logic_vector(7 downto 0);
		DBG_DAT_IN	: in std_logic_vector(7 downto 0);
		DBG_DAT_WR	: in std_logic;
		DBG_BRK		: out std_logic
	);
end SPPU;

architecture rtl of SPPU is

signal DOT_CLK : std_logic := '0';
signal CLK_CNT : unsigned(2 downto 0) := (others => '0');
signal IO_CLK, IO_CLKN : std_logic;
signal MDR1, MDR2	: std_logic_vector(7 downto 0);

signal PAWR_Nr, PARD_Nr	: std_logic;
signal REG : std_logic_vector(7 downto 0);

-- Registers
signal FORCE_BLANK : std_logic;
signal MB : std_logic_vector(3 downto 0);
signal OBJADDR : std_logic_vector(2 downto 0);
signal OBJNAME : std_logic_vector(1 downto 0);
signal OBJSIZE : std_logic_vector(2 downto 0);
signal OAMADD : std_logic_vector(8 downto 0);
signal OAM_PRIO : std_logic;
signal TM : std_logic_vector(7 downto 0);
signal TS : std_logic_vector(7 downto 0);
signal BGINTERLACE : std_logic;
signal OBJINTERLACE : std_logic;
signal OVERSCAN : std_logic;
signal PSEUDOHIRES : std_logic;
signal M7EXTBG	: std_logic;
signal BG_MODE	: std_logic_vector(2 downto 0);
signal BG3PRIO	: std_logic;
signal BG_SIZE	: std_logic_vector(3 downto 0);
signal BG_MOSAIC_EN : std_logic_vector(3 downto 0);
signal MOSAIC_SIZE : std_logic_vector(3 downto 0);
signal BG_SC_ADDR	: BgScAddr_t;
signal BG_SC_SIZE	: BgScSize_t;
signal BG_NBA : BgTileAddr_t;
signal CGADD : std_logic_vector(8 downto 0);
signal VMAIN_ADDRINC : std_logic;
signal VMAIN_ADDRTRANS : std_logic_vector(1 downto 0);
signal VMADD : std_logic_vector(15 downto 0);

signal BG_HOFS: BgScroll_t;
signal BG_VOFS: BgScroll_t;

signal M7SEL: std_logic_vector(7 downto 0);
signal M7A: std_logic_vector(15 downto 0);
signal M7B: std_logic_vector(15 downto 0);
signal M7C: std_logic_vector(15 downto 0);
signal M7D: std_logic_vector(15 downto 0);
signal M7HOFS: std_logic_vector(12 downto 0);
signal M7VOFS: std_logic_vector(12 downto 0);
signal M7X: std_logic_vector(12 downto 0);
signal M7Y: std_logic_vector(12 downto 0);
signal MPYL: std_logic_vector(7 downto 0);
signal MPYM: std_logic_vector(7 downto 0);
signal MPYH: std_logic_vector(7 downto 0);

signal WH0 : std_logic_vector(7 downto 0);
signal WH1 : std_logic_vector(7 downto 0);
signal WH2 : std_logic_vector(7 downto 0);
signal WH3 : std_logic_vector(7 downto 0);
signal W12SEL : std_logic_vector(7 downto 0);
signal W34SEL : std_logic_vector(7 downto 0);
signal WOBJSEL : std_logic_vector(7 downto 0);
signal WBGLOG : std_logic_vector(7 downto 0);
signal WOBJLOG : std_logic_vector(7 downto 0);
signal TMW : std_logic_vector(7 downto 0);
signal TSW : std_logic_vector(7 downto 0);
signal CGWSEL : std_logic_vector(7 downto 0);
signal CGADSUB	: std_logic_vector(7 downto 0);

signal OPHCT : std_logic_vector(8 downto 0);
signal OPVCT : std_logic_vector(8 downto 0);

signal OPHCT_latch : std_logic;
signal OPVCT_latch : std_logic;
signal CGRAM_Lsb : std_logic_vector(7 downto 0);
signal BGOFS_latch : std_logic_vector(7 downto 0);
signal M7_latch : std_logic_vector(7 downto 0);
signal BGHOFS_latch : std_logic_vector(2 downto 0);
signal OAM_latch : std_logic_vector(7 downto 0);
signal VRAMDATA_Prefetch : std_logic_vector(15 downto 0);
signal VMADD_INC : unsigned(7 downto 0);
signal F_LATCH : std_logic;
signal OBJ_TIME_OFL : std_logic;
signal OBJ_RANGE_OFL : std_logic;

signal VMADD_TRANS : std_logic_vector(15 downto 0);
signal VRAM1_WRITE, VRAM2_WRITE : std_logic;
signal VRAM_ADDR_INC : std_logic;
signal EXTLATCHr : std_logic;

-- HV COUNTERS
signal H_CNT : unsigned(8 downto 0);
signal V_CNT : unsigned(8 downto 0);
signal FIELD : std_logic;

signal LAST_VIS_LINE : unsigned(8 downto 0);
signal IN_HBL : std_logic;
signal IN_VBL : std_logic;

-- BACKGROUND
signal BG_VRAM_ADDRA, BG_VRAM_ADDRB : std_logic_vector(15 downto 0);
signal BG_VRAM_FETCH : std_logic;
signal SPR_GET_PIXEL, BG_GET_PIXEL, BG_MOSAIC, BG_MATH,  BG_OUT : std_logic;
signal GET_PIXEL_X, WINDOW_X, OUT_X, OUT_Y	: unsigned(7 downto 0);
signal BG_MOSAIC_X : unsigned(3 downto 0);
signal BG_MOSAIC_Y : unsigned(3 downto 0);
signal BF : BgFetch_r;
signal BG3_OPT_DATA0 : std_logic_vector(15 downto 0);
signal BG3_OPT_DATA1 : std_logic_vector(15 downto 0);
signal BG_DATA : BgData_t;
signal BG_TILE_INFO : BgTileInfo_t;

type BgPlanes_t is array(0 to 11) of std_logic_vector(7 downto 0);
type BgTileInfo_r is record
	PLANES : BgPlanes_t;
	ATR : BgTileAtr_t;
end record;
type BgTileInfos_t is array(0 to 1) of BgTileInfo_r;
signal BG_TILES : BgTileInfos_t;

signal BG1_PIX_DATA : std_logic_vector(11 downto 0);
signal BG2_PIX_DATA : std_logic_vector(7 downto 0);
signal BG3_PIX_DATA, BG4_PIX_DATA : std_logic_vector(5 downto 0);

signal M7_TEMP_X, M7_TEMP_Y : signed(23 downto 0);
signal MPY, MPY2 : signed(23 downto 0);
signal M7_TILE_N : unsigned(7 downto 0);
signal M7_TILE_ROW, M7_TILE_COL : unsigned(2 downto 0);
signal M7_TILE_OUTSIDE : std_logic;

-- OBJ
signal OAM_D : std_logic_vector(15 downto 0);
signal OAM_Q_A : std_logic_vector(15 downto 0);
signal OAM_Q_B : std_logic_vector(31 downto 0);
signal OAM_ADDR_A : std_logic_vector(7 downto 0);
signal OAM_ADDR_B : std_logic_vector(6 downto 0);
signal OAM_WE : std_logic;
signal HOAM_Q_A : std_logic_vector(7 downto 0);
signal HOAM_Q_B : std_logic_vector(1 downto 0);
signal HOAM_ADDR_B : std_logic_vector(6 downto 0);
signal HOAM_ADDR_A : std_logic_vector(4 downto 0);
signal HOAM_WE : std_logic;

signal OAM_ADDR : std_logic_vector(9 downto 0);
signal OAM_RANGE : RangeOam_t;
signal OAM_OBJ : Sprite_r;
signal SCAN_OAM_ADDR : unsigned(7 downto 0);
signal RANGE_CNT_WR : unsigned(5 downto 0);
signal RANGE_CNT_RD	: unsigned(5 downto 0);
signal TILES_OAM_CNT : unsigned(5 downto 0);
signal TILES_CNT : unsigned(2 downto 0);
signal SPR_TILES : SprTiles_t;

signal OBJ_RANGE, OBJ_TIME: std_logic;
signal OBJ_RANGE_DONE : std_logic;

signal SPR_PIX_DATA, SPR_PIX_DATA_BUF : std_logic_vector(8 downto 0);
signal SPR_PIXEL_X : unsigned(7 downto 0);
signal OBJ_VRAM_ADDR : std_logic_vector(15 downto 0);

--type Oam_t is array(0 to 127) of std_logic_vector(31 downto 0);
--signal OAM : Oam_t;
--type Hoam_t is array(0 to 127) of std_logic_vector(1 downto 0);
--signal HOAM : Hoam_t;

-- MATH
signal SUBCOL : std_logic_vector(14 downto 0);
signal MAIN_R, MAIN_G, MAIN_B	: unsigned(4 downto 0);
signal SUB_R, SUB_G, SUB_B	: unsigned(4 downto 0);
signal HIRES : std_logic;

-- CRAM
type Cram_t is array(0 to 255) of std_logic_vector(14 downto 0);
signal CRAM : Cram_t;

signal CRAM_DATA, CRAM_MAIN_DATA, CRAM_SUB_DATA  : std_logic_vector(14 downto 0);
signal CRAM_MAIN_ADDR, CRAM_SUB_ADDR, CRAM_ADDR : std_logic_vector(7 downto 0);
signal CRAM_ADDR_INC: std_logic;

--debug
signal DBG_VRAM_ADDR : std_logic_vector(16 downto 0);
signal DBG_CRAM_ADDR : std_logic_vector(7 downto 0);
signal DBG_OAM_ADDR : std_logic_vector(7 downto 0);
signal DBG_DAT_WRr : std_logic;
signal DBG_CTRL : std_logic_vector(7 downto 0);
signal DBG_RUN_LAST : std_logic;
signal DBG_BRK_HCNT : std_logic_vector(8 downto 0);
signal DBG_BRK_VCNT : std_logic_vector(8 downto 0); 
signal DBG_BG_EN : std_logic_vector(7 downto 0) := (others => '1');
signal DBG_OBJ_EN : std_logic_vector(7 downto 0) := (others => '1');
signal FRAME_CNT: unsigned(15 downto 0);
	
begin

process( RST_N, CLK )
variable DOT_CYCLES: unsigned(2 downto 0);
begin
	if RST_N = '0' then
		CLK_CNT <= (others => '0');
		DOT_CLK <= '0';
		IO_CLK <= '0';
	elsif falling_edge(CLK) then
		if ENABLE = '0' then
			DOT_CYCLES := "100";
		elsif V_CNT = 240 and BGINTERLACE = '0' and FIELD = '1' and PAL = '0' then
			DOT_CYCLES := "100";
		elsif H_CNT = 323 or H_CNT = 327 then
			DOT_CYCLES := "110";
		else
			DOT_CYCLES := "100";
		end if;
			
		CLK_CNT <= CLK_CNT + 1;
		if CLK_CNT = 1  then
			DOT_CLK <= '1';
		elsif CLK_CNT = DOT_CYCLES-1  then
			CLK_CNT <= (others => '0');
			DOT_CLK <= '0';
		end if;
		
		IO_CLK <= not IO_CLK;
	end if;
end process;


IO_CLKN <= not IO_CLK;

process( RST_N, IO_CLK, ENABLE, IN_HBL, IN_VBL, FORCE_BLANK, DOT_CLK, CGADD, CRAM_SUB_ADDR, CRAM_MAIN_ADDR, DBG_CRAM_ADDR )
begin
	if ENABLE = '0' then
		CRAM_ADDR <= DBG_CRAM_ADDR;
	elsif IN_HBL = '1' or IN_VBL = '1' or FORCE_BLANK = '1' then
		CRAM_ADDR <= CGADD(8 downto 1);
	elsif DOT_CLK = '0' then
		CRAM_ADDR <= CRAM_SUB_ADDR;
	else
		CRAM_ADDR <= CRAM_MAIN_ADDR;
	end if;
	
	if RST_N = '0' then
		CRAM <= (others => (others => '0'));
	elsif falling_edge(IO_CLK) then
		if ENABLE = '1' then
			if PAWR_N = '0' and PA = x"22" and CGADD(0) = '1' then
				CRAM(to_integer(unsigned(CRAM_ADDR))) <= DI(6 downto 0) & CGRAM_Lsb;
			end if;
		end if;
	end if;
end process;

CRAM_DATA <= CRAM(to_integer(unsigned(CRAM_ADDR)));

CRAM_MAIN_DATA <= CRAM_DATA;
process( RST_N, DOT_CLK )
begin
	if RST_N = '0' then
		CRAM_SUB_DATA  <= (others => '0');
	elsif rising_edge(DOT_CLK) then
		if ENABLE = '1' then
			CRAM_SUB_DATA  <= CRAM_DATA;
		end if;
	end if;
end process;

OAM : entity work.ppuoam
port map(
	clock			=> IO_CLKN,
	data_a		=> OAM_D,
	data_b		=> (others => '0'),
	address_a	=> OAM_ADDR_A,
	address_b	=> OAM_ADDR_B,
	wren_a		=> OAM_WE,
	wren_b		=> '0',
	q_a			=> OAM_Q_A,
	q_b			=> OAM_Q_B
);
OAM_D <= DI & OAM_latch;
OAM_ADDR_A <= OAM_ADDR(8 downto 1) when ENABLE = '1' else DBG_OAM_ADDR;
OAM_ADDR_B <= std_logic_vector(SCAN_OAM_ADDR(7 downto 1));
OAM_WE <= ENABLE when OAM_ADDR(0) = '1' and OAM_ADDR(9) = '0' and PAWR_N = '0' and PA = x"04" else '0';

HOAM : entity work.ppuhoam
port map(
	clock			=> IO_CLKN,
	data_a		=> DI,
	data_b		=> (others => '0'),
	address_a	=> HOAM_ADDR_A,
	address_b	=> HOAM_ADDR_B,
	wren_a		=> HOAM_WE,
	wren_b		=> '0',
	q_a			=> HOAM_Q_A,
	q_b			=> HOAM_Q_B
);
HOAM_ADDR_A <= OAM_ADDR(4 downto 0) when ENABLE = '1' else DBG_OAM_ADDR(4 downto 0);
HOAM_ADDR_B <= std_logic_vector(SCAN_OAM_ADDR(7 downto 1));
HOAM_WE <= ENABLE when OAM_ADDR(9) = '1' and PAWR_N = '0' and PA = x"04" else '0';


LAST_VIS_LINE <= '0' & x"E0" when OVERSCAN = '0' else '0' & x"EF";

process( RST_N, IO_CLK )
begin
	if RST_N = '0' then
		PAWR_Nr <= '1';
		PARD_Nr <= '1';
	elsif falling_edge(IO_CLK) then
		PAWR_Nr <= PAWR_N;
		PARD_Nr <= PARD_N;
	end if;
end process;

process( RST_N, IO_CLK )
begin
	if RST_N = '0' then
		REG <= (others => '1');
		
		FORCE_BLANK <= '1';
		MB <= (others => '0');
		OBJADDR <= (others => '0');
		OBJNAME <= (others => '0');
		OBJSIZE <= (others => '0');
		OAMADD <= (others => '0');
		TM <= (others => '0');
		TS <= (others => '0');
		BGINTERLACE <= '0';
		OBJINTERLACE <= '0';
		OVERSCAN <= '0';
		PSEUDOHIRES <= '0';
		M7EXTBG <= '0';
		BG_MODE <= (others => '0'); 
		BG3PRIO <= '0';
		BG_SIZE <= (others => '0');
		BG_MOSAIC_EN <= (others => '0');
		MOSAIC_SIZE <= (others => '0');
		BG_SC_ADDR <= (others => (others => '0'));
		BG_SC_SIZE <= (others => (others => '0'));
		BG_NBA <= (others => (others => '0'));
		CGADD <= (others => '0');
		VMAIN_ADDRINC <= '0';
		VMAIN_ADDRTRANS <= (others => '0');
		VMADD <= (others => '0');
		BG_HOFS <= (others => (others => '0'));
		BG_VOFS <= (others => (others => '0'));
		M7SEL <= (others => '0');
		M7A <= (others => '0');
		M7B <= (others => '0');
		M7C <= (others => '0');
		M7D <= (others => '0');
		M7HOFS <= (others => '0');
		M7VOFS <= (others => '0');
		M7X <= (others => '0');
		M7Y <= (others => '0');
		WH0 <= (others => '0');
		WH1 <= (others => '0');
		WH2 <= (others => '0');
		WH3 <= (others => '0');
		W12SEL <= (others => '0');
		W34SEL <= (others => '0');
		WOBJSEL <= (others => '0');
		WBGLOG <= (others => '0');
		WOBJLOG <= (others => '0');
		TMW <= (others => '0');
		TSW <= (others => '0');
		CGWSEL <= (others => '0');
		CGADSUB <= (others => '0');
		OPHCT <= (others => '0');
		OPVCT <= (others => '0');
		SUBCOL <= (others => '0');
		
		VRAMDATA_Prefetch <= (others => '0');
		VMADD_INC <= x"01";
		
		OPHCT_latch <= '0';
		OPVCT_latch <= '0';
		F_LATCH <= '0';
		M7_latch <= (others => '0');
		BGOFS_latch <= (others => '0');
		BGHOFS_latch <= (others => '0');
		EXTLATCHr <= '1';
		
		OAM_ADDR <= (others => '0');
		OAM_PRIO <= '0';
		OAM_latch <= (others => '0');
		
		CGRAM_Lsb <= (others => '0');
		
		MDR1 <= (others => '1');
		MDR2 <= (others => '1');
		
	elsif falling_edge(IO_CLK) then
		if PAWR_N = '0' and PAWR_Nr = '1' then
			REG <= PA;
			case PA is
				when x"00" =>						--INIDISP
					FORCE_BLANK <= DI(7);
					MB <= DI(3 downto 0);
				when x"01" =>						--OBSEL
					OBJADDR <= DI(2 downto 0);
					OBJNAME <= DI(4 downto 3);
					OBJSIZE <= DI(7 downto 5);
				when x"02" =>						--OAMADDL
					OAMADD(7 downto 0) <= DI;
				when x"03" =>						--OAMADDH
					OAMADD(8) <= DI(0);
					OAM_PRIO <= DI(7);
				when x"04" =>						--OAMDI
					if OAM_ADDR(9) = '0' and OAM_ADDR(0) = '0' then
						OAM_latch <= DI;
					end if;
				when x"05" =>						--BGMODE
					BG_MODE <= DI(2 downto 0);
					BG3PRIO <= DI(3);
					BG_SIZE <= DI(7 downto 4);
				when x"06" =>						--MOSAIC
					BG_MOSAIC_EN <= DI(3 downto 0);
					MOSAIC_SIZE <= DI(7 downto 4);
				when x"07" =>						--BG1SC
					BG_SC_SIZE(BG1) <= DI(1 downto 0);
					BG_SC_ADDR(BG1) <= DI(7 downto 2);
				when x"08" =>						--BG2SC
					BG_SC_SIZE(BG2) <= DI(1 downto 0);
					BG_SC_ADDR(BG2) <= DI(7 downto 2);
				when x"09" =>						--BG3SC
					BG_SC_SIZE(BG3) <= DI(1 downto 0);
					BG_SC_ADDR(BG3) <= DI(7 downto 2);
				when x"0A" =>						--BG4SC
					BG_SC_SIZE(BG4) <= DI(1 downto 0);
					BG_SC_ADDR(BG4) <= DI(7 downto 2);
				when x"0B" =>						--BG12NBA
					BG_NBA(BG1) <= DI(3 downto 0);
					BG_NBA(BG2) <= DI(7 downto 4);
				when x"0C" =>						--BG34NBA
					BG_NBA(BG3) <= DI(3 downto 0);
					BG_NBA(BG4) <= DI(7 downto 4);
				when x"0D" =>						--BG1HOFS
					BGOFS_latch <= DI;
					BGHOFS_latch <= DI(2 downto 0);
					BG_HOFS(BG1) <= DI(1 downto 0) & BGOFS_latch(7 downto 3) & BGHOFS_latch;
					
					M7_latch <= DI;
					M7HOFS <= DI(4 downto 0) & M7_latch;
				when x"0E" =>						--BG1VOFS
					BGOFS_latch <= DI;
					BG_VOFS(BG1) <= DI(1 downto 0) & BGOFS_latch;
					
					M7_latch <= DI;
					M7VOFS <= DI(4 downto 0) & M7_latch;
				when x"0F" =>						--BG2HOFS
					BGOFS_latch <= DI;
					BGHOFS_latch <= DI(2 downto 0);
					BG_HOFS(BG2) <= DI(1 downto 0) & BGOFS_latch(7 downto 3) & BGHOFS_latch;
				when x"10" =>						--BG2VOFS
					BGOFS_latch <= DI;
					BG_VOFS(BG2) <= DI(1 downto 0) & BGOFS_latch;
				when x"11" =>						--BG3HOFS
					BGOFS_latch <= DI;
					BGHOFS_latch <= DI(2 downto 0);
					BG_HOFS(BG3) <= DI(1 downto 0) & BGOFS_latch(7 downto 3) & BGHOFS_latch;
				when x"12" =>						--BG3VOFS
					BGOFS_latch <= DI;
					BG_VOFS(BG3) <= DI(1 downto 0) & BGOFS_latch;
				when x"13" =>						--BG4HOFS
					BGOFS_latch <= DI;
					BGHOFS_latch <= DI(2 downto 0);
					BG_HOFS(BG4) <= DI(1 downto 0) & BGOFS_latch(7 downto 3) & BGHOFS_latch;
				when x"14" =>						--BG4VOFS
					BGOFS_latch <= DI;
					BG_VOFS(BG4) <= DI(1 downto 0) & BGOFS_latch;
				when x"15" =>						--VMAIN
					VMAIN_ADDRINC <= DI(7);
					VMAIN_ADDRTRANS <= DI(3 downto 2);
					case DI(1 downto 0) is
						when "00" =>
							VMADD_INC <= x"01";
						when "01" =>
							VMADD_INC <= x"20";
						when others =>
							VMADD_INC <= x"80";
					end case;
				when x"16" =>						--VMADDL
					VMADD(7 downto 0) <= DI;
				when x"17" =>						--VMADDH
					VMADD(15 downto 8) <= DI;
--				when x"18" =>						--VMDIL
--				when x"19" =>						--VMDIH
				when x"1A" =>						--M7SEL
					M7SEL <= DI;
				when x"1B" =>						--M7A
					M7_latch <= DI;
					M7A <= DI & M7_latch;
				when x"1C" =>						--M7B
					M7_latch <= DI;
					M7B <= DI & M7_latch;
				when x"1D" =>						--M7C
					M7_latch <= DI;
					M7C <= DI & M7_latch;
				when x"1E" =>						--M7D
					M7_latch <= DI;
					M7D <= DI & M7_latch;
				when x"1F" =>						--M7X
					M7_latch <= DI;
					M7X <= DI(4 downto 0) & M7_latch;
				when x"20" =>						--M7Y
					M7_latch <= DI;
					M7Y <= DI(4 downto 0) & M7_latch;
				when x"21" =>						--CGADD
					CGADD <= DI & '0';
				when x"22" =>						--CGDI
					if CGADD(0) = '0' then
						CGRAM_Lsb <= DI;
					end if;
				when x"23" =>						--W12SEL
					W12SEL <= DI;
				when x"24" =>						--W34SEL
					W34SEL <= DI;
				when x"25" =>						--WOBJSEL
					WOBJSEL <= DI;
				when x"26" =>						--WH0
					WH0 <= DI;
				when x"27" =>						--WH1
					WH1 <= DI;
				when x"28" =>						--WH2
					WH2 <= DI;
				when x"29" =>						--WH3
					WH3 <= DI;
				when x"2A" =>						--WBGLOG
					WBGLOG <= DI;
				when x"2B" =>						--WOBJLOG
					WOBJLOG <= DI;
				when x"2C" =>						--TM
					TM <= DI;
				when x"2D" =>						--TS
					TS <= DI;
				when x"2E" =>						--TMW
					TMW <= DI;
				when x"2F" =>						--TSW
					TSW <= DI;
				when x"30" =>						--CGWSEL
					CGWSEL <= DI;
				when x"31" =>						--CGADSUB
					CGADSUB <= DI;
				when x"32" =>						--COLDI
					if DI(7) = '1' then
						SUBCOL(14 downto 10) <= DI(4 downto 0);
					end if;
					if DI(6) = '1' then
						SUBCOL(9 downto 5) <= DI(4 downto 0);
					end if;
					if DI(5) = '1' then
						SUBCOL(4 downto 0) <= DI(4 downto 0);
					end if;
				when x"33" =>						--SETINI
					BGINTERLACE <= DI(0);
					OBJINTERLACE <= DI(1);
					OVERSCAN <= DI(2);
					PSEUDOHIRES <= DI(3);		--Always out H512
					M7EXTBG <= DI(6);
				when others => null;
			end case;
			
		elsif PARD_N = '0' and PARD_Nr = '1' then
			REG <= PA;
			
			case PA is
				when x"34" =>						--MPYL
					MDR1 <= std_logic_vector(MPY(7 downto 0));
				when x"35" =>						--MPYM
					MDR1 <= std_logic_vector(MPY(15 downto 8));
				when x"36" =>						--MPYH
					MDR1 <= std_logic_vector(MPY(23 downto 16));
				when x"37" =>						--SLHV
					if EXTLATCH = '1' then
						OPHCT <= std_logic_vector(H_CNT);
						OPVCT <= std_logic_vector(V_CNT);	
						F_LATCH <= '1';
					end if;
				when x"38" =>						--RDOAM
					if OAM_ADDR(9) = '0' then
						if OAM_ADDR(0) = '0' then
							MDR1 <= OAM_Q_A(7 downto 0);
						else
							MDR1 <= OAM_Q_A(15 downto 8);
						end if;
					else
						MDR1 <= HOAM_Q_A;
					end if;
				when x"39" =>						--RDVRAML
					MDR1 <= VRAMDATA_Prefetch(7 downto 0);
				when x"3A" =>						--RDVRAMH
					MDR1 <= VRAMDATA_Prefetch(15 downto 8);
				when x"3B" =>						--RDCGRAM
					if CGADD(0) = '0' then
						MDR2 <= CRAM_DATA(7 downto 0);
					else
						MDR2 <= MDR2(7) & CRAM_DATA(14 downto 8);
					end if;
				when x"3C" =>						--OPHCT
					if OPHCT_latch = '0' then
						MDR2 <= OPHCT(7 downto 0);
					else
						MDR2 <= MDR2(7 downto 1) & OPHCT(8);
					end if;
				when x"3D" =>						--OPVCT
					if OPVCT_latch = '0' then
						MDR2 <= OPVCT(7 downto 0);
					else
						MDR2 <= MDR2(7 downto 1) & OPVCT(8);
					end if;
				when x"3E" =>						--STAT77
					MDR1 <= OBJ_TIME_OFL & OBJ_RANGE_OFL & "0" & MDR1(4) & x"1";
				when x"3F" =>						--STAT78
					MDR2 <= FIELD & ((not EXTLATCH) or F_LATCH) & MDR2(5) & PAL & x"3";
				when others => null;
			end case;
				
		elsif PAWR_N = '1' and PAWR_Nr = '0' then
			case REG is
				when x"00" =>						--INIDISP
					if FORCE_BLANK = '1' and V_CNT = LAST_VIS_LINE + 1 then
						OAM_ADDR <= OAMADD & "0";
					end if;
				when x"02" | x"03" =>			--OAMADDL/OAMADDH
					OAM_ADDR <= OAMADD & "0";
				when x"04" =>			--OAMDATA
					OAM_ADDR <= std_logic_vector(unsigned(OAM_ADDR) + 1);
				when x"16" | x"17" =>			--VMADDL/VMADDH
					if FORCE_BLANK = '1' or IN_VBL = '1' then
						VRAMDATA_Prefetch <= VRAM_DBI & VRAM_DAI;
					else
						VRAMDATA_Prefetch <= (others => '0');
					end if;
				when x"18" =>						--VMDATAL
					if VMAIN_ADDRINC = '0' then
						VMADD <= std_logic_vector(unsigned(VMADD) + VMADD_INC);
					end if;
				when x"19" =>						--VMDATAH
					if VMAIN_ADDRINC = '1' then
						VMADD <= std_logic_vector(unsigned(VMADD) + VMADD_INC);
					end if;
				when x"22" =>			--CGDATA
					CGADD <= std_logic_vector(unsigned(CGADD) + 1);
				when others => null;
			end case;
		elsif PARD_N = '1' and PARD_Nr = '0' then
			case REG is
				when x"38" =>			--RDOAM
					OAM_ADDR <= std_logic_vector(unsigned(OAM_ADDR) + 1);
				when x"3B" =>			--RDCGRAM
					CGADD <= std_logic_vector(unsigned(CGADD) + 1);
				when x"39" =>						--RDVRAML
					if VMAIN_ADDRINC = '0' then
						VMADD <= std_logic_vector(unsigned(VMADD) + VMADD_INC);
					
						if FORCE_BLANK = '1' or IN_VBL = '1' then
							VRAMDATA_Prefetch <= VRAM_DBI & VRAM_DAI;
						else
							VRAMDATA_Prefetch <= (others => '0');
						end if;
					end if;
				when x"3A" =>						--RDVRAMH
					if VMAIN_ADDRINC = '1' then
						VMADD <= std_logic_vector(unsigned(VMADD) + VMADD_INC);
					
						if FORCE_BLANK = '1' or IN_VBL = '1' then
							VRAMDATA_Prefetch <= VRAM_DBI & VRAM_DAI;
						else
							VRAMDATA_Prefetch <= (others => '0');
						end if;
					end if;
				when x"3C" =>						--OPHCT
					OPHCT_latch <= not OPHCT_latch;
				when x"3D" =>						--OPVCT
					OPVCT_latch <= not OPVCT_latch;
				when x"3F" =>						--STAT78
					OPHCT_latch <= '0';
					OPVCT_latch <= '0';
					if EXTLATCH = '1' then
						F_LATCH <= '0';
					end if;
				when others => null;
			end case;
		end if;
		
		if (H_CNT = 339 and V_CNT = LAST_VIS_LINE and FORCE_BLANK = '0') then
			OAM_ADDR <= OAMADD & "0";
		end if;
		
		EXTLATCHr <= EXTLATCH;
		if EXTLATCH = '0' and EXTLATCHr = '1' then
			OPHCT <= std_logic_vector(H_CNT);
			OPVCT <= std_logic_vector(V_CNT);	
			F_LATCH <= '1';
		end if;
	end if;
end process;

process( PA, MDR1, MDR2)
begin 
	case PA is
		when x"3B" | x"3C" | x"3D" | x"3F" =>
			DO <= MDR2;
		when others =>
			DO <= MDR1;
	end case;
end process;

				 
VMADD_TRANS <= VMADD(15 downto  8) & VMADD(4 downto 0) & VMADD(7 downto 5) when VMAIN_ADDRTRANS = "01" else 
					VMADD(15 downto  9) & VMADD(5 downto 0) & VMADD(8 downto 6) when VMAIN_ADDRTRANS = "10" else 
					VMADD(15 downto 10) & VMADD(6 downto 0) & VMADD(9 downto 7) when VMAIN_ADDRTRANS = "11" else 
					VMADD(15 downto  0);
					
VRAM1_WRITE <= '1' when PAWR_N = '0' and PA = x"18" and (FORCE_BLANK = '1' or IN_VBL = '1') else '0';
VRAM2_WRITE <= '1' when PAWR_N = '0' and PA = x"19" and (FORCE_BLANK = '1' or IN_VBL = '1') else '0';			

		
VRAM_ADDRA <= DBG_VRAM_ADDR(16 downto 1) when ENABLE = '0' else
				  BG_VRAM_ADDRA when BG_VRAM_FETCH = '1' and FORCE_BLANK = '0'else 
				  OBJ_VRAM_ADDR when OBJ_TIME = '1' and FORCE_BLANK = '0' else
				  VMADD_TRANS;
VRAM_ADDRB <= DBG_VRAM_ADDR(16 downto 1) when ENABLE = '0' else
				  BG_VRAM_ADDRB when BG_VRAM_FETCH = '1' and FORCE_BLANK = '0'else 
				  OBJ_VRAM_ADDR when OBJ_TIME = '1' and FORCE_BLANK = '0' else
				  VMADD_TRANS;				 
				 

VRAM_DAO <= DI;
VRAM_DBO <= DI;
VRAM_RD_N <= '0' when ENABLE = '0' else VRAM1_WRITE or VRAM2_WRITE;
VRAM_WRA_N <= '1' when ENABLE = '0' else not VRAM1_WRITE;
VRAM_WRB_N <= '1' when ENABLE = '0' else not VRAM2_WRITE;


--HV counters
process( RST_N, DOT_CLK )
variable LAST_LINE: unsigned(8 downto 0);
variable LAST_DOT: unsigned(8 downto 0);
begin
	if RST_N = '0' then
		H_CNT <= (others => '0');
		V_CNT <= (others => '0');
		FIELD <= '0';
		FRAME_CNT <= (others => '0');
	elsif falling_edge(DOT_CLK) then
		if ENABLE = '1' then
			if PAL = '0' then
				if BGINTERLACE = '1' and FIELD = '0' then
					LAST_LINE := LINE_NUM_NTSC;
				else
					LAST_LINE := LINE_NUM_NTSC-1;
				end if;
				LAST_DOT := DOT_NUM-1;
			else
				if BGINTERLACE = '1' and FIELD = '0' then
					LAST_LINE := LINE_NUM_PAL;
				else
					LAST_LINE := LINE_NUM_PAL-1;
				end if;
				if V_CNT = 311 and BGINTERLACE = '1' and FIELD = '1' then
					LAST_DOT := DOT_NUM;
				else
					LAST_DOT := DOT_NUM-1;
				end if;
			end if;
			
			H_CNT <= H_CNT + 1;
			if H_CNT = LAST_DOT then
				H_CNT <= (others => '0');
				V_CNT <= V_CNT + 1;			
				if V_CNT = LAST_LINE then
					V_CNT <= (others => '0');
					FIELD <= not FIELD;
					FRAME_CNT <= FRAME_CNT + 1;
				end if;
			end if;
		end if;
	end if;
end process;

IN_VBL <= '1' when V_CNT > LAST_VIS_LINE else '0';
IN_HBL <= '1' when H_CNT >= 274 or H_CNT < 1 else '0';--



process( H_CNT, V_CNT, LAST_VIS_LINE )
begin
	if H_CNT <= (256+16)-1 and V_CNT >= 0 and V_CNT <= LAST_VIS_LINE then
		BG_VRAM_FETCH <= '1';
	else
		BG_VRAM_FETCH <= '0';
	end if;
	
	if H_CNT >= (16) and H_CNT <= (16+256)-1 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
		SPR_GET_PIXEL <= '1';
	else
		SPR_GET_PIXEL <= '0';
	end if;
	
	if H_CNT >= (17) and H_CNT <= (17+256)-1 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
		BG_GET_PIXEL <= '1';
	else
		BG_GET_PIXEL <= '0';
	end if;
	
	if H_CNT >= (18) and H_CNT <= (18+256)-1 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
		BG_MATH <= '1';
	else
		BG_MATH <= '0';
	end if;
	
	if H_CNT >= (19) and H_CNT <= (19+256)-1 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
		BG_OUT <= '1';
	else
		BG_OUT <= '0';
	end if;
	
	if H_CNT <= (256)-1 and V_CNT < LAST_VIS_LINE then
		OBJ_RANGE <= '1';
	else
		OBJ_RANGE <= '0';
	end if;
	
	if H_CNT >= (16+256) and H_CNT <= (16+256+68)-1 and V_CNT < LAST_VIS_LINE then
		OBJ_TIME <= '1';
	else
		OBJ_TIME <= '0';
	end if;
end process;


--Background engine
HIRES <= '1' when BG_MODE = "101" or BG_MODE = "110" else '0';

BF <= BF_TBL(to_integer(unsigned(BG_MODE)), to_integer(H_CNT(2 downto 0)));

process( RST_N, DOT_CLK, BF, BG_MODE, BG_SIZE, BG_SC_ADDR, BG_SC_SIZE, BG_NBA, BG_HOFS, BG_VOFS, H_CNT, V_CNT, IN_VBL, FORCE_BLANK,
			BG_DATA, BG_TILE_INFO, BG3_OPT_DATA0, BG3_OPT_DATA1, BG_MOSAIC_Y, BG_MOSAIC_EN, FIELD, HIRES, BGINTERLACE, VRAM_DAI,
			M7_TILE_N, M7_TILE_COL, M7_TILE_ROW, M7_TEMP_X, M7_TEMP_Y, MPY, MPY2, M7SEL, M7HOFS, M7VOFS, M7X, M7Y, M7A, M7B, M7C, M7D)
variable SCREEN_X : unsigned(8 downto 0);
variable SCREEN_Y : unsigned(7 downto 0);
variable OPTH_EN, OPTV_EN : std_logic;
variable IS_OPT : std_logic;
variable OPT_HOFS, OPT_VOFS : unsigned(9 downto 0);
variable MOSAIC_Y : unsigned(7 downto 0);
variable TILE_INFO_N : unsigned(9 downto 0);
variable TILE_INFO_HFLIP : std_logic;
variable TILE_INFO_VFLIP : std_logic;
variable TILE_X : unsigned(5 downto 0);
variable TILE_Y : unsigned(5 downto 0);
variable OFFSET_X : unsigned(9 downto 0);
variable OFFSET_Y : unsigned(9 downto 0);
variable TILE_N : unsigned(9 downto 0);
variable OFFSET : unsigned(11 downto 0);
variable TILE_INC : unsigned(4 downto 0);
variable FLIP_Y : unsigned(2 downto 0);
variable TILE_OFFS : unsigned(14 downto 0);
variable TILEPOS_INC : unsigned(4 downto 0);
variable M7_VRAM_X, M7_VRAM_Y : signed(23 downto 0);
variable ORG_X, ORG_Y  : signed(10 downto 0);
variable M7_SCREEN_X, M7_SCREEN_Y  : signed(8 downto 0);
variable M7_TILE : unsigned(7 downto 0);
variable BG_TILEMAP_ADDR, BG_TILEDATA_ADDR : unsigned(15 downto 0);
variable M7_VRAM_ADDRA, M7_VRAM_ADDRB : unsigned(13 downto 0);
variable M7_IS_OUTSIDE : std_logic;
begin
	case BG_MODE is
		when "000" =>
			BG_TILE_INFO(0) <= BG_DATA(3);
			BG_TILE_INFO(1) <= BG_DATA(2);
			BG_TILE_INFO(2) <= BG_DATA(1);
			BG_TILE_INFO(3) <= BG_DATA(0);
		when "001" =>
			BG_TILE_INFO(0) <= BG_DATA(2);
			BG_TILE_INFO(1) <= BG_DATA(1);
			BG_TILE_INFO(2) <= BG_DATA(0);
			BG_TILE_INFO(3) <= (others => '0');
		when others =>
			BG_TILE_INFO(0) <= BG_DATA(1);
			BG_TILE_INFO(1) <= BG_DATA(0);
			BG_TILE_INFO(2) <= (others => '0');
			BG_TILE_INFO(3) <= (others => '0');
	end case;
	
	SCREEN_X := H_CNT;
	SCREEN_Y := V_CNT(7 downto 0);

	if BG_MOSAIC_EN(BF.BG) = '0' then
		MOSAIC_Y := SCREEN_Y;
	else
		MOSAIC_Y := SCREEN_Y - BG_MOSAIC_Y;
	end if;
	
	-- MODE 0-6
	IS_OPT := (BG_MODE(2) or BG_MODE(1)) and (not BG_MODE(0));	-- MODE 2,4,6
	
	case BF.BG is
		when BG1 => 
			OPTH_EN := (BG_MODE(1) and BG3_OPT_DATA0(13)) or (not BG_MODE(1) and not BG3_OPT_DATA0(15) and BG3_OPT_DATA0(13));
			OPTV_EN := (BG_MODE(1) and BG3_OPT_DATA1(13)) or (not BG_MODE(1) and     BG3_OPT_DATA0(15) and BG3_OPT_DATA0(13));
		when BG2 => 
			OPTH_EN := (BG_MODE(1) and BG3_OPT_DATA0(14)) or (not BG_MODE(1) and not BG3_OPT_DATA0(15) and BG3_OPT_DATA0(14));
			OPTV_EN := (BG_MODE(1) and BG3_OPT_DATA1(14)) or (not BG_MODE(1) and     BG3_OPT_DATA0(15) and BG3_OPT_DATA0(14));
		when others => 
			OPTH_EN := '0';
			OPTV_EN := '0';
	end case;
	
	OPT_HOFS := unsigned(BG3_OPT_DATA0(9 downto 0));
	if BG_MODE(1) = '0' then
		OPT_VOFS := unsigned(BG3_OPT_DATA0(9 downto 0));
	else
		OPT_VOFS := unsigned(BG3_OPT_DATA1(9 downto 0));
	end if;
	
	TILE_INFO_N := unsigned(BG_TILE_INFO(BF.BG)(9 downto 0));
	TILE_INFO_HFLIP := BG_TILE_INFO(BF.BG)(14);
	TILE_INFO_VFLIP := BG_TILE_INFO(BF.BG)(15);
			
	if BF.MODE = BF_OPT0 then
		OFFSET_X := resize(SCREEN_X(8 downto 3)&"000", OFFSET_X'length) + unsigned(BG_HOFS(BF.BG));
	elsif BF.MODE = BF_OPT1 then
		OFFSET_X := resize(SCREEN_X(8 downto 3)&"000", OFFSET_X'length) + unsigned(BG_HOFS(BF.BG));
	else
		if IS_OPT = '1' and OPTH_EN = '1' then	--OPT
			OFFSET_X := resize(SCREEN_X(8 downto 3)&"000", OFFSET_X'length) + (OPT_HOFS(9 downto 3) & unsigned(BG_HOFS(BF.BG)(2 downto 0)));
		else
			OFFSET_X := resize(SCREEN_X(8 downto 3)&"000", OFFSET_X'length) + unsigned(BG_HOFS(BF.BG));
		end if;
	end if;

	
	if BF.MODE = BF_OPT0 then
		OFFSET_Y := unsigned(BG_VOFS(BF.BG));
	elsif BF.MODE = BF_OPT1 then
		OFFSET_Y := unsigned(BG_VOFS(BF.BG)) + 8;
	else
		if IS_OPT = '1' and OPTV_EN = '1' then	--OPT
			OFFSET_Y := resize(MOSAIC_Y, OFFSET_Y'length) + OPT_VOFS;
		elsif HIRES = '1' and BGINTERLACE = '1' then
			OFFSET_Y := resize(MOSAIC_Y & FIELD, OFFSET_Y'length) + unsigned(BG_VOFS(BF.BG));
		else
			OFFSET_Y := resize(MOSAIC_Y, OFFSET_Y'length) + unsigned(BG_VOFS(BF.BG));
		end if;
	end if;
	
	if BG_SIZE(BF.BG) = '0' or HIRES = '1' then
		TILE_X := OFFSET_X(8 downto 3);
	else
		TILE_X := OFFSET_X(9 downto 4);
	end if;
	if BG_SIZE(BF.BG) = '0' then
		TILE_Y := OFFSET_Y(8 downto 3);
	else
		TILE_Y := OFFSET_Y(9 downto 4);
	end if;
	
	case BG_SC_SIZE(BF.BG) is
		when "00" =>
			OFFSET := "00" & TILE_Y(4 downto 0) & TILE_X(4 downto 0);
		when "01" =>
			OFFSET := "0" & TILE_X(5) & TILE_Y(4 downto 0) & TILE_X(4 downto 0); 
		when "10" =>
			OFFSET := "0" & TILE_Y(5) & TILE_Y(4 downto 0) & TILE_X(4 downto 0); 
		when others =>
			OFFSET := TILE_Y(5) & TILE_X(5) & TILE_Y(4 downto 0) & TILE_X(4 downto 0); 
	end case;
	BG_TILEMAP_ADDR := (resize(unsigned(BG_SC_ADDR(BF.BG)),BG_TILEMAP_ADDR'length) sll 10) + resize(OFFSET,BG_TILEMAP_ADDR'length);
	
	if BG_SIZE(BF.BG) = '0'then
		TILE_INC := (others => '0');
	elsif BG_SIZE(BF.BG) = '1' and HIRES = '1' then
		TILE_INC := (OFFSET_Y(3) xor TILE_INFO_VFLIP) & "0000";
	else
		TILE_INC := (OFFSET_Y(3) xor TILE_INFO_VFLIP) & "000" & (OFFSET_X(3) xor TILE_INFO_HFLIP);
	end if;
	TILE_N := TILE_INFO_N + resize(TILE_INC,TILE_N'length);
	
	if TILE_INFO_VFLIP = '0' then
		FLIP_Y := OFFSET_Y(2 downto 0);
	else
		FLIP_Y := not OFFSET_Y(2 downto 0);
	end if;
	
	case BG_MODE is
		when "000" =>
			TILE_OFFS := resize((TILE_N & FLIP_Y),TILE_OFFS'length);
		when "001" =>
			if BF.BG = BG1 or BF.BG = BG2 then
				TILE_OFFS := resize((TILE_N & "0" & FLIP_Y),TILE_OFFS'length);
			else
				TILE_OFFS := resize((TILE_N & FLIP_Y),TILE_OFFS'length);
			end if;
		when "010" =>
			TILE_OFFS := resize((TILE_N & "0" & FLIP_Y),TILE_OFFS'length);
		when "011" =>
			if BF.BG = BG1 then
				TILE_OFFS := resize((TILE_N & "00" & FLIP_Y),TILE_OFFS'length);
			else
				TILE_OFFS := resize((TILE_N & "0" & FLIP_Y),TILE_OFFS'length);
			end if;
		when "100" =>
			if BF.BG = BG1 then
				TILE_OFFS := resize((TILE_N & "00" & FLIP_Y),TILE_OFFS'length);
			else
				TILE_OFFS := resize((TILE_N & FLIP_Y),TILE_OFFS'length);
			end if;
		when "101" =>
			if BF.BG = BG1 then
				TILE_OFFS := resize((TILE_N & "0" & FLIP_Y),TILE_OFFS'length);
			else
				TILE_OFFS := resize((TILE_N & FLIP_Y),TILE_OFFS'length);
			end if;
		when others =>
			TILE_OFFS := resize((TILE_N & "0" & FLIP_Y),TILE_OFFS'length);
	end case;
	
	case BF.MODE is
		when BF_TILEDAT1 =>
			TILEPOS_INC := "01000";	--8
		when BF_TILEDAT2 =>
			TILEPOS_INC := "10000";	--16
		when BF_TILEDAT3 =>
			TILEPOS_INC := "11000";	--24
		when others =>
			TILEPOS_INC := "00000";	--0
	end case;
	BG_TILEDATA_ADDR := (resize(unsigned(BG_NBA(BF.BG)),BG_TILEDATA_ADDR'length) sll 12) + TILE_OFFS + TILEPOS_INC;
	
	-- MODE 7
	ORG_X := resize(signed(M7HOFS) - signed(M7X), ORG_X'length);
	ORG_Y := resize(signed(M7VOFS) - signed(M7Y), ORG_Y'length);
	
	if M7SEL(0) = '0' then
		M7_SCREEN_X := signed(resize(SCREEN_X(7 downto 0), 9));
	else
		M7_SCREEN_X := signed(resize(not SCREEN_X(7 downto 0), 9));
	end if;
	
	if M7SEL(1) = '0' then
		M7_SCREEN_Y := signed(resize(SCREEN_Y, 9));
	else
		M7_SCREEN_Y := signed(resize(not SCREEN_Y, 9));
	end if;
				
	if FORCE_BLANK = '0' and IN_VBL = '0' and BG_MODE = "111" then
		case H_CNT is
			when "101010001" =>	-- H = -3 (337)
				MPY <= resize(signed(M7A) * signed(ORG_X), MPY'length);
				MPY2 <= resize(signed(M7C) * signed(ORG_X), MPY'length);
			when "101010010" =>	-- H = -2 (338)
				MPY <= resize(signed(M7B) * signed(ORG_Y), MPY'length);
				MPY2 <= resize(signed(M7D) * signed(ORG_Y), MPY'length);
			when "101010011" =>	-- H = -1 (339)
				MPY <= resize(signed(M7B) * M7_SCREEN_Y, MPY'length);
				MPY2 <= resize(signed(M7D) * M7_SCREEN_Y, MPY'length);
			when others =>	-- H = 0-336
				MPY <= resize(signed(M7A) * M7_SCREEN_X, MPY'length);
				MPY2 <= resize(signed(M7C) * M7_SCREEN_X, MPY'length);
		end case;
	else
		MPY <= resize(signed(M7A) * signed(M7B(15 downto 8)), MPY'length);
		MPY2 <= resize(signed(M7A) * signed(M7B(15 downto 8)), MPY'length);
	end if;
	
	M7_VRAM_X := M7_TEMP_X + MPY;
	M7_VRAM_Y := M7_TEMP_Y + MPY2;
	if M7_VRAM_X(23 downto 18) = "000000" and M7_VRAM_Y(23 downto 18) = "000000" then
		M7_IS_OUTSIDE := '0';
	else
		M7_IS_OUTSIDE := '1';
	end if;
	
	if M7SEL(7 downto 6) = "11" and M7_IS_OUTSIDE = '1' then 
		M7_TILE := x"00";
	else 
		M7_TILE := unsigned(VRAM_DAI);
	end if;
			
	M7_VRAM_ADDRA := unsigned(M7_VRAM_Y(17 downto 11)) & unsigned(M7_VRAM_X(17 downto 11));
	M7_VRAM_ADDRB := M7_TILE_N & M7_TILE_ROW & M7_TILE_COL;
	
	case BF.MODE is
		when BF_TILEDATM7 => 
			BG_VRAM_ADDRA <= "00"&std_logic_vector(M7_VRAM_ADDRA);
			BG_VRAM_ADDRB <= "00"&std_logic_vector(M7_VRAM_ADDRB);
		when BF_TILEMAP | BF_OPT0 | BF_OPT1 => 
			BG_VRAM_ADDRA <= std_logic_vector(BG_TILEMAP_ADDR);
			BG_VRAM_ADDRB <= std_logic_vector(BG_TILEMAP_ADDR);
		when others => 
			BG_VRAM_ADDRA <= std_logic_vector(BG_TILEDATA_ADDR);
			BG_VRAM_ADDRB <= std_logic_vector(BG_TILEDATA_ADDR);
	end case;
	
	if RST_N = '0' then
		M7_TILE_N <= (others => '0');
		M7_TILE_ROW <= (others => '0');
		M7_TILE_COL <= (others => '0');
		M7_TILE_OUTSIDE <= '0';
	elsif falling_edge(DOT_CLK) then 
		M7_TILE_N <= M7_TILE;
		M7_TILE_COL <= unsigned(M7_VRAM_X(10 downto 8));
		M7_TILE_ROW <= unsigned(M7_VRAM_Y(10 downto 8));
		M7_TILE_OUTSIDE <= M7_IS_OUTSIDE;
	end if;
end process;

process( RST_N, DOT_CLK )
variable M7_PIX : std_logic_vector(7 downto 0);
begin
	if RST_N = '0' then
		BG_DATA <= (others => (others => '0'));
		BG3_OPT_DATA0 <= (others => '0');
		BG3_OPT_DATA1 <= (others => '0');
		BG_MOSAIC_Y <= (others => '0');
		
		M7_TEMP_X <= (others => '0');
		M7_TEMP_Y <= (others => '0');
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = 339 and V_CNT <= LAST_VIS_LINE then
				BG_DATA <= (others => (others => '0'));
								
				if BG_MOSAIC_Y = unsigned(MOSAIC_SIZE) then
					BG_MOSAIC_Y <= (others => '0');
				else
					BG_MOSAIC_Y <= BG_MOSAIC_Y + 1;
				end if;
			end if;
			
			if H_CNT = 339 and V_CNT = 261 then
				BG_MOSAIC_Y <= (others => '0');
			end if;
			
			case H_CNT is
				when "101010001" =>	-- H = -3 (337)
					M7_TEMP_X <= (resize(signed(M7X), M7_TEMP_X'length) sll 8) + signed(MPY(23 downto 6) & "000000");
					M7_TEMP_Y <= (resize(signed(M7Y), M7_TEMP_Y'length) sll 8) + signed(MPY2(23 downto 6) & "000000");
				when "101010010" =>	-- H = -2 (338)
					M7_TEMP_X <= M7_TEMP_X + signed(MPY(23 downto 6) & "000000");
					M7_TEMP_Y <= M7_TEMP_Y + signed(MPY2(23 downto 6) & "000000");
				when "101010011" =>	-- H = -1 (339)
					M7_TEMP_X <= M7_TEMP_X + signed(MPY(23 downto 6) & "000000");
					M7_TEMP_Y <= M7_TEMP_Y + signed(MPY2(23 downto 6) & "000000");
				when others => null;
			end case;
			
			if BG_VRAM_FETCH = '1' and FORCE_BLANK = '0' then
				if BG_MODE /= "111" then 
					BG_DATA(to_integer(H_CNT(2 downto 0))) <= VRAM_DBI & VRAM_DAI;
				else
					if M7SEL(7 downto 6) = "10" and M7_TILE_OUTSIDE = '1' then 
						M7_PIX := (others => '0');
					else 
						M7_PIX := VRAM_DBI;
					end if;
					BG_DATA(to_integer(H_CNT(2 downto 0)))(15 downto 8) <= M7_PIX;
				end if;
				
				if H_CNT(2 downto 0) = 0 then
					case BG_MODE is
						when "000" =>
							BG_TILES(0).PLANES( 0) <= FlipPlane(BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 1) <= FlipPlane(BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14));
							
							BG_TILES(0).PLANES( 8) <= FlipPlane(BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES( 9) <= FlipPlane(BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG2)(14));
							
							BG_TILES(0).PLANES( 4) <= FlipPlane(BG_DATA(5)( 7 downto 0), BG_TILE_INFO(BG3)(14));
							BG_TILES(0).PLANES( 5) <= FlipPlane(BG_DATA(5)(15 downto 8), BG_TILE_INFO(BG3)(14));
							
							BG_TILES(0).PLANES( 6) <= FlipPlane(BG_DATA(4)( 7 downto 0), BG_TILE_INFO(BG4)(14));
							BG_TILES(0).PLANES( 7) <= FlipPlane(BG_DATA(4)(15 downto 8), BG_TILE_INFO(BG4)(14));
							
						when "001" =>
							BG_TILES(0).PLANES( 0) <= FlipPlane(BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 1) <= FlipPlane(BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 2) <= FlipPlane(BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 3) <= FlipPlane(BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14));
							
							BG_TILES(0).PLANES( 8) <= FlipPlane(BG_DATA(4)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES( 9) <= FlipPlane(BG_DATA(4)(15 downto 8), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(10) <= FlipPlane(BG_DATA(5)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(11) <= FlipPlane(BG_DATA(5)(15 downto 8), BG_TILE_INFO(BG2)(14));
							
							BG_TILES(0).PLANES( 4) <= FlipPlane(BG_DATA(3)( 7 downto 0), BG_TILE_INFO(BG3)(14));
							BG_TILES(0).PLANES( 5) <= FlipPlane(BG_DATA(3)(15 downto 8), BG_TILE_INFO(BG3)(14));
							
						when "010" =>
							BG_TILES(0).PLANES( 0) <= FlipPlane(BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 1) <= FlipPlane(BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 2) <= FlipPlane(BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 3) <= FlipPlane(BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14));
							
							BG_TILES(0).PLANES( 8) <= FlipPlane(BG_DATA(4)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES( 9) <= FlipPlane(BG_DATA(4)(15 downto 8), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(10) <= FlipPlane(BG_DATA(5)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(11) <= FlipPlane(BG_DATA(5)(15 downto 8), BG_TILE_INFO(BG2)(14));
						
						when "011" =>
							BG_TILES(0).PLANES( 0) <= FlipPlane(BG_DATA(4)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 1) <= FlipPlane(BG_DATA(4)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 2) <= FlipPlane(BG_DATA(5)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 3) <= FlipPlane(BG_DATA(5)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 4) <= FlipPlane(BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 5) <= FlipPlane(BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 6) <= FlipPlane(BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 7) <= FlipPlane(BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14));
							
							BG_TILES(0).PLANES( 8) <= FlipPlane(BG_DATA(2)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES( 9) <= FlipPlane(BG_DATA(2)(15 downto 8), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(10) <= FlipPlane(BG_DATA(3)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES(11) <= FlipPlane(BG_DATA(3)(15 downto 8), BG_TILE_INFO(BG2)(14));
							
						when "100" =>
							BG_TILES(0).PLANES( 0) <= FlipPlane(BG_DATA(4)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 1) <= FlipPlane(BG_DATA(4)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 2) <= FlipPlane(BG_DATA(5)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 3) <= FlipPlane(BG_DATA(5)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 4) <= FlipPlane(BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 5) <= FlipPlane(BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 6) <= FlipPlane(BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14));
							BG_TILES(0).PLANES( 7) <= FlipPlane(BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14));
							
							BG_TILES(0).PLANES( 8) <= FlipPlane(BG_DATA(3)( 7 downto 0), BG_TILE_INFO(BG2)(14));
							BG_TILES(0).PLANES( 9) <= FlipPlane(BG_DATA(3)(15 downto 8), BG_TILE_INFO(BG2)(14));
						
						when "101" =>
							BG_TILES(0).PLANES( 0) <= FlipBGPlaneHR(BG_DATA(4)( 7 downto 0) & BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 1) <= FlipBGPlaneHR(BG_DATA(4)(15 downto 8) & BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 2) <= FlipBGPlaneHR(BG_DATA(5)( 7 downto 0) & BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 3) <= FlipBGPlaneHR(BG_DATA(5)(15 downto 8) & BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 4) <= FlipBGPlaneHR(BG_DATA(4)( 7 downto 0) & BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 5) <= FlipBGPlaneHR(BG_DATA(4)(15 downto 8) & BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 6) <= FlipBGPlaneHR(BG_DATA(5)( 7 downto 0) & BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 7) <= FlipBGPlaneHR(BG_DATA(5)(15 downto 8) & BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14), '1');
							
							BG_TILES(0).PLANES( 8) <= FlipBGPlaneHR(BG_DATA(2)( 7 downto 0) & BG_DATA(3)( 7 downto 0), BG_TILE_INFO(BG2)(14), '0');
							BG_TILES(0).PLANES( 9) <= FlipBGPlaneHR(BG_DATA(2)(15 downto 8) & BG_DATA(3)(15 downto 8), BG_TILE_INFO(BG2)(14), '0');
							BG_TILES(0).PLANES(10) <= FlipBGPlaneHR(BG_DATA(2)( 7 downto 0) & BG_DATA(3)( 7 downto 0), BG_TILE_INFO(BG2)(14), '1');
							BG_TILES(0).PLANES(11) <= FlipBGPlaneHR(BG_DATA(2)(15 downto 8) & BG_DATA(3)(15 downto 8), BG_TILE_INFO(BG2)(14), '1');
						
						when "110" =>
							BG_TILES(0).PLANES( 0) <= FlipBGPlaneHR(BG_DATA(4)( 7 downto 0) & BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 1) <= FlipBGPlaneHR(BG_DATA(4)(15 downto 8) & BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 2) <= FlipBGPlaneHR(BG_DATA(5)( 7 downto 0) & BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 3) <= FlipBGPlaneHR(BG_DATA(5)(15 downto 8) & BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14), '0');
							BG_TILES(0).PLANES( 4) <= FlipBGPlaneHR(BG_DATA(4)( 7 downto 0) & BG_DATA(6)( 7 downto 0), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 5) <= FlipBGPlaneHR(BG_DATA(4)(15 downto 8) & BG_DATA(6)(15 downto 8), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 6) <= FlipBGPlaneHR(BG_DATA(5)( 7 downto 0) & BG_DATA(7)( 7 downto 0), BG_TILE_INFO(BG1)(14), '1');
							BG_TILES(0).PLANES( 7) <= FlipBGPlaneHR(BG_DATA(5)(15 downto 8) & BG_DATA(7)(15 downto 8), BG_TILE_INFO(BG1)(14), '1');
							
						when others =>
							BG_TILES(0).PLANES( 0) <= BG_DATA(1)( 8) & BG_DATA(2)( 8) & BG_DATA(3)( 8) & BG_DATA(4)( 8) & BG_DATA(5)( 8) & BG_DATA(6)( 8) & BG_DATA(7)( 8) & M7_PIX(0);
							BG_TILES(0).PLANES( 1) <= BG_DATA(1)( 9) & BG_DATA(2)( 9) & BG_DATA(3)( 9) & BG_DATA(4)( 9) & BG_DATA(5)( 9) & BG_DATA(6)( 9) & BG_DATA(7)( 9) & M7_PIX(1);
							BG_TILES(0).PLANES( 2) <= BG_DATA(1)(10) & BG_DATA(2)(10) & BG_DATA(3)(10) & BG_DATA(4)(10) & BG_DATA(5)(10) & BG_DATA(6)(10) & BG_DATA(7)(10) & M7_PIX(2);
							BG_TILES(0).PLANES( 3) <= BG_DATA(1)(11) & BG_DATA(2)(11) & BG_DATA(3)(11) & BG_DATA(4)(11) & BG_DATA(5)(11) & BG_DATA(6)(11) & BG_DATA(7)(11) & M7_PIX(3);
							BG_TILES(0).PLANES( 4) <= BG_DATA(1)(12) & BG_DATA(2)(12) & BG_DATA(3)(12) & BG_DATA(4)(12) & BG_DATA(5)(12) & BG_DATA(6)(12) & BG_DATA(7)(12) & M7_PIX(4);
							BG_TILES(0).PLANES( 5) <= BG_DATA(1)(13) & BG_DATA(2)(13) & BG_DATA(3)(13) & BG_DATA(4)(13) & BG_DATA(5)(13) & BG_DATA(6)(13) & BG_DATA(7)(13) & M7_PIX(5);
							BG_TILES(0).PLANES( 6) <= BG_DATA(1)(14) & BG_DATA(2)(14) & BG_DATA(3)(14) & BG_DATA(4)(14) & BG_DATA(5)(14) & BG_DATA(6)(14) & BG_DATA(7)(14) & M7_PIX(6);
							BG_TILES(0).PLANES( 7) <= BG_DATA(1)(15) & BG_DATA(2)(15) & BG_DATA(3)(15) & BG_DATA(4)(15) & BG_DATA(5)(15) & BG_DATA(6)(15) & BG_DATA(7)(15) & M7_PIX(7);
					end case;

					BG_TILES(0).ATR(0) <= BG_TILE_INFO(BG1)(13 downto 10);
					BG_TILES(0).ATR(1) <= BG_TILE_INFO(BG2)(13 downto 10);
					BG_TILES(0).ATR(2) <= BG_TILE_INFO(BG3)(13 downto 10);
					BG_TILES(0).ATR(3) <= BG_TILE_INFO(BG4)(13 downto 10);
					BG_TILES(1) <= BG_TILES(0);
				end if;
				
				if H_CNT(2 downto 0) = 7 then
					BG3_OPT_DATA0 <= BG_DATA(2);
					BG3_OPT_DATA1 <= BG_DATA(3);
				end if;
			end if;
			
		end if;
	end if;
end process;

--Sprites range engine
process( RST_N, DOT_CLK )
variable SCREEN_Y : unsigned(7 downto 0);
variable W, H : unsigned(5 downto 0);
variable NEW_RANGE_CNT : unsigned(5 downto 0);
begin
	if RST_N = '0' then
		SCAN_OAM_ADDR <= (others => '0');
		RANGE_CNT_WR <= (others => '0');
		OBJ_RANGE_DONE <= '0';
		OAM_OBJ <= ("000000000","00000000","00000000",'0',"000","00",'0','0','0');
		OBJ_RANGE_OFL <= '0';
		OAM_RANGE <= (others => ("000000000","00000000","00000000",'0',"000","00",'0','0','0'));
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = 339 and V_CNT < LAST_VIS_LINE then
				RANGE_CNT_WR <= (others => '1');
				OBJ_RANGE_DONE <= '0';
				if OAM_PRIO = '0' then
					SCAN_OAM_ADDR <= (others => '0');
				else
					SCAN_OAM_ADDR <= unsigned(OAM_ADDR(8 downto 2)) & "0";
				end if;
			end if;
			
			if H_CNT = 339 and V_CNT = 261 then
				if FORCE_BLANK = '0' then
					OBJ_RANGE_OFL <= '0';
				end if;
			end if;
			
			if OBJ_RANGE = '1' then
				case H_CNT(0) is
					when '0' =>
						OAM_OBJ <= (unsigned(HOAM_Q_B(0) & OAM_Q_B(7 downto 0)), 
										unsigned(OAM_Q_B(15 downto 8)), 
										unsigned(OAM_Q_B(23 downto 16)),
										OAM_Q_B(24),
										OAM_Q_B(27 downto 25),
										OAM_Q_B(29 downto 28),
										OAM_Q_B(30),
										OAM_Q_B(31),
										HOAM_Q_B(1));
						SCAN_OAM_ADDR <= SCAN_OAM_ADDR+2;
					when '1' =>
						SCREEN_Y := V_CNT(7 downto 0);
						W := SprWidth(OAM_OBJ.S & OBJSIZE);
						H := SprHeight(OAM_OBJ.S & OBJSIZE);
						if OBJINTERLACE = '1' then
							H := (H srl 1);
						end if;
						if (OAM_OBJ.X <= 256 or (0 - OAM_OBJ.X) <= W) and (SCREEN_Y - OAM_OBJ.Y) <= H then
							if OBJ_RANGE_DONE = '0' then
								NEW_RANGE_CNT := RANGE_CNT_WR + 1;
								OAM_RANGE(to_integer(NEW_RANGE_CNT(4 downto 0))) <= OAM_OBJ;
								RANGE_CNT_WR <= NEW_RANGE_CNT;
								if NEW_RANGE_CNT = 31 then
									OBJ_RANGE_DONE <= '1';
								end if;
							elsif OBJ_RANGE_OFL = '0' then
								OBJ_RANGE_OFL <= '1';
							end if;
						end if;
						
					when others => null;
				end case;
			end if;
		end if;
	end if;
end process;


--Sprites time engine
process( RST_N, DOT_CLK, OAM_RANGE, RANGE_CNT_RD, TILES_CNT, OBJINTERLACE, FIELD, OBJSIZE, OBJNAME, OBJADDR, H_CNT, V_CNT )
variable SCREEN_Y : unsigned(7 downto 0);
variable TILE_X : unsigned(8 downto 0);
variable W, H : unsigned(5 downto 0);
variable TILE_GAP : unsigned(14 downto 0);
variable SPR : Sprite_r;
variable CUR_TILES_CNT : unsigned(2 downto 0);
variable Y : unsigned(7 downto 0);
variable TEMP : unsigned(5 downto 0);
variable TILE_COL, TILE_ROW : unsigned(3 downto 0);
begin
	SPR := OAM_RANGE(to_integer(RANGE_CNT_RD(4 downto 0)));
	if SPR.X(8) = '1' and TILES_CNT = 0 then
		TEMP := 0 - unsigned(SPR.X(5 downto 0));
		CUR_TILES_CNT := TEMP(5 downto 3);
	else
		CUR_TILES_CNT := TILES_CNT;
	end if;
	
	SCREEN_Y := V_CNT(7 downto 0);
	if SPR.VFLIP = '0' then
		Y := SCREEN_Y - SPR.Y;
	else
		Y := not (SCREEN_Y - SPR.Y);
	end if;
	if OBJINTERLACE = '1' then
		Y := (Y(6 downto 0) & FIELD);
	end if;

	W := SprWidth(SPR.S & OBJSIZE);
	H := SprHeight(SPR.S & OBJSIZE);
	if SPR.HFLIP = '0' then
		TILE_COL := unsigned(SPR.TILE(3 downto 0)) + CUR_TILES_CNT;
	else
		TILE_COL := unsigned(SPR.TILE(3 downto 0)) + ((not CUR_TILES_CNT) and W(5 downto 3));
	end if;
	TILE_ROW := unsigned(SPR.TILE(7 downto 4)) + (Y(5 downto 3) and H(5 downto 3));
	if SPR.N = '0' then
		TILE_GAP := (others => '0');
	else
		TILE_GAP := 4096 + (resize(unsigned(OBJNAME),TILE_GAP'length) sll 12);
	end if;
	OBJ_VRAM_ADDR <= std_logic_vector( (resize(unsigned(OBJADDR),OBJ_VRAM_ADDR'length) sll 13) + 
												  resize(TILE_GAP,OBJ_VRAM_ADDR'length) + 
												  resize((TILE_ROW & TILE_COL & H_CNT(0) & Y(2 downto 0)),OBJ_VRAM_ADDR'length) );
	
	if RST_N = '0' then
		RANGE_CNT_RD <= (others => '0');
		TILES_OAM_CNT <= (others => '0');
		TILES_CNT <= (others => '0');
		SPR_TILES <= (others => (x"00000000","000000000","000","00",'0'));
		OBJ_TIME_OFL <= '0';
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = (256+16)-1 and V_CNT < LAST_VIS_LINE then
				TILES_OAM_CNT <= (others => '0');
				TILES_CNT <= (others => '0');
				SPR_TILES <= (others => (x"00000000","000000000","000","00",'0'));
				RANGE_CNT_RD <= RANGE_CNT_WR;
			end if;
			
			if H_CNT = 339 and V_CNT = 261 then
				if FORCE_BLANK = '0' then
					OBJ_TIME_OFL <= '0';
				end if;
			end if;
			
			if H_CNT = 0 and V_CNT <= LAST_VIS_LINE then
				if RANGE_CNT_RD /= "111111" and TILES_OAM_CNT = 34 then
					OBJ_TIME_OFL <= '1';
				end if;
			end if;
			
			if OBJ_TIME = '1' then 
				if RANGE_CNT_RD /= "111111" then
					case H_CNT(0) is
						when '0' =>
							SPR_TILES(to_integer(TILES_OAM_CNT)).DATA(7 downto 0) <= FlipPlane(VRAM_DAI, SPR.HFLIP);
							SPR_TILES(to_integer(TILES_OAM_CNT)).DATA(15 downto 8) <= FlipPlane(VRAM_DBI, SPR.HFLIP);
						when others =>
							TILE_X := SPR.X + (resize(CUR_TILES_CNT,9) sll 3);
							
							SPR_TILES(to_integer(TILES_OAM_CNT)).DATA(23 downto 16) <= FlipPlane(VRAM_DAI, SPR.HFLIP);
							SPR_TILES(to_integer(TILES_OAM_CNT)).DATA(31 downto 24) <= FlipPlane(VRAM_DBI, SPR.HFLIP);
							SPR_TILES(to_integer(TILES_OAM_CNT)).X <= TILE_X;
							SPR_TILES(to_integer(TILES_OAM_CNT)).PAL <= SPR.PAL;
							SPR_TILES(to_integer(TILES_OAM_CNT)).PRIO <= SPR.PRIO;
							SPR_TILES(to_integer(TILES_OAM_CNT)).VALID <= '1';
							TILES_OAM_CNT <= TILES_OAM_CNT + 1;
							
							TILES_CNT <= CUR_TILES_CNT + 1;
							if CUR_TILES_CNT = W(5 downto 3) or (TILE_X + 8) >= 256 then
								TILES_CNT <= (others => '0');
								RANGE_CNT_RD <= RANGE_CNT_RD - 1;
							end if;
					end case;
				end if;
			end if;
		end if;
	end if;
end process;


process( RST_N, DOT_CLK )
variable p0,p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13,p14,p15,p16,
			p17,p18,p19,p20,p21,p22,p23,p24,p25,p26,p27,p28,p29,p30,p31,p32,p33: std_logic_vector(3 downto 0); 
begin
	if RST_N = '0' then
		SPR_PIX_DATA_BUF <= (others => '0');
		SPR_PIXEL_X <= (others => '0');
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = 339 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
				SPR_PIXEL_X <= (others => '0');
			end if;

			p0 := GetSpriteTilePixel(SPR_TILES(0), SPR_PIXEL_X);
			p1 := GetSpriteTilePixel(SPR_TILES(1), SPR_PIXEL_X);
			p2 := GetSpriteTilePixel(SPR_TILES(2), SPR_PIXEL_X);
			p3 := GetSpriteTilePixel(SPR_TILES(3), SPR_PIXEL_X);
			p4 := GetSpriteTilePixel(SPR_TILES(4), SPR_PIXEL_X);
			p5 := GetSpriteTilePixel(SPR_TILES(5), SPR_PIXEL_X);
			p6 := GetSpriteTilePixel(SPR_TILES(6), SPR_PIXEL_X);
			p7 := GetSpriteTilePixel(SPR_TILES(7), SPR_PIXEL_X);
			p8 := GetSpriteTilePixel(SPR_TILES(8), SPR_PIXEL_X);
			p9 := GetSpriteTilePixel(SPR_TILES(9), SPR_PIXEL_X);
			p10 := GetSpriteTilePixel(SPR_TILES(10), SPR_PIXEL_X);
			p11 := GetSpriteTilePixel(SPR_TILES(11), SPR_PIXEL_X);
			p12 := GetSpriteTilePixel(SPR_TILES(12), SPR_PIXEL_X);
			p13 := GetSpriteTilePixel(SPR_TILES(13), SPR_PIXEL_X);
			p14 := GetSpriteTilePixel(SPR_TILES(14), SPR_PIXEL_X);
			p15 := GetSpriteTilePixel(SPR_TILES(15), SPR_PIXEL_X);
			p16 := GetSpriteTilePixel(SPR_TILES(16), SPR_PIXEL_X);
			p17 := GetSpriteTilePixel(SPR_TILES(17), SPR_PIXEL_X);
			p18 := GetSpriteTilePixel(SPR_TILES(18), SPR_PIXEL_X);
			p19 := GetSpriteTilePixel(SPR_TILES(19), SPR_PIXEL_X);
			p20 := GetSpriteTilePixel(SPR_TILES(20), SPR_PIXEL_X);
			p21 := GetSpriteTilePixel(SPR_TILES(21), SPR_PIXEL_X);
			p22 := GetSpriteTilePixel(SPR_TILES(22), SPR_PIXEL_X);
			p23 := GetSpriteTilePixel(SPR_TILES(23), SPR_PIXEL_X);
			p24 := GetSpriteTilePixel(SPR_TILES(24), SPR_PIXEL_X);
			p25 := GetSpriteTilePixel(SPR_TILES(25), SPR_PIXEL_X);
			p26 := GetSpriteTilePixel(SPR_TILES(26), SPR_PIXEL_X);
			p27 := GetSpriteTilePixel(SPR_TILES(27), SPR_PIXEL_X);
			p28 := GetSpriteTilePixel(SPR_TILES(28), SPR_PIXEL_X);
			p29 := GetSpriteTilePixel(SPR_TILES(29), SPR_PIXEL_X);
			p30 := GetSpriteTilePixel(SPR_TILES(30), SPR_PIXEL_X);
			p31 := GetSpriteTilePixel(SPR_TILES(31), SPR_PIXEL_X);
			p32 := GetSpriteTilePixel(SPR_TILES(32), SPR_PIXEL_X);
			p33 := GetSpriteTilePixel(SPR_TILES(33), SPR_PIXEL_X);
			if SPR_GET_PIXEL = '1' then
				if p33 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(33).PRIO & SPR_TILES(33).PAL & p33;
				elsif p32 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(32).PRIO & SPR_TILES(32).PAL & p32;
				elsif p31 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(31).PRIO & SPR_TILES(31).PAL & p31;
				elsif p30 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(30).PRIO & SPR_TILES(30).PAL & p30;
				elsif p29 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(29).PRIO & SPR_TILES(29).PAL & p29;
				elsif p28 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(28).PRIO & SPR_TILES(28).PAL & p28;
				elsif p27 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(27).PRIO & SPR_TILES(27).PAL & p27;
				elsif p26 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(26).PRIO & SPR_TILES(26).PAL & p26;
				elsif p25 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(25).PRIO & SPR_TILES(25).PAL & p25;
				elsif p24 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(24).PRIO & SPR_TILES(24).PAL & p24;
				elsif p23 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(23).PRIO & SPR_TILES(23).PAL & p23;
				elsif p22 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(22).PRIO & SPR_TILES(22).PAL & p22;
				elsif p21 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(21).PRIO & SPR_TILES(21).PAL & p21;
				elsif p20 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(20).PRIO & SPR_TILES(20).PAL & p20;
				elsif p19 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(19).PRIO & SPR_TILES(19).PAL & p19;
				elsif p18 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(18).PRIO & SPR_TILES(18).PAL & p18;
				elsif p17 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(17).PRIO & SPR_TILES(17).PAL & p17;
				elsif p16 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(16).PRIO & SPR_TILES(16).PAL & p16;
				elsif p15 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(15).PRIO & SPR_TILES(15).PAL & p15;
				elsif p14 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(14).PRIO & SPR_TILES(14).PAL & p14;
				elsif p13 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(13).PRIO & SPR_TILES(13).PAL & p13;
				elsif p12 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(12).PRIO & SPR_TILES(12).PAL & p12;
				elsif p11 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(11).PRIO & SPR_TILES(11).PAL & p11;
				elsif p10 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(10).PRIO & SPR_TILES(10).PAL & p10;
				elsif p9 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(9).PRIO & SPR_TILES(9).PAL & p9;
				elsif p8 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(8).PRIO & SPR_TILES(8).PAL & p8;
				elsif p7 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(7).PRIO & SPR_TILES(7).PAL & p7;
				elsif p6 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(6).PRIO & SPR_TILES(6).PAL & p6;
				elsif p5 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(5).PRIO & SPR_TILES(5).PAL & p5;
				elsif p4 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(4).PRIO & SPR_TILES(4).PAL & p4;
				elsif p3 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(3).PRIO & SPR_TILES(3).PAL & p3;
				elsif p2 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(2).PRIO & SPR_TILES(2).PAL & p2;
				elsif p1 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(1).PRIO & SPR_TILES(1).PAL & p1;
				elsif p0 /= "0000" then
					SPR_PIX_DATA_BUF <= SPR_TILES(0).PRIO & SPR_TILES(0).PAL & p0;
				else
					SPR_PIX_DATA_BUF <= (others => '0');
				end if;
				
				SPR_PIXEL_X <= SPR_PIXEL_X + 1;
			end if;
		end if;
	end if;
end process;



process( RST_N, DOT_CLK )
variable N1,N2,N3,N4	: unsigned(3 downto 0);
begin
	if RST_N = '0' then
		GET_PIXEL_X <= (others => '0');
		BG1_PIX_DATA <= (others => '0');
		BG2_PIX_DATA <= (others => '0');
		BG3_PIX_DATA <= (others => '0');
		BG4_PIX_DATA <= (others => '0');
		SPR_PIX_DATA <= (others => '0');
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = 339 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
				GET_PIXEL_X <= (others => '0');
				BG_MOSAIC_X <= (others => '0');
			end if;
			
			if BG_GET_PIXEL = '1' then
				if BG_MOSAIC_EN(BG1) = '0' or BG_MOSAIC_X = 0  then
					if BG_MODE /= "111" then
						N1 := not (("0"&GET_PIXEL_X(2 downto 0)) + ("0"&unsigned(BG_HOFS(BG1)(2 downto 0))));
						BG1_PIX_DATA <= BG_TILES(to_integer(N1(3 downto 3))).ATR(BG1) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(7)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(6)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(5)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(4)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(3)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(2)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(1)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(0)(to_integer(N1(2 downto 0)));
					else
						N1 := not ("0"&GET_PIXEL_X(2 downto 0));
						BG1_PIX_DATA <= "0000" &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(7)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(6)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(5)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(4)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(3)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(2)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(1)(to_integer(N1(2 downto 0))) &
											 BG_TILES(to_integer(N1(3 downto 3))).PLANES(0)(to_integer(N1(2 downto 0)));
					end if;
				end if;
				
				if BG_MOSAIC_EN(BG2) = '0' or BG_MOSAIC_X = 0  then
					if BG_MODE /= "111" then
						N2 := not (("0"&GET_PIXEL_X(2 downto 0)) + ("0"&unsigned(BG_HOFS(BG2)(2 downto 0))));
						BG2_PIX_DATA <= BG_TILES(to_integer(N2(3 downto 3))).ATR(BG2) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(11)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(10)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES( 9)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES( 8)(to_integer(N2(2 downto 0)));
					else
						N2 := not ("0"&GET_PIXEL_X(2 downto 0));
						BG2_PIX_DATA <= BG_TILES(to_integer(N2(3 downto 3))).PLANES(7)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(6)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(5)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(4)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(3)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(2)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(1)(to_integer(N2(2 downto 0))) &
											 BG_TILES(to_integer(N2(3 downto 3))).PLANES(0)(to_integer(N2(2 downto 0)));
					end if;
				end if;
				
				if BG_MOSAIC_EN(BG3) = '0' or BG_MOSAIC_X = 0  then
					N3 := not (("0"&GET_PIXEL_X(2 downto 0)) + ("0"&unsigned(BG_HOFS(BG3)(2 downto 0))));
					BG3_PIX_DATA <= BG_TILES(to_integer(N3(3 downto 3))).ATR(BG3) &
										 BG_TILES(to_integer(N3(3 downto 3))).PLANES(5)(to_integer(N3(2 downto 0))) &
										 BG_TILES(to_integer(N3(3 downto 3))).PLANES(4)(to_integer(N3(2 downto 0)));
				end if;
				
				if BG_MOSAIC_EN(BG4) = '0' or BG_MOSAIC_X = 0  then				 
					N4 := not (("0"&GET_PIXEL_X(2 downto 0)) + ("0"&unsigned(BG_HOFS(BG4)(2 downto 0))));
					BG4_PIX_DATA <= BG_TILES(to_integer(N4(3 downto 3))).ATR(BG4) &
										 BG_TILES(to_integer(N4(3 downto 3))).PLANES(7)(to_integer(N4(2 downto 0))) &
										 BG_TILES(to_integer(N4(3 downto 3))).PLANES(6)(to_integer(N4(2 downto 0)));
				end if;
				
				GET_PIXEL_X <= GET_PIXEL_X + 1;
				
				
				if BG_MOSAIC_X = unsigned(MOSAIC_SIZE) then
					BG_MOSAIC_X <= (others => '0');
				else
					BG_MOSAIC_X <= BG_MOSAIC_X + 1;
				end if;
				
				SPR_PIX_DATA <= SPR_PIX_DATA_BUF;
			end if;
		end if;
	end if;
end process;


process( RST_N, DOT_CLK, WH0, WH1, WH2, WH3, W12SEL, W34SEL, WOBJSEL, WBGLOG, WOBJLOG, CGWSEL, CGADSUB, TMW, TSW, TM, TS, BG_MODE, BG3PRIO, M7EXTBG,
			WINDOW_X, SPR_PIX_DATA, BG1_PIX_DATA, BG2_PIX_DATA, BG3_PIX_DATA, BG4_PIX_DATA, DBG_BG_EN, DBG_OBJ_EN)
variable PAL1,PAL2,PAL3,PAL4,OBJ_PAL : std_logic_vector(7 downto 0);
variable PRIO1,PRIO2,PRIO3,PRIO4 : std_logic;
variable MBGPR0EN, MBGPR1EN, SBGPR0EN, SBGPR1EN : std_logic_vector(3 downto 0);
variable MOBJPR0EN,MOBJPR1EN,MOBJPR2EN,MOBJPR3EN,SOBJPR0EN,SOBJPR1EN,SOBJPR2EN,SOBJPR3EN : std_logic;
variable OBJ_PRIO : std_logic_vector(1 downto 0);
variable win1, win2, win1en, win2en, bglog0, bglog1, winres : std_logic_vector(5 downto 0);
variable main_dis, sub_dis : std_logic_vector(4 downto 0);
variable MAIN_EN, SUB_EN : std_logic;
variable MAIN_DCM, SUB_DCM, SUB_BD, MATH : std_logic;
variable MAIN_COLOR, SUB_COLOR	: std_logic_vector(14 downto 0);
variable MATH_R, MATH_G, MATH_B	: unsigned(4 downto 0);
variable HALF : std_logic;
begin
	if WINDOW_X >= unsigned(WH0) and WINDOW_X <= unsigned(WH1) then
		win1 := not (WOBJSEL(4)&WOBJSEL(0)&W34SEL(4)&W34SEL(0)&W12SEL(4)&W12SEL(0));
	else
		win1 := WOBJSEL(4)&WOBJSEL(0)&W34SEL(4)&W34SEL(0)&W12SEL(4)&W12SEL(0);
	end if;
	if WINDOW_X >= unsigned(WH2) and WINDOW_X <= unsigned(WH3) then
		win2 := not (WOBJSEL(6)&WOBJSEL(2)&W34SEL(6)&W34SEL(2)&W12SEL(6)&W12SEL(2));
	else
		win2 := WOBJSEL(6)&WOBJSEL(2)&W34SEL(6)&W34SEL(2)&W12SEL(6)&W12SEL(2);
	end if;
	win1en := WOBJSEL(5)&WOBJSEL(1)&W34SEL(5)&W34SEL(1)&W12SEL(5)&W12SEL(1);
	win2en := WOBJSEL(7)&WOBJSEL(3)&W34SEL(7)&W34SEL(3)&W12SEL(7)&W12SEL(3);
	bglog0 := WOBJLOG(2)&WOBJLOG(0)&WBGLOG(6)&WBGLOG(4)&WBGLOG(2)&WBGLOG(0);
	bglog1 := WOBJLOG(3)&WOBJLOG(1)&WBGLOG(7)&WBGLOG(5)&WBGLOG(3)&WBGLOG(1);
	
	for i in 0 to 5 loop
		if win1en(i) = '0' and win2en(i) = '0' then
			winres(i) := '0';
		elsif win1en(i) = '1' and win2en(i) = '0' then
			winres(i) := win1(i);
		elsif win1en(i) = '0' and win2en(i) = '1' then
			winres(i) := win2(i);
		else
			if bglog1(i) = '0' and bglog0(i) = '0' then
				winres(i) := win1(i) or win2(i);
			elsif bglog1(i) = '0' and bglog0(i) = '1' then
				winres(i) := win1(i) and win2(i);
			elsif bglog1(i) = '1' and bglog0(i) = '0' then
				winres(i) := win1(i) xor win2(i);
			else
				winres(i) := not(win1(i) xor win2(i));
			end if;
		end if;
		
	end loop;
	for i in 0 to 4 loop
		main_dis(i) := winres(i) and TMW(i);
		sub_dis(i) := winres(i) and TSW(i);
	end loop;
	
	case CGWSEL(7 downto 6) is
		when "00" => MAIN_EN := '1';
		when "01" => MAIN_EN := winres(5);
		when "10" => MAIN_EN := not winres(5);
		when "11" => MAIN_EN := '0';
		when others => null;
	end case;
	case CGWSEL(5 downto 4) is
		when "00" => SUB_EN := '1';
		when "01" => SUB_EN := winres(5);
		when "10" => SUB_EN := not winres(5);
		when "11" => SUB_EN := '0';
		when others => null;
	end case;
	
	SUB_BD := '0';
	MAIN_DCM := '0';
	SUB_DCM := '0';
	MATH := '0';
	
	OBJ_PRIO := SPR_PIX_DATA(8 downto 7);

	PRIO1 := BG1_PIX_DATA(11);
	PRIO2 := BG2_PIX_DATA(7);
	PRIO3 := BG3_PIX_DATA(5);
	PRIO4 := BG4_PIX_DATA(5);
	
	MBGPR0EN(0) := TM(0) and (not main_dis(0)) and (not PRIO1) and DBG_BG_EN(0);
	MBGPR0EN(1) := TM(1) and (not main_dis(1)) and (not PRIO2) and DBG_BG_EN(1);
	MBGPR0EN(2) := TM(2) and (not main_dis(2)) and (not PRIO3) and DBG_BG_EN(2);
	MBGPR0EN(3) := TM(3) and (not main_dis(3)) and (not PRIO4) and DBG_BG_EN(3);
	MBGPR1EN(0) := TM(0) and (not main_dis(0)) and (    PRIO1) and DBG_BG_EN(4);
	MBGPR1EN(1) := TM(1) and (not main_dis(1)) and (    PRIO2) and DBG_BG_EN(5);
	MBGPR1EN(2) := TM(2) and (not main_dis(2)) and (    PRIO3) and DBG_BG_EN(6);
	MBGPR1EN(3) := TM(3) and (not main_dis(3)) and (    PRIO4) and DBG_BG_EN(7);
	MOBJPR0EN := TM(4) and (not main_dis(4)) and (not OBJ_PRIO(0)) and (not OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	MOBJPR1EN := TM(4) and (not main_dis(4)) and (    OBJ_PRIO(0)) and (not OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	MOBJPR2EN := TM(4) and (not main_dis(4)) and (not OBJ_PRIO(0)) and (    OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	MOBJPR3EN := TM(4) and (not main_dis(4)) and (    OBJ_PRIO(0)) and (    OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	
	SBGPR0EN(0) := TS(0) and (not sub_dis(0)) and (not PRIO1) and DBG_BG_EN(0);
	SBGPR0EN(1) := TS(1) and (not sub_dis(1)) and (not PRIO2) and DBG_BG_EN(1);
	SBGPR0EN(2) := TS(2) and (not sub_dis(2)) and (not PRIO3) and DBG_BG_EN(2);
	SBGPR0EN(3) := TS(3) and (not sub_dis(3)) and (not PRIO4) and DBG_BG_EN(3);
	SBGPR1EN(0) := TS(0) and (not sub_dis(0)) and (    PRIO1) and DBG_BG_EN(4);
	SBGPR1EN(1) := TS(1) and (not sub_dis(1)) and (    PRIO2) and DBG_BG_EN(5);
	SBGPR1EN(2) := TS(2) and (not sub_dis(2)) and (    PRIO3) and DBG_BG_EN(6);
	SBGPR1EN(3) := TS(3) and (not sub_dis(3)) and (    PRIO4) and DBG_BG_EN(7);
	SOBJPR0EN := TS(4) and (not sub_dis(4)) and (not OBJ_PRIO(0)) and (not OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	SOBJPR1EN := TS(4) and (not sub_dis(4)) and (    OBJ_PRIO(0)) and (not OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	SOBJPR2EN := TS(4) and (not sub_dis(4)) and (not OBJ_PRIO(0)) and (    OBJ_PRIO(1)) and DBG_OBJ_EN(0);
	SOBJPR3EN := TS(4) and (not sub_dis(4)) and (    OBJ_PRIO(0)) and (    OBJ_PRIO(1)) and DBG_OBJ_EN(0);
			
	
	if BG_MODE = "000" then	-- MODE0
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(1 downto 0);
			MATH := CGADSUB(0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "001" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(1 downto 0);
			MATH := CGADSUB(0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "001" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(2) = '1' then
			CRAM_MAIN_ADDR <= "010" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
			MATH := CGADSUB(2);
		elsif BG4_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(3) = '1' then
			CRAM_MAIN_ADDR <= "011" & BG4_PIX_DATA(4 downto 2) & BG4_PIX_DATA(1 downto 0);
			MATH := CGADSUB(3);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(2) = '1' then
			CRAM_MAIN_ADDR <= "010" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
			MATH := CGADSUB(2);
		elsif BG4_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(3) = '1' then
			CRAM_MAIN_ADDR <= "011" & BG4_PIX_DATA(4 downto 2) & BG4_PIX_DATA(1 downto 0);
			MATH := CGADSUB(3);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= "000" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(1 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "001" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= "000" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(1 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "001" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(2) = '1' then
			CRAM_SUB_ADDR <= "010" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
		elsif BG4_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(3) = '1' then
			CRAM_SUB_ADDR <= "011" & BG4_PIX_DATA(4 downto 2) & BG4_PIX_DATA(1 downto 0); 
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(2) = '1' then
			CRAM_SUB_ADDR <= "010" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
		elsif BG4_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(3) = '1' then
			CRAM_SUB_ADDR <= "011" & BG4_PIX_DATA(4 downto 2) & BG4_PIX_DATA(1 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "001" then	-- MODE1
		if BG3_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(2) = '1' and BG3PRIO = '1' then
			CRAM_MAIN_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
			MATH := CGADSUB(2);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
			MATH := CGADSUB(0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
			MATH := CGADSUB(0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(2) = '1' and BG3PRIO = '0' then
			CRAM_MAIN_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
			MATH := CGADSUB(2);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(2) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
			MATH := CGADSUB(2);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if BG3_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(2) = '1' and BG3PRIO = '1' then
			CRAM_SUB_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1'then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(2) = '1' and BG3PRIO = '0' then
			CRAM_SUB_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG3_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(2) = '1' then
			CRAM_SUB_ADDR <= "000" & BG3_PIX_DATA(4 downto 2) & BG3_PIX_DATA(1 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "010" then	-- MODE2
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "011" then	-- MODE3
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= BG1_PIX_DATA(7 downto 0); 
			MAIN_DCM := CGWSEL(0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= BG1_PIX_DATA(7 downto 0);
			MAIN_DCM := CGWSEL(0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
			MATH := CGADSUB(1);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= BG1_PIX_DATA(7 downto 0); 
			SUB_DCM := CGWSEL(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0); 
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= BG1_PIX_DATA(7 downto 0); 
			SUB_DCM := CGWSEL(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "100" then	-- MODE4
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= BG1_PIX_DATA(7 downto 0); 
			MAIN_DCM := CGWSEL(0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= BG1_PIX_DATA(7 downto 0); 
			MAIN_DCM := CGWSEL(0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
			MATH := CGADSUB(1);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= BG1_PIX_DATA(7 downto 0); 
			SUB_DCM := CGWSEL(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= BG1_PIX_DATA(7 downto 0); 
			SUB_DCM := CGWSEL(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "101" then	-- MODE5
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 4) /= "0000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(7 downto 4);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 2) /= "00" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 2);
			MATH := CGADSUB(1);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 4) /= "0000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(7 downto 4);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(3 downto 2) /= "00" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(3 downto 2);
			MATH := CGADSUB(1);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR1EN(1) = '1' then
			CRAM_SUB_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(1 downto 0) /= "00" and SBGPR0EN(1) = '1' then
			CRAM_SUB_ADDR <= "000" & BG2_PIX_DATA(6 downto 4) & BG2_PIX_DATA(1 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	elsif BG_MODE = "110" then	-- MODE6
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 4) /= "0000" and MBGPR1EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(7 downto 4);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 4) /= "0000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(7 downto 4);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR1EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(3 downto 0) /= "0000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= "0" & BG1_PIX_DATA(10 downto 8) & BG1_PIX_DATA(3 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
		
	else	-- MODE7
		if SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR3EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR2EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(6 downto 0) /= "0000000" and MBGPR1EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR1EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and MBGPR0EN(0) = '1' then
			CRAM_MAIN_ADDR <= BG1_PIX_DATA(7 downto 0);
			MAIN_DCM := CGWSEL(0);
			MATH := CGADSUB(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and MOBJPR0EN = '1' then
			CRAM_MAIN_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
			MATH := CGADSUB(4) and SPR_PIX_DATA(6);
		elsif BG2_PIX_DATA(6 downto 0) /= "0000000" and MBGPR0EN(1) = '1' then
			CRAM_MAIN_ADDR <= "0" & BG2_PIX_DATA(6 downto 0);
		else
			CRAM_MAIN_ADDR <= (others => '0');
			MATH := CGADSUB(5);
		end if;
		
		if SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR3EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR2EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(6 downto 0) /= "0000000" and SBGPR1EN(1) = '1' and M7EXTBG = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR1EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG1_PIX_DATA(7 downto 0) /= "00000000" and SBGPR0EN(0) = '1' then
			CRAM_SUB_ADDR <= BG1_PIX_DATA(7 downto 0);
			SUB_DCM := CGWSEL(0);
		elsif SPR_PIX_DATA(3 downto 0) /= "0000" and SOBJPR0EN = '1' then
			CRAM_SUB_ADDR <= "1" & SPR_PIX_DATA(6 downto 0);
		elsif BG2_PIX_DATA(6 downto 0) /= "0000000" and SBGPR0EN(1) = '1' and M7EXTBG = '1' then
			CRAM_SUB_ADDR <= "0" & BG2_PIX_DATA(6 downto 0);
		else
			CRAM_SUB_ADDR <= (others => '0');
			SUB_BD := '1';
		end if;
	end if;

	
	if RST_N = '0' then
		WINDOW_X <= (others => '0');
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if BG_GET_PIXEL = '1' then
				WINDOW_X <= GET_PIXEL_X;
			end if;
			
			if BG_MATH = '1' then
				if MAIN_EN = '0' then
					MAIN_COLOR := (others => '0');
				elsif MAIN_DCM = '1' then
					MAIN_COLOR := GetDCM(BG1_PIX_DATA(10 downto 0));
				else
					MAIN_COLOR := CRAM_MAIN_DATA ;
				end if;
				
				if SUB_BD = '1' and HIRES = '0' then
					SUB_COLOR := SUBCOL;
				elsif SUB_DCM = '1' then
					SUB_COLOR := GetDCM(BG1_PIX_DATA(10 downto 0));
				else
					SUB_COLOR := CRAM_SUB_DATA ;
				end if;
				
				HALF := CGADSUB(6) and MAIN_EN and ((not CGWSEL(1)) or (not SUB_BD));
				if CGWSEL(1) = '1' then
					MATH_R := AddSub(unsigned(MAIN_COLOR(4 downto 0)),unsigned(SUB_COLOR(4 downto 0)),not CGADSUB(7),HALF);
					MATH_G := AddSub(unsigned(MAIN_COLOR(9 downto 5)),unsigned(SUB_COLOR(9 downto 5)),not CGADSUB(7),HALF);
					MATH_B := AddSub(unsigned(MAIN_COLOR(14 downto 10)),unsigned(SUB_COLOR(14 downto 10)),not CGADSUB(7),HALF);
				else
					MATH_R := AddSub(unsigned(MAIN_COLOR(4 downto 0)),unsigned(SUBCOL(4 downto 0)),not CGADSUB(7),HALF);
					MATH_G := AddSub(unsigned(MAIN_COLOR(9 downto 5)),unsigned(SUBCOL(9 downto 5)),not CGADSUB(7),HALF);
					MATH_B := AddSub(unsigned(MAIN_COLOR(14 downto 10)),unsigned(SUBCOL(14 downto 10)),not CGADSUB(7),HALF);
				end if;

				if FORCE_BLANK = '1' or (MAIN_EN = '0' and SUB_EN = '0') then
					SUB_R <= (others => '0');
					SUB_G <= (others => '0');
					SUB_B <= (others => '0');
				elsif HIRES = '1' then
					SUB_R <= unsigned(SUB_COLOR(4 downto 0));
					SUB_G <= unsigned(SUB_COLOR(9 downto 5));
					SUB_B <= unsigned(SUB_COLOR(14 downto 10));
				elsif MATH = '1' and SUB_EN = '1' then
					SUB_R <= MATH_R;
					SUB_G <= MATH_G;
					SUB_B <= MATH_B;
				else
					SUB_R <= unsigned(MAIN_COLOR(4 downto 0));
					SUB_G <= unsigned(MAIN_COLOR(9 downto 5));
					SUB_B <= unsigned(MAIN_COLOR(14 downto 10));
				end if;

				if FORCE_BLANK = '1' or (MAIN_EN = '0' and SUB_EN = '0') then
					MAIN_R <= (others => '0');
					MAIN_G <= (others => '0');
					MAIN_B <= (others => '0');
				elsif MATH = '1' and SUB_EN = '1' and HIRES = '0' then
					MAIN_R <= MATH_R;
					MAIN_G <= MATH_G;
					MAIN_B <= MATH_B;
				else
					MAIN_R <= unsigned(MAIN_COLOR(4 downto 0));
					MAIN_G <= unsigned(MAIN_COLOR(9 downto 5));
					MAIN_B <= unsigned(MAIN_COLOR(14 downto 10));
				end if;
			end if;
		end if;
	end if;
end process;

process( RST_N, DOT_CLK, MAIN_B, MAIN_G, MAIN_R, SUB_B, SUB_G, SUB_R, MB)

begin
	if DOT_CLK = '0' then
		COLOR_OUT <= Bright(MB, SUB_B) & Bright(MB, SUB_G) & Bright(MB, SUB_R);
	else
		COLOR_OUT <= Bright(MB, MAIN_B) & Bright(MB, MAIN_G) & Bright(MB, MAIN_R);
	end if;
	
	if RST_N = '0' then
		OUT_Y <= (others => '0');
		OUT_X <= (others => '0');
	elsif falling_edge(DOT_CLK) then 
		if ENABLE = '1' then
			if H_CNT = 339 and V_CNT >= 1 and V_CNT <= LAST_VIS_LINE then
				OUT_Y <= OUT_Y + 1;
			end if;
			
			if H_CNT = 339 and V_CNT = 261 then
				OUT_Y <= (others => '0');
			end if;
			
			if BG_MATH = '1' then
				OUT_X <= WINDOW_X;
			end if;
		end if;
	end if;
end process;

DOTCLK <= DOT_CLK;
HBLANK <= IN_HBL;
VBLANK <= IN_VBL;

FRAME_OUT <= BG_OUT;
X_OUT <= std_logic_vector(OUT_X & DOT_CLK);
Y_OUT <= std_logic_vector(FIELD & OUT_Y);
V224 <= not OVERSCAN;

--debug 
process( RST_N, DOT_CLK )
begin
	if RST_N = '0' then
		DBG_BRK <= '0';
		DBG_RUN_LAST <= '0';
	elsif falling_edge(DOT_CLK) then
		if ENABLE = '1' then
			DBG_BRK <= '0';
			if DBG_CTRL(0) = '1' then			--dot step
				DBG_BRK <= '1';
			elsif DBG_CTRL(2) = '1' then		--HV counters break
				if H_CNT = unsigned(DBG_BRK_HCNT) and V_CNT = unsigned(DBG_BRK_VCNT) then
					DBG_BRK <= '1';
				end if;
			end if;
		end if;
		
		DBG_RUN_LAST <= DBG_CTRL(7);			--run
		if DBG_CTRL(7) = '1' and DBG_RUN_LAST = '0' then
			DBG_BRK <= '0';
		end if;
	end if;
end process; 
	
process( DOT_CLK, RST_N, DBG_REG, FORCE_BLANK, MB, OBJSIZE, OBJNAME, OBJADDR, OAMADD, OAM_PRIO, BG_SIZE, BG3PRIO, BG_MODE,
			MOSAIC_SIZE, BG_MOSAIC_EN, BG_SC_ADDR, BG_SC_SIZE, BG_NBA, TM, TS, BG_HOFS, BG_VOFS, WH0, WH1, WH2, WH3,
			W12SEL, W34SEL, WOBJSEL, WBGLOG, WOBJLOG, TMW, TSW, CGWSEL, CGADSUB, VMAIN_ADDRINC, VMAIN_ADDRTRANS,
			OPHCT, OPVCT, H_CNT, V_CNT, FIELD, VMADD, OBJ_TIME_OFL, OBJ_RANGE_OFL, M7SEL, M7A, M7B, M7C, M7D, M7X, M7Y, 
			M7HOFS, M7VOFS, VRAM_DAI, VRAM_DBI, FRAME_CNT, CRAM_DATA, OAM_Q_A, HOAM_Q_A)
begin
	case DBG_REG is
		when x"00" => DBG_DAT_OUT <= FORCE_BLANK & "000" & MB;
		when x"01" => DBG_DAT_OUT <= OBJSIZE & OBJNAME & OBJADDR;
		when x"02" => DBG_DAT_OUT <= OAMADD(7 downto 0);
		when x"03" => DBG_DAT_OUT <= OAM_PRIO & "000000" & OAMADD(8);
		when x"04" => DBG_DAT_OUT <= BG_SIZE & BG3PRIO & BG_MODE;
		when x"05" => DBG_DAT_OUT <= MOSAIC_SIZE & BG_MOSAIC_EN;
		when x"06" => DBG_DAT_OUT <= BG_SC_ADDR(BG1)&BG_SC_SIZE(BG1);
		when x"07" => DBG_DAT_OUT <= BG_SC_ADDR(BG2)&BG_SC_SIZE(BG2);
		when x"08" => DBG_DAT_OUT <= BG_SC_ADDR(BG3)&BG_SC_SIZE(BG3);
		when x"09" => DBG_DAT_OUT <= BG_SC_ADDR(BG4)&BG_SC_SIZE(BG4);
		when x"0A" => DBG_DAT_OUT <= BG_NBA(BG2)&BG_NBA(BG1);
		when x"0B" => DBG_DAT_OUT <= BG_NBA(BG4)&BG_NBA(BG3);
		when x"0C" => DBG_DAT_OUT <= TM;
		when x"0D" => DBG_DAT_OUT <= TS;
		when x"0E" => DBG_DAT_OUT <= BG_HOFS(BG1)(7 downto 0);
		when x"0F" => DBG_DAT_OUT <= "000000" & BG_HOFS(BG1)(9 downto 8);
		when x"10" => DBG_DAT_OUT <= BG_VOFS(BG1)(7 downto 0);
		when x"11" => DBG_DAT_OUT <= "000000" & BG_VOFS(BG1)(9 downto 8);
		when x"12" => DBG_DAT_OUT <= BG_HOFS(BG2)(7 downto 0);
		when x"13" => DBG_DAT_OUT <= "000000" & BG_HOFS(BG2)(9 downto 8);
		when x"14" => DBG_DAT_OUT <= BG_VOFS(BG2)(7 downto 0);
		when x"15" => DBG_DAT_OUT <= "000000" & BG_VOFS(BG2)(9 downto 8);
		when x"16" => DBG_DAT_OUT <= BG_HOFS(BG3)(7 downto 0);
		when x"17" => DBG_DAT_OUT <= "000000" & BG_HOFS(BG3)(9 downto 8);
		when x"18" => DBG_DAT_OUT <= BG_VOFS(BG3)(7 downto 0);
		when x"19" => DBG_DAT_OUT <= "000000" & BG_VOFS(BG3)(9 downto 8);
		when x"1A" => DBG_DAT_OUT <= BG_HOFS(BG4)(7 downto 0);
		when x"1B" => DBG_DAT_OUT <= "000000" & BG_HOFS(BG4)(9 downto 8);
		when x"1C" => DBG_DAT_OUT <= BG_VOFS(BG4)(7 downto 0);
		when x"1D" => DBG_DAT_OUT <= "000000" & BG_VOFS(BG4)(9 downto 8);
		when x"1E" => DBG_DAT_OUT <= WH0;
		when x"1F" => DBG_DAT_OUT <= WH1;
		when x"20" => DBG_DAT_OUT <= WH2;
		when x"21" => DBG_DAT_OUT <= WH3;
		when x"22" => DBG_DAT_OUT <= W12SEL;
		when x"23" => DBG_DAT_OUT <= W34SEL;
		when x"24" => DBG_DAT_OUT <= WOBJSEL;
		when x"25" => DBG_DAT_OUT <= WBGLOG;
		when x"26" => DBG_DAT_OUT <= WOBJLOG;
		when x"27" => DBG_DAT_OUT <= TMW;
		when x"28" => DBG_DAT_OUT <= TSW;
		when x"29" => DBG_DAT_OUT <= CGWSEL;
		when x"2A" => DBG_DAT_OUT <= CGADSUB;
		when x"2B" => DBG_DAT_OUT <= VMAIN_ADDRINC & "000" & VMAIN_ADDRTRANS & "00";
		when x"2C" => DBG_DAT_OUT <= OPHCT(7 downto 0);
		when x"2D" => DBG_DAT_OUT <= "0000000" & OPHCT(8);
		when x"2E" => DBG_DAT_OUT <= OPVCT(7 downto 0);
		when x"2F" => DBG_DAT_OUT <= "0000000" & OPVCT(8);
		when x"30" => DBG_DAT_OUT <= std_logic_vector(H_CNT(7 downto 0));
		when x"31" => DBG_DAT_OUT <= "0000000" & H_CNT(8);
		when x"32" => DBG_DAT_OUT <= std_logic_vector(V_CNT(7 downto 0));
		when x"33" => DBG_DAT_OUT <= FIELD & "000000" & V_CNT(8);
		when x"34" => DBG_DAT_OUT <= std_logic_vector(VMADD(7 downto 0));
		when x"35" => DBG_DAT_OUT <= "0" & std_logic_vector(VMADD(14 downto 8)); 
		when x"36" => DBG_DAT_OUT <= "00000" & OBJ_TIME_OFL & OBJ_RANGE_OFL & "0";
		when x"37" => DBG_DAT_OUT <= M7SEL;
		when x"38" => DBG_DAT_OUT <= M7A(7 downto 0);
		when x"39" => DBG_DAT_OUT <= M7A(15 downto 8);
		when x"3A" => DBG_DAT_OUT <= M7B(7 downto 0);
		when x"3B" => DBG_DAT_OUT <= M7B(15 downto 8);
		when x"3C" => DBG_DAT_OUT <= M7C(7 downto 0);
		when x"3D" => DBG_DAT_OUT <= M7C(15 downto 8);
		when x"3E" => DBG_DAT_OUT <= M7D(7 downto 0);
		when x"3F" => DBG_DAT_OUT <= M7D(15 downto 8);
		when x"40" => DBG_DAT_OUT <= M7X(7 downto 0);
		when x"41" => DBG_DAT_OUT <= "000" & M7X(12 downto 8);
		when x"42" => DBG_DAT_OUT <= M7Y(7 downto 0);
		when x"43" => DBG_DAT_OUT <= "000" & M7Y(12 downto 8);
		when x"44" => DBG_DAT_OUT <= M7HOFS(7 downto 0);
		when x"45" => DBG_DAT_OUT <= "000" & M7HOFS(12 downto 8);
		when x"46" => DBG_DAT_OUT <= M7VOFS(7 downto 0);
		when x"47" => DBG_DAT_OUT <= "000" & M7VOFS(12 downto 8);
		when x"48" => DBG_DAT_OUT <= std_logic_vector(FRAME_CNT(7 downto 0));
		when x"49" => DBG_DAT_OUT <= std_logic_vector(FRAME_CNT(15 downto 8));
		
		when x"80" => DBG_DAT_OUT <= VRAM_DAI;
		when x"81" => DBG_DAT_OUT <= VRAM_DBI;
		when x"82" => DBG_DAT_OUT <= CRAM_DATA(7 downto 0);
		when x"83" => DBG_DAT_OUT <= "0" & CRAM_DATA(14 downto 8);
		when x"84" => DBG_DAT_OUT <= OAM_Q_A(7 downto 0);
		when x"85" => DBG_DAT_OUT <= OAM_Q_A(15 downto 8);
		when x"86" => DBG_DAT_OUT <= HOAM_Q_A;
		when others => DBG_DAT_OUT <= x"00";
	end case; 
	
	if RST_N = '0' then
		DBG_VRAM_ADDR <= (others => '0');
		DBG_CRAM_ADDR <= (others => '0');
		DBG_OAM_ADDR <= (others => '0');
		DBG_DAT_WRr <= '0';
	elsif falling_edge(DOT_CLK) then
		DBG_DAT_WRr <= DBG_DAT_WR;
		if DBG_DAT_WR = '1' and DBG_DAT_WRr = '0' then
			case DBG_REG is
				when x"80" => DBG_VRAM_ADDR(7 downto 0) <= DBG_DAT_IN;
				when x"81" => DBG_VRAM_ADDR(15 downto 8) <= DBG_DAT_IN;
				when x"82" => DBG_VRAM_ADDR(16) <= DBG_DAT_IN(0);
				when x"83" => DBG_CRAM_ADDR <= DBG_DAT_IN;
				when x"84" => DBG_OAM_ADDR <= DBG_DAT_IN;
				when x"85" => DBG_CTRL <= DBG_DAT_IN;
				when x"86" => DBG_BRK_HCNT(7 downto 0) <= DBG_DAT_IN;
				when x"87" => DBG_BRK_HCNT(8) <= DBG_DAT_IN(0);
				when x"88" => DBG_BRK_VCNT(7 downto 0) <= DBG_DAT_IN;
				when x"89" => DBG_BRK_VCNT(8) <= DBG_DAT_IN(0);
				when x"8A" => DBG_BG_EN <= DBG_DAT_IN;
				when x"8B" => DBG_OBJ_EN <= DBG_DAT_IN;
				when others => null;
			end case;
		end if;
	end if;
end process;
	
	
end rtl;