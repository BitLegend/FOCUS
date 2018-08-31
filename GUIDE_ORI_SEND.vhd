----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:17:38 05/09/2017 
-- Design Name: 
-- Module Name:    GUIDE_ORI_SEND - Behavioral 
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

entity GUIDE_ORI_SEND is
    Port ( iClk 	: in  STD_LOGIC;
           iRst 	: in  STD_LOGIC;
		   ---------- time tick 1ms  ---------
           iUpdate 	: in  STD_LOGIC;
		   ----- normalized data of guide telescope ---------
           iDataXP 	: in  STD_LOGIC_VECTOR (15 downto 0);
		   iDataXN 	: in  STD_LOGIC_VECTOR (15 downto 0);
           iDataYP 	: in  STD_LOGIC_VECTOR (15 downto 0);
		   iDataYN 	: in  STD_LOGIC_VECTOR (15 downto 0);
		   --------- ASY_TRANS interface ---------
           oTxD 	: out  STD_LOGIC);
end GUIDE_ORI_SEND;

architecture Behavioral of GUIDE_ORI_SEND is
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
	signal sre_dataPack	: a8of8 := ((others => '0'), (others => '0'), (others => '0'),
		(others => '0'),(others => '0'), (others => '0'), (others => '0'),
		(others => '0'));

	signal s8_check     : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
	signal s_busy       : STD_LOGIC := '0';
	signal s_busy_reg   : STD_LOGIC := '0';
	-- Transfer register
	signal s_send       : STD_LOGIC := '0';
	signal s8_data      : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	
	-- data counter
	signal i_dataCnt    : integer range 0 to 9 := 0;
	-- header counter
	signal i_headerCnt  : integer range 0 to 2 := 0;
begin

	---------------------------------------
	-- instantiate component
	---------------------------------------
	ASY_TRANS_Inst1: ASY_TRANS
	GENERIC MAP(
		gAccWidth => 19,
		gInc => 1638
	)
	PORT MAP (
		  iRst => iRst,
		  iClk => iClk,
		  iStart => s_send,
		  iData => s8_data,
		  oTxD => oTxD,
		  oBusy => s_busy
		);


	---------------------------------------
	-- Register input data
	---------------------------------------
	process(iRst,iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iUpdate = '1') then
				sre_dataPack(0) <= iDataXP(15 downto 8);
				sre_dataPack(1) <= iDataXP(7 downto 0);				
				sre_dataPack(2) <= iDataXN(15 downto 8);
				sre_dataPack(3) <= iDataXN(7 downto 0);
				sre_dataPack(4) <= iDataYP(15 downto 8);
				sre_dataPack(5) <= iDataYP(7 downto 0);				
				sre_dataPack(6) <= iDataYN(15 downto 8);
				sre_dataPack(7) <= iDataYN(7 downto 0);
			else
				sre_dataPack <= sre_dataPack;			
			end if;
			s_busy_reg <= s_busy;
		end if;
	end process;
	---------------------------------------
	-- Data counter
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			i_dataCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = DATA or pr_state = CHECK) then 
				if((s_busy = '1') and (s_busy_reg = '0')) then
					i_dataCnt <= i_dataCnt + 1;
				else
					i_dataCnt <= i_dataCnt;
				end if;
			else
				i_dataCnt <= 0;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Header counter
	---------------------------------------
	process(iClk,iRst)
	begin
		if(iRst = '1') then
			i_headerCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = HEADER) then 
				if((s_busy = '1') and (s_busy_reg = '0')) then
					i_headerCnt <= i_headerCnt + 1;
				else
					i_headerCnt <= i_headerCnt;
				end if;
			else
				i_headerCnt <= 0;
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
	process(pr_state,iUpdate,s_busy,s_busy_reg,i_dataCnt,i_headerCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iUpdate = '1' and s_busy = '0') then
					nx_state <= HEADER;
				else
					nx_state <= IDLE;
				end if;
			when HEADER =>
				if(i_headerCnt = 2) then
					nx_state <= DATA;
				else
					nx_state <= HEADER;
				end if;
			when DATA =>
				if((i_dataCnt = 7 and s_busy = '0')) then
					nx_state <= CHECK;
				else
					nx_state <= DATA;
				end if;
			when CHECK =>
				if(i_dataCnt = 9 and s_busy = '0') then
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
			s_send <= '0';
			s8_data <= (others => '0');
			s8_check <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			s_send <= '0';
			s8_data <= (others => '0');
			s8_check <= (others => '0');
			case pr_state is 
				when IDLE =>
					s8_data <= c8_synHeader;
				when HEADER =>
					s8_data <= c8_synHeader;
					if(s_busy = '0' and i_headerCnt /= 2) then
						s_send <= '1';
					else
						s_send <= '0';
					end if;
				when DATA =>
					s8_data <= sre_dataPack(i_dataCnt);
					if((s_busy = '0') and (s_busy_reg = '1')) then
						s_send <= '1';
						s8_check <= s8_check XOR s8_data;
					else
						s8_check <= s8_check;
						s_send <= '0';
					end if;
				when CHECK =>
					s8_check <= s8_check;
					s8_data <= s8_check;
					if((s_busy = '0') and (s_busy_reg = '1') and (i_dataCnt = 8)) then
						s_send <= '1';
					else
						s_send <= '0';
					end if;
					
				when others =>					
			end case;
		end if;
	end process;	

end Behavioral;

