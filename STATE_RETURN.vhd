----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:58:17 05/04/2017 
-- Design Name: 
-- Module Name:    STATE_RETURN - Behavioral 
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
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity STATE_RETURN is
    Port ( iClk 		: in  STD_LOGIC;
           iRst 		: in  STD_LOGIC;
           iUpdate 		: in  STD_LOGIC;
			  
		   iCmd			: in  STD_LOGIC_VECTOR (7 downto 0);
           iPiezoX 		: in  STD_LOGIC_VECTOR (11 downto 0);
           iPiezoY 		: in  STD_LOGIC_VECTOR (11 downto 0);
           iPiezoZ 		: in  STD_LOGIC_VECTOR (11 downto 0);
		   iErrX		: in  STD_LOGIC_VECTOR (7 downto 0);
		   iErrY		: in  STD_LOGIC_VECTOR (7 downto 0);
		   ------------ Remote sense ------------
		   iSense		: in madDataOut;
		   ------------ Operating sate ----------
           iStabSt 		: in  STD_LOGIC_VECTOR (7 downto 0);
           iRkSt 		: in  STD_LOGIC_VECTOR (7 downto 0);
           iRS422St 	: in  STD_LOGIC_VECTOR (7 downto 0);
		   ------------- Heat time --------------
		   iHeatTime    : in  a4of8;
		   
		   --------- ASY_TRANS interface ---------
		   oTxD         : out STD_LOGIC);
end STATE_RETURN;

architecture Behavioral of STATE_RETURN is
	-- COMPONENT declaration
    COMPONENT ASY_TRANS
	GENERIC (gAccWidth  : integer;
			 gInc       : integer);
    PORT(
         iRst 			: IN  std_logic;
         iClk 			: IN  std_logic;
         iStart 		: IN  std_logic;
         iData 			: IN  std_logic_vector(7 downto 0);
         oTxD 			: OUT  std_logic;
         oBusy 			: OUT  std_logic
        );
    END COMPONENT;


	-- State definition
	Type STATE_FSM is (IDLE, HEADER, DATA, CHECK);
	signal pr_state, nx_state : STATE_FSM := IDLE;

	-- signal definition	
	signal sre_DataPack	: a29of8 := ((others => '0'), (others => '0'), (others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'),(others => '0'),(others => '0'),(others => '0'),(others => '0'),
		(others => '0'));

	signal s8_Check     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
	signal s_Busy       : STD_LOGIC := '0';
	signal s_Busy_reg   : STD_LOGIC := '0';
	-- Transfer register
	signal s_Send       : STD_LOGIC := '0';
	signal s8_Data      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
	-- data counter
	signal i_DataCnt    : integer range 0 to 30 := 0;
	-- header counter
	signal i_HeaderCnt  : integer range 0 to 2 := 0;
begin

	---------------------------------------
	-- instantiate component
	---------------------------------------
	ASY_TRANS_Inst0: ASY_TRANS
	GENERIC MAP(
		gAccWidth => 19,
		gInc => 1638
	)
	PORT MAP (
		  iRst => iRst,
		  iClk => iClk,
		  iStart => s_Send,
		  iData => s8_Data,
		  oTxD => oTxD,
		  oBusy => s_Busy
		);





	---------------------------------------
	-- Register input data
	---------------------------------------
	process(iRst,iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iUpdate = '1') then
				sre_DataPack(0) <= iCmd;
				sre_DataPack(1) <= "0000"&iPiezoX(11 downto 8);
				sre_DataPack(2) <= iPiezoX(7 downto 0);				
				sre_DataPack(3) <= "0000"&iPiezoY(11 downto 8);
				sre_DataPack(4) <= iPiezoY(7 downto 0);
				sre_DataPack(5) <= "0000"&iPiezoZ(11 downto 8);
				sre_DataPack(6) <= iPiezoZ(7 downto 0);
				
				sre_DataPack(7 ) <= iErrX;
				sre_DataPack(8 ) <= iErrY;
				sre_DataPack(9 ) <= iSense(8)(11 downto 4);
				sre_DataPack(10) <= iSense(9)(11 downto 4);
				sre_DataPack(11) <= iSense(10)(11 downto 4);
				sre_DataPack(12) <= iSense(11)(11 downto 4);
				sre_DataPack(13) <= iSense(12)(11 downto 4);
				sre_DataPack(14) <= iSense(13)(11 downto 4);
				sre_DataPack(15) <= iSense(7)(11 downto 4);
				sre_DataPack(16) <= iStabSt;
				sre_DataPack(17) <= iSense(0)(11 downto 4);
				sre_DataPack(18) <= iSense(1)(11 downto 4);
				sre_DataPack(19) <= iSense(2)(11 downto 4);
				sre_DataPack(20) <= iSense(3)(11 downto 4);
				sre_DataPack(21) <= iSense(4)(11 downto 4);
				sre_DataPack(22) <= iRkSt;
				sre_DataPack(23) <= iRS422St;		
				sre_DataPack(24) <= iHeatTime(0);		
				sre_DataPack(25) <= iHeatTime(1);	
				sre_DataPack(26) <= iHeatTime(2);	
				sre_DataPack(27) <= iHeatTime(3);	
				sre_DataPack(28) <= iSense(5)(11 downto 4);
				
			else
				sre_DataPack <= sre_DataPack;			
			end if;
			s_Busy_reg <= s_Busy;
		end if;
	end process;
	---------------------------------------
	-- Data counter
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			i_DataCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = DATA or pr_state = CHECK) then 
				if((s_Busy = '1') and (s_Busy_reg = '0')) then
					i_DataCnt <= i_DataCnt + 1;
				else
					i_DataCnt <= i_DataCnt;
				end if;
			else
				i_DataCnt <= 0;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Header counter
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			i_HeaderCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = HEADER) then 
				if((s_Busy = '1') and (s_Busy_reg = '0')) then
					i_HeaderCnt <= i_HeaderCnt + 1;
				else
					i_HeaderCnt <= i_HeaderCnt;
				end if;
			else
				i_HeaderCnt <= 0;
			end if;
		end if;
	end process;	
