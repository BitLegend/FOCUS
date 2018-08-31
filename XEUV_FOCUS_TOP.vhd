----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:58:51 06/08/2017 
-- Design Name: 
-- Module Name:    XEUV_FOCUS_TOP - Behavioral 
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
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity XEUV_FOCUS_TOP is
    Port ( 
	 -- test pin
--	 otstRxData   : out STD_LOGIC_VECTOR (7 downto 0);
--	 otstRxRdy    : out STD_LOGIC;
	 
		--iRst : in  STD_LOGIC;
		iClk 			: in  STD_LOGIC;
		---------- Measurement AD interface ----------
		iMadSDO 		: IN  std_logic;
		oMadSDI 		: OUT  std_logic;
		oMadSCLK		: OUT  std_logic;
		oMadCS_n 		: OUT  std_logic;
		---------- Multiplexer ----------
		oRktEn			: OUT  std_logic;
		oRktA 			: OUT  std_logic_vector(3 downto 0);
		---------- Level shifter ----------
		oAD_IO_en		: OUT STD_LOGIC;
		oG_IO_en		: OUT STD_LOGIC;
		---------- CCD driver ----------
		oCCDTxD 		: OUT  std_logic;
		iCCDRx                  : IN std_logic;
		----------- X AD677 -----------
		oClk1 			: out  STD_LOGIC;
		oCal1 			: out  STD_LOGIC;
		oSmp1 			: out  STD_LOGIC;
		iSdata1 		: in  STD_LOGIC;
		iSclk1 			: in  STD_LOGIC;
		iSdata2 		: in  STD_LOGIC;
		iSclk2 			: in  STD_LOGIC;
		----------- Y AD677 -----------
		oClk3 			: out  STD_LOGIC;
		oCal3 			: out  STD_LOGIC;
		oSmp3 			: out  STD_LOGIC;
		iSdata3 		: in  STD_LOGIC;
		iSclk3 			: in  STD_LOGIC;
		iSdata4 		: in  STD_LOGIC;
		iSclk4 			: in  STD_LOGIC;	
		----------- SGS AD interface -----------
		iPadSDO			: in  STD_LOGIC;
		oPadSDI                 : out  STD_LOGIC;
		oPadSCLK                : out  STD_LOGIC;
		oPadCS_n                : out  STD_LOGIC;
		----------- DAC port ----------- 
		oDA_DB                  : out  STD_LOGIC_VECTOR (11 downto 0);
		oDA_A                   : out  STD_LOGIC_VECTOR (1 downto 0);
		oDA_CS                  : out  STD_LOGIC;
		oDA_LDAC                : out  STD_LOGIC;		
		---------- Relay control ---------
		oSWF                    : out  STD_LOGIC;
		oSWO                    : out  STD_LOGIC;
		----------- Heat output control ------------
		
		oCtrl0                  : out  STD_LOGIC;
		oCtrl1                  : out  STD_LOGIC;
		oCtrl2                  : out  STD_LOGIC;
		oCtrl3                  : out  STD_LOGIC;
		
		---------- Heat state ----------
		iRkSt                   : IN std_logic_vector(3 downto 0);
		---------- data received from central controller ---------
		iJMRxZ     		: in  STD_LOGIC;
		iJMRxB     		: in  STD_LOGIC;
		---------- data sent to central controller ---------
		oJMTxZ     		: out  STD_LOGIC;
		oJMTxB     		: out  STD_LOGIC;
		---------- guide telescope data sent to central controller ---------
		oGuideTxZ       	: out  STD_LOGIC;
		oGuideTxB       	: out  STD_LOGIC;	   
		---------- main and backup signal: High enable ---------
		iZSig			: in  STD_LOGIC;
		iBSig                   : in  STD_LOGIC;
		---------- RS422 enable signals ---------
		oTxENH	                : out  STD_LOGIC;
		oTxENL			: out  STD_LOGIC;
		oRxENH			: out  STD_LOGIC;
		oRxENL			: out  STD_LOGIC		
		
		);
end XEUV_FOCUS_TOP;

architecture Behavioral of XEUV_FOCUS_TOP is
--=============================================================================
--  Components declaration
--=============================================================================	
	-- test
