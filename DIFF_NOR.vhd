----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:05:38 04/05/2017 
-- Design Name: 
-- Module Name:    DIFF_NOR - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--   50clk
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity DIFF_NOR is
	Port(
		iRst           : in STD_LOGIC;
		iClk           : in STD_LOGIC;
		----------- Input Data -----------
		iData1         : in STD_LOGIC_VECTOR(15 downto 0);
		iData2         : in STD_LOGIC_VECTOR(15 downto 0);		
		iData3         : in STD_LOGIC_VECTOR(15 downto 0);		
		iData4         : in STD_LOGIC_VECTOR(15 downto 0);
		iRdy           : in STD_LOGIC;
		
		----------- Diff and nomalized Output -----------
		-- signed number both quotient and fractional
		-- 1 sign bit and 1 quo bit  and 14 fractional length
		oDataXNor        : out STD_LOGIC_VECTOR(15 downto 0);
		oDataYNor        : out STD_LOGIC_VECTOR(15 downto 0)			
		
		
	);
end DIFF_NOR;

architecture Behavioral of DIFF_NOR is
--=============================================================================
--  Components declaration
--=============================================================================		  
	component Div_Guide
		port (
		clk: in std_logic;
		rfd: out std_logic;
		dividend: in std_logic_vector(16 downto 0);
		divisor: in std_logic_vector(16 downto 0);
		quotient: out std_logic_vector(16 downto 0);
		remainder: out std_logic_vector(14 downto 0));
	end component;-- Synplicity black box declaration
attribute syn_black_box : boolean;
attribute syn_black_box of Div_Guide: component is true;
--=============================================================================
--  Signal declaration
--=============================================================================		
	signal s16_data1_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_data2_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 	
	signal s16_data3_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_data4_reg    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
		
	signal s17_xSum         : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 
	signal s17_xDiff        : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 

	signal s17_ySum         : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 
	signal s17_yDiff        : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 	
	
	signal s17_xQuo         : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 
	signal s15_xFra         : STD_LOGIC_VECTOR(14 downto 0) := (others => '0'); 	

	signal s17_yQuo         : STD_LOGIC_VECTOR(16 downto 0) := (others => '0'); 
	signal s15_yFra         : STD_LOGIC_VECTOR(14 downto 0) := (others => '0'); 	
	
	signal s16_dataXNor     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	signal s16_dataYNor     : STD_LOGIC_VECTOR(15 downto 0) := (others => '0'); 
	-- constant values
	signal c17_zeroTh       : STD_LOGIC_VECTOR(16 downto 0) := B"0_0000_0001_0000_0000";
begin
	Div_Guide_inst0 : Div_Guide
		port map (
			clk => iClk,
			rfd => open,
			dividend => s17_xDiff,
			divisor => s17_xSum,
			quotient => s17_xQuo,
			remainder => s15_xFra);

	Div_Guide_inst1 : Div_Guide
		port map (
			clk => iClk,
			rfd => open,
			dividend => s17_yDiff,
			divisor => s17_ySum,
			quotient => s17_yQuo,
			remainder => s15_yFra);
			
	---------------------------------------
	-- register AD677 data 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iClk'event and iClk = '1') then
			if(iRdy = '1') then
				s16_data1_reg <= iData1;
				s16_data2_reg <= iData2;
				s16_data3_reg <= iData3;
				s16_data4_reg <= iData4;
			else
				s16_data1_reg <= s16_data1_reg;
				s16_data2_reg <= s16_data2_reg;
				s16_data3_reg <= s16_data3_reg;
				s16_data4_reg <= s16_data4_reg;
			end if;	
		end if;
	end process;	

	---------------------------------------
	-- sum and difference 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iClk'event and iClk = '1') then
			s17_xSum <= SXT(s16_data1_reg,17) + SXT(s16_data2_reg,17);
			s17_ySum <= SXT(s16_data3_reg,17) + SXT(s16_data4_reg,17);

			s17_xDiff <= SXT(s16_data1_reg,17) - SXT(s16_data2_reg,17);
			s17_yDiff <= SXT(s16_data3_reg,17) - SXT(s16_data4_reg,17);
		end if;
	end process;	
	
	---------------------------------------
	-- normalized output
	---------------------------------------
	process(iClk, iRst)
		variable tmp : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
		variable tmp1 : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	begin
		if(iClk'event and iClk = '1') then
			if(s17_xSum < c17_zeroTh) then
				s16_dataXNor <= X"0000";
			else
			   tmp := s17_xQuo(16) & s17_xQuo(0) & '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0';
				s16_dataXNor <= tmp + SXT(s15_xFra,16);
			end if;
			if(s17_ySum < c17_zeroTh) then
				s16_datayNor <= X"0000";
			else
				tmp1 := s17_yQuo(16) & s17_yQuo(0) & '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0'& '0'&'0';
				s16_datayNor <= tmp1 + SXT(s15_yFra,16);
			end if;			
		end if;
	end process;		

	oDataXNor <= s16_dataXNor;
	oDataYNor <= s16_dataYNor;
end Behavioral;

