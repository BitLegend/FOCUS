----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:24:13 07/12/2017 
-- Design Name: 
-- Module Name:    IMG_STATE_PRO - Behavioral 
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

entity IMG_STATE_PRO is
    Port ( iRst 				: in  STD_LOGIC;
           iClk 				: in  STD_LOGIC;
           iCCDRxRdy 			: in  STD_LOGIC;
           iCCDRxData 			: in  STD_LOGIC_VECTOR (7 downto 0);
           oVal 				: out  STD_LOGIC;
           oState 				: out  STD_LOGIC_VECTOR (7 downto 0);
           oChan 				: out  STD_LOGIC_VECTOR (7 downto 0));
end IMG_STATE_PRO;

architecture Behavioral of IMG_STATE_PRO is

--=============================================================================
--  Signal definition
--=============================================================================	
	-- State definition
	Type STATE_FSM is (IDLE, JUDGE, DATA1, DATA2, CHECK, VALOUT);
	signal pr_state, nx_state : STATE_FSM := IDLE;

	--output register
	signal s8_State   		:  STD_LOGIC_VECTOR (7 downto 0) := (others =>'0'); -- image state parameters
	signal s8_Chan   		:  STD_LOGIC_VECTOR (7 downto 0) := c8_ChanX; -- image channel
	signal s_DataVal      	:  STD_LOGIC := '0';
	--output register
	signal s8_StateReg   	:  STD_LOGIC_VECTOR (7 downto 0) := (others =>'0'); -- image state parameters
	signal s8_ChanReg   	:  STD_LOGIC_VECTOR (7 downto 0) := c8_ChanX; -- image channel
	signal s_DataValReg   	:  STD_LOGIC := '0';
	-- check data
	signal s8_Check         :  STD_LOGIC_VECTOR(7 downto 0) := (others => '0');

	
begin


	---------------------------------------
	-- Output register assign
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s8_State     <= (others =>'0');
			s8_Chan      <= c8_ChanX;
			s_DataVal	 <= '0';		
		elsif(iClk'event and iClk = '1') then
			if(s_DataValReg = '1' ) then 
				s8_State		 <= s8_StateReg;
				s8_Chan    		 <= s8_ChanReg;
				s_DataVal	 	 <= '1';		
			else
				s8_State		 <= s8_State;
				s8_Chan    		 <= s8_Chan;
				s_DataVal	 	 <= '0';						
			end if;
		end if;
	end process;
	---------------------------------------
	-- Output assign
	---------------------------------------			
	oState          <= s8_State; 
	oChan		    <= s8_Chan;
	oVal       		<= s_DataVal;
				
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
	-- Next state function
	---------------------------------------
	process(pr_state, iCCDRxRdy, iCCDRxData, s8_Check)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iCCDRxRdy = '1' and iCCDRxData = X"7E") then
					nx_state <= JUDGE;
				else
					nx_state <= IDLE;
				end if;
			when JUDGE =>
				if(iCCDRxRdy = '1' and iCCDRxData = X"7E") then
					nx_state <= DATA1;
				elsif(iCCDRxRdy = '1' and iCCDRxData /= X"7E") then
					nx_state <= IDLE;
				else
					nx_state <= JUDGE;
				end if;
			when DATA1 =>
				if(iCCDRxRdy = '1') then
					nx_state <= DATA2;			
				else 
					nx_state <= DATA1;
				end if;
			when DATA2 =>
				if(iCCDRxRdy = '1') then
					nx_state <= CHECK;
				else
					nx_state <= DATA2;
				end if;
			when CHECK =>
				if(iCCDRxRdy = '1' and s8_Check = iCCDRxData) then
					nx_state <= VALOUT;
				elsif(iCCDRxRdy = '1' and s8_Check /= iCCDRxData) then	
					nx_state <= IDLE;
				else
					nx_state <= CHECK;
				end if;
			when VALOUT =>
				nx_state <= IDLE;
			when others =>
				nx_state <= IDLE;
		end case;
	end process;
	---------------------------------------
	-- Output function
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s_DataValReg <= '0';
			s8_StateReg  <= X"00";
			s8_ChanReg   <= c8_ChanX;		
		elsif(iClk'event and iClk = '1') then			
			s_DataValReg <= '0';
			s8_StateReg <= s8_StateReg;
			s8_ChanReg  <= s8_ChanReg;			
			case pr_state is 
				when IDLE  | JUDGE =>
				when DATA1 =>
					if(iCCDRxRdy = '1') then
						s8_StateReg <= iCCDRxData;
						s8_Check 	<= iCCDRxData;
					else
						s8_StateReg <= s8_StateReg;
						s8_Check 	<= s8_Check;
					end if;
				when DATA2 =>
					if(iCCDRxRdy = '1') then
						s8_Check	 <= s8_Check XOR iCCDRxData;
						s8_ChanReg 	 <= iCCDRxData;
					else
						s8_ChanReg  <= s8_ChanReg;
						s8_Check 	<= s8_Check;
					end if;
				when CHECK =>
					
				when VALOUT =>
					s_DataValReg <= '1';							
				when others =>					
			end case;
		end if;
	end process;	

end Behavioral;