--	COMPONENT CNT_tst
--	PORT(
--		iClk : IN std_logic;
--		iTime1ms : IN std_logic;          
--		oDataXP : OUT std_logic_vector(15 downto 0);
--		oDataXN : OUT std_logic_vector(15 downto 0);
--		oDataYP : OUT std_logic_vector(15 downto 0);
--		oDataYN : OUT std_logic_vector(15 downto 0)
--		);
--	END COMPONENT;	
	
	-- system reset
	COMPONENT SYSREST
	PORT(
		iClk : IN std_logic;     
		oSysRst : OUT std_logic
		);
	END COMPONENT;
	-- central control
    COMPONENT CENTRAL_CTRL
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iTick1s : IN  std_logic;
	       iTick2ms : IN std_logic;
         iDataVal : IN  std_logic;
         iCmd : IN  std_logic_vector(7 downto 0);
         iFocusPos : IN  std_logic_vector(11 downto 0);
         iParas : IN a3of8;
         iHeatMode : IN a4of8;
         iHeatSenSel : IN a4of8;
         iHeatDuty : IN a4of8;
         iHeatTarget : IN a4of12;
      	 iCCDVal : IN STD_LOGIC;
	       iCCDState : IN STD_LOGIC_VECTOR(7 downto 0);
	       iCCDChan : IN STD_LOGIC_VECTOR(7 downto 0);
	       iPiezDrTemper : IN  std_logic_vector(11 downto 0);
         iPiezoX : IN  std_logic_vector(11 downto 0);
         iPiezoY : IN  std_logic_vector(11 downto 0);
         oHeatMode : OUT   a4of8;
         oHeatSenSel : OUT a4of8;
         oHeatDuty : OUT   a4of8;
         oHeatTarget : OUT a4of12;
         oSWF : OUT  std_logic;
         oSWO : OUT  std_logic;
         oEnStab : OUT  std_logic_vector(1 downto 0);
         oClose : OUT  std_logic_vector(2 downto 0);
         oSetDataA : OUT  std_logic_vector(11 downto 0);
         oSetDataB : OUT  std_logic_vector(11 downto 0);
         oSetDataC : OUT  std_logic_vector(11 downto 0);
	       oSt : ouT STD_LOGIC_VECTOR(2 downto 0)
        );
    END COMPONENT;
	-- Generate time tick 
    COMPONENT TIME_TICK
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         oTick01ms : OUT  std_logic;
         oTick1ms : OUT  std_logic;
         oTick2ms : OUT  std_logic;
	 oTick5ms : OUT  std_logic;
	 oTick40ms : OUT  std_logic;
         oTick1s : OUT  std_logic
        );
    END COMPONENT;

	-- Remote sense and heat temperature
    COMPONENT RSHC_SMP
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iMadSDO : IN  std_logic;
         oMadSDI : OUT  std_logic;
         oMadSCLK : OUT  std_logic;
         oMadCS_n : OUT  std_logic;
         oRktEn : OUT  std_logic;
         oRktA : OUT  std_logic_vector(3 downto 0);
         iSmp : IN  std_logic;
         oData : OUT  madDataOut
        );
    END COMPONENT;
	
	-- State return 
	COMPONENT STATE_RETURN
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         iUpdate : IN  std_logic;
	 iCmd	: IN  STD_LOGIC_VECTOR (7 downto 0);
         iPiezoX : IN  std_logic_vector(11 downto 0);
         iPiezoY : IN  std_logic_vector(11 downto 0);
         iPiezoZ : IN  std_logic_vector(11 downto 0);
	 iErrX : IN  std_logic_vector (7 downto 0);
	 iErrY : IN  std_logic_vector (7 downto 0);
         iSense : IN  madDataOut;
         iStabSt : IN  std_logic_vector(7 downto 0);
         iRkSt : IN  std_logic_vector(7 downto 0);
         iRS422St : IN  std_logic_vector(7 downto 0);
	 iHeatTime : in  a4of8;
         oTxD : OUT  std_logic
        );
    END COMPONENT;
	
	-- RS422 receiver
	COMPONENT ASY_REC
	GENERIC (gAccWidth : integer;
		gInc      : integer);
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iRxD : IN  std_logic;
         oRxReady : OUT  std_logic;
         oRxData : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
	-- Process CCD state data
    COMPONENT IMG_STATE_PRO
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iCCDRxRdy : IN  std_logic;
         iCCDRxData : IN  std_logic_vector(7 downto 0);
         oVal : OUT  std_logic;
         oState : OUT  std_logic_vector(7 downto 0);
         oChan : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;	 
	-- Handle main controller command
	COMPONENT CMD_HANDLER
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iTick : IN  std_logic;
         iRxRdy : IN  std_logic;
         iData : IN  std_logic_vector(7 downto 0);
         oCmd : OUT  std_logic_vector(7 downto 0);
         oFocusPos : OUT  std_logic_vector(11 downto 0);
         oParas : OUT  a3of8;
	       oScaleParas : out  a8of16;
         oOffParas : out  a2of16;
         oCtrlParas : out  a3of16;
         oHeatMode : out  a4of8;
	       oHeatSenSel : out  a4of8;
	       oHeatDuty : out  a4of8;
	       oHeatTarget : out  a4of12;
         oDataVal : OUT  std_logic;
         oReturn : OUT  std_logic;
         oState : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
