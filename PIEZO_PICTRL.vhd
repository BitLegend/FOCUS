----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:46:31 03/14/2017 
-- Design Name: 
-- Module Name:    PIEZO_PICTRL - Behavioral 
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
USE ieee.std_logic_signed.all;
use IEEE.STD_LOGIC_ARITH.ALL;
library work;
use work.mytypes.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PIEZO_PICTRL is
    Port ( 
		   iClk : in  STD_LOGIC;
           iRst : in  STD_LOGIC;
		   
		   ----------- Control signal -----------
           iTick         : in  STD_LOGIC;
		   -- 
		   iPiezoDwX     : in STD_LOGIC_VECTOR(11 downto 0);
		   iPiezoDwY     : in STD_LOGIC_VECTOR(11 downto 0);
		   -- Level transfer enable signal --
		   oAD_IO_en	 : out STD_LOGIC;	   
		   -- bit0 for stabilization, bit1 for adjust focal plane
		   iEnStab       : in  STD_LOGIC_VECTOR(1 downto 0); -- Is stabilization and adjust enabled
           -- bit0 for channel A, 0 : open-loop; 1 : close-loop		  
		   iClose        : in  STD_LOGIC_VECTOR(2 downto 0); -- Is close loop controlled
		   
		   ----------- Set data -----------
		   iSetDataA     : in STD_LOGIC_VECTOR(11 downto 0); -- X direction
		   iSetDataB     : in STD_LOGIC_VECTOR(11 downto 0); -- Y direction
		   iSetDataC     : in STD_LOGIC_VECTOR(11 downto 0); -- Z direction
		   ----------- Set data -----------
		   iCtrlParas    : in a3of16;
		   ----------- Initial state -----------
		   -- 11:Ready for control 10: DIS_STB  01: DIS_ADJ 00: DIS_ALL
		   oState        : out STD_LOGIC_VECTOR (1 downto 0); -- stablization and adjustment State	

		   oPiezoX       : out STD_LOGIC_VECTOR (11 downto 0);
		   oPiezoY       : out STD_LOGIC_VECTOR (11 downto 0);
		   oPiezoZ       : out STD_LOGIC_VECTOR (11 downto 0);
		   ----------- TLV2548 interface -----------
           iPadSDO       : in  STD_LOGIC;
           oPadSDI       : out  STD_LOGIC;
           oPadSCLK      : out  STD_LOGIC;
           oPadCS_n      : out  STD_LOGIC;
		   ----------- DAC port ----------- 
           oDA_DB        : out  STD_LOGIC_VECTOR (11 downto 0);
           oDA_A         : out  STD_LOGIC_VECTOR (1 downto 0);
           oDA_CS        : out  STD_LOGIC;
           oDA_LDAC      : out  STD_LOGIC;
		   ------------ Trace Error ----------------
		   oErrX		 : out STD_LOGIC_VECTOR(7 downto 0);
		   oErrY         : out STD_LOGIC_VECTOR(7 downto 0)
		   );
end PIEZO_PICTRL;

architecture Behavioral of PIEZO_PICTRL is
--=============================================================================
--  Components declaration
--=============================================================================		  
   COMPONENT PAD2548_CTRL
    PORT(
         iRst : IN  STD_LOGIC;
         iClk : IN  STD_LOGIC;
		 oAD_IO_en	: OUT STD_LOGIC;	   
         iPadSDO : IN  STD_LOGIC;
         oPadSDI : OUT  STD_LOGIC;
         oPadSCLK : OUT  STD_LOGIC;
         oPadCS_n : OUT  STD_LOGIC;
         iSmp : IN  STD_LOGIC;
         oData0 : OUT  STD_LOGIC_VECTOR(11 downto 0);
         oData1 : OUT  STD_LOGIC_VECTOR(11 downto 0);
         oData2 : OUT  STD_LOGIC_VECTOR(11 downto 0);
         oData3 : OUT  STD_LOGIC_VECTOR(11 downto 0);
         oDataRdy : OUT  STD_LOGIC_VECTOR (3 downto 0)
        );
    END COMPONENT;
	COMPONENT PIEZO_DAC8412
	PORT(
		iRst : IN STD_LOGIC;
		iClk : IN STD_LOGIC;
		iDB_A : IN STD_LOGIC_VECTOR(11 downto 0);
		iDB_B : IN STD_LOGIC_VECTOR(11 downto 0);
		iDB_C : IN STD_LOGIC_VECTOR(11 downto 0);
		iDB_D : IN STD_LOGIC_VECTOR(11 downto 0);
		iWr : IN STD_LOGIC;          
		oDA_DB : OUT STD_LOGIC_VECTOR(11 downto 0);
		oDA_A : OUT STD_LOGIC_VECTOR(1 downto 0);
		oDA_CS : OUT STD_LOGIC;
		oDA_LDAC : OUT STD_LOGIC
		);
	END COMPONENT;
		
