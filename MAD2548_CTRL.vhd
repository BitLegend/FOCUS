----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:50:39 02/21/2017 
-- Design Name: 
-- Module Name:    MAD2548_CTRL - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				1. Sample TLV2548, MODE: one shot  channels:  0
--              2. Conversion Clock = SCLK 1MHz
--              3. Long Sample
--              4. CFG = A280
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MAD2548_CTRL is 
    Port ( 
		   iRst          : in  STD_LOGIC;
           iClk          : in  STD_LOGIC;
		   ----------- TLV2548 interface -----------
           iMadSDO       : in  STD_LOGIC;
           oMadSDI       : out  STD_LOGIC;
           oMadSCLK      : out  STD_LOGIC;
           oMadCS_n      : out  STD_LOGIC;
		   ----------- Sampling control -----------
           iSmp          : in  STD_LOGIC;
		   -- last sample data
           oData         : out  STD_LOGIC_VECTOR (11 downto 0);	   
           oDataRdy      : out  STD_LOGIC);
end MAD2548_CTRL;

architecture Behavioral of MAD2548_CTRL is

   -- Component Declaration 
    COMPONENT SPI_MASTER
		Generic (		
		N        : positive := 16;-- serial word length  		
		CPOL     : STD_LOGIC := '0';-- SPI mode set (polarity)                                          
		CPHA     : STD_LOGIC := '0';-- SPI mode set (phase)   
		-- SPI clock divisor, if assigned to 8 ,then for 80MHz iClk, result in 5MHz SCLK
		SPI_2X_CLK_DIV : positive := 8);            
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         oSpiSsel : OUT  std_logic;
         oSpiSclk : OUT  std_logic;
         oSpiMOSI : OUT  std_logic;
         iSpiMISO : IN  std_logic;
         iWr : IN  std_logic;
         iData : IN  std_logic_vector(N-1 downto 0);
         oDataVal : OUT  std_logic;
         oData : OUT  std_logic_vector(N-1 downto 0)
        );
    END COMPONENT;
	
	-- configure data
	constant c16_Cfg    : STD_LOGIC_VECTOR (15 downto 0) := X"A280";
	constant c16_DetData    : STD_LOGIC_VECTOR (15 downto 0) := X"A000";	
	-- state definition
	TYPE states is (INITIAL, IDLE, DET, CFG, SAMPLE);
	signal pr_state, nx_state : states := INITIAL;	
	-- internal connect signal
	signal s_Wr             : STD_LOGIC := '0';

	signal s_DataVal        : STD_LOGIC := '0';
	signal s_DataValDl      : STD_LOGIC := '0';
    signal s16_DataCtrl     : STD_LOGIC_VECTOR (15 downto 0) := c16_DetData;
	signal s16_Data_reg     : STD_LOGIC_VECTOR (15 downto 0) := X"0000";
	
	signal s42_SPIIData     : STD_LOGIC_VECTOR (41 downto 0) := (others => '0');
	signal s42_SPIOData     : STD_LOGIC_VECTOR (41 downto 0) := (others => '0');
	-- counter
	signal s12_SmpIterCnt   : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');
	signal s4_DataCnt       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');	
	signal s_DataRdy        : STD_LOGIC := '0';
	signal s12_Data        : STD_LOGIC_VECTOR (11 downto 0) := (others => '0');	
	
	-- accumulate sum
	signal s15_SumData     : STD_LOGIC_VECTOR (14 downto 0) := (others => '0');
	-- state changed
	signal s_CntEqOne      : STD_LOGIC := '0';
	