--	-- Send processed guide telescope data	 
--    COMPONENT GUIDE_SEND
--    PORT(
--         iClk : IN  std_logic;
--         iRst : IN  std_logic;
--         iUpdate : IN  std_logic;
--         iDataX : IN  std_logic_vector(15 downto 0);
--         iDataY : IN  std_logic_vector(15 downto 0);
--         oTxD : OUT  std_logic
--        );
--    END COMPONENT;	 
	 
	 
	-- Send original guide telescope data
    COMPONENT GUIDE_ORI_SEND
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         iUpdate : IN  std_logic;
         iDataXP : IN  std_logic_vector(15 downto 0);
         iDataXN : IN  std_logic_vector(15 downto 0);
         iDataYP : IN  std_logic_vector(15 downto 0);
         iDataYN : IN  std_logic_vector(15 downto 0);
         oTxD : OUT  std_logic
        );
    END COMPONENT;	
	-- Send guide telescope data and piezo data to CCD driver
	COMPONENT CCD_SEND
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         iUpdate : IN  std_logic;
         iDataXP : IN  std_logic_vector(15 downto 0);
         iDataXN : IN  std_logic_vector(15 downto 0);
         iDataYP : IN  std_logic_vector(15 downto 0);
         iDataYN : IN  std_logic_vector(15 downto 0);
         iPiezoX : IN  std_logic_vector(11 downto 0);
         iPiezoY : IN  std_logic_vector(11 downto 0);
         iPiezoZ : IN  std_logic_vector(11 downto 0);
	 iCCD_Temp1 : IN  STD_LOGIC_VECTOR (11 downto 0);
	 iCCD_Temp2  : IN  STD_LOGIC_VECTOR (11 downto 0);
	 iGuideXErr : IN  STD_LOGIC_VECTOR (7 downto 0);
	 iGuideYErr : IN  STD_LOGIC_VECTOR (7 downto 0);
         oTxD : OUT  std_logic
        );
    END COMPONENT;
	-- Sample and process guide telescope data 
    COMPONENT GUIDE_CTRL
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iTick : IN  std_logic;
    	 iTick40ms : IN std_logic;
      	 iPiezoUpX : IN STD_LOGIC_VECTOR(11 downto 0) ; --3.7
      	 iPiezoDwX : IN  STD_LOGIC_VECTOR(11 downto 0) ; --0.7
      	 iPiezoUpY :  IN STD_LOGIC_VECTOR(11 downto 0) ; --3.7
      	 iPiezoDwY :  IN STD_LOGIC_VECTOR(11 downto 0) ; --0.7
      		
      	 iScaleEUVX :  IN STD_LOGIC_VECTOR(15 downto 0) ;--0.4
      	 iScaleXX :  IN STD_LOGIC_VECTOR(15 downto 0) ;--0.2
      	 iScaleEUVY :  IN STD_LOGIC_VECTOR(15 downto 0) ;
      	 iScaleXY :  IN STD_LOGIC_VECTOR(15 downto 0) ;
      
      	 iOffsetX :  IN STD_LOGIC_VECTOR(15 downto 0) ; --1.9
      	 iOffsetY :  IN STD_LOGIC_VECTOR(15 downto 0) ;	--1.9	
      	 oG_IO_en : OUT  STD_LOGIC;
      	 iCCDChan : in STD_LOGIC_VECTOR(7 downto 0);
         oClk1 : OUT  std_logic;
         oCal1 : OUT  std_logic;
         oSmp1 : OUT  std_logic;
         iSdata1 : IN  std_logic;
         iSclk1 : IN  std_logic;
         iSdata2 : IN  std_logic;
         iSclk2 : IN  std_logic;
         oClk3 : OUT  std_logic;
         oCal3 : OUT  std_logic;
         oSmp3 : OUT  std_logic;
         iSdata3 : IN  std_logic;
         iSclk3 : IN  std_logic;
         iSdata4 : IN  std_logic;
         iSclk4 : IN  std_logic;
	       oGuideXErr : OUT  STD_LOGIC_VECTOR (7 downto 0);
	       oGuideYErr : OUT  STD_LOGIC_VECTOR (7 downto 0);
         oData1 : OUT  std_logic_vector(15 downto 0);
         oData2 : OUT  std_logic_vector(15 downto 0);
         oData3 : OUT  std_logic_vector(15 downto 0);
         oData4 : OUT  std_logic_vector(15 downto 0);
	       oRdy10X : OUT std_logic;
         oDataXNor : OUT  std_logic_vector(15 downto 0);
         oDataYNor : OUT  std_logic_vector(15 downto 0);
	       oPiezoX : out STD_LOGIC_VECTOR(11 downto 0);
	       oPiezoY : out STD_LOGIC_VECTOR(11 downto 0)					
        );
    END COMPONENT;
	-- Piezo control module
    COMPONENT PIEZO_PICTRL
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         iTick : IN  std_logic;
	 iPiezoDwX : in STD_LOGIC_VECTOR(11 downto 0);
	 iPiezoDwY : in STD_LOGIC_VECTOR(11 downto 0);
	 oAD_IO_en : OUT STD_LOGIC;	
         iEnStab : IN  std_logic_vector(1 downto 0);
         iClose : IN  std_logic_vector(2 downto 0);
         iSetDataA : IN  std_logic_vector(11 downto 0);
         iSetDataB : IN  std_logic_vector(11 downto 0);
         iSetDataC : IN  std_logic_vector(11 downto 0);
	 iCtrlParas : IN a3of16;
         oState : OUT  std_logic_vector(1 downto 0);
	 oPiezoX : out STD_LOGIC_VECTOR (11 downto 0);
	 oPiezoY : out STD_LOGIC_VECTOR (11 downto 0);
	 oPiezoZ : out STD_LOGIC_VECTOR (11 downto 0);
         iPadSDO : IN  std_logic;
         oPadSDI : OUT  std_logic;
         oPadSCLK : OUT  std_logic;
         oPadCS_n : OUT  std_logic;
         oDA_DB : OUT  std_logic_vector(11 downto 0);
         oDA_A : OUT  std_logic_vector(1 downto 0);
         oDA_CS : OUT  std_logic;
         oDA_LDAC : OUT  std_logic;
	 oErrX : OUT STD_LOGIC_VECTOR(7 downto 0);
	 oErrY : OUT STD_LOGIC_VECTOR(7 downto 0)
        );
    END COMPONENT;
	-- Heat control
    COMPONENT HEAT_CTRL
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iTick1S : IN  std_logic;
	 iTick40ms : IN std_logic;
         iMode : IN  a4of8;
         iSenSel : IN  a4of8;
         iTarget : IN  a4of12;
         iDuty : IN  a4of8;
         iMes1 : IN  std_logic_vector(11 downto 0);
         iMes2 : IN  std_logic_vector(11 downto 0);
         iRkSt : IN std_logic_vector(3 downto 0);
	 oHeatTime : out a4of8;
         oCtrl0	: out STD_LOGIC;
	 oCtrl1	: out STD_LOGIC;
	 oCtrl2	: out STD_LOGIC;
	 oCtrl3	: out STD_LOGIC
        );
    END COMPONENT;
	-- backup control
    COMPONENT ZBCTRL
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
      	 iTick  : IN  STD_LOGIC;
         iJMRxZ : IN  std_logic;
         iJMRxB : IN  std_logic;
         oJMRxD : OUT  std_logic;
         oJMTxZ : OUT  std_logic;
         oJMTxB : OUT  std_logic;
         iJMTxD : IN  std_logic;
         oGuideTxZ : OUT  std_logic;
         oGuideTxB : OUT  std_logic;
         iGuideTxD : IN  std_logic;
         iZSig : IN  std_logic;
         iBSig : IN  std_logic;
         oTxENH : OUT  std_logic;
         oTxENL : OUT  std_logic;
         oRxENH : OUT  std_logic;
         oRxENL : OUT  std_logic
        );
    END COMPONENT;
