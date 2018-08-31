----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:41:11 02/22/2017 
-- Design Name: 
-- Module Name:    RSHC_SMP - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RSHC_SMP is
    Port ( iRst : in  STD_LOGIC;
           iClk : in  STD_LOGIC;
		   ----------- TLV2548 interface -----------
           iMadSDO       : in  STD_LOGIC;
           oMadSDI       : out  STD_LOGIC;
           oMadSCLK      : out  STD_LOGIC;
           oMadCS_n      : out  STD_LOGIC;		   
		   --------- Multiplexer interface ---------
		   oRktEn        : out STD_LOGIC;
		   oRktA         : out STD_LOGIC_VECTOR (3 downto 0);
		   ----------- Sampling control -------------
           iSmp          : in  STD_LOGIC; -- 10kHz pulse
           oData         : out  madDataOut);
end RSHC_SMP;

architecture Behavioral of RSHC_SMP is
	-- COMPONENT declaration
	COMPONENT MAD2548_CTRL
	PORT(
		iRst : IN std_logic;
		iClk : IN std_logic;
		iMadSDO : IN std_logic;
		iSmp : IN std_logic;          
		oMadSDI : OUT std_logic;
		oMadSCLK : OUT std_logic;
		oMadCS_n : OUT std_logic;
		oData : OUT std_logic_vector(11 downto 0);
		oDataRdy : OUT std_logic
		);
	END COMPONENT;

	-- signal register
	signal s12_Data       : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s_DataRdy       : STD_LOGIC := '0';
	signal s4_RktA         : STD_LOGIC_VECTOR(3 downto 0) := (others => '1');
	-- channel counter
	signal us4_ChCnt       : Unsigned (3 downto 0) := (others => '1');
	
	-- output data register
	signal a16_DataOut     : madDataOut := ((others => '0'), (others => '0'), (others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'));
		
begin
	---------------------------------------
	-- Instantiate the TlV2548 component
	---------------------------------------
	Mad2548Ctrl_Inst: MAD2548_CTRL 
	PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iMadSDO => iMadSDO,
		oMadSDI => oMadSDI,
		oMadSCLK => oMadSCLK,
		oMadCS_n => oMadCS_n,
		iSmp => iSmp,
		oData => s12_Data,
		oDataRdy => s_DataRdy
	);
				  
	---------------------------------------
	-- Channel switch counter and output enable
	---------------------------------------	
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			oRktEn <= '1';
			us4_ChCnt <= (others => '1');
		elsif(iClk'event and iClk = '1') then
			oRktEn <= '0';
			if(s_DataRdy = '1') then
				us4_ChCnt <= us4_ChCnt + 1;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Channel Output assignment
	---------------------------------------	
	process(iClk,iRst)
		variable tmp : integer := 0;
	begin
		if(iClk'event and iClk = '1') then
			tmp := conv_integer(us4_ChCnt);
			if(s_DataRdy = '1') then
				a16_DataOut(tmp) <= s12_Data;
			else
				a16_DataOut <= a16_DataOut;
			end if;
		end if;
	end process;	
	---------------------------------------
	-- Output connect
	---------------------------------------		
	oRktA <= conv_std_logic_vector(us4_ChCnt,4);
	oData <= a16_DataOut;
	
	
end Behavioral;

