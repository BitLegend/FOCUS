----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:13:05 06/28/2017 
-- Design Name: 
-- Module Name:    BIQUAD_Z - Behavioral 
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BIQUAD_X is
    Port ( iRst : in  STD_LOGIC;
           iClk : in  STD_LOGIC;
		   iND  : in  STD_LOGIC;
           iData : in  STD_LOGIC_VECTOR (17 downto 0);
		   oRdy  : out STD_LOGIC;
           oData : out  STD_LOGIC_VECTOR (11 downto 0));
end BIQUAD_X;

architecture Behavioral of BIQUAD_X is
--=============================================================================
--  Components declaration
--=============================================================================		
	-- FIR compiler 3.2   
   COMPONENT X_FIRx0
    PORT(
		 rfd : out STD_LOGIC; 
		 rdy : out STD_LOGIC; 
		 nd : in STD_LOGIC := 'X'; 
		 clk : in STD_LOGIC := 'X'; 
		 dout : out STD_LOGIC_VECTOR ( 35 downto 0 ); 
		 din : in STD_LOGIC_VECTOR ( 17 downto 0 ) 
        );
    END COMPONENT;
	-- FIR compiler 3.2
    COMPONENT X_FIRy0
    PORT(
      clk : IN STD_LOGIC;
      nd : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(28 DOWNTO 0);
      rdy : OUT STD_LOGIC;
      rfd : OUT STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(45 DOWNTO 0)   
        );
    END COMPONENT;	

	-- FIR compiler 3.2   
   COMPONENT X_FIRx
    PORT(
		 rfd : out STD_LOGIC; 
		 rdy : out STD_LOGIC; 
		 nd : in STD_LOGIC := 'X'; 
		 clk : in STD_LOGIC := 'X'; 
		 dout : out STD_LOGIC_VECTOR ( 35 downto 0 ); 
		 din : in STD_LOGIC_VECTOR ( 17 downto 0 ) 
        );
    END COMPONENT;
	-- FIR compiler 3.2
    COMPONENT X_FIRy
    PORT(
      clk : IN STD_LOGIC;
      nd : IN STD_LOGIC;
      din : IN STD_LOGIC_VECTOR(28 DOWNTO 0);
      rdy : OUT STD_LOGIC;
      rfd : OUT STD_LOGIC;
      dout : OUT STD_LOGIC_VECTOR(45 DOWNTO 0)   
        );
    END COMPONENT;	

--=============================================================================
--  Signal definition
--=============================================================================	
	-- Fractional length 20
	signal s36_xDataO             : STD_LOGIC_VECTOR(35 downto 0) := (others => '0');

	signal s35_xyDataSum          : STD_LOGIC_VECTOR(34 downto 0) := (others => '0');	
	-- Fractional length 14
	signal s29_yDataI             : STD_LOGIC_VECTOR(28 downto 0) := (others => '0');		
	-- Fractional length 28
	signal s46_yDataO             : STD_LOGIC_VECTOR(45 downto 0) := (others => '0');		
	
	signal s_ND_reg               : STD_LOGIC := '0';
	signal s_yRdy                 : STD_LOGIC := '0';
	-- notch filter 0 signals
	-- fixdt(1,18,6)
	signal s36_x0DataO            : STD_LOGIC_VECTOR(35 downto 0) := (others => '0');
	signal s35_xy0DataSum         : STD_LOGIC_VECTOR(34 downto 0) := (others => '0');	
	-- Fractional length 14
	signal s29_y0DataI            : STD_LOGIC_VECTOR(28 downto 0) := (others => '0');		
	-- Fractional length 28
	signal s46_y0DataO            : STD_LOGIC_VECTOR(45 downto 0) := (others => '0');		
	
	signal s_ND_reg0              : STD_LOGIC := '0';
	signal s_y0Rdy                : STD_LOGIC := '0';
    -- notch filter 0 output data and ready signal
	signal s18_Notch0DataO        : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
	signal s_Notch0Rdy            : STD_LOGIC := '0';
	
	
