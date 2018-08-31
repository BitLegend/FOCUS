----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:03:40 03/31/2017 
-- Design Name: 
-- Module Name:    GUIDE_CTRL - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GUIDE_CTRL is
    Port ( iRst 			: in  STD_LOGIC;
           iClk 			: in  STD_LOGIC;
           iTick 			: in  STD_LOGIC;
           iTick40ms                      : in  STD_LOGIC;
		   -- prameters 
		   iPiezoUpX 	 	: in STD_LOGIC_VECTOR(11 downto 0) ; --3.7
		   iPiezoDwX 		: in STD_LOGIC_VECTOR(11 downto 0) ; --0.7
		   iPiezoUpY 		: in STD_LOGIC_VECTOR(11 downto 0) ; --3.7
		   iPiezoDwY 	 	: in STD_LOGIC_VECTOR(11 downto 0) ; --0.7
		
		   iScaleEUVX 		: in STD_LOGIC_VECTOR(15 downto 0) ;--0.4
		   iScaleXX  	 	: in STD_LOGIC_VECTOR(15 downto 0) ;--0.2
		   iScaleEUVY 	 	: in STD_LOGIC_VECTOR(15 downto 0) ;
		   iScaleXY  	 	: in STD_LOGIC_VECTOR(15 downto 0) ;

		   iOffsetX 	 	: in STD_LOGIC_VECTOR(15 downto 0) ; --1.9
		   iOffsetY  	 	: in STD_LOGIC_VECTOR(15 downto 0) ; --1.9		
		   -- Level transfer enable signal --
		   oG_IO_en         : out  STD_LOGIC;
		   ----------- CCD image channel -----------
		   iCCDChan         : in STD_LOGIC_VECTOR(7 downto 0);
           ----------- X AD677 -----------
		   oClk1 			: out  STD_LOGIC;
           oCal1 			: out  STD_LOGIC;
           oSmp1 			: out  STD_LOGIC;
           iSdata1 			: in  STD_LOGIC;-- X+ direction data
           iSclk1 			: in  STD_LOGIC;
           iSdata2 			: in  STD_LOGIC;-- X- direction data
           iSclk2 			: in  STD_LOGIC;
		   
           ----------- Y AD677 -----------
		   oClk3 			: out  STD_LOGIC;
           oCal3 			: out  STD_LOGIC;
           oSmp3 			: out  STD_LOGIC;
           iSdata3 			: in  STD_LOGIC;-- Y+ direction data
           iSclk3 			: in  STD_LOGIC;
           iSdata4 			: in  STD_LOGIC;-- Y- direction data
           iSclk4 			: in  STD_LOGIC;		   
		   ------------ sampling error counter -----------------
		   oGuideXErr 		: out  STD_LOGIC_VECTOR (7 downto 0);
		   oGuideYErr 		: out  STD_LOGIC_VECTOR (7 downto 0);
		   
		   ----------- original Output -----------
		   oData1           : out STD_LOGIC_VECTOR(15 downto 0);
		   oData2           : out STD_LOGIC_VECTOR(15 downto 0);
		   oData3           : out STD_LOGIC_VECTOR(15 downto 0);
		   oData4           : out STD_LOGIC_VECTOR(15 downto 0);
		   oRdy10X          : out STD_LOGIC;
		   ----------- Diff and nomalized Output -----------
		   -- signed: 1 sign bit and 14 fractional length
		   oDataXNor		: out STD_LOGIC_VECTOR(15 downto 0);
		   oDataYNor        : out STD_LOGIC_VECTOR(15 downto 0);		   
		   ----------- scaled Output -----------
		   oPiezoX          : out STD_LOGIC_VECTOR(11 downto 0);
		   oPiezoY          : out STD_LOGIC_VECTOR(11 downto 0)		   			
			
		   );
end GUIDE_CTRL;

