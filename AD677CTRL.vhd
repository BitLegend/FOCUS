----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:50:32 12/07/2016 
-- Design Name: 
-- Module Name:    AD677CTRL - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--		sample time is about 17.8us
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity AD677CTRL is
    Port ( iRst          : in  STD_LOGIC;
           iClk          : in  STD_LOGIC;
           iAD677_Cal    : in  STD_LOGIC;
           iAD677_Smp    : in  STD_LOGIC;
           oAD677_Clk    : out  STD_LOGIC;
           oAD677_Cal    : out  STD_LOGIC;
           oAD677_Smp    : out  STD_LOGIC);
end AD677CTRL;

architecture Behavioral of AD677CTRL is
--******************************Signal Definition******************************
	Type STATE_FSM is (IDLE, CALH, CHT, CTH, CTL, SMP, SMPC, SCH, SCL);
	signal pr_state, nx_state : STATE_FSM := IDLE;
	-- Counters
	signal s8_hCnt : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal s6_clkPerCnt  : STD_LOGIC_VECTOR(5 downto 0) := (others => '0');
	signal s17_clkNumCnt  : STD_LOGIC_VECTOR(16 downto 0) := (others => '0');
	-- constant
	constant c6_halfClkNum  : STD_LOGIC_VECTOR(5 downto 0) := B"01_0000";
	constant c6_halfClkNumMin2  : STD_LOGIC_VECTOR(5 downto 0) := B"00_1110";
begin
--***************************  Counter ****************************************
	---------------------------------------
	-- time counter
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s8_hCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(nx_state = CALH or nx_state = CHT or nx_state = SMP 
			   or nx_state = SMPC) then
				s8_hCnt <= s8_hCnt + 1;
			else
				s8_hCnt <= (others => '0');
			end if;
		end if;
	end process;
	---------------------------------------
	-- Clock period counter (32clk)
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s6_clkPerCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(nx_state = CTH or nx_state = CTL or nx_state = SCH or
			   nx_state = SCL) then
				if(s6_clkPerCnt = c6_halfClkNum) then
					s6_clkPerCnt <= B"00_0001";
				else
					s6_clkPerCnt <= s6_clkPerCnt + 1;
				end if;
			else
				s6_clkPerCnt <= (others => '0');
			end if;
		end if;
	end process;

--*************************State Machine **************************************
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
	process(pr_state, iAD677_Smp, iAD677_Cal, s6_clkPerCnt, s17_clkNumCnt,s8_hCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iAD677_Cal = '1') then
					nx_state <= CALH;
				elsif(iAD677_Smp = '1') then
					nx_state <= SMP;
				else
					nx_state <= IDLE;
				end if;
			when CALH =>
				if(s8_hCnt = X"6") then
					nx_state <= CHT;
				else
					nx_state <= CALH;
				end if;
			when CHT =>
				if(s8_hCnt = X"C") then
					nx_state <= CTH;
				else
					nx_state <= CHT;
				end if;			
			when CTH =>
				if(s6_clkPerCnt = c6_halfClkNum) then
					nx_state <= CTL;
				else
					nx_state <= CTH;
				end if;
			when CTL =>
				if(s17_clkNumCnt = B"1_0100_1110_0001_1100") then--85532
					nx_state <= IDLE;
				elsif(s6_clkPerCnt = c6_halfClkNum) then
					nx_state <= CTH;
				else
					nx_state <= CTL;
				end if;		
			when SMP =>
				if(s8_hCnt = X"A8") then--168
					nx_state <= SMPC;
				else
					nx_state <= SMP;
				end if;		
			when SMPC =>
				if(s8_hCnt = X"AE") then--174
					nx_state <= SCH;
				else
					nx_state <= SMPC;
				end if;			
			when SCH =>
				if(s6_clkPerCnt = c6_halfClkNum) then
					nx_state <= SCL;
				else
					nx_state <= SCH;
				end if;
			when SCL =>
				if(s17_clkNumCnt = B"0_0000_0000_0001_0001") then--17
					nx_state <= IDLE;
				elsif(s6_clkPerCnt = c6_halfClkNum) then
					nx_state <= SCH;
				else
					nx_state <= SCL;
				end if;					
			when others =>
				nx_state <= IDLE;
		end case;
	end process;
	---------------------------------------
	-- Output function
	---------------------------------------
	process(iClk, iRst, pr_state)
	begin
		if(iRst = '1') then
			oAD677_Clk <= '0';
			oAD677_Cal <= '0';
			oAD677_Smp <= '0';
			s17_clkNumCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			oAD677_Clk <= '0';
			oAD677_Cal <= '0';
			oAD677_Smp <= '0';
			s17_clkNumCnt <= (others => '0');
			case pr_state is 
				when IDLE =>
				when CALH =>
					oAD677_Cal <= '1';
				when CHT =>
				when CTH =>
					oAD677_Clk <= '1';
					s17_clkNumCnt <= s17_clkNumCnt;
				when CTL =>
					if(s6_clkPerCnt = c6_halfClkNumMin2) then
						s17_clkNumCnt <= s17_clkNumCnt + 1;
					else
						s17_clkNumCnt <= s17_clkNumCnt;
					end if;
				when SMP =>
					oAD677_Smp <= '1';
				when SMPC =>
				when SCH =>
					oAD677_Clk <= '1';
					s17_clkNumCnt <= s17_clkNumCnt;
				when SCL =>
					if(s6_clkPerCnt = c6_halfClkNumMin2) then
						s17_clkNumCnt <= s17_clkNumCnt + 1;
					else
						s17_clkNumCnt <= s17_clkNumCnt;
					end if;
				when others =>
					
			end case;
		end if;
	end process;

end Behavioral;

