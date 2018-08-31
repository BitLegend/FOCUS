--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   08:13:33 01/23/2017
-- Design Name:   
-- Module Name:   E:/Project/X-EUV/Software/FPGA-SW/FocusPlane/SPI_master_tb.vhd
-- Project Name:  FocusPlane
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SPI_MASTER
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
USE ieee.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY SPI_master_tb IS
	Generic (		
		N        : positive := 32;-- serial word length  		
		CPOL     : STD_LOGIC := '0';-- SPI mode set (polarity)                                          
		CPHA     : STD_LOGIC := '0';-- SPI mode set (phase)   
		-- SPI clock divisor, for 80MHz iClk, result in 5MHz SCLK
		SPI_2X_CLK_DIV : positive := 8);   
END SPI_master_tb;
 
ARCHITECTURE behavior OF SPI_master_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
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
    

   --Inputs
   signal iClk : std_logic := '0';
   signal iRst : std_logic := '0';
   signal iSpiMISO : std_logic := '0';
   signal iWr : std_logic := '0';
   signal iData : std_logic_vector(N-1 downto 0) := (others => '0');

 	--Outputs
   signal oSpiSsel : std_logic;
   signal oSpiSclk : std_logic;
   signal oSpiMOSI : std_logic;
   signal oDataVal : std_logic;
   signal oData : std_logic_vector(N-1 downto 0);

   -- Clock period definitions
   constant iClk_period : time := 12.5 ns;
  --=========================================================
    -- constants
    --=========================================================
    constant fifo_memory_size : integer := 2;
    
    --=========================================================
    -- types
    --=========================================================
    type fifo_memory_type is array (0 to fifo_memory_size-1) of std_logic_vector (N-1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: SPI_MASTER 
   generic map(
   		N    => N,   	
		CPOL => CPOL,                                     
		CPHA => CPHA,   
		-- SPI clock divisor, for 80MHz iClk, result in 5MHz SCLK
		SPI_2X_CLK_DIV => SPI_2X_CLK_DIV)
   PORT MAP (
          iClk => iClk,
          iRst => iRst,
          oSpiSsel => oSpiSsel,
          oSpiSclk => oSpiSclk,
          oSpiMOSI => oSpiMOSI,
          iSpiMISO => iSpiMISO,
          iWr => iWr,
          iData => iData,
          oDataVal => oDataVal,
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
  
   -- Stimulus process
   stim_proc: process
	variable fifo_memory : fifo_memory_type := 
		(X"43211204",X"abcd5874");
	variable fifo_head : integer range 0 to fifo_memory_size-1;
   begin		
      -- hold reset state for 100 ns.
	  iRst <= '1';
      wait for 100 ns;	
		
      wait for iClk_period*10;
	  iRst <= '0';
      -- insert stimulus here 
	  iWr <= '1';
	  iData <= fifo_memory(0);
	  wait for iClk_period;
	  iWr <= '0';
	  for i in 0 to 15 loop
		  wait until oSpiSclk'event and oSpiSclk = '1';
		  iSpiMISO <= not iSpiMISO;	  
	  end loop;
	  
	  wait until oDataVal = '1';
	  wait for iClk_period;
	  iWr <= '1';
	  iData <= fifo_memory(1);
	  wait for iClk_period;
	  iWr <= '0';	  
      wait;
   end process;

END;
