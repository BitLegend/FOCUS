--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   17:22:09 03/13/2017
-- Design Name:   
-- Module Name:   E:/Project/X-EUV/Software/FPGA-SW/FocusPlane/PI_tb.vhd
-- Project Name:  FocusPlane
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: PI
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
 
ENTITY PI_tb IS
END PI_tb;
 
ARCHITECTURE behavior OF PI_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT PI
	GENERIC(
			-- Discrete PI parameters (Tustin transform)
			-- prarameter to adjust the sensitivity : fraction length = 14 - c_SumFraN
			gFracN        : integer := 4; 
			-- Data Type: fixed-point data, Fraction length 20
			-- 0.0075
		   gPaNow         : STD_LOGIC_VECTOR(15 downto 0) := X"1eb8";
		   -- 0.0075
		   gPaPre         : STD_LOGIC_VECTOR(15 downto 0) := X"1eb8";
		   -- anti-windup parameter : power of 2; = (2^gND)/(2^14)  9=<gND<=14
		   gND            : integer := 10

		);	
    PORT(
         iClk : IN  std_logic;
         iRst : IN  std_logic;
         iUpdate : IN  std_logic;
			iClose			  : in  STD_LOGIC;
			  iManual        : in  STD_LOGIC_VECTOR (11 downto 0); -- Manual set point
         iSP : IN  std_logic_vector(11 downto 0);
         iPV : IN  std_logic_vector(11 downto 0);
		 oVal           : out STD_LOGIC;
         oCtrl : OUT  std_logic_vector(17 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal iClk : std_logic := '0';
   signal iRst : std_logic := '0';
   signal iUpdate : std_logic := '0';
   signal iClose : std_logic := '0';
   signal iManual : std_logic_vector(11 downto 0) := (others => '0');
   signal iSP : std_logic_vector(11 downto 0) := (others => '0');
   signal iPV : std_logic_vector(11 downto 0) := (others => '0');

 	--Outputs
   signal oCtrl : std_logic_vector(17 downto 0);
   signal oVal : std_logic;

   -- Clock period definitions
   constant iClk_period : time := 25 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: PI 
   	GENERIC MAP(
			-- Discrete PI parameters (Tustin transform)
			-- prarameter to adjust the sensitivity : fraction length = 14 - c_SumFraN
			gFracN       => 9,
			-- Data Type: fixed-point data, Fraction length 20
			-- 0.0075
		   gPaNow         => X"0831",
		   -- 0.0075
		   gPaPre         =>X"0831",
		   -- anti-windup parameter : power of 2; = (2^gND)/(2^14)  9=<gND<=14
		   gND            =>9
		)
   PORT MAP (
          iClk => iClk,
          iRst => iRst,
          iUpdate => iUpdate,
			 iClose => iClose,
			 iManual => iManual,
          iSP => iSP,
          iPV => iPV,
		  oVal => oVal,
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
 
   -- Update process
   iUpdata_pr :process
   begin
		iUpdate <= '0';
		wait for 100 us;
		iUpdate <= '1';
		wait for iClk_period;
   end process;
   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
	  iRst <= '1';
      wait for 100 ns;	
	  iRst <= '0';
	  iManual <= X"000";
	  iClose <= '1';
      wait for iClk_period*10;
		iSP <= X"FFF";
		iPV <= X"000";
      -- insert stimulus here 
      wait for 100ms;
	  iClose <= '0';		
      wait for 20ms;		
		iSP <= X"000";
	  iClose <= '1';		
      wait for 20ms;		
	  iClose <= '0';		
	  	  iManual <= X"000";
      wait for 20ms;			
	iRst <= '1';
	wait for iClk_period*10;
	  iRst <= '0';
		iSP <= X"007";
		iPV <= X"000";
	        wait for 10ms;
	iRst <= '1';
	wait for iClk_period*10;
	  iRst <= '0';
		iSP <= X"009";
		iPV <= X"000";
	        wait for 10ms;
	iRst <= '1';
	wait for iClk_period*10;
	  iRst <= '0';
	iSP <= X"000";
	iPV <= X"800";
      wait;
   end process;

END;
