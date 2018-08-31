----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:10:48 12/22/2016 
-- Design Name: 
-- Module Name:    ASY_TRANS - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- 				1 start bit + 8bits data + 1 stop bit
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

entity ASY_TRANS is
	GENERIC(
	--default value Baudrate:115200 , clock frequency:40M, oversampling:1
			-- Counter Width = log2(ClkFrequency/Baud)+10 or larger
			gAccWidth : integer := 19;--40M 115200
			-- Increment = Baud*OverSampling/ClkFrequency*2^accWidth
			gInc      : integer := 1510 -- OverSampling equals 1 for trans, 16 for rec
	);
    Port ( iRst       : in  STD_LOGIC;
           iClk       : in  STD_LOGIC;
           iStart     : in  STD_LOGIC;
           iData      : in  STD_LOGIC_VECTOR (7 downto 0);
           oTxD       : out  STD_LOGIC;
           oBusy      : out  STD_LOGIC);
end ASY_TRANS;

architecture Behavioral of ASY_TRANS is
--****************************COMPONENT Declaration****************************
	COMPONENT BAUD_TICK_GEN
	GENERIC(gAccWidth : integer;
			gInc      : integer);
	PORT(
		iRst : IN std_logic;
		iClk : IN std_logic;
		iEn  : IN std_logic;          
		oTick : OUT std_logic
		);
	END COMPONENT;
--******************************Signal Definition******************************
-- State definition
Type STATE_FSM is (IDLE, START, VADDATA, STOP);
signal pr_state, nx_state : STATE_FSM := IDLE;

-- Register outputs
signal s_txD  : STD_LOGIC := '1';
signal s_tick : STD_LOGIC := '0';
signal s_busy : STD_LOGIC := '0';
-- Register input
signal s8_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
-- Parity bit
signal s_parity : STD_LOGIC := '0';
-- Counter valid data
signal s3_datCnt : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
begin
--*****************************COMPONENT Instance******************************
	BAUD_TICK_GEN_Inst: BAUD_TICK_GEN 
	GENERIC MAP(
	gAccWidth => gAccWidth,
	gInc => gInc
	)
	PORT MAP(
		iRst => iRst,
		iClk => iClk,
		iEn => s_busy,
		oTick => s_tick
	);
---------------------------------------
-- Combinational logic
---------------------------------------
oTxD <= s_txD;
oBusy <= s_busy;

s_busy <= '0' when pr_state = IDLE else 
         '1';
---------------------------------------
-- Register input data 
-- Count valid data
---------------------------------------
process(iRst, iClk)
begin
	if(iRst = '1') then
		s8_data <= (others => '0');
		s3_datCnt <= (others => '0');
	elsif(iClk'event and iClk = '1') then
		if(iStart = '1' AND s_busy = '0') then
			s8_data <= iData;
			s3_datCnt <= (others => '0');
		elsif((pr_state = VADDATA) and s_tick = '1') then
			s8_data <= '0'&s8_data(7 downto 1);
			s3_datCnt <= s3_datCnt + 1;
		else
			s8_data <= s8_data;
			s3_datCnt <= s3_datCnt;
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
process(pr_state, iStart, s_tick, s3_datCnt)
begin
	nx_state <= IDLE;
	case pr_state is
		when IDLE =>
			if(iStart = '1') then
				nx_state <= START;
			else
				nx_state <= IDLE;
			end if;
		when START =>
			if(s_tick = '1') then
				nx_state <= VADDATA;
			else
				nx_state <= START;
			end if;
		when VADDATA =>
			if(s_tick = '1' and s3_datCnt = B"111") then
				nx_state <= STOP;
			else
				nx_state <= VADDATA;
			end if;
		when STOP =>
			if(s_tick = '1') then
				nx_state <= IDLE;
			else
				nx_state <= STOP;
			end if;			
		when others =>
	end case;
end process;
---------------------------------------
-- Output function
---------------------------------------
process(iRst, iClk)
begin
	if(iRst = '1') then
		s_txD <= '1';
	elsif(iClk'event and iClk = '1') then	
		s_txD <= '1';
		case pr_state is
			when IDLE =>
				s_txD <= '1';
			when START =>
				s_txD <= '0';
			when VADDATA =>
				s_txD <= s8_data(0);
			when STOP =>
				s_txD <= '1';
			when others =>
				s_txD <= '1';
		end case;
	end if;
end process;
end Behavioral;