--	COMPONENT DAC8412_OUT_CTRL
--	PORT(
--		iRst : IN STD_LOGIC;
--		iClk : IN STD_LOGIC;
--		iTick : IN STD_LOGIC;
--		iUpdate : IN STD_LOGIC;
--		iEnStab : IN STD_LOGIC_VECTOR(1 downto 0);
--		iDB_A : IN STD_LOGIC_VECTOR(11 downto 0);
--		iDB_B : IN STD_LOGIC_VECTOR(11 downto 0);
--		iDB_C : IN STD_LOGIC_VECTOR(11 downto 0);          
--		oState : OUT STD_LOGIC_VECTOR(2 downto 0);
--		oDA_DB : OUT STD_LOGIC_VECTOR(11 downto 0);
--		oDA_A : OUT STD_LOGIC_VECTOR(1 downto 0);
--		oDA_CS : OUT STD_LOGIC;
--		oDA_LDAC : OUT STD_LOGIC
--		);
--	END COMPONENT;

    COMPONENT PI
	GENERIC(
		    -- Slope control parameters: limit the change in one interval,fixdt(1,27,14)
			gUpSlope        : STD_LOGIC_VECTOR(26 downto 0) := "000"&X"016c17";--40mA 9.6Hz 12uF
			gDwSlope        : STD_LOGIC_VECTOR(26 downto 0) := "111"&X"fe93e9";
			-- prarameter to adjust the sensitivity : fraction length = 14 - c_SumFraN
			gFracN          : integer := 4; 
			-- anti-windup parameter : power of 2; = (2^gND)/(2^14)  9=<gND<=14
			gND             : integer := 10
		);	
    PORT(
         iClk : IN  STD_LOGIC;
         iRst : IN  STD_LOGIC;
         iUpdate : IN  STD_LOGIC;
		 iClose : in  STD_LOGIC;
		 iManual : in  STD_LOGIC_VECTOR (11 downto 0); -- Manual set point
         iSP : IN  STD_LOGIC_VECTOR(11 downto 0);
         iPV : IN  STD_LOGIC_VECTOR(11 downto 0);
		-- PI parameters Data Type: fixed-point data, Fraction length 20			
		 iPaNow : in  STD_LOGIC_VECTOR (15 downto 0);
		 iPaPre : in  STD_LOGIC_VECTOR (15 downto 0);
		 oVal : out STD_LOGIC;
         oCtrl : OUT  STD_LOGIC_VECTOR(17 downto 0)
        );
    END COMPONENT;
	
    COMPONENT BIQUAD_X0
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(17 downto 0)
        );
    END COMPONENT;		
    COMPONENT BIQUAD_X
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(11 downto 0)
        );
    END COMPONENT;	
 
    COMPONENT BIQUAD_Y0
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(17 downto 0)
        );
    END COMPONENT;		
    COMPONENT BIQUAD_Y
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(11 downto 0)
        );
    END COMPONENT;		

    COMPONENT BIQUAD_Z0
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(17 downto 0)
        );
    END COMPONENT;	
    COMPONENT BIQUAD_Z
    PORT(
         iRst : in  STD_LOGIC;
         iClk : IN  STD_LOGIC;
         iND : IN  STD_LOGIC;
         iData : IN  STD_LOGIC_VECTOR(17 downto 0);
         oRdy : OUT  STD_LOGIC;
         oData : OUT  STD_LOGIC_VECTOR(11 downto 0)
        );
    END COMPONENT;		
	
	-- Multiplier V10.0
	COMPONENT Multi_OP
	PORT (
		clk : IN STD_LOGIC;
		a : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		b : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		p : OUT STD_LOGIC_VECTOR(10 DOWNTO 0)
	    );	
    END COMPONENT;	
