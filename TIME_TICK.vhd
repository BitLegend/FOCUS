----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:43:28 05/09/2017 
-- Design Name: 
-- Module Name:    TIME_TICK - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TIME_TICK is
    Port ( iClk 			: in  STD_LOGIC;-- 40Mhz
           iRst 			: in  STD_LOGIC;
		   ------------ output Tick -----------
           oTick01ms 		: out  STD_LOGIC;
           oTick1ms 		: out  STD_LOGIC;
           oTick2ms 		: out  STD_LOGIC;
		   oTick5ms         : out  STD_LOGIC;
		   oTick40ms		: out  STD_LOGIC;
           oTick1s 			: out  STD_LOGIC);
end TIME_TICK;

architecture Behavioral of TIME_TICK is

	-- 0.1ms timer counter
	signal i_01msCnt		: integer range 0 to 3999 := 0;
	signal i_1msCnt         : integer range 0 to 9 := 0;
	signal i_2msCnt         : integer range 0 to 1 := 0;
	signal i_5msCnt         : integer range 0 to 4 := 0;
	signal i_40msCnt       : integer range 0 to 7 := 0;
	signal i_1sCnt          : integer range 0 to 499 := 0;
	
	-- output register 
	signal s_Tick01ms       : STD_LOGIC := '0';
	signal s_Tick1ms        : STD_LOGIC := '0';
	signal s_Tick2ms        : STD_LOGIC := '0';
	signal s_Tick5ms        : STD_LOGIC := '0';
	signal s_Tick40ms		: STD_LOGIC := '0';
	signal s_Tick1s         : STD_LOGIC := '0';

begin

	-----------------------------------
	-- output assign
	-----------------------------------
	oTick01ms 	<= s_Tick01ms;
	oTick1ms 	<= s_Tick1ms;
	oTick2ms 	<= s_Tick2ms;
	oTick5ms 	<= s_Tick5ms;
	oTick40ms   <= s_Tick40ms;
	oTick1s 	<= s_Tick1s;
	
	-----------------------------------
	-- 0.1ms tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_01msCnt <= 0;
			s_Tick01ms <= '0';
		elsif(iClk'event and iClk = '1') then
			if(i_01msCnt = 3999) then
				i_01msCnt <= 0;
				s_Tick01ms <= '1';
			else
				i_01msCnt <= i_01msCnt + 1;
				s_Tick01ms <= '0';
			end if;
		end if;
	end process;

	-----------------------------------
	-- 1ms tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_1msCnt <= 0;
			s_Tick1ms <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick01ms = '1') then
				if(i_1msCnt = 9) then
					i_1msCnt <= 0;
					s_Tick1ms <= '1';
				else
					i_1msCnt <= i_1msCnt + 1;
					s_Tick1ms <= '0';
				end if;
			else
				i_1msCnt <= i_1msCnt;
				s_Tick1ms <= '0';
			end if;
		end if;
	end process;

	
	-----------------------------------
	-- 2ms tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_2msCnt <= 0;
			s_Tick2ms <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick1ms = '1') then
				if(i_2msCnt = 1) then
					i_2msCnt <= 0;
					s_Tick2ms <= '1';
				else
					i_2msCnt <= i_2msCnt + 1;
					s_Tick2ms <= '0';
				end if;
			else
				i_2msCnt <= i_2msCnt;
				s_Tick2ms <= '0';
			end if;
		end if;
	end process;	
	
	-----------------------------------
	-- 5ms tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_5msCnt <= 0;
			s_Tick5ms <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick1ms = '1') then
				if(i_5msCnt = 4) then
					i_5msCnt <= 0;
					s_Tick5ms <= '1';
				else
					i_5msCnt <= i_5msCnt + 1;
					s_Tick5ms <= '0';
				end if;
			else
				i_5msCnt <= i_5msCnt;
				s_Tick5ms <= '0';
			end if;
		end if;
	end process;	
	-----------------------------------
	-- 40ms tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_40msCnt <= 0;
			s_Tick40ms <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick5ms = '1') then
				if(i_40msCnt = 7) then
					i_40msCnt <= 0;
					s_Tick40ms <= '1';
				else
					i_40msCnt <= i_40msCnt + 1;
					s_Tick40ms <= '0';
				end if;
			else
				i_40msCnt <= i_40msCnt;
				s_Tick40ms <= '0';
			end if;
		end if;
	end process;		
	-----------------------------------
	-- 1s tick
	-----------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			i_1sCnt <= 0;
			s_Tick1s <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick2ms = '1') then
				if(i_1sCnt = 499) then
					i_1sCnt <= 0;
					s_Tick1s <= '1';
				else
					i_1sCnt <= i_1sCnt + 1;
					s_Tick1s <= '0';
				end if;
			else
				i_1sCnt <= i_1sCnt;
				s_Tick1s <= '0';
			end if;
		end if;
	end process;		
	
	
	
end Behavioral;

