----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:43:28 06/09/2017 
-- Design Name: 
-- Module Name:    SYSREST - Behavioral 
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity SYSREST is
    Port ( iClk				 : in  STD_LOGIC;
           oSysRst 			 : out  STD_LOGIC);
end SYSREST;

architecture Behavioral of SYSREST is



   -- component BUFG
   -- port (
      -- O : out std_ulogic;     -- Clock buffer output
      -- I : in std_ulogic      -- Clock buffer input
   -- );	
   -- end component;

--=============================================================================
--  Signal definition
--=============================================================================	
	signal s_Rst     		: STD_LOGIC := '1';
	signal s16_1msCnt	    : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');	
begin
	------------------------------
	-- Release reset signal
	------------------------------
	process(iClk)
	begin
	    if(iClk'event and iClk = '1') then
			if(s16_1msCnt > X"9C3E") then
				s_Rst <= '0';
			else 
				s_Rst <= '1';
			end if;
		end if;
	end process;
	------------------------------
	-- Count 1ms then release reset
	------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
				if(s16_1msCnt > X"9C3E") then
					s16_1msCnt <= s16_1msCnt;
				else
					s16_1msCnt <= s16_1msCnt + 1;
				end if;
			end if;
	end process;	
   --	oSysRst <= s_Rst;
     BUFG_inst : BUFG
     port map (
        O => oSysRst,     -- Clock buffer output
        I => s_Rst        -- Clock buffer input
     );	
	
end Behavioral;

