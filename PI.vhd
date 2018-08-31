----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:36:59 03/13/2017 
-- Design Name: 
-- Module Name:    PI - Behavioral 
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
-- use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity PI is
	GENERIC(
			-- Slope control parameters: limit the change in one interval,fixdt(1,27,14)
			gUpSlope        : STD_LOGIC_VECTOR(26 downto 0) := "000"&X"016c17";--40mA 9.6Hz 12uF
			gDwSlope        : STD_LOGIC_VECTOR(26 downto 0) := "111"&X"fe93e9";
			-- prarameter to adjust the sensitivity : fraction length = 14 - gFracN
			gFracN         	: integer := 4; 
		    -- anti-windup parameter : power of 2; = (2^gND)/(2^14)  9=<gND<=11
		    gND           	: integer := 10
		);
    Port ( 	iClk          	: in  STD_LOGIC;
			iRst          	: in  STD_LOGIC;
			----------- Input parameter ----------
			iUpdate        	: in  STD_LOGIC;
			iClose			: in  STD_LOGIC;
			iManual         : in  STD_LOGIC_VECTOR (11 downto 0); -- Manual set point
			iSP             : in  STD_LOGIC_VECTOR (11 downto 0); -- Set point
			iPV             : in  STD_LOGIC_VECTOR (11 downto 0); -- Measurement value
			-- PI parameters Data Type: fixed-point data, Fraction length 20			
			iPaNow          : in  STD_LOGIC_VECTOR (15 downto 0);
			iPaPre          : in  STD_LOGIC_VECTOR (15 downto 0);
			----------- Output parameter ----------		
			oVal            : out STD_LOGIC;
			-- Data Type: fixed-point data, (1,18,6)
			oCtrl           : out  STD_LOGIC_VECTOR (17 downto 0));
end PI;

architecture Behavioral of PI is
	-- Multiplier V10.0
	COMPONENT Multi_PI
	  PORT (
		clk : IN STD_LOGIC;
		-- Data Type: fixed-point data, (1,13,0)
		a : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
		-- Data Type: fixed-point data, (1,16,20)
		b : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		-- Data Type: fixed-point data, (1,23,14)
		p : OUT STD_LOGIC_VECTOR(22 DOWNTO 0)
	  );
	END COMPONENT;
	
	-- Error between set and measurement
	signal s13_Er        : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	signal s13_ErPre     : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');

	-- saturation output
	constant c_SatUp     : STD_LOGIC_VECTOR(11 downto 0) := X"7AA";
	constant c_SatDw     : STD_LOGIC_VECTOR(11 downto 0) := X"fab";
	constant c_SumPZe    : STD_LOGIC_VECTOR(gFracN downto 1) := (others => '0');
	constant c_SatPZe    : STD_LOGIC_VECTOR(gND downto 1) := (others => '0');
	--slope control: fixdt(1,27,14)
	-- constant gUpSlope   : STD_LOGIC_VECTOR(26 downto 0) := "000"&X"012df8";
	-- constant gDwSlope   : STD_LOGIC_VECTOR(26 downto 0) := "111"&X"fed208";
	-- fixdt(1,23,14)
	signal s23_NowErPro  : STD_LOGIC_VECTOR(22 downto 0) := (others => '0');
	signal s23_PreErPro  : STD_LOGIC_VECTOR(22 downto 0) := (others => '0');
	
	-- Sum: fixdt(1,27,14)
	signal s27_Sum       : STD_LOGIC_VECTOR(26 downto 0) := (others => '0');
	signal s27_ErrAdd    : STD_LOGIC_VECTOR(26 downto 0) := (others => '0');	
	signal s27_ErrAddTh  : STD_LOGIC_VECTOR(26 downto 0) := (others => '0');	
	-- fixdt(1,27,14)	
	signal s27_SumAddTmp : STD_LOGIC_VECTOR(26 downto 0) := (others => '0');
	
	-- Saturation error : fixdt(1,15,0)
	signal s15_SatEr     : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
	signal s15_SatErPre  : STD_LOGIC_VECTOR(14 downto 0) := (others => '0');
	
	-- Saturation error sum : fixdt(1,16,0)
	signal s16_SatErSum  : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
	-- Saturation error product: Fraction length 8
	signal s27_SatErPro  : STD_LOGIC_VECTOR(26 downto 0) := (others => '0');
	
	-- anti-windup parameter
	signal s18_SaOut     : STD_LOGIC_VECTOR(17 downto 0) := (others => '0');
	
    -- output data delay
	signal s5_oValDelay  : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');	
	