begin
	-- Instantiate the component
   X_FIRx0_inst: X_FIRx0 PORT MAP (
          clk => iClk,
          nd => iND,
          rfd => open,
          rdy => open,
          din => iData,
          dout => s36_x0DataO
        );		
	-- Instantiate the component
   X_FIRy0_inst: X_FIRy0 PORT MAP (
          clk => iClk,
          nd => s_ND_reg0,
          rfd => open,
          rdy => s_y0Rdy,
          din => s29_y0DataI,
          dout => s46_y0DataO
        );
	-- Fractional length 20 
	s35_xy0DataSum <= (s36_x0DataO(s36_x0DataO'left)&s36_x0DataO(33 downto 0)) 
		- (s46_y0DataO(s46_y0DataO'LEFT)&s46_y0DataO(41 downto 8));

	-----------------------------------
	-- Delay Y data 
	-----------------------------------	
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iND = '1') then
				s29_y0DataI <= s35_xy0DataSum(34 downto 6);
			else
				s29_y0DataI <= s29_y0DataI;
			end if;
			s_ND_reg0 <= iND;
		end if;
	end process;
		
	-----------------------------------
	-- Register output
	-----------------------------------	
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			s18_Notch0DataO <= (others => '0');
			s_Notch0Rdy <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s35_xy0DataSum(34 downto 20) > STD_LOGIC_VECTOR(conv_signed(2047,15))) then
				s18_Notch0DataO <= B"01_1111_1111_1100_0000";
			elsif(s35_xy0DataSum(34 downto 20) < STD_LOGIC_VECTOR(conv_signed(-2048,15))) then
				s18_Notch0DataO <= B"10_0000_0000_0000_0000";
			else
				s18_Notch0DataO <= s35_xy0DataSum(s35_xy0DataSum'LEFT)&s35_xy0DataSum(30 downto 14);
			end if;
			
			if(s_y0Rdy = '1') then
				s_Notch0Rdy <= '1';
			else
				s_Notch0Rdy <= '0';
			end if;
		end if;
	end process;






	-- Instantiate the component
   X_FIRx_inst: X_FIRx PORT MAP (
          clk => iClk,
          nd => s_Notch0Rdy,
          rfd => open,
          rdy => open,
          din => s18_Notch0DataO,
          dout => s36_xDataO
        );

		
	-- Instantiate the component
   X_FIRy_inst: X_FIRy PORT MAP (
          clk => iClk,
          nd => s_ND_reg,
          rfd => open,
          rdy => s_yRdy,
          din => s29_yDataI,
          dout => s46_yDataO
        );
	-- Fractional length 20 
	s35_xyDataSum <= (s36_xDataO(s36_xDataO'left)&s36_xDataO(33 downto 0)) - (s46_yDataO(s46_yDataO'LEFT)&s46_yDataO(41 downto 8));

	-----------------------------------
	-- Delay Y data 
	-----------------------------------	
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(s_Notch0Rdy = '1') then
				s29_yDataI <= s35_xyDataSum(34 downto 6);
			else
				s29_yDataI <= s29_yDataI;
			end if;
			s_ND_reg <= s_Notch0Rdy;
		end if;
	end process;
		
	-----------------------------------
	-- Register output
	-----------------------------------	
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			oData <= (others => '0');
			oRdy <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s35_xyDataSum(34 downto 20) > STD_LOGIC_VECTOR(conv_signed(2047,15))) then
				oData <= STD_LOGIC_VECTOR(conv_signed(2047,12));
			elsif(s35_xyDataSum(34 downto 20) < STD_LOGIC_VECTOR(conv_signed(-2048,15))) then
				oData <= STD_LOGIC_VECTOR(conv_signed(-2048,12));
			else
				oData <= s35_xyDataSum(s35_xyDataSum'LEFT)&s35_xyDataSum(30 downto 20);
			end if;
			
			if(s_yRdy = '1') then
				oRdy <= '1';
			else
				oRdy <= '0';
			end if;
		end if;
	end process;

	
end Behavioral;