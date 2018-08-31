--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:46:18 04/10/2017
-- Design Name:   
-- Module Name:   E:/Project/X-EUV/Software/FPGA-SW/FocusPlane/HEAT_CTRL_tb.vhd
-- Project Name:  FocusPlane
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: HEAT_CTRL
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
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY HEAT_CTRL_tb IS
END HEAT_CTRL_tb;
 
ARCHITECTURE behavior OF HEAT_CTRL_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT HEAT_CTRL
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iTick1S : IN  std_logic;
         iMode : IN  a4of8;
         iSenSel : IN  a4of8;
         iTarget : IN  a4of12;
         iDuty : IN  a4of8;
         iMes1 : IN  std_logic_vector(11 downto 0);
         iMes2 : IN  std_logic_vector(11 downto 0);
		 oHeatTime           : out a4of8;
         oCtrl : OUT  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal iRst : std_logic := '0';
   signal iClk : std_logic := '0';
   signal iUpdate : std_logic := '0';
   signal iTick1S : std_logic := '0';
   signal iMode : a4of8 := ((others => '0'),(others => '0'),(others => '0'),(others => '0'));
   signal iSenSel : a4of8 := ((others => '0'),(others => '0'),(others => '0'),(others => '0'));
   signal iTarget : a4of12 := ((others => '0'),(others => '0'),(others => '0'),(others => '0'));
   signal iDuty : a4of8 := ((others => '0'),(others => '0'),(others => '0'),(others => '0'));
   signal iMes1 : std_logic_vector(11 downto 0) := (others => '0');
   signal iMes2 : std_logic_vector(11 downto 0) := (others => '0');

 	--Outputs
	signal oHeatTime : a4of8;
   signal oCtrl : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant iClk_period : time := 25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: HEAT_CTRL PORT MAP (
          iRst => iRst,
          iClk => iClk,
          iTick1S => iTick1S,
          iMode => iMode,
          iSenSel => iSenSel,
          iTarget => iTarget,
          iDuty => iDuty,
          iMes1 => iMes1,
          iMes2 => iMes2,
		  oHeatTime => oHeatTime,
          oCtrl => oCtrl
        );

   -- Clock process definitions
   iClk_process :process
   begin
		iClk <= '0';
		wait for iClk_period/2;
		iClk <= '1';
		wait for iClk_period/2;
   end process;
 
    -- Sampling process
   iTick1S_pr :process
   begin
		iTick1S <= '0';
		wait for 1 ms;
		iTick1S <= '1';
		wait for iClk_period;
		iTick1S <= '0';
   end process;  
   
   
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	  iRst <= '1';
      wait for 100 ns;	
	  iRst <= '0';
      wait for iClk_period*10;
	  iMode(0) <= c8_open;
	  iMode(1) <= c8_open;
	  iMode(2) <= c8_close;
	  iMode(3) <= c8_close;
	  iSenSel(0)  <= c8_open;  
	  iSenSel(1)  <= c8_open;  
	  iSenSel(2)  <= c8_close;  
	  iSenSel(3)  <= c8_close;  	  
	  iTarget(0) <= X"555";
	  iTarget(1) <= X"555";	  
	  iTarget(2) <= X"555";
	  iTarget(3) <= X"555";
	  
	  iDuty(0) <= X"00";
	  iDuty(1) <= X"01";	  
	  iDuty(2) <= X"09";
	  iDuty(3) <= X"0a";
	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";
	  
	  wait for 400 ms;	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";
	  
	  wait for 400 ms;	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";

	  iTarget(0) <= X"055";
	  iTarget(1) <= X"055";	  
	  iTarget(2) <= X"055";
	  iTarget(3) <= X"055";

	  

	  wait for 400 ms;	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";

	  iMode(0) <= c8_open;
	  iMode(1) <= c8_open;
	  iMode(2) <= c8_open;
	  iMode(3) <= c8_open;
	  
	  wait for 400 ms;	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";
	  
	  wait for 400 ms;	  
	  iMes1 <= X"055";
	  iMes2 <= X"055";
		iDuty(0) <= X"0b";
	  iDuty(1) <= X"00";	
	  iTarget(0) <= X"555";
	  iTarget(1) <= X"555";	  
	  iTarget(2) <= X"555";
	  iTarget(3) <= X"555";
	  iMode(0) <= c8_open;
	  iMode(1) <= c8_open;
	  iMode(2) <= c8_close;
	  iMode(3) <= c8_close;
	  
	  wait for 400 ms;	  
	  iMes1 <= X"555";
	  iMes2 <= X"555";
	  -- larger than target temperature and rise
	  wait for 400 ms;	  
	  iMes1 <= X"655";
	  iMes2 <= X"655";	

	  -- larger than target temperature and fall	
	  -- lower than target temperature and fall		  
	  wait for 400 ms;
	  iMes1 <= X"565";
	  iMes2 <= X"565";	
	  
	  wait for 400 ms;	  
	  iMes1 <= X"555";
	  iMes2 <= X"555";
	  
	  -- larger than target temperature and rise	
	  -- lower than target temperature and rise		  
	  wait for 400 ms;
	  iMes1 <= X"558";--大于或等于3个码加热-1 
	  iMes2 <= X"552";--小于或等于3个码加热不变	 

	  -- larger than target temperature and rise	
	  -- lower than target temperature and rise		  
	  wait for 400 ms;
	  iMes1 <= X"557";--
	  iMes2 <= X"553";--	 

	  
	  wait for 400 ms;
	  iMes1 <= X"556";--
	  iMes2 <= X"555";--	

	  wait for 400 ms;
	  iMes1 <= X"557";--
	  iMes2 <= X"554";--	

	  wait for 400 ms;
	  iMes1 <= X"566";--
	  iMes2 <= X"566";--	  
      -- insert stimulus here 

      wait;
   end process;

END;