--=============================================================================
--  State Machine
--=============================================================================		
	---------------------------------------
	-- State register
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			pr_state <= IDLE;
		elsif(iClk'event and iClk = '1') then
			pr_state <= nx_state;
		end if;
	end process;
	---------------------------------------
	-- Next state process
	---------------------------------------
	process(pr_state,iUpdate,s_Busy,s_Busy_reg,i_DataCnt,i_HeaderCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iUpdate = '1' and s_Busy = '0') then
					nx_state <= HEADER;
				else
					nx_state <= IDLE;
				end if;
			when HEADER =>
				if(i_HeaderCnt = 2) then
					nx_state <= DATA;
				else
					nx_state <= HEADER;
				end if;
			when DATA =>
				if((i_DataCnt = 28 and s_Busy = '0')) then
					nx_state <= CHECK;
				else
					nx_state <= DATA;
				end if;
			when CHECK =>
				if(i_DataCnt = 30 and s_Busy = '0') then
					nx_state <= IDLE;
				else
					nx_state <= CHECK;
				end if;
			when others =>
				nx_state <= IDLE;
		end case;
	end process;
	---------------------------------------
	-- Output process
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s_Send <= '0';
			s8_Data <= (others => '0');
			s8_Check <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			s_Send <= '0';
			s8_Data <= (others => '0');
			s8_Check <= (others => '0');
			case pr_state is 
				when IDLE =>
					s8_Data <= c8_synHeader;
				when HEADER =>
					s8_Data <= c8_synHeader;
					if(s_Busy = '0' and i_HeaderCnt /= 2) then
						s_Send <= '1';
					else
						s_Send <= '0';
					end if;
				when DATA =>
					s8_Data <= sre_DataPack(i_DataCnt);
					if((s_Busy = '0') and (s_Busy_reg = '1')) then
						s_Send <= '1';
						s8_Check <= s8_Check XOR s8_Data;
					else
						s8_Check <= s8_Check;
						s_Send <= '0';
					end if;
				when CHECK =>
					s8_Check <= s8_Check;
					s8_Data <= s8_Check;
					if((s_Busy = '0') and (s_Busy_reg = '1') and (i_DataCnt = 29)) then
						s_Send <= '1';
					else
						s_Send <= '0';
					end if;
					
				when others =>					
			end case;
		end if;
	end process;	

end Behavioral;