begin
	---------------------------------------
	-- Instantiate the SPI master interface
	---------------------------------------
	SPI_master_Inst1: SPI_MASTER 
	generic map(
		N    => 42,   	
		CPOL => '0',                                     
		CPHA => '0',   
		-- SPI clock divisor, for 40MHz iClk, result in 4MHz SCLK
		SPI_2X_CLK_DIV => 20)
	PORT MAP (
		  iClk => iClk,
		  iRst => iRst,
		  oSpiSsel => oMadCS_n,
		  oSpiSclk => oMadSCLK,
		  oSpiMOSI => oMadSDI,
		  iSpiMISO => iMadSDO,
		  iWr => s_Wr,
		  iData => s42_SPIIData,
		  oDataVal => s_DataVal,
		  oData => s42_SPIOData
		);
		
		s42_SPIIData <= s16_DataCtrl&B"1111_1111_1111_1111_1111_1111_11";
		s16_Data_reg <= s42_SPIOData(41 downto 26);
	---------------------------------------
	-- sample interval counter
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			s_DataValDl <= s_DataVal; -- delay s_DataVal by one clock
			if(pr_state = DET or pr_state = CFG or pr_state = SAMPLE) then
				s12_SmpIterCnt <= '0'&s12_SmpIterCnt(10 downto 0) + 1;
			else
				s12_SmpIterCnt <= (others => '0');
			end if;
		end if;
	end process;		
	s_CntEqOne <= '1' when s12_SmpIterCnt = B"0_0000_0001" else
		'0';
	---------------------------------------
	-- sample data counter
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(pr_state = SAMPLE) then
				if(s12_SmpIterCnt(s12_SmpIterCnt'LEFT) = '1') then
					s4_DataCnt <= s4_DataCnt + 1;
				else
					s4_DataCnt <= s4_DataCnt;
				end if;
			else
				s4_DataCnt <= (others => '0');
			end if;
		end if;
	end process;	
	---------------------------------------
	-- Output assignment
	---------------------------------------
	oData <= s12_Data;
	oDataRdy <= s_DataRdy;
--=============================================================================
--  State Machine
--=============================================================================		
	---------------------------------------
	-- State register
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			pr_state <= INITIAL;
		elsif(iClk'event and iClk = '1') then
			pr_state <= nx_state;
		end if;
	end process;
	---------------------------------------
	-- Next state function
	---------------------------------------
	process(pr_state, iSmp, s12_SmpIterCnt,s_DataRdy)
	begin
		nx_state <= IDLE;
		case pr_state is
			when INITIAL =>
				nx_state <= DET;
			when DET =>
				if(s12_SmpIterCnt(s12_SmpIterCnt'LEFT) = '1') then
					nx_state <= CFG;
				else
					nx_state <= DET;
				end if;
			when CFG =>
				if(s12_SmpIterCnt(s12_SmpIterCnt'LEFT) = '1') then
					nx_state <= SAMPLE;
				else
					nx_state <= CFG;
				end if;
			when SAMPLE =>
				if(s_DataRdy = '1') then
					nx_state <= IDLE;
				else
					nx_state <= SAMPLE;
				end if;
			when IDLE =>
				if(iSmp = '1') then
					nx_state <= SAMPLE;
				else
					nx_state <= IDLE;
				end if;
			when others =>
				nx_state <= IDLE;
		end case;
	end process;
	---------------------------------------
	-- Output function
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s16_DataCtrl <= c16_DetData;
			s12_Data <= (others => '0');
			s_DataRdy <= '0';
			s_Wr <= '0';
			s15_SumData <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			s16_DataCtrl <= X"0000";
			s12_Data <= s12_Data;
			s_DataRdy <= '0';
			s_Wr <= '0';
			s15_SumData <= (others => '0');
			case pr_state is 
				when INITIAL =>
					s16_DataCtrl <= c16_DetData;
				when DET =>
					if(s_CntEqOne = '1') then
						s_Wr <= '1';
					else
						s_Wr <= '0';
					end if;
					s16_DataCtrl <= c16_DetData;
				when CFG =>
					if(s_CntEqOne = '1') then
						s_Wr <= '1';
					else
						s_Wr <= '0';
					end if;
					s16_DataCtrl <= c16_Cfg;
				when SAMPLE =>
					if(s_CntEqOne = '1') then
						s_Wr <= '1';
					else
						s_Wr <= '0';
					end if;				
					if(s_DataVal = '1' and s4_DataCnt(s4_DataCnt'LEFT) = '1') then
						s15_SumData <= s15_SumData + s16_Data_reg(15 downto 4);
					else
						s15_SumData <= s15_SumData;
					end if;					
					if(s_DataValDl = '1' and s4_DataCnt = "1111") then
						s_DataRdy <= '1';
						s12_Data <= s15_SumData(14 downto 3);
					else
						s_DataRdy <= '0';
						s12_Data <= s12_Data;
					end if;
				when IDLE =>
				when others =>					
			end case;
		end if;
	end process;		

end Behavioral;