--=============================================================================
--  Signal definition
--=============================================================================		  
	-- State definition
	Type STATE_FSM is (INITIAL, READY, DIS_STB_PR, DIS_STB, DIS_ADJ_PR, 
	    DIS_ADJ, DIS_ALL_PR, DIS_ALL);
	signal pr_state, nx_state : STATE_FSM := DIS_ALL;
	-- Initial time counter
    constant c_CntVal    : STD_LOGIC_VECTOR(9 downto 0) := (others => '1');
    constant c_CntValHaf : STD_LOGIC_VECTOR(8 downto 0) := (others => '1');
	signal s10_IniCnt   :  STD_LOGIC_VECTOR(9 downto 0) := (others => '0');

	signal s12_PvA       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_PvB       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_PvC       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	
	signal s4_PvRdy      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	
	signal s12_DacA      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_DacB      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_DacC      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
    signal s_DacUpd      : STD_LOGIC; 
	signal s2_EnSt       : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
	
	-- Control parameters 
	signal s16_ParaXI    : STD_LOGIC_VECTOR(15 downto 0) := c_ParaXI;
	signal s16_ParaYI    : STD_LOGIC_VECTOR(15 downto 0) := c_ParaYI;
	signal s16_ParaZI    : STD_LOGIC_VECTOR(15 downto 0) := c_ParaZI;
	
	-- Target position
	signal s12_ManA      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_ManB      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_ManC      : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');	

	signal s12_TarClA    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_TarClB    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_TarClC    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');	
	
	-- Set value when close loop 	 
	signal s18_PIA       : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
	signal s18_PIB       : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
	signal s18_PIC       : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
	signal s_PIValA      : STD_LOGIC := '0';
	signal s_PIValB      : STD_LOGIC := '0';
	signal s_PIValC      : STD_LOGIC := '0';		
	
	-- notch filter output
	signal s12_NotchA    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_NotchB    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_NotchC    : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');	
	signal s_NotchValA   : STD_LOGIC := '0';
	signal s_NotchValB   : STD_LOGIC := '0';
	signal s_NotchValC   : STD_LOGIC := '0';
	
	signal s13_CtrlA     : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	signal s13_CtrlB     : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	signal s13_CtrlC     : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	-- DA data
	signal s12_DB_A  	 : STD_LOGIC_VECTOR(11 downto 0) := X"800";
	signal s12_DB_B   	 : STD_LOGIC_VECTOR(11 downto 0) := X"800";
	signal s12_DB_C      : STD_LOGIC_VECTOR(11 downto 0) := X"800";
	constant s12_DB_D    : STD_LOGIC_VECTOR(11 downto 0) := X"800";	
	-- connect signal 
	signal s_Wr          : STD_LOGIC := '0';
	signal s_DisAll      : STD_LOGIC := '0';
		 
	signal s_PIRstA      : STD_LOGIC := '0';
	signal s_PIRstB      : STD_LOGIC := '0';
	signal s_PIRstC      : STD_LOGIC := '0';	
	
	signal s3_IsClose    : STD_LOGIC_VECTOR(2 downto 0) := (others => '1');
	
	-- scale iSet for open loop : minus min
	signal s13_TarMusMinA: STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	signal s13_TarMusMinB: STD_LOGIC_VECTOR(12 downto 0) := (others => '0');	
	
	-- Set value when open loop 
	signal s11_OpA       : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
	signal s11_OpB       : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
	signal s11_OpC       : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');	
	

	
	-- Enable DAC output delay
	-- signal s4_UpdDelay  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');	
	-- stablization and adjustment state definition
	constant c_Rdy    : STD_LOGIC_VECTOR(1 downto 0) := "11";
	constant c_DisStb : STD_LOGIC_VECTOR(1 downto 0) := "10";
	constant c_DisAdj : STD_LOGIC_VECTOR(1 downto 0) := "01";
	constant c_DisAll : STD_LOGIC_VECTOR(1 downto 0) := "00";