--=============================================================================
--  signal definition
--=============================================================================		
	-- Reset
	signal s_RST2ALL_Rst				: STD_LOGIC := '1';
	-- System clock
	signal s_SysClk					: STD_LOGIC := '0';	
	-- Central control
	signal s8_CCTRL2HCTRL_HeatModeVal 		: a4of8 := (c8_close, c8_open, c8_close, c8_open);
	signal s8_CCTRL2HCTRL_HeatSenSelVal     	: a4of8 := (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);
	signal s8_CCTRL2HCTRL_HeatDutyVal		: a4of8 := ((others => '0'), (others => '0'), (others => '0'),
										     (others => '0'));
	signal s12_CCTRL2HCTRL_HeatTargetVal    	: a4of12 := (c12_tmpNorTar, c12_tmpNorTar, c12_tmpClrTar,
										      c12_tmpClrTar);	
	signal s3_CCTRL2SRE_CentralSt			: STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
										
	-- Time tick
	signal s_Tick01ms				: std_logic := '0';
	signal s_Tick2ms      				: std_logic := '0';
	signal s_Tick1ms         		   	: std_logic := '0';
	signal s_Tick5ms				: std_logic := '0';
	signal s_Tick40ms				: std_logic := '0';
	signal s_Tick1s					: std_logic := '0';
	-- RS422 receiver
	signal s_M2CH_RxRdy				: STD_LOGIC := '0';
	signal s8_M2CH_RxData		        	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	-- CCD receiver
	signal s_CCD2ISP_RxRdy		        	: STD_LOGIC := '0';
	signal s8_CCD2ISP_RxData	        	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal s_ISP2CCTRL_StVal	        	: STD_LOGIC := '0';	
	signal s8_ISP2CCTRL_State	        	: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal s8_ISP2CCTRL_CCDChan	        	: STD_LOGIC_VECTOR(7 downto 0) := c8_ChanX;	
	
	-- Command handler
	signal s8_CH2CCTRL_Cmd 			      	: std_logic_vector(7 downto 0):= (others => '0');	
	signal s12_CH2CCTRL_FocusPos 	  		: std_logic_vector(11 downto 0):= (others => '0');	
	signal s8_CH2CCTRL_Paras 		      	: a3of8 := (c4_PiezClose&c4_PiezClose, c4_PiezClose&c4_PiezClose, c8_TempImg);
	signal s16_CH2GCTRL_ScaleParas    	: a8of16 := (c16_PiezoUpX,c16_PiezoDwX,c16_PiezoUpY,c16_PiezoDwY,c16_ScaleEUVX,c16_ScaleXX,c16_ScaleEUVY,c16_ScaleXY);
 	signal s16_CH2GCTRL_OffParas    		: a2of16 := (c16_offsetX,c16_offsetY);
	signal s8_CH2CCTRL_HeatMode 		  	: a4of8 := (c8_close, c8_open, c8_close, c8_open);
	signal s8_CH2CCTRL_HeatSenSel 			: a4of8 := (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);
	signal s8_CH2CCTRL_HeatDuty		    	: a4of8 := ((others => '0'), (others => '0'), (others => '0'),
											(others => '0'));
	signal s12_CH2CCTRL_HeatTarget 			: a4of12 := ((others => '0'), (others => '0'), (others => '0'),
											(others => '0'));
	signal s_CH2CCTRL_CmdVal			: std_logic := '0';
	signal s_CH2SRE_Return 				: std_logic := '0';
	signal s8_CH2SRE_MR422State 			: std_logic_vector(7 downto 0) := (others => '0');	
   
    signal s16_CH2PIC_CtrlParas				: a3of16 := (c_ParaXI,c_ParaYI,c_ParaZI);
	-- State return
	signal s12_PIC2SRE_PiezoX 			: std_logic_vector(11 downto 0) := c12_stbXPos;
	signal s12_PIC2SRE_PiezoY 			: std_logic_vector(11 downto 0) := c12_stbYPos;
	signal s12_PIC2SRE_PiezoZ 			: std_logic_vector(11 downto 0) := c12_adjPos;
	signal s8_PIC2SRE_ERRX				: std_logic_vector(7 downto 0) := (others => '0');
	signal s8_PIC2SRE_ERRY				: std_logic_vector(7 downto 0) := (others => '0');
	
	

	signal s12_RSHC2SRE_Sense 			: madDataOut := ((others => '0'), (others => '0'), (others => '0'),
											(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
											(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
											(others => '0'),(others => '0'),(others => '1'));
	signal s8_CCTRL2SRE_StabSt 			: std_logic_vector(7 downto 0) := (others => '0');
	signal s8_TOP2SRE_RkSt 				: std_logic_vector(7 downto 0) := (others => '0');
	signal s8_HC2SRE_HeatTime 			: a4of8 := ((others => '0'), (others => '0'), (others => '0'),
											(others => '0'));   
	signal s_SRE2ZB_JMTxD				: std_logic := '1';									
	-- Guide telescope data send
	signal s16_GCTRL2GS_DataXP 			: std_logic_vector(15 downto 0) := (others => '0');
	signal s16_GCTRL2GS_DataXN 			: std_logic_vector(15 downto 0) := (others => '0');
	signal s16_GCTRL2GS_DataYP 			: std_logic_vector(15 downto 0) := (others => '0');
	signal s16_GCTRL2GS_DataYN 			: std_logic_vector(15 downto 0) := (others => '0');	
	signal s_GCTRL2GS_Tick 				: std_logic := '0';
	signal s_GS2ZB_GuideTxD				: STD_LOGIC := '1';
	-- Guide telescope sampling error counter
	signal s8_GCTRL2CCDS_GuideXErr 			: std_logic_vector (7 downto 0) := (others => '0');
	signal s8_GCTRL2CCDS_GuideYErr 			: std_logic_vector (7 downto 0) := (others => '0');
	-- Sample guide telescope data
	-- signed: 1 sign bit and 14 fractional length
	signal s16_GCTRL2GS_DataXNor 			: std_logic_vector(15 downto 0):= (others => '0');
	signal s16_GCTRL2GS_DataYNor 			: std_logic_vector(15 downto 0):= (others => '0');
	-- tmp
--	signal s16_1 			: std_logic_vector(15 downto 0):= X"1234";
--	signal s16_2 			: std_logic_vector(15 downto 0):= X"5678";
--	signal s16_3 			: std_logic_vector(15 downto 0):= X"9108";
--	signal s16_4			: std_logic_vector(15 downto 0):= X"3456";

	-- Piezo control
	signal s2_PIC2SRE_StabEnSt			: std_logic_vector(1 downto 0) := (others => '0');
	signal s2_CCTRL2PIC_EnStab 			: std_logic_vector(1 downto 0) := (others => '0');
	signal s3_CCTRL2SRE_Close			: std_logic_vector(2 downto 0) := (others => '1');
	signal s12_CCTRL2PIC_SetDataA 			: std_logic_vector(11 downto 0) := c12_stbXPos;
	signal s12_CCTRL2PIC_SetDataB 			: std_logic_vector(11 downto 0) := c12_stbYPos;
	signal s12_CCTRL2PIC_SetDataC 			: std_logic_vector(11 downto 0) := c12_adjPos;
	signal s12_GC2CCTRL_PiezoXTar  			: std_logic_vector (11 downto 0) := c12_stbXPos;	
	signal s12_GC2CCTRL_PiezoYTar   		: std_logic_vector (11 downto 0) := c12_stbYPos;	
	-- backup control
	signal s_ZB2RS422Rx0_RxD			: std_logic := '1';
begin

	-- 4245 Enable
	-- oAD_IO_en <= '0';
	-- oG_IO_en <= '0';
--	otstRxData <= s8_CCD2ISP_RxData;
--	otstRxRdy <= s_CCD2ISP_RxRdy;
	--oRktA <= "1001"; -- for debug
--=============================================================================
--  Instantiate the Unit
--=============================================================================	
--		Inst_CNT_tst: CNT_tst PORT MAP(
--		iClk => iClk,
--		iTime1ms => s_Tick1ms,
--		oDataXP => s16_GCTRL2GS_DataXP,
--		oDataXN => s16_GCTRL2GS_DataXN,
--		oDataYP => s16_GCTRL2GS_DataYP,
--		oDataYN => s16_GCTRL2GS_DataYN
--	);
   CLK_BUFG_inst : BUFG
   port map (
      O => s_SysClk,     -- Clock buffer output
      I => iCLK        -- Clock buffer input
   );		
	-- Instantiate the system reset
	SYSREST_inst: SYSREST PORT MAP(
		iClk 			=> s_SysClk,
		oSysRst 		=> s_RST2ALL_Rst
	);	
	-- Instantiate the CENTRAL_CTRL
	CENTRAL_CTRL_inst: CENTRAL_CTRL PORT MAP (
		  iRst 			=> s_RST2ALL_Rst,
		  iClk 			=> s_SysClk,
		  iTick1s 		=> s_Tick1s,
		  iTick2ms		=> s_Tick2ms,
		  iDataVal 		=> s_CH2CCTRL_CmdVal,
		  iCmd 			=> s8_CH2CCTRL_Cmd,
		  iFocusPos 		=> s12_CH2CCTRL_FocusPos,
		  iParas 		=> s8_CH2CCTRL_Paras(0 to 2),
		  iHeatMode 		=> s8_CH2CCTRL_HeatMode,
		  iHeatSenSel 		=> s8_CH2CCTRL_HeatSenSel,
		  iHeatDuty 		=> s8_CH2CCTRL_HeatDuty,
		  iHeatTarget 		=> s12_CH2CCTRL_HeatTarget,
		  iCCDVal	 	=> s_ISP2CCTRL_StVal,
		  iCCDState    		=> s8_ISP2CCTRL_State,
		  iCCDChan      	=> s8_ISP2CCTRL_CCDChan,
		  iPiezDrTemper 	=> s12_RSHC2SRE_Sense(3),
		  iPiezoX 		=> s12_GC2CCTRL_PiezoXTar,
		  iPiezoY 		=> s12_GC2CCTRL_PiezoYTar,
		  oHeatMode 		=> s8_CCTRL2HCTRL_HeatModeVal,
		  oHeatSenSel 		=> s8_CCTRL2HCTRL_HeatSenSelVal,
		  oHeatDuty 		=> s8_CCTRL2HCTRL_HeatDutyVal,
		  oHeatTarget 		=> s12_CCTRL2HCTRL_HeatTargetVal,
		  oSWF 			=> oSWF,
		  oSWO 			=> oSWO,
		  oEnStab 		=> s2_CCTRL2PIC_EnStab,
		  oClose 		=> s3_CCTRL2SRE_Close,
		  oSetDataA 		=> s12_CCTRL2PIC_SetDataA,
		  oSetDataB 		=> s12_CCTRL2PIC_SetDataB,
		  oSetDataC 		=> s12_CCTRL2PIC_SetDataC,
		  oSt 			=> s3_CCTRL2SRE_CentralSt
		);
	-- Instantiate the time tick
   TIME_TICK_inst: TIME_TICK PORT MAP (
          iClk 				=> s_SysClk,
          iRst 				=> s_RST2ALL_Rst,
          oTick01ms 	        	=> s_Tick01ms,
          oTick1ms 			=> s_Tick1ms,
          oTick2ms 			=> s_Tick2ms,
	  oTick5ms 			=> s_Tick5ms,
	  oTick40ms                     => s_Tick40ms,
          oTick1s 			=> s_Tick1s
        );
		
	-- Instantiate the rs422 receiver
	RS422Rx_inst0: ASY_REC 
	GENERIC MAP(
		gAccWidth 			=> 19,
		gInc 				=> 26214 -- 125000
	)
	PORT MAP (
		  iRst 				=> s_RST2ALL_Rst,
		  iClk 				=> s_SysClk,
		  iRxD 				=> s_ZB2RS422Rx0_RxD,
		  oRxReady 			=> s_M2CH_RxRdy,
		  oRxData 			=> s8_M2CH_RxData
		);
		
		
	-- Instantiate the CCD receiver
	RS422Rx_inst1: ASY_REC 
	GENERIC MAP(
		gAccWidth 			=> 19,
		gInc 				=> 26214 -- 125000
	)
	PORT MAP (
		  iRst 				=> s_RST2ALL_Rst,
		  iClk 				=> s_SysClk,
		  iRxD 				=> iCCDRx,
		  oRxReady 			=> s_CCD2ISP_RxRdy,
		  oRxData 			=> s8_CCD2ISP_RxData
		);
	-- Instantiate the CCD state processing module
   IMG_STATE_PRO_inst: IMG_STATE_PRO PORT MAP (
          iRst				=> s_RST2ALL_Rst,
          iClk 				=> s_SysClk,
          iCCDRxRdy 	        	=> s_CCD2ISP_RxRdy,
          iCCDRxData 	        	=> s8_CCD2ISP_RxData,
          oVal 				=> s_ISP2CCTRL_StVal,	
          oState 			=> s8_ISP2CCTRL_State,	
          oChan				=> s8_ISP2CCTRL_CCDChan	
        );
		
	-- Instantiate the command handler
   CMD_HANDLER_inst: CMD_HANDLER PORT MAP (
          iRst 				=> s_RST2ALL_Rst,
          iClk 				=> s_SysClk,
          iTick 			=> s_Tick1ms,
          iRxRdy 			=> s_M2CH_RxRdy,
          iData 			=> s8_M2CH_RxData,
          oCmd 				=> s8_CH2CCTRL_Cmd,
          oFocusPos   => s12_CH2CCTRL_FocusPos,
          oParas 			=> s8_CH2CCTRL_Paras,
	        oScaleParas	=> s16_CH2GCTRL_ScaleParas,
          oOffParas   => s16_CH2GCTRL_OffParas,
	        oCtrlParas  => s16_CH2PIC_CtrlParas,
          oHeatMode  	=> s8_CH2CCTRL_HeatMode,
          oHeatSenSel	=> s8_CH2CCTRL_HeatSenSel,
          oHeatDuty 	=> s8_CH2CCTRL_HeatDuty,
          oHeatTarget	=> s12_CH2CCTRL_HeatTarget,
          oDataVal 		=> s_CH2CCTRL_CmdVal,
          oReturn 		=> s_CH2SRE_Return,
          oState 			=> s8_CH2SRE_MR422State
        );
	-- Instantiate the state returner
	s8_TOP2SRE_RkSt 		<= "0000"&iRkSt;-- '0' mean Heating  
	s8_CCTRL2SRE_StabSt 	<= s3_CCTRL2SRE_Close&s3_CCTRL2SRE_CentralSt&s2_PIC2SRE_StabEnSt;
	STATE_RETURN_inst: STATE_RETURN PORT MAP (
		  iClk 				=> s_SysClk,
		  iRst 				=> s_RST2ALL_Rst,
		  iUpdate 			=> s_CH2SRE_Return,
		  iCmd 				=> s8_CH2CCTRL_Cmd,
		  iPiezoX 			=> s12_PIC2SRE_PiezoX,
		  iPiezoY 			=> s12_PIC2SRE_PiezoY,
		  iPiezoZ 			=> s12_PIC2SRE_PiezoZ,
		  iErrX				=> s8_PIC2SRE_ERRX,
		  iErrY				=> s8_PIC2SRE_ERRY,
		  iSense 			=> s12_RSHC2SRE_Sense,
		  iStabSt 			=> s8_CCTRL2SRE_StabSt,
		  iRkSt 			=> s8_TOP2SRE_RkSt,
		  iRS422St 			=> s8_CH2SRE_MR422State,
		  iHeatTime 	        	=> s8_HC2SRE_HeatTime,
		  oTxD 				=> s_SRE2ZB_JMTxD
		);
		
	-- Instantiate the RSHC_SMP
	RSHC_SMP_inst: RSHC_SMP PORT MAP (
		  iRst 				=> s_RST2ALL_Rst,
		  iClk 				=> s_SysClk,
		  iMadSDO 			=> iMadSDO,
		  oMadSDI 			=> oMadSDI,
		  oMadSCLK 			=> oMadSCLK,
		  oMadCS_n 			=> oMadCS_n,
		  oRktEn 			=> oRktEn,
		  oRktA 			=> oRktA ,
		  iSmp 				=> s_Tick2ms,
		  oData 			=> s12_RSHC2SRE_Sense
		);	
		
	-- Instantiate the GUIDE_SEND
--	GUIDE_SEND_inst: GUIDE_SEND PORT MAP (
--			iClk => iClk,
--			iRst => s_RST2ALL_Rst,
--			iUpdate => s_GCTRL2GS_Tick,
--			iDataX => s16_GCTRL2GS_DataXNor,
--			iDataY => s16_GCTRL2GS_DataYNor,
--			oTxD => oGTxD
--		);		

	-- Instantiate the GUIDE_ORI_SEND
	GUIDE_ORI_SEND_inst: GUIDE_ORI_SEND PORT MAP (
		  iClk 			=> s_SysClk,
		  iRst 			=> s_RST2ALL_Rst,
		  iUpdate 		=> s_GCTRL2GS_Tick,
		  iDataXP 		=> s16_GCTRL2GS_DataXP,
		  iDataXN 		=> s16_GCTRL2GS_DataXN,
		  iDataYP 		=> s16_GCTRL2GS_DataYP,
		  iDataYN 		=> s16_GCTRL2GS_DataYN,
		  oTxD 			=> s_GS2ZB_GuideTxD
		);		
	-- Instantiate the CCD_SEND
	CCD_SEND_inst: CCD_SEND PORT MAP (
		  iClk 			=> s_SysClk,
		  iRst 			=> s_RST2ALL_Rst,
		  iUpdate 		=> s_Tick5ms,
		  iDataXP 		=> s16_GCTRL2GS_DataXP,
		  iDataXN 		=> s16_GCTRL2GS_DataXN,
		  iDataYP 		=> s16_GCTRL2GS_DataYP,
		  iDataYN 		=> s16_GCTRL2GS_DataYN,
		  iPiezoX 		=> s12_PIC2SRE_PiezoX,
		  iPiezoY 		=> s12_PIC2SRE_PiezoY,
		  iPiezoZ 		=> s12_PIC2SRE_PiezoZ,
		  iCCD_Temp1 		=> s12_RSHC2SRE_Sense(0),
		  iCCD_Temp2 		=> s12_RSHC2SRE_Sense(1),
		  iGuideXErr            => s8_GCTRL2CCDS_GuideXErr,
		  iGuideYErr            => s8_GCTRL2CCDS_GuideYErr,
		  oTxD 			=> oCCDTxD
		);
			
		
	-- Instantiate the GUIDE_CTRL
	GUIDE_CTRL_inst: GUIDE_CTRL PORT MAP (
		  iRst 			=> s_RST2ALL_Rst,
		  iClk 			=> s_SysClk,
		  iTick 		=> s_Tick01ms,
		  iTick40ms             => s_Tick40ms,
		  iPiezoUpX 		=> s16_CH2GCTRL_ScaleParas(0)(11 downto 0)  , --3.7
		  iPiezoDwX 		=> s16_CH2GCTRL_ScaleParas(1)(11 downto 0)  , --0.7
		  iPiezoUpY 		=> s16_CH2GCTRL_ScaleParas(2)(11 downto 0)  , --3.7
		  iPiezoDwY 		=> s16_CH2GCTRL_ScaleParas(3)(11 downto 0)  , --0.7
		                 
		  iScaleEUVX 		=> s16_CH2GCTRL_ScaleParas(4) ,--0.4
		  iScaleXX  		=> s16_CH2GCTRL_ScaleParas(5)   ,--0.2
		  iScaleEUVY 		=> s16_CH2GCTRL_ScaleParas(6) ,
		  iScaleXY 		=> s16_CH2GCTRL_ScaleParas(7)   ,
                       
		  iOffsetX 		=> s16_CH2GCTRL_OffParas(0), --1.9
		  iOffsetY 		=> s16_CH2GCTRL_OffParas(1), --1.9	
		  oG_IO_en 		=> oG_IO_en,
		  iCCDChan 		=> s8_ISP2CCTRL_CCDChan, 
		  oClk1 		=> oClk1,
		  oCal1 		=> oCal1,
		  oSmp1 		=> oSmp1,
		  iSdata1 		=> iSdata1,
		  iSclk1 		=> iSclk1,
		  iSdata2 		=> iSdata2,
		  iSclk2 		=> iSclk2,
		  oClk3 		=> oClk3,
		  oCal3			=> oCal3,
		  oSmp3 		=> oSmp3,
		  iSdata3 		=> iSdata3,
		  iSclk3 		=> iSclk3,
		  iSdata4 		=> iSdata4,
		  iSclk4 		=> iSclk4,
		  oGuideXErr            => s8_GCTRL2CCDS_GuideXErr,
		  oGuideYErr            => s8_GCTRL2CCDS_GuideYErr,
		  oData1 		=> s16_GCTRL2GS_DataXP,
		  oData2 		=> s16_GCTRL2GS_DataXN,
		  oData3 		=> s16_GCTRL2GS_DataYP,
		  oData4 		=> s16_GCTRL2GS_DataYN,
		  oRdy10X               => s_GCTRL2GS_Tick,
		  oDataXNor 		=> s16_GCTRL2GS_DataXNor,
		  oDataYNor 		=> s16_GCTRL2GS_DataYNor,
		  oPiezoX 		=> s12_GC2CCTRL_PiezoXTar,
		  oPiezoY 		=> s12_GC2CCTRL_PiezoYTar		  
		);
		
	-- Instantiate the PIEZO_PICTRL
	PIEZO_PICTRL_inst: PIEZO_PICTRL PORT MAP (
		  iClk 			=> s_SysClk,
		  iRst 			=> s_RST2ALL_Rst,
		  iTick 		=> s_Tick01ms,
		  iPiezoDwX  		=> s16_CH2GCTRL_ScaleParas(3)(11 downto 0),
		  iPiezoDwY  		=> s16_CH2GCTRL_ScaleParas(1)(11 downto 0),
		  oAD_IO_en 		=> oAD_IO_en,
		  iEnStab 		=> s2_CCTRL2PIC_EnStab,
		  iClose 		=> s3_CCTRL2SRE_Close,
		  iSetDataA 		=> s12_CCTRL2PIC_SetDataA,
		  iSetDataB 		=> s12_CCTRL2PIC_SetDataB,
		  iSetDataC 		=> s12_CCTRL2PIC_SetDataC,
		  iCtrlParas            => s16_CH2PIC_CtrlParas,
		  oState 		=> s2_PIC2SRE_StabEnSt,
		  oPiezoX 		=> s12_PIC2SRE_PiezoX,
		  oPiezoY 		=> s12_PIC2SRE_PiezoY,
		  oPiezoZ 		=> s12_PIC2SRE_PiezoZ,
		  iPadSDO 		=> iPadSDO,
		  oPadSDI 		=> oPadSDI,
		  oPadSCLK 		=> oPadSCLK,
		  oPadCS_n 		=> oPadCS_n,
		  oDA_DB 		=> oDA_DB,
		  oDA_A 		=> oDA_A,
		  oDA_CS 		=> oDA_CS,
		  oDA_LDAC		=> oDA_LDAC,
		  oErrX 		=> s8_PIC2SRE_ERRX,
		  oErrY 		=> s8_PIC2SRE_ERRY
		);
	-- Instantiate the HEAT_CTRL 
	HEAT_CTRL_inst: HEAT_CTRL PORT MAP (
		  iRst 			=> s_RST2ALL_Rst,
		  iClk 			=> s_SysClk,
		  iTick1S 		=> s_Tick1s,
		  iTick40ms             => s_Tick40ms,
		  iMode 	        => s8_CCTRL2HCTRL_HeatModeVal,
		  iSenSel 		=> s8_CCTRL2HCTRL_HeatSenSelVal,
		  iTarget		=> s12_CCTRL2HCTRL_HeatTargetVal,
		  iDuty 		=> s8_CCTRL2HCTRL_HeatDutyVal,
		  iMes1 		=> s12_RSHC2SRE_Sense(0),
		  iMes2 		=> s12_RSHC2SRE_Sense(1),
		  iRkSt			=> iRkSt,
		  oHeatTime 		=> s8_HC2SRE_HeatTime,
          oCtrl0			=> oCtrl0,
		  oCtrl1	        => oCtrl1,
		  oCtrl2	        => oCtrl2,
		  oCtrl3	        => oCtrl3
		);		
		
   ZBCTRL_inst: ZBCTRL PORT MAP (
          iClk 				=> s_SysClk,
          iRst				=> s_RST2ALL_Rst,
	  iTick                         => s_Tick5ms,
          iJMRxZ 			=> iJMRxZ,
          iJMRxB 			=> iJMRxB,
          oJMRxD 			=> s_ZB2RS422Rx0_RxD,
          oJMTxZ 			=> oJMTxZ,
          oJMTxB 			=> oJMTxB,
          iJMTxD 			=> s_SRE2ZB_JMTxD,
          oGuideTxZ 	        	=> oGuideTxZ,
          oGuideTxB 	        	=> oGuideTxB,
          iGuideTxD 	        	=> s_GS2ZB_GuideTxD,
          iZSig 			=> iZSig,
          iBSig 			=> iBSig,
          oTxENH 			=> oTxENH,
          oTxENL 			=> oTxENL,
          oRxENH 			=> oRxENH,
          oRxENL 			=> oRxENL
        );
end Behavioral;

