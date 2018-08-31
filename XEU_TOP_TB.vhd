
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   11:01:25 06/09/2017
-- Design Name:   XEUV_TOP
-- Module Name:   C:/Xilinx92i/FOCUS_TST/XEU_TOP_TB.vhd
-- Project Name:  FOCUS_TST
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: XEUV_TOP
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY XEU_TOP_TB_vhd IS
END XEU_TOP_TB_vhd;

ARCHITECTURE behavior OF XEU_TOP_TB_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT XEUV_TOP
	PORT(
		iClk : IN std_logic;
		iMadSDO : IN std_logic;
		iMRxD : IN std_logic;
		iSdata1 : IN std_logic;
		iSclk1 : IN std_logic;
		iSdata2 : IN std_logic;
		iSclk2 : IN std_logic;
		iSdata3 : IN std_logic;
		iSclk3 : IN std_logic;
		iSdata4 : IN std_logic;
		iSclk4 : IN std_logic;
		iPadSDO : IN std_logic;
		iRkSt : IN std_logic_vector(3 downto 0);          
		oMadSDI : OUT std_logic;
		oMadSCLK : OUT std_logic;
		oMadCS_n : OUT std_logic;
		oRktEn : OUT std_logic;
		oRktA : OUT std_logic_vector(3 downto 0);
		oAD_IO_en : OUT std_logic;
		oG_IO_en : OUT std_logic;
		oMTxD : OUT std_logic;
		oGTxD : OUT std_logic;
		oCCDTxD : OUT std_logic;
		oClk1 : OUT std_logic;
		oCal1 : OUT std_logic;
		oSmp1 : OUT std_logic;
		oClk3 : OUT std_logic;
		oCal3 : OUT std_logic;
		oSmp3 : OUT std_logic;
		oPadSDI : OUT std_logic;
		oPadSCLK : OUT std_logic;
		oPadCS_n : OUT std_logic;
		oDA_DB : OUT std_logic_vector(11 downto 0);
		oDA_A : OUT std_logic_vector(1 downto 0);
		oDA_CS : OUT std_logic;
		oDA_LDAC : OUT std_logic;
		oSWF : OUT std_logic;
		oSWO : OUT std_logic;
		oCtrl : OUT std_logic_vector(3 downto 0)
		);
	END COMPONENT;

	--Inputs
	SIGNAL iClk :  std_logic := '0';
	SIGNAL iMadSDO :  std_logic := '0';
	SIGNAL iMRxD :  std_logic := '0';
	SIGNAL iSdata1 :  std_logic := '0';
	SIGNAL iSclk1 :  std_logic := '0';
	SIGNAL iSdata2 :  std_logic := '0';
	SIGNAL iSclk2 :  std_logic := '0';
	SIGNAL iSdata3 :  std_logic := '0';
	SIGNAL iSclk3 :  std_logic := '0';
	SIGNAL iSdata4 :  std_logic := '0';
	SIGNAL iSclk4 :  std_logic := '0';
	SIGNAL iPadSDO :  std_logic := '0';
	SIGNAL iRkSt :  std_logic_vector(3 downto 0) := (others=>'0');

	--Outputs
	SIGNAL oMadSDI :  std_logic;
	SIGNAL oMadSCLK :  std_logic;
	SIGNAL oMadCS_n :  std_logic;
	SIGNAL oRktEn :  std_logic;
	SIGNAL oRktA :  std_logic_vector(3 downto 0);
	SIGNAL oAD_IO_en :  std_logic;
	SIGNAL oG_IO_en :  std_logic;
	SIGNAL oMTxD :  std_logic;
	SIGNAL oGTxD :  std_logic;
	SIGNAL oCCDTxD :  std_logic;
	SIGNAL oClk1 :  std_logic;
	SIGNAL oCal1 :  std_logic;
	SIGNAL oSmp1 :  std_logic;
	SIGNAL oClk3 :  std_logic;
	SIGNAL oCal3 :  std_logic;
	SIGNAL oSmp3 :  std_logic;
	SIGNAL oPadSDI :  std_logic;
	SIGNAL oPadSCLK :  std_logic;
	SIGNAL oPadCS_n :  std_logic;
	SIGNAL oDA_DB :  std_logic_vector(11 downto 0);
	SIGNAL oDA_A :  std_logic_vector(1 downto 0);
	SIGNAL oDA_CS :  std_logic;
	SIGNAL oDA_LDAC :  std_logic;
	SIGNAL oSWF :  std_logic;
	SIGNAL oSWO :  std_logic;
	SIGNAL oCtrl :  std_logic_vector(3 downto 0);
   -- Clock period definitions
   constant iClk_period : time := 25 ns;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: XEUV_TOP PORT MAP(
		iClk => iClk,
		iMadSDO => iMadSDO,
		oMadSDI => oMadSDI,
		oMadSCLK => oMadSCLK,
		oMadCS_n => oMadCS_n,
		oRktEn => oRktEn,
		oRktA => oRktA,
		oAD_IO_en => oAD_IO_en,
		oG_IO_en => oG_IO_en,
		oMTxD => oMTxD,
		iMRxD => iMRxD,
		oGTxD => oGTxD,
		oCCDTxD => oCCDTxD,
		oClk1 => oClk1,
		oCal1 => oCal1,
		oSmp1 => oSmp1,
		iSdata1 => iSdata1,
		iSclk1 => iSclk1,
		iSdata2 => iSdata2,
		iSclk2 => iSclk2,
		oClk3 => oClk3,
		oCal3 => oCal3,
		oSmp3 => oSmp3,
		iSdata3 => iSdata3,
		iSclk3 => iSclk3,
		iSdata4 => iSdata4,
		iSclk4 => iSclk4,
		iPadSDO => iPadSDO,
		oPadSDI => oPadSDI,
		oPadSCLK => oPadSCLK,
		oPadCS_n => oPadCS_n,
		oDA_DB => oDA_DB,
		oDA_A => oDA_A,
		oDA_CS => oDA_CS,
		oDA_LDAC => oDA_LDAC,
		oSWF => oSWF,
		oSWO => oSWO,
		oCtrl => oCtrl,
		iRkSt => iRkSt
	);
   -- Clock process definitions
   iClk_process :process
   begin
		iClk <= '0';
		wait for iClk_period/2;
		iClk <= '1';
		wait for iClk_period/2;
   end process;
	
	tb : PROCESS
	BEGIN

		-- Wait 100 ns for global reset to finish
		wait for 100 ns;

		-- Place stimulus here

		wait; -- will wait forever
	END PROCESS;

END;