begin

	PAD2548_CTRL_Inst: PAD2548_CTRL 
	PORT MAP(
		iRst => iRst,
		iClk => iClk,
		oAD_IO_en => oAD_IO_en,
		iPadSDO => iPadSDO,
		oPadSDI => oPadSDI,
		oPadSCLK => oPadSCLK,
		oPadCS_n => oPadCS_n,
		iSmp => iTick,
		oData0 => s12_PvA,
		oData1 => s12_PvB,
		oData2 => s12_PvC,
		oData3 => open,
		oDataRdy => s4_PvRdy
	);
	PIEZO_DAC8412_inst: PIEZO_DAC8412 PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iDB_A => s12_DB_A,
		iDB_B => s12_DB_B,
		iDB_C => s12_DB_C,
		iDB_D => s12_DB_D,
		iWr => s_Wr,
		oDA_DB => oDA_DB,
		oDA_A => oDA_A,
		oDA_CS => oDA_CS,
		oDA_LDAC => oDA_LDAC
	);	
--	Inst_DAC8412_OUT_CTRL0: DAC8412_OUT_CTRL 
--	PORT MAP(
--		iRst => iRst,
--		iClk => iClk,
--		iTick => iTick,
--		iUpdate => s_DacUpd,
--  	iEnStab => iEnStab,
--		oState => s2_EnSt,
--		iDB_A => s12_DacA,
--		iDB_B => s12_DacB,
--		iDB_C => s12_DacC,
--		oDA_DB => oDA_DB,
--		oDA_A => oDA_A,
--		oDA_CS => oDA_CS,
--		oDA_LDAC => oDA_LDAC
--	);	
	
	PI_instA: PI 
   	GENERIC MAP(
	    gUpSlope       =>   "000"&X"016c17",--40mA 9.6Hz 12uF
		gDwSlope       =>   "111"&X"fe93e9",
		gFracN         => 8,
		gND            =>9
		)
	PORT MAP(
		iClk => iClk,
		iRst => s_PIRstA,
		iUpdate => s4_PvRdy(0),
		iClose => s3_IsClose(0),
		iManual => s12_ManA,
		iSP => s12_TarClA,
		iPV => s12_PvA,
		iPaNow => s16_ParaXI,
		iPaPre => s16_ParaXI,
		oVal => s_PIValA,
		oCtrl => s18_PIA
	);
	-- Instantiate Notch filter 
   BIQUAD_X_inst: BIQUAD_X PORT MAP (
          iRst => s_PIRstA,
          iClk => iClk,
          iND => s_PIValA,
          iData => s18_PIA,
          oRdy => s_NotchValA,
          oData => s12_NotchA
        );
		
	PI_instB: PI 
   	GENERIC MAP(
	    gUpSlope       =>  "000"&X"016c17",--40mA 9.6Hz 12uF
		gDwSlope       =>  "111"&X"fe93e9",
		gFracN         => 8,
		gND            =>9
		)
	PORT MAP(
		iClk => iClk,
		iRst => s_PIRstB,
		iUpdate => s4_PvRdy(1),
		iClose => s3_IsClose(1),
		iManual => s12_ManB,
		iSP => s12_TarClB,
		iPV => s12_PvB,
		iPaNow => s16_ParaYI,
		iPaPre => s16_ParaYI,
		oVal => s_PIValB,
		oCtrl => s18_PIB
	);
	
	-- Instantiate Notch filter 
   BIQUAD_Y_inst: BIQUAD_Y PORT MAP (
          iRst => s_PIRstB,
          iClk => iClk,
          iND => s_PIValB,
          iData => s18_PIB,
          oRdy => s_NotchValB,
          oData => s12_NotchB
        );
		
	PI_instC: PI 
   	GENERIC MAP(
	    gUpSlope       =>  "000"&X"002bb1", -- 10mA 25uf 1.15hz
		gDwSlope       =>  "111"&X"ffd44f",
		gFracN         => 5,
		gND            =>9
		)
	PORT MAP(
		iClk => iClk,
		iRst => s_PIRstC,
		iUpdate => s4_PvRdy(2),
		iClose => s3_IsClose(2),
		iManual => s12_ManC,
		iSP => s12_TarClC,
		iPV => s12_PvC,
		iPaNow => s16_ParaZI,
		iPaPre => s16_ParaZI,
		oVal => s_PIValC,
		oCtrl => s18_PIC
	);
	-- Instantiate Notch filter 
   Biquad_Z_inst: BIQUAD_Z PORT MAP (
          iRst => s_PIRstC,
          iClk => iClk,
          iND => s_PIValC,
          iData => s18_PIC,
          oRdy => s_NotchValC,
          oData => s12_NotchC
        );
	
	Inst_MultiOpA : Multi_OP
	PORT MAP (
		clk => iClk,
		a => s13_TarMusMinA(11 downto 0),
		b => c_ParaOpA,
		p => s11_OpA
	);
	Inst_MultiOpB : Multi_OP
	PORT MAP (
		clk => iClk,
		a => s13_TarMusMinB(11 downto 0),
		b => c_ParaOpB,
		p => s11_OpB
	);
	Inst_MultiOpC : Multi_OP
	PORT MAP (
		clk => iClk,
		a => s12_TarClC,
		b => c_ParaOpC,
		p => s11_OpC
	);
	-----------------------------------
	-- Calculate the trace error
	-----------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			oErrX <= (others => '0');
			oErrY <= (others => '0');		
		elsif(iClk'event and iClk = '1') then
			oErrX <= ('0'&s12_TarClA(11 downto 5)) - ('0'&s12_PvA(11 downto 5));
			oErrY <= ('0'&s12_TarClB(11 downto 5)) - ('0'&s12_PvB(11 downto 5));
		end if;
	end process;	
	
	-----------------------------------
	-- Constrain the control parameters
	-----------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s16_ParaXI <= c_ParaXI;
			s16_ParaYI <= c_ParaYI;	
			s16_ParaZI <= c_ParaZI;		
		elsif(iClk'event and iClk = '1') then
			if(iCtrlParas(0) > c_ParaXIUp) then
				s16_ParaXI <= c_ParaXIUp;
			elsif(iCtrlParas(0) < c_ParaXILw) then
				s16_ParaXI <= c_ParaXILw;
			else
				s16_ParaXI <= iCtrlParas(0);
			end if;
			if(iCtrlParas(1) > c_ParaYIUp) then
				s16_ParaYI <= c_ParaYIUp;
			elsif(iCtrlParas(1) < c_ParaYILw) then
				s16_ParaYI <= c_ParaYILw;
			else
				s16_ParaYI <= iCtrlParas(1);
			end if;
			if(iCtrlParas(2) > c_ParaZIUp) then
				s16_ParaZI <= c_ParaZIUp;
			elsif(iCtrlParas(2) < c_ParaZILw) then
				s16_ParaZI <= c_ParaZILw;
			else
				s16_ParaZI <= iCtrlParas(2);
			end if;
		end if;
	end process;			
	-----------------------------------
	-- Minus the min value of target position
	-----------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s13_TarMusMinA <= (others => '0');
			s13_TarMusMinB <= (others => '0');		
		elsif(iClk'event and iClk = '1') then
			s13_TarMusMinA <= ('0'&s12_TarClA) - ('0'&iPiezoDwX);
			s13_TarMusMinB <= ('0'&s12_TarClB) - ('0'&iPiezoDwY);
		end if;
	end process;		

	-----------------------------------
	-- Calculate control data  
	-----------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s13_CtrlA <= '0'&X"800";
			s13_CtrlB <= '0'&X"800";
			s13_CtrlC <= '0'&X"800";	
			s_DacUpd <= '0';			
		elsif(iClk'event and iClk = '1') then
			s13_CtrlA <= s12_NotchA + ('0'&X"800");
			s13_CtrlB <= s12_NotchB + ('0'&X"800");
			s13_CtrlC <= s12_NotchC + ('0'&X"800");
			s_DacUpd <= s_NotchValA or s_NotchValB or s_NotchValC;
		end if;
	end process;	
	-- DAC set data select
	s12_DacA <= s13_CtrlA(11 downto 0);
	s12_DacB <= s13_CtrlB(11 downto 0);
	s12_DacC <= s13_CtrlC(11 downto 0);	

	---------------------------------------
	-- Initial time counter 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s10_IniCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(pr_state = INITIAL or pr_state = DIS_STB_PR 
				or pr_state = DIS_ADJ_PR or pr_state = DIS_ALL_PR) 
			then
				if(iTick = '1') then
					s10_IniCnt <= s10_IniCnt + 1;
				else
					s10_IniCnt <= s10_IniCnt;
				end if;
			else
				s10_IniCnt <= (others => '0');
			end if;
		end if;
	end process;		
	
	-- PI algorithm reset control
	s_PIRstA <= iRst ;--or ( not s2_EnSt(0) );
	s_PIRstB <= iRst ;--or ( not s2_EnSt(0) );
	s_PIRstC <= iRst ;--or ( not s2_EnSt(1) );

  -- Output assign	 
	oState <= s2_EnSt;
	
	oPiezoX <= s12_PvA;
	oPiezoY <= s12_PvB;
	oPiezoZ <= s12_PvC;
			
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
			if(iTick = '1') then
				pr_state <= nx_state;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Next state function
	---------------------------------------
	process(pr_state,s10_IniCnt,iEnStab)
	begin
		nx_state <= INITIAL;
		case pr_state is
			when INITIAL =>
				if(s10_IniCnt = c_CntVal) then
					if(iEnStab = "10") then
						nx_state <= DIS_STB_PR;
					elsif(iEnStab = "01") then
						nx_state <= DIS_ADJ_PR;
					elsif(iEnStab = "00") then
						nx_state <= DIS_ALL_PR;
					else
						nx_state <= READY;
					end if;
				else
					nx_state <= INITIAL;
				end if;		
			when READY =>
				if(iEnStab = "10") then
					nx_state <= DIS_STB_PR;
				elsif(iEnStab = "01") then
					nx_state <= DIS_ADJ_PR;
				elsif(iEnStab = "00") then
					nx_state <= DIS_ALL_PR;
				else
					nx_state <= READY;
				end if;
			when DIS_STB_PR =>
				if(s10_IniCnt = c_CntVal) then
					nx_state <= DIS_STB;
				else
					nx_state <= DIS_STB_PR;
				end if;
			when DIS_STB =>
				if(iEnStab = "10") then
					nx_state <= DIS_STB;
				elsif(iEnStab = "01") then
					nx_state <= DIS_ADJ_PR;
				elsif(iEnStab = "00") then
					nx_state <= DIS_ALL_PR;
				else
					nx_state <= READY;
				end if;	
			when DIS_ADJ_PR =>
				if(s10_IniCnt = c_CntVal) then
					nx_state <= DIS_ADJ;
				else
					nx_state <= DIS_ADJ_PR;
				end if;
			when DIS_ADJ =>
				if(iEnStab = "10") then
					nx_state <= DIS_STB_PR;
				elsif(iEnStab = "01") then
					nx_state <= DIS_ADJ;
				elsif(iEnStab = "00") then
					nx_state <= DIS_ALL_PR;
				else
					nx_state <= READY;
				end if;		
			when DIS_ALL_PR =>
				if(s10_IniCnt = c_CntVal) then
					nx_state <= DIS_ALL;
				else
					nx_state <= DIS_ALL_PR;
				end if;
			when DIS_ALL =>
				if(iEnStab = "00") then
					nx_state <= DIS_ALL;
				else
					nx_state <= INITIAL;
				end if;				
			when others =>
				nx_state <= INITIAL;
		end case;
	end process;
	---------------------------------------
	-- Output function
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s12_DB_A <= X"800";     
			s12_DB_B <= X"800";       
			s12_DB_C <= X"800";       
			s12_TarClA <= X"800"; 
			s12_TarClB <= X"800"; 
			s12_TarClC <= X"800"; 
			s12_ManA <= X"000";
			s12_ManB <= X"000";
			s12_ManC <= X"000";
			s3_IsClose <= "111";		
			s_Wr <= '0';     
			s2_EnSt <= c_DisAll;	
			s_DisAll <= '0';		
		elsif(iClk'event and iClk = '1') then
			s12_DB_A <= s12_DacA;     
			s12_DB_B <= s12_DacB;       
			s12_DB_C <= s12_DacC;       
			s12_TarClA <= iSetDataA; 
			s12_TarClB <= iSetDataB; 
			s12_TarClC <= iSetDataC;    
			s12_ManA <= '0'&s11_OpA;
			s12_ManB <= '0'&s11_OpB;
			s12_ManC <= '0'&s11_OpC;	
			s3_IsClose <= iClose;				
			s_Wr <= '0'; 
			s2_EnSt <= c_DisAll;
			s_DisAll <= '0';				
			case pr_state is 
				when INITIAL =>
					s12_DB_A <= X"800";     
					s12_DB_B <= X"800";         
					s12_ManA <= X"000";
					s12_ManB <= X"000";
					s12_ManC <= X"000";	
					s3_IsClose(1 downto 0) <= "00";	
					s3_IsClose(2) <= '1';		
					s_Wr <= s_DacUpd;    
					s2_EnSt <= c_DisAll;	 
				when READY =>
					s_Wr <= s_DacUpd;
					s2_EnSt <= c_Rdy;
				when DIS_STB_PR =>
				   
					s12_TarClC <= s12_TarClC;   
					s12_ManC <= s12_ManC;
					s3_IsClose(2) <= s3_IsClose(2);
					s12_ManA <= X"000";
					s12_ManB <= X"000";
					s3_IsClose(1 downto 0) <= "00";	
					s_Wr <= s_DacUpd;		
					s2_EnSt <= c_DisStb;		
				when DIS_STB =>	
					s12_ManA <= X"000";
					s12_ManB <= X"000";	
					s3_IsClose(1 downto 0) <= "00";						
					s_Wr <= s_DacUpd;
					s2_EnSt <= c_DisStb;
				when DIS_ADJ_PR =>
				    s12_TarClA <= s12_TarClA; 
				    s12_TarClB <= s12_TarClB; 
					s12_ManA <= s12_ManA;
					s12_ManB <= s12_ManB;
					s3_IsClose(1 downto 0) <= s3_IsClose(1 downto 0);
					s12_ManC <= X"3AA";	
					s3_IsClose(2) <= '0';
					s_Wr <= s_DacUpd;		
					s2_EnSt <= c_DisAdj;	
				when DIS_ADJ =>	
					s12_ManC <= X"3AA"; -- 2.29V / 55V
					s3_IsClose(2) <= '0';
					s_Wr <= s_DacUpd;			
					s2_EnSt <= c_DisAdj;
				when DIS_ALL_PR =>									
					s12_ManA <= X"000";
					s12_ManB <= X"000";
					s3_IsClose(1 downto 0) <= "00";	
					if(('0'&s10_IniCnt) > ("00"&c_CntValHaf)) then
					    s3_IsClose(2) <= '0';
					    s12_ManC <= X"000";	
					else
					    s3_IsClose(2) <= s3_IsClose(2);
					    s12_ManC <= s12_ManC;	
					end if;
					s12_TarClC <= s12_TarClC;
					s_Wr <= s_DacUpd;			
					s_DisAll <= '1';
					s2_EnSt <= c_DisAll;	
				when DIS_ALL =>			
					s12_DB_A <= X"800";  -- 0V   
					s12_DB_B <= X"800";       
					s12_DB_C <= X"800";  
					s3_IsClose <= "000";
					if(s_DisAll = '1') then
						s_Wr <= '1';  
					else
						s_Wr <= '0';
					end if;			
					s2_EnSt <= c_DisAll;					
				when others =>				
			end case;
		end if;
	end process;	
end Behavioral;

