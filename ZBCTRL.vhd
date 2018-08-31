----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:30:50 03/14/2018 
-- Design Name: 
-- Module Name:    ZBCTRL - Behavioral 
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

entity ZBCTRL is
    Port ( iClk 				: in  STD_LOGIC;
           iRst 				: in  STD_LOGIC;
		   iTick                : in  STD_LOGIC;
		   ---------- data received from central controller ---------
		   iJMRxZ     		    : in  STD_LOGIC;
		   iJMRxB     		    : in  STD_LOGIC;
		   oJMRxD      		    : out  STD_LOGIC;
		   ---------- data sent to central controller ---------
		   oJMTxZ     		    : out  STD_LOGIC;
		   oJMTxB     		    : out  STD_LOGIC;
		   iJMTxD      		    : in  STD_LOGIC;
		   ---------- guide telescope data sent to central controller ---------
		   oGuideTxZ   		    : out  STD_LOGIC;
		   oGuideTxB   		    : out  STD_LOGIC;
		   iGuideTxD   		    : in  STD_LOGIC;		   
		   ---------- main and backup signal: High enable ---------
		   iZSig			    : in  STD_LOGIC;
		   iBSig                : in  STD_LOGIC;
		   ---------- RS422 enable signals ---------
		   oTxENH				: out  STD_LOGIC;
		   oTxENL				: out  STD_LOGIC;
		   oRxENH				: out  STD_LOGIC;
		   oRxENL				: out  STD_LOGIC
		   
		   );
end ZBCTRL;

architecture Behavioral of ZBCTRL is

	signal s3_ZSigReg			: STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
	signal s3_BSigReg			: STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
	signal s2_delay				: STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
	-- main 422 enable or disable : High enable
	signal s_Zen				: STD_LOGIC := '0';
	-- output register
	signal s_JMRxD				: STD_LOGIC := '1';
	signal s_JMTxZ				: STD_LOGIC := '1';
	signal s_JMTxB				: STD_LOGIC := '1';
	signal s_GuideTxZ			: STD_LOGIC := '1';
	signal s_GuideTxB			: STD_LOGIC := '1';
begin
	---------------------------------------
	-- register ZSig and BSig
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			s3_ZSigReg <= (others => '0');
			s3_BSigReg <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(iTick = '1') then 
				s3_ZSigReg(2) <= s3_ZSigReg(1);
				s3_ZSigReg(1) <= s3_ZSigReg(0);
				s3_ZSigReg(0) <= iZSig;
				s3_BSigReg(2) <= s3_BSigReg(1);
				s3_BSigReg(1) <= s3_BSigReg(0);
				s3_BSigReg(0) <= iBSig;
			else
				s3_ZSigReg <= s3_ZSigReg;
				s3_BSigReg <= s3_BSigReg;
			end if;
		end if;
	end process;
	---------------------------------------
	-- main 422 enable control
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			-- disable the main 422
			s_Zen <= '0';
			-- delay decision of enable or disable main 422
			s2_delay <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			s2_delay(1)	<= s2_delay(0);
			s2_delay(0) <= '1';
			if(s2_delay(1) = '1') then
				if(s3_ZSigReg(2) = '0' and s3_ZSigReg(1) = '0'and 
					s3_BSigReg(2) = '1' and s3_BSigReg(1) = '1') then
					s_Zen <= '0';
				else
					s_Zen <= '1';
				end if;
			else
				s_Zen <= '0';
			end if;			
			if(s_Zen = '1') then
				oTxENH <= '1';
				oTxENL <= '0';
				oRxENH <= '1';
				oRxENL <= '0';
			else
				oTxENH <= '0';
				oTxENL <= '1';
				oRxENH <= '0';
				oRxENL <= '1';				
			end if;
		end if;
	end process;
	---------------------------------------
	-- connect control
	---------------------------------------
	
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			s_JMRxD <= '1';
			s_JMTxZ <= '1';
			s_JMTxB	<= '1';
			s_GuideTxZ <= '1';
			s_GuideTxB <= '1';
		elsif(iClk'event and iClk = '1') then
			if(s_Zen = '1') then
				s_JMRxD <= iJMRxZ;
				s_JMTxZ <= iJMTxD;
				s_JMTxB <= '1';
				s_GuideTxZ <= iGuideTxD;
				s_GuideTxB <= '1';							
			else
				s_JMRxD <= iJMRxB;
				s_JMTxZ <= '1';
				s_JMTxB <= iJMTxD;
				s_GuideTxZ <= '1';
				s_GuideTxB <= iGuideTxD;					
			end if;
		end if;
	end process;
	
	oJMRxD 		<= s_JMRxD;	
	oJMTxZ 		<= s_JMTxZ;
	oJMTxB 		<= s_JMTxB;
	oGuideTxZ	<= s_GuideTxZ;
	oGuideTxB 	<= s_GuideTxB;
	
	
end Behavioral;