begin

	---------------------------------------
	-- Update Error of set point and measurement 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s13_Er <= (others => '0');
			s13_ErPre <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(iUpdate = '1') then
				s13_Er <= ('0'&iSP) - ('0'&iPV);
				s13_ErPre <= s13_Er;
			end if;
		end if;
	end process;	
	
	Multi_PI_inst1 : Multi_PI
	PORT MAP (
		clk => iClk,
		a => s13_Er,
		b => iPaNow,
		p => s23_NowErPro
	);
	
	Multi_PI_inst2 : Multi_PI
	PORT MAP (
		clk => iClk,
		a => s13_ErPre,
		b => iPaPre,
		p => s23_PreErPro
	);	
	
	---------------------------------------
	-- Summarize the products 
	---------------------------------------
	process(iClk, iRst)
	begin	
		if(iRst = '1') then
			s27_SumAddTmp <=  (others => '0');
			s27_ErrAdd <= (others => '0');
		elsif(iClk'event and iClk = '1') then	
			if(iClose = '0') then
				s27_ErrAdd <= s27_SatErPro;
			else
				s27_ErrAdd <= s23_NowErPro + s23_PreErPro + s27_SatErPro;
			end if;
			s27_SumAddTmp <= s27_Sum + s27_ErrAddTh;					
		end if;
	end process;	
	-- limit change between interval
	s27_ErrAddTh <= gUpSlope when s27_ErrAdd > gUpSlope else
						 gDwSlope when s27_ErrAdd < gDwSlope else
						 (s27_ErrAdd(26 downto gFracN)&c_SumPZe);
	---------------------------------------
	-- Register PI output
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s27_Sum <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(iUpdate = '1') then
				s27_Sum <= s27_SumAddTmp; 
			end if;
		end if;
	end process;		
	
	s18_SaOut <= c_SatUp&B"000000" when s27_SumAddTmp(26 downto 14) > c_SatUp else
				 c_SatDw&B"000000" when s27_SumAddTmp(26 downto 14) < c_SatDw else
				 s27_SumAddTmp(26)&s27_SumAddTmp(24 downto 8);
	oCtrl <= s18_SaOut;
	---------------------------------------
	-- Update Error of saturated output and output 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s15_SatEr <= (others => '0');
			s15_SatErPre <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(iUpdate = '1') then
				if(iClose = '0') then
					s15_SatEr <= SXT(iManual,15) - SXT(s27_SumAddTmp(26 downto 14),15) ;
				else
					s15_SatEr <= SXT(s18_SaOut(17 downto 6),15) - SXT(s27_SumAddTmp(26 downto 14),15);
				end if;
				s15_SatErPre <= s15_SatEr;
			end if;
		end if;
	end process;	
	
	s16_SatErSum <= SXT(s15_SatEr,16) + SXT(s15_SatErPre,16);
	-- s16_SatErSum multiply 0.0625; change by gND
	s27_SatErPro <= SXT(s16_SatErSum&c_SatPZe,27) ; -- fraction length 14	
	
	---------------------------------------
	-- Delay update signal of DAC  
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iClk'event and iClk = '1') then
			s5_oValDelay <= s5_oValDelay(3 downto 0)&iUpdate;
		end if;
	end process;	
	oVal <= s5_oValDelay(4); 				
				
end Behavioral;

