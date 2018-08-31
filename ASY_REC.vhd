----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:59:47 12/24/2016 
-- Design Name: 
-- Module Name:    ASY_REC - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
-- 1 start bit + 8bits data + 1 odd check bit+ 1 stop bit
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

entity ASY_REC is
	GENERIC(
	--default value Baudrate:115200 , clock frequency:80M, oversampling:16
			-- Counter Width = log2(ClkFrequency/Baud)+10
			gAccWidth : integer := 20;--80M 115200
			-- Increment = Baud*OverSampling/ClkFrequency*2^accWidth
			gInc      : integer := 24159 -- OverSampling equals 1 for trans, 16 for rec
	);
    Port ( iRst       : in  STD_LOGIC;
           iClk       : in  STD_LOGIC;
           iRxD       : in  STD_LOGIC;
           oRxReady   : out  STD_LOGIC;
           oRxData    : out  STD_LOGIC_VECTOR (7 downto 0));
end ASY_REC;

architecture Behavioral of ASY_REC is
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

	signal s_Tick 			: STD_LOGIC := '0';
	-- Register outputs
	signal s8_RxData 		: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal s_RxReady 		: STD_LOGIC := '0';

	-- Counter valid data
	signal s4_DatCnt 		: STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	-- Input filter counter
	signal s3_FilCnt 		: STD_LOGIC_VECTOR(2 downto 0) := (others => '1');
	-- Sample time counter
	signal s4_SmpCnt 		: STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
	signal s_SmpNow 		: STD_LOGIC :=  '0';
	-- Input synchronize
	signal s2_RxD			: STD_LOGIC_VECTOR(1 downto 0) := (others => '1');
	-- filtered input
	signal s_RxDF 			: STD_LOGIC := '1';
begin
--*****************************COMPONENT Instance******************************
	BAUD_TICK_GEN_Inst: BAUD_TICK_GEN 
	GENERIC MAP(
	gAccWidth 	=> gAccWidth,
	gInc 		=> gInc
	)
	PORT MAP(
		iRst 	=> iRst,
		iClk	=> iClk,
		iEn 	=> '1',
		oTick 	=> s_Tick
	);
	---------------------------------------
	-- Synchronize input 
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s2_RxD <= (others => '1');
		elsif(iClk'event and iClk = '1') then
			if(s_Tick = '1') then
				s2_RxD <= s2_RxD(0) & iRxD;
			else
				s2_RxD <= s2_RxD;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Filter input 
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s3_FilCnt <= (others => '1');
			s_RxDF <= '1';
		elsif(iClk'event and iClk = '1') then
			if(s_Tick = '1') then
				if(s2_RxD(1) = '1' AND s3_FilCnt /= "111") then
					s3_FilCnt <= s3_FilCnt + 1;
				elsif(s2_RxD(1) = '0' AND s3_FilCnt /= "000") then
					s3_FilCnt <= s3_FilCnt - 1;
				else
					s3_FilCnt <= s3_FilCnt;
				end if;
				if(s3_FilCnt = "111") then
					s_RxDF <= '1';
				elsif(s3_FilCnt = "000") then
					s_RxDF <= '0';
				else
					s_RxDF <= s_RxDF;
				end if;
			else
				s_RxDF <= s_RxDF;
				s3_FilCnt <= s3_FilCnt;
			end if;
		end if;
	end process;

	---------------------------------------
	-- Sample time control
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s4_SmpCnt <= (others => '0');
			s4_DatCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(pr_state = IDLE) then
				s4_SmpCnt <= (others => '0');
			else
				if(s_Tick = '1') then
					s4_SmpCnt <= s4_SmpCnt + 1;
				else
					s4_SmpCnt <= s4_SmpCnt;
				end if;
			end if;
			if(pr_state = VADDATA) then 
				if(s_SmpNow = '1') then
					s4_DatCnt <= s4_DatCnt + 1;
				else 
					s4_DatCnt <= s4_DatCnt;
				end if;
			else
				s4_DatCnt <= (others => '0');
			end if;
		end if;
	end process;
	s_SmpNow <= '1' when (s_Tick = '1') AND (s4_SmpCnt = "0111") else '0';


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
	process(pr_state, s_Tick, s_SmpNow, s_RxDF, s4_DatCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(s_RxDF = '0') then
					nx_state <= START;
				else
					nx_state <= IDLE;
				end if;
			when START =>
				if(s_SmpNow = '1') then
					nx_state <= VADDATA;
				else
					nx_state <= START;
				end if;
			when VADDATA =>
				if(s4_DatCnt = B"1000") then
					nx_state <= STOP;
				else
					nx_state <= VADDATA;
				end if;
			when STOP =>
				if(s_SmpNow = '1') then
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
			s_RxReady <= '0';
			s8_RxData <= (others => '0');
		elsif(iClk'event and iClk = '1') then	
			s_RxReady <= '0';	
			s8_RxData <= s8_RxData;
			case pr_state is
				when IDLE =>
				when START =>
				when VADDATA =>
					if(s_SmpNow = '1') then
						s8_RxData <= s_RxDF & s8_RxData(7 downto 1);
					else 
						s8_RxData <= s8_RxData;
					end if;
				when STOP =>
					if(s_SmpNow = '1' AND s_RxDF = '1') then
						s_RxReady <= '1';
					else
						s_RxReady <= '0';
					end if;
				when others =>

			end case;
		end if;
	end process;
	oRxReady <= s_RxReady;
	oRxData <= s8_RxData;
end Behavioral;