architecture Behavioral of GUIDE_CTRL is
--=============================================================================
--  Components declaration
--=============================================================================		  
	COMPONENT DIFF_NOR
	PORT(
		iRst : IN std_logic;
		iClk : IN std_logic;
		iData1 : IN std_logic_vector(15 downto 0);
		iData2 : IN std_logic_vector(15 downto 0);
		iData3 : IN std_logic_vector(15 downto 0);
		iData4 : IN std_logic_vector(15 downto 0);
		iRdy : IN std_logic;          
		oDataXNor : OUT std_logic_vector(15 downto 0);
		oDataYNor : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;

	
	COMPONENT AD677DATA
	PORT(
		iRst : IN std_logic;
		iClk : IN std_logic;
		iSmp : IN std_logic;
		iSCLK : IN std_logic;
		iSDATA : IN std_logic;          
		oSt : OUT std_logic;
		oErrNum  : OUT STD_LOGIC_VECTOR(3 downto 0);
		oDataReady : OUT std_logic;
		oData : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;
	
	COMPONENT AD677CTRL
	PORT(
		iRst : IN std_logic;
		iClk : IN std_logic;
		iAD677_Cal : IN std_logic;
		iAD677_Smp : IN std_logic;          
		oAD677_Clk : OUT std_logic;
		oAD677_Cal : OUT std_logic;
		oAD677_Smp : OUT std_logic
		);
	END COMPONENT;	
	-- Multiplier V10.0
	COMPONENT Multi_Scale
	PORT (
		clk : IN STD_LOGIC;
		-- Signed 14 fraction length
		a : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		-- signed
		b : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		-- High 18 bits
		p : OUT STD_LOGIC_VECTOR(17 DOWNTO 0)
	    );	
    END COMPONENT;	
--=============================================================================
--  Signal definition
--=============================================================================		  
	signal s4_iniCnt        : STD_LOGIC_VECTOR(3 downto 0) := (others => '0'); 
	signal s2_smpCnt        : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
	
        signal s_cal            : STD_LOGIC := '0';
	signal s_smp            : STD_LOGIC := '0';

	signal s_daRdy1         : STD_LOGIC := '0';
	signal s_daRdy2         : STD_LOGIC := '0';	
	signal s_daRdy3         : STD_LOGIC := '0';
	signal s_daRdy4         : STD_LOGIC := '0';
	signal s_rdy            : STD_LOGIC := '0';
	signal s_rdy_reg        : STD_LOGIC := '0';
	-- register for the data ready signal
	signal s_daRdy1_reg     : STD_LOGIC := '0';
	signal s_daRdy2_reg     : STD_LOGIC := '0';	
	signal s_daRdy3_reg     : STD_LOGIC := '0';
	signal s_daRdy4_reg     : STD_LOGIC := '0';
	-- time counter
	signal i_cnt10          : integer range 0 to 9 := 0;
	
	signal s16_data1        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_data2        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 	
	signal s16_data3        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_data4        : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	
	signal s16_dataXNor     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_dataYNor     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 	
	
	-- guide telescope data scale
	
	signal s18_PiezoXMulti  :  STD_LOGIC_VECTOR (17 downto 0) := (others => '0'); 
	signal s18_PiezoYMulti  :  STD_LOGIC_VECTOR (17 downto 0) := (others => '0'); 
	
	signal s19_PiezoXMOffs  :  STD_LOGIC_VECTOR (18 downto 0) := (others => '0'); 
	signal s19_PiezoYMOffs  :  STD_LOGIC_VECTOR (18 downto 0) := (others => '0'); 
	
	signal s12_PiezoX       :  STD_LOGIC_VECTOR (11 downto 0) := c12_stbXPos;	
	signal s12_PiezoY       :  STD_LOGIC_VECTOR (11 downto 0) := c12_stbYPos;		
	
	signal s16_selScaleX    :  STD_LOGIC_VECTOR(15 downto 0) := c16_ScaleXX;
	signal s16_selScaleY    :  STD_LOGIC_VECTOR(15 downto 0) := c16_ScaleXY;	
	
begin

	AD677CTRL_inst1: AD677CTRL PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iAD677_Cal => s_cal,
		iAD677_Smp => s_smp,
		oAD677_Clk => oClk1,
		oAD677_Cal => oCal1,
		oAD677_Smp => oSmp1
	);
	
	AD677DATA_inst1: AD677DATA PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iSmp => s_smp,
		iSCLK => iSclk1,
		iSDATA => iSdata1,
		oSt => open,
		oErrNum => oGuideXErr(7 downto 4),
		oDataReady => s_daRdy1,
		oData => s16_data1
	);
	
	AD677DATA_inst2: AD677DATA PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iSmp => s_smp,
		iSCLK => iSclk2,
		iSDATA => iSdata2,
		oSt => open,
		oErrNum => oGuideXErr(3 downto 0),
		oDataReady => s_daRdy2,
		oData => s16_data2
	);

	AD677CTRL_inst3: AD677CTRL PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iAD677_Cal => s_cal,
		iAD677_Smp => s_smp,
		oAD677_Clk => oClk3,
		oAD677_Cal => oCal3,
		oAD677_Smp => oSmp3
	);
	
	AD677DATA_inst3: AD677DATA PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iSmp => s_smp,
		iSCLK => iSclk3,
		iSDATA => iSdata3,
		oSt => open,
		oErrNum => oGuideYErr(7 downto 4),
		oDataReady => s_daRdy3,
		oData => s16_data3
	);
	
	AD677DATA_inst4: AD677DATA PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iSmp => s_smp,
		iSCLK => iSclk4,
		iSDATA => iSdata4,
		oSt => open,
		oErrNum => oGuideYErr(3 downto 0),
		oDataReady => s_daRdy4,
		oData => s16_data4
	);
	
	DIFF_NOR_inst0: DIFF_NOR PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iData1 => s16_data1,
		iData2 => s16_data2,
		iData3 => s16_data3,
		iData4 => s16_data4,
		iRdy => s_rdy,
		oDataXNor => s16_dataXNor,
		oDataYNor => s16_dataYNor
	);
			
	MultiScale_instX : Multi_Scale
	PORT MAP (
		clk => iClk,
		a => s16_dataXNor,
		b => s16_selScaleX,
		p => s18_PiezoXMulti
	);			
	MultiScale_instY : Multi_Scale
	PORT MAP (
		clk => iClk,
		a => s16_dataYNor,
		b => s16_selScaleY,
		p => s18_PiezoYMulti
	);					
			
	---------------------------------------
	-- Enable level transfer 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			oG_IO_en <= '0';
		elsif(iClk'event and iClk = '1') then
			oG_IO_en <= '0';
		end if;
	end process;	
	---------------------------------------
	-- Calibration counter
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s4_iniCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(s4_iniCnt >= X"5") then
				s4_iniCnt <= s4_iniCnt;
			else
				s4_iniCnt <= s4_iniCnt + 1;
			end if;
		end if;
	end process;	
	s_cal <= '1' when s4_iniCnt = X"4" else
			 '0';
	---------------------------------------
	-- Register four channel ready signal 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s_daRdy1_reg <= '0';
			s_daRdy2_reg <= '0';
			s_daRdy3_reg <= '0';
			s_daRdy4_reg <= '0';
		elsif(iClk'event and iClk = '1') then
			s_rdy_reg <= s_rdy;	
			s_rdy <= s_daRdy1_reg and s_daRdy2_reg and s_daRdy3_reg and s_daRdy4_reg;
			if(s_smp = '1') then
				s_daRdy1_reg <= '0';
				s_daRdy2_reg <= '0';
				s_daRdy3_reg <= '0';
				s_daRdy4_reg <= '0';
			else
				if(s_daRdy1 = '1') then
					s_daRdy1_reg <= '1';
				else
					s_daRdy1_reg <= s_daRdy1_reg;
				end if;
				if(s_daRdy2 = '1') then
					s_daRdy2_reg <= '1';
				else
					s_daRdy2_reg <= s_daRdy2_reg;
				end if;
				if(s_daRdy3 = '1') then
					s_daRdy3_reg <= '1';
				else
					s_daRdy3_reg <= s_daRdy3_reg;
				end if;
				if(s_daRdy4 = '1') then
					s_daRdy4_reg <= '1';
				else
					s_daRdy4_reg <= s_daRdy4_reg;
				end if;
			end if;
		end if;
	end process;		
	
	---------------------------------------
	-- Counter for the 1ms time 
	---------------------------------------	
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			i_cnt10 <= 0;
		elsif(iClk'event and iClk = '1') then
			if(s_smp = '1') then
				if(i_cnt10 = 9) then
					i_cnt10 <= 0;
				else
					i_cnt10 <= i_cnt10 + 1;
				end if;
			else
				i_cnt10 <= i_cnt10;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Output ready signal 10X tick
	---------------------------------------	
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			oRdy10X <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_rdy = '1' and s_rdy_reg = '0' and i_cnt10 = 9) then
				oRdy10X <= '1';
			else
				oRdy10X <= '0';
			end if;
		end if;
	end process;	

	
	---------------------------------------
	-- Control the beginning of sample signal   
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s2_smpCnt <= (others => '0');
			s_smp <= '0';
		elsif(iClk'event and iClk = '1') then
			if(iTick40ms = '1') then
				if(s2_smpCnt = B"10") then
					s2_smpCnt <= s2_smpCnt;
				else
					s2_smpCnt <= s2_smpCnt + 1;
				end if;
			else
				s2_smpCnt <= s2_smpCnt;
			end if;			
			if(s2_smpCnt = B"10") then 
				s_smp <= iTick;
			else
				s_smp <= s_smp;
			end if;
		end if;
	end process;			
	
	oData1 <= s16_data1;
	oData2 <= s16_data2;
	oData3 <= s16_data3;
	oData4 <= s16_data4;	
	
	oDataXNor <= s16_dataXNor;
	oDataYNor <= s16_dataYNor;
	
	oPiezoX <= s12_PiezoX;
	oPiezoY <= s12_PiezoY;
	---------------------------------------
	-- Select scale parameters
	---------------------------------------	
	process(iClk, iRst)
	begin
		if(iRst = '1')then
			s16_selScaleX <= c16_ScaleXX;
			s16_selScaleY <= c16_ScaleXY;
		elsif(iClk'event and iClk = '1') then
			s16_selScaleX <= s16_selScaleX;
			s16_selScaleY <= s16_selScaleY;
			case iCCDChan is
				when c8_ChanEUV =>
					s16_selScaleX <= iScaleEUVX;		
					s16_selScaleY <= iScaleEUVY;						
				when c8_ChanX =>
					s16_selScaleX <= iScaleXX;
					s16_selScaleY <= iScaleXY;
				when others =>
			end case;
		end if;
	end process;
	
	---------------------------------------
	-- Offset piezo positon data
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s19_PiezoXMOffs <= (others => '0'); 
			s19_PiezoYMOffs <= (others => '0'); 
		elsif(iClk'event and iClk = '1') then
			s19_PiezoXMOffs <= SXT(s18_PiezoXMulti,19) + ioffsetX;
			s19_PiezoYMOffs <= SXT(s18_PiezoYMulti,19) + ioffsetY;
		end if;
	end process;	
	
	
	
	---------------------------------------
	-- Guide telescope data scale
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s12_PiezoX <= (others => '0'); 
			s12_PiezoY <= (others => '0'); 
		elsif(iClk'event and iClk = '1') then
			-- X
			if((s19_PiezoXMOffs > ('0'&iPiezoUpX)) or (s19_PiezoXMOffs < ('0'&iPiezoDwX))) then
				s12_PiezoX <= s12_PiezoX;
			else
				s12_PiezoX <= s19_PiezoXMOffs(11 downto 0);
			end if;
			-- Y
			if((s19_PiezoYMOffs > ('0'&iPiezoUpY)) or (s19_PiezoYMOffs < ('0'&iPiezoDwY))) then
				s12_PiezoY <= s12_PiezoY;
			else
				s12_PiezoY <= s19_PiezoYMOffs(11 downto 0);
			end if;
		end if;
	end process;
	
end Behavioral;

