--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:01:46 02/23/2017
-- Design Name:   
-- Module Name:   E:/Project/X-EUV/Software/FPGA-SW/FocusPlane/RsHcSmp_tb.vhd
-- Project Name:  FocusPlane
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: RSHC_SMP
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
 
ENTITY RsHcSmp_tb IS
END RsHcSmp_tb;
 
ARCHITECTURE behavior OF RsHcSmp_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
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
    

   --Inputs
   signal iRst : std_logic := '0';
   signal iClk : std_logic := '0';
   signal iMadSDO : std_logic := '0';
   signal iPadINT : std_logic := '1';
   signal iSmp : std_logic := '0';

 	--Outputs
   signal oMadSDI : std_logic;
   signal oMadSCLK : std_logic;
   signal oMadCS_n : std_logic;
   signal oRktEn : std_logic;
   signal oRktA : std_logic_vector(3 downto 0);
   signal oData : madDataOut;

   -- Clock period definitions
   constant iClk_period : time := 25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: RSHC_SMP PORT MAP (
          iRst => iRst,
          iClk => iClk,
          iMadSDO => iMadSDO,
          oMadSDI => oMadSDI,
          oMadSCLK => oMadSCLK,
          oMadCS_n => oMadCS_n,
          oRktEn => oRktEn,
          oRktA => oRktA,
          iSmp => iSmp,
          oData => oData
        );

   -- Clock process definitions
   iClk_process :process
   begin
		iClk <= '0';
		wait for iClk_period/2;
		iClk <= '1';
		wait for iClk_period/2;
   end process;
    -- data process 
   data_process :process
   begin
		wait until oMadSCLK'event and oMadSCLK = '0';
		wait for 25 ns;
		iMadSDO <= not iMadSDO;	  
   end process; 
    -- Sampling process
   iSmp_pr :process
   begin
		iSmp <= '0';
		wait for 1000 us;
		iSmp <= '1';
		wait for iClk_period;
		iSmp <= '1';
   end process;  
   
    -- INT process
   INT :process
   begin
	iPadINT <= '1';
	wait for 25 us;
	iPadINT <= '0';
	wait for iClk_period;
	iPadINT <= '1';
	wait for 75 us;
	
   end process;  
   
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	  iRst <= '1';
      wait for 100 ns;	
	  iRst <= '0';
	        -- insert stimulus here 	  	  
      wait;
   end process;

END;
