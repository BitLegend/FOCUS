----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:18:30 12/22/2016 
-- Design Name: 
-- Module Name:    BAUD_TICK_GEN - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity BAUD_TICK_GEN is
	GENERIC (
			-- Counter Width = log2(ClkFrequency/Baud)+10
			gAccWidth : integer := 20;--80M 115200
			-- Increment = Baud*OverSampling/ClkFrequency*2^accWidth
			gInc      : integer := 1510 -- OverSampling equals 1 for trans, 8 for rec
	);
    Port ( 
		   iRst     : in  STD_LOGIC;
		   iClk     : in  STD_LOGIC;
           iEn      : in  STD_LOGIC;
           oTick    : out  STD_LOGIC);
end BAUD_TICK_GEN;

architecture Behavioral of BAUD_TICK_GEN is
--******************************Signal Definition******************************
	signal sv_Acc : STD_LOGIC_VECTOR(gAccWidth downto 0) := (others => '0');
begin
	---------------------------------------
	-- Generate tick
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			sv_Acc <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(iEn = '1') then
				sv_Acc <= '0'&sv_Acc(gAccWidth-1 downto 0) + gInc;
			else
				sv_Acc <= (others => '0');
			end if;
		end if;
	end process;
	oTick <= sv_Acc(gAccWidth);
end Behavioral;

