----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:04:42 12/21/2016 
-- Design Name: 
-- Module Name:    AD677DATA - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity AD677DATA is
    Port ( iRst     : in  STD_LOGIC;
           iClk     : in  STD_LOGIC;
		   iSmp     : in  STD_LOGIC;
           iSCLK    : in  STD_LOGIC;
           iSDATA   : in  STD_LOGIC;
		   oSt      : out STD_LOGIC;
		   oErrNum  : out STD_LOGIC_VECTOR(3 downto 0);
           oDataReady : out  STD_LOGIC;
           oData    : out  STD_LOGIC_VECTOR (15 downto 0));
end AD677DATA;

architecture Behavioral of AD677DATA is
--******************************Signal Definition******************************
	-- State definition
	Type STATE_FSM is (IDLE, SMP, DOUT, ERROR);
	signal pr_state, nx_state : STATE_FSM := IDLE;
	-- Register inputs
	signal s3_sclk_reg   : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
	signal s2_data_reg   : STD_LOGIC_VECTOR (1 downto 0) := (others => '0');
	-- Register output
	signal s16_OData_reg : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
	signal s_oSt_reg     : STD_LOGIC := '0';
	signal s4_errNum     : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	-- Counter
	signal s5_dataCnt    : STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
	signal s11_erCnt     : STD_LOGIC_VECTOR (10 downto 0) := (others => '0');
begin
	---------------------------------------
	-- Double flip-flop input signals
	---------------------------------------
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			s3_sclk_reg <= (others => '0');
			s2_data_reg <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			s3_sclk_reg <= s3_sclk_reg(1 downto 0) & iSCLK;
			s2_data_reg <= s2_data_reg(0) & iSDATA;
		end if;
	end process;
	---------------------------------------
	-- Count number of data
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s5_dataCnt <= (others => '0');
			s11_erCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(pr_state = SMP) then
				s11_erCnt <= s11_erCnt + 1;
				if(s3_sclk_reg(2) = '0' AND s3_sclk_reg(1) = '1') then
				   s5_dataCnt <= s5_dataCnt + 1;
				else
				   s5_dataCnt <= s5_dataCnt;
				end if;
			else
				s11_erCnt <= (others => '0');
				s5_dataCnt <= (others => '0');
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
	process(pr_state, iSmp, s5_dataCnt, s11_erCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iSmp = '1') then
					nx_state <= SMP;
				else
					nx_state <= IDLE;
				end if;
			when SMP =>
				if(s5_dataCnt = B"1_0000") then
					nx_state <= DOUT;
				elsif(s11_erCnt = B"100_0000_0000") then -- 1024clk /900clk最小
					nx_state <= ERROR;
				else
					nx_state <= SMP;
				end if;
			when DOUT =>
				nx_state <= IDLE;
			when ERROR =>
				nx_state <= IDLE;
		end case;
	end process;
	---------------------------------------
	-- Output function
	---------------------------------------
	oData <= s16_OData_reg;
	oSt <= s_oSt_reg;
	oErrNum <= s4_errNum;
	process(iRst, iClk, pr_state)
	begin
		if(iRst = '1') then
			oDataReady <= '0';
			s16_OData_reg <= (others => '0');
			s_oSt_reg <= '0';
			s4_errNum <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			oDataReady <= '0';
			s16_OData_reg <= s16_OData_reg;
			s_oSt_reg <= s_oSt_reg;
			s4_errNum <= s4_errNum;
			case pr_state is
				when IDLE =>
				when SMP =>
					if(s3_sclk_reg(2) = '0' AND s3_sclk_reg(1) = '1') then
						s16_OData_reg <= s16_OData_reg(14 downto 0) & s2_data_reg(1);
					else 
						s16_OData_reg <= s16_OData_reg;
					end if;
				when DOUT =>
					oDataReady <= '1';
					s_oSt_reg <= '0';
				when ERROR =>
					s_oSt_reg <= '1';
					s4_errNum <= s4_errNum + 1;
				when others =>
			end case;
		end if;
	end process;

end Behavioral;

