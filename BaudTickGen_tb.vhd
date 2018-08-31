--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:11:20 12/22/2016
-- Design Name:   
-- Module Name:   E:/Project/X-EUV/Software/FPGA-SW/FocusPlane/BAUD_TICK_GEN_tb.vhd
-- Project Name:  FocusPlane
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: BAUD_TICK_GEN
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY BAUD_TICK_GEN_tb IS
END BAUD_TICK_GEN_tb;
 
ARCHITECTURE behavior OF BAUD_TICK_GEN_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT BAUD_TICK_GEN
		GENERIC (gAccWidth : integer;
			gInc      : integer);
    PORT(
         iRst : IN  std_logic;
         iClk : IN  std_logic;
         iEn : IN  std_logic;
         oTick : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal iRst : std_logic := '0';
   signal iClk : std_logic := '0';
   signal iEn : std_logic := '0';

 	--Outputs
   signal oTick : std_logic;

   -- Clock period definitions
   constant iClk_period : time := 25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: BAUD_TICK_GEN 
    GENERIC MAP(
	gAccWidth => 19,
	gInc => 1510
	)
   PORT MAP (
          iRst => iRst,
          iClk => iClk,
          iEn => iEn,
          oTick => oTick
        );

   -- Clock process definitions
   iClk_process :process
   begin
		iClk <= '0';
		wait for iClk_period/2;
		iClk <= '1';
		wait for iClk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	  iRst <= '1';
      wait for 100 ns;	
	  iRst <= '0';
	  iEn <= '0';
      wait for iClk_period*10;
	  iEn <= '1';
      -- insert stimulus here 

      wait;
   end process;

END;
