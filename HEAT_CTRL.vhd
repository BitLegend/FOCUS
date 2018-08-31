----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:49:51 04/07/2017 
-- Design Name: 
-- Module Name:    HEAT_CTRL - Behavioral 
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
use IEEE.STD_LOGIC_SIGNED.ALL;

library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity HEAT_CTRL is
    Port ( 
		iRst 				: in  STD_LOGIC;
		iClk 				: in  STD_LOGIC;
		iTick1S             : in  STD_LOGIC;
		iTick40ms			: in  STD_LOGIC;
		--------------- Control mode select -----------
		iMode 				: in  a4of8;
		--------------- Sensor select ----------------
		iSenSel				: in  a4of8;
		--------------- Temperature target --------------
		iTarget 			: in  a4of12;
		--------------- Duty -------------------------
		iDuty 				: in  a4of8;
		--------------- Measured temperature ------------
		iMes1 				: in  STD_LOGIC_VECTOR (11 downto 0);
		iMes2 				: in  STD_LOGIC_VECTOR (11 downto 0);
		--------------- RKSt ------------
		iRkSt               : IN std_logic_vector(3 downto 0);    
		--------------- Heat time monitor ---------------
		oHeatTime           : out a4of8;
		--------------- Output control ------------------
		oCtrl0				: out STD_LOGIC;
		oCtrl1				: out STD_LOGIC;
		oCtrl2				: out STD_LOGIC;
		oCtrl3				: out STD_LOGIC
		);
end HEAT_CTRL;

architecture Behavioral of HEAT_CTRL is


	TYPE a4ofus8 IS ARRAY(0 to 3) OF UNSIGNED(7 downto 0);
	TYPE a4ofus9 IS ARRAY(0 to 3) OF UNSIGNED(8 downto 0);
--=============================================================================
--  Signal definition
--=============================================================================		
	signal us4_clsCnt       : UNSIGNED(3 downto 0) := (others => '1');
	signal us8_PeriodCnt   : UNSIGNED(7 downto 0) := (others => '1');
	
	signal s_clsTick         : STD_LOGIC := '0';
	signal s_clsTick_reg     : STD_LOGIC := '0';
	signal s_clsTick_reg1    : STD_LOGIC := '0';
	
	signal us4_opCnt        : UNSIGNED(3 downto 0) := (others => '0');

	-- 60s counter
--	signal i_time60Cnt      : integer range 0 to 59 := 0;
--	signal s_60sTick        : STD_LOGIC := '0';
	signal s_Tick1s_dly     : STD_LOGIC := '0';	
	
	
	signal s12_Mes1         : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_Mes2         : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_Mes1_reg     : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
	signal s12_Mes2_reg     : STD_LOGIC_VECTOR(11 downto 0) := (others => '0');
		
	signal s13_NewMinOld1   : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	signal s13_NewMinOld2   : STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
	
	signal s13_Target       : a4of13 := ((others => '0'), (others => '0'), (others => '0'),
										(others => '0'));

	signal s13_TarMinMes    : a4of13 := ((others => '0'), (others => '0'), (others => '0'),
										(others => '0'));
		
	signal s12_MesVal       : a4of12 := ((others => '0'), (others => '0'), (others => '0'),
										(others => '0'));
	signal s13_NewMinOld    : a4of13 := ((others => '0'), (others => '0'), (others => '0'),
										(others => '0'));
	
	signal us9_clsHeatTime  : a4ofus9 := ((others => '0'), (others => '0'), (others => '0'),
										 (others => '0'));
	
	-- register heating mode and open loop duty 
	signal s8_mode          : a4of8 := (c8_close, c8_open, c8_open, c8_open);
	signal s4_duty          : a4of4 := ((others => '0'), (others => '0'), (others => '0'),
										(others => '0'));
	signal s4_selfheat      : a4of4 := (c4_SelfHeat, c4_SelfHeat, c4_SelfHeat, c4_SelfHeat);	
	-- heating time in 60s
	signal us8_heatTimeCnt  : a4ofus8 := ((others => '0'), (others => '0'), (others => '0'),
										 (others => '0'));
	signal s8_heatTimeReg   : a4of8   := ((others => '0'), (others => '0'), (others => '0'),
										 (others => '0'));
	-- output control
	signal s4_clsCtrl       : STD_LOGIC_VECTOR (3 downto 0) := (others => '1');
	signal s4_opCtrl        : STD_LOGIC_VECTOR (3 downto 0) := (others => '1');	
	signal s4_oCtrl         : STD_LOGIC_VECTOR (3 downto 0) := (others => '1');	

	constant c12_thrUp      : STD_LOGIC_VECTOR(11 downto 0) := X"fae"; --4.9V 约70摄氏度
	constant c12_thrLow     : STD_LOGIC_VECTOR(11 downto 0) := X"07a"; --0.15V 约-80摄氏度
	-- constant parameters :must less than c13_thrHTmp
	constant c13_thrHCmp    : STD_LOGIC_VECTOR(12 downto 0) := B"0_0000_0000_0100";
	constant c13_thrLCmp    : STD_LOGIC_VECTOR(12 downto 0) := B"1_1111_1111_1100";
	-- control temperature changing rate
	-- the allowed temperature change in 10s
	constant c13_thrHTmp    : STD_LOGIC_VECTOR(12 downto 0) := B"0_0000_0000_1000";
	constant c13_thrLTmp    : STD_LOGIC_VECTOR(12 downto 0) := B"1_1111_1111_1000";
begin
	---------------------------------------
	-- Generate close loop tick  16s
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iTick1S = '1') then
				us4_clsCnt <= us4_clsCnt + 1;
			else
				us4_clsCnt <= us4_clsCnt;
			end if;
			
			if(iTick1S = '1' and us4_clsCnt = conv_unsigned(15,4)) then
				s_clsTick <= '1';
			else 
				s_clsTick <= '0';
			end if;
			s_clsTick_reg <= s_clsTick;
			s_clsTick_reg1 <= s_clsTick_reg;
		end if;
	end process;

	---------------------------------------
	-- close-loop control period 
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iTick40ms = '1') then
				us8_PeriodCnt <= us8_PeriodCnt + 1;
			else
				us8_PeriodCnt <= us8_PeriodCnt;
			end if;
		end if;
	end process;	
	
	---------------------------------------
	-- Generate 10s tick  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iTick1S = '1') then
				if(us4_opCnt = conv_unsigned(9,4)) then
					us4_opCnt <= (others => '0');
				else
					us4_opCnt <= us4_opCnt + 1;
				end if;
			else
				us4_opCnt <= us4_opCnt;
			end if;
			
		end if;
	end process;

	---------------------------------------
	-- Register temperature  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iTick1S = '1' and us4_clsCnt = conv_unsigned(15,4)) then
				s12_Mes1 <= iMes1;
				s12_Mes2 <= iMes2;
				s12_Mes1_reg <= s12_Mes1;
				s12_Mes2_reg <= s12_Mes2;								
			else
				s12_Mes1 <= s12_Mes1;
				s12_Mes2 <= s12_Mes2;
				s12_Mes1_reg <= s12_Mes1_reg;
				s12_Mes2_reg <= s12_Mes2_reg;	
			end if;			
		end if;
	end process;
	
	---------------------------------------
	-- stop heating when temperature is out of scope
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s8_mode <= (c8_close, c8_open, c8_open, c8_open);
			s4_duty <= ((others => '0'), (others => '0'), (others => '0'),
							(others => '0'));
		elsif(iClk'event and iClk = '1') then
			for i in 0 to 3 loop			
				if(s4_selfheat(i) = c4_SelfHeat) then
						if(EXT(s12_MesVal(i),13) < EXT(c12_thrLow,13) OR
							EXT(s12_MesVal(i),13) > EXT(c12_thrUp,13)) then
							s8_mode(i) <= c8_open;
							s4_duty(i) <= (others => '0');
						else
							s8_mode(i) <= iMode(i);
							s4_duty(i) <= iDuty(i)(3 downto 0);
						end if;
				elsif(s4_selfheat(i) = c4_CenHeat) then
					s8_mode(i) <= iMode(i);
					s4_duty(i) <= iDuty(i)(3 downto 0);
				else
					s8_mode(i) <= c8_open;
					s4_duty(i) <= (others => '0');
				end if;
			end loop;			
		end if;
	end process;	
	---------------------------------------
	-- self stop heating or not
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s4_selfheat   <= (c4_SelfHeat, c4_SelfHeat, c4_SelfHeat, c4_SelfHeat);	
		elsif(iClk'event and iClk = '1') then
			for i in 0 to 3 loop		
				if(iDuty(i)(7 downto 4) = c4_SelfHeat) then
					s4_selfheat(i) <= c4_SelfHeat;
				elsif(iDuty(i)(7 downto 4) = c4_CenHeat) then
					s4_selfheat(i) <= c4_CenHeat;
				else
					s4_selfheat(i) <= s4_selfheat(i);
				end if;
			end loop;			
		end if;
	end process;		
		
	
	---------------------------------------
	-- Temperature changing direction 
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(s_clsTick = '1') then
				s13_NewMinOld1 <= EXT(s12_Mes1,13) - EXT(s12_Mes1_reg,13);
				s13_NewMinOld2 <= EXT(s12_Mes2,13) - EXT(s12_Mes2_reg,13);				
			else
				s13_NewMinOld1 <= s13_NewMinOld1;
				s13_NewMinOld2 <= s13_NewMinOld2;
			end if;			
		end if;
	end process;		
	---------------------------------------
	-- difference between target and measured value
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			for i in 0 to 3 loop
				if(s_clsTick_reg = '1') then
					s13_TarMinMes(i) <= s13_Target(i) - EXT(s12_MesVal(i),13);
				else
					s13_TarMinMes(i) <= s13_TarMinMes(i);
				end if;
			end loop;
		end if;
	end process;		
	
	
	---------------------------------------
	-- Select sensor  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk='1') then
			for i in 0 to 3 loop
				if(s_clsTick_reg = '1') then
					case iSenSel(i) is
						when c4_sensor1 =>
							s13_NewMinOld(i) <= s13_NewMinOld1; 
						when c4_sensor2 =>
							s13_NewMinOld(i) <= s13_NewMinOld2; 
						when others =>
							s13_NewMinOld(i) <= s13_NewMinOld(i); 						
					end case;
				end if;
				if(s_clsTick = '1') then
					case iSenSel(i) is
						when c4_sensor1 =>
							s12_MesVal(i) <= s12_Mes1;
						when c4_sensor2 =>
							s12_MesVal(i) <= s12_Mes2;
						when others =>
							s12_MesVal(i) <= s12_MesVal(i);						
					end case;
				end if;
			end loop;
		end if;
	end process;		
	
	---------------------------------------
	-- Calculate heating time
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk='1') then
			for i in 0 to 3 loop
				if(s_clsTick_reg1 = '1') then
				    -- reset the close-loop heating time to zero when open loop
					if(s8_mode(i) = c8_open) then
						us9_clsHeatTime(i) <= (others => '0');
					-- measured temperature less than target and temperature doesn't rise
					elsif(s13_TarMinMes(i) > c13_thrHCmp and 
					   s13_NewMinOld(i) <= '0'&X"000") then
						if(us9_clsHeatTime(i) = conv_unsigned(256,9)) then
							us9_clsHeatTime(i) <= us9_clsHeatTime(i);
						else
							us9_clsHeatTime(i) <= us9_clsHeatTime(i)+1;
						end if;
					-- measured temperature larger than or equal target and temperature doesn't fall
					elsif(s13_TarMinMes(i) <= c13_thrLCmp and 
					   s13_NewMinOld(i) >= '0'&X"000") then
						if(us9_clsHeatTime(i) = conv_unsigned(0,9)) then
							us9_clsHeatTime(i) <= us9_clsHeatTime(i);
						else
							us9_clsHeatTime(i) <= us9_clsHeatTime(i)-1;
						end if;		
					else
						us9_clsHeatTime(i) <= us9_clsHeatTime(i);
					end if;
				end if;
			end loop;
		end if;
	end process;			
	
	---------------------------------------
	-- Generate close-loop control signal
	---------------------------------------	
	process(us9_clsHeatTime,us8_PeriodCnt)
	begin
		for i in 0 to 3 loop
			if(us8_PeriodCnt < us9_clsHeatTime(i)) then 
				s4_clsCtrl(i) <= '0'; -- heat
			else 
				s4_clsCtrl(i) <= '1'; -- don't heat
			end if;
		end loop;
	end process;		
	
	---------------------------------------
	-- Generate open-loop control signal
	---------------------------------------	
	process(s4_duty,us4_opCnt)
	begin
		for i in 0 to 3 loop
			if('0'&conv_std_logic_vector(us4_opCnt,4) < '0'&s4_duty(i)) then 
				s4_opCtrl(i) <= '0'; 
			else 
				s4_opCtrl(i) <= '1'; 
			end if;
		end loop;
	end process;		
	
	---------------------------------------
	-- Select control
	---------------------------------------	
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			s4_oCtrl <= (others => '1');
		elsif(iClk'event and iClk = '1') then
			for i in 0 to 3 loop
				case s8_mode(i) is
					when c8_close =>
						s4_oCtrl(i) <= s4_clsCtrl(i);
					when c8_open =>
						s4_oCtrl(i) <= s4_opCtrl(i);
					when others =>
						s4_oCtrl(i) <= '1';
				end case;
			end loop;			
		end if;
	end process;		
	
	---------------------------------------
	-- Channel 3 and 4 cannot be heated at the same time
	---------------------------------------	
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			oCtrl0 <= '1';
			oCtrl1 <= '1';
			oCtrl2 <= '1';
			oCtrl3 <= '1';
		elsif(iClk'event and iClk = '1') then
			if(s4_oCtrl(2) = '0' and s4_oCtrl(3) = '0') then
				oCtrl0 <= s4_oCtrl(0);
				oCtrl1 <= s4_oCtrl(1);				
				oCtrl2 <= s4_oCtrl(2);
				oCtrl3 <= '1';
			else
				oCtrl0 <= s4_oCtrl(0);
				oCtrl1 <= s4_oCtrl(1);				
				oCtrl2 <= s4_oCtrl(2);
				oCtrl3 <= s4_oCtrl(3);
			end if;
		end if;
	end process;		
	
	
	---------------------------------------
	-- Target change rate 
	---------------------------------------
	process(iRst, iClk)
	begin
		if(iRst = '1') then
			s13_Target <= ((others => '0'), (others => '0'), (others => '0'),
						   (others => '0'));
		elsif(iClk'event and iClk = '1') then
			for i in 0 to 3 loop
				if(s8_mode(i) = c8_open) then
					s13_Target(i) <= EXT(s12_MesVal(i),13);
				elsif(iTick1S = '1' and us4_opCnt = conv_unsigned(9,4)) then
					if( (EXT(iTarget(i),13) - s13_Target(i)) > c13_thrHTmp ) then
						if(s13_Target(i) - EXT(s12_MesVal(i),13) > c13_thrHTmp) then
							s13_Target(i) <= s13_Target(i);
						else
							s13_Target(i) <= s13_Target(i) + c13_thrHTmp;
						end if;
					elsif( (EXT(iTarget(i),13) - s13_Target(i)) < c13_thrLTmp ) then
						if(s13_Target(i) - EXT(s12_MesVal(i),13) < c13_thrLTmp) then
							s13_Target(i) <= s13_Target(i);
						else
							s13_Target(i) <= s13_Target(i) + c13_thrLTmp;
						end if;					
					else
						s13_Target(i) <= '0'&iTarget(i);
					end if;
				else
					s13_Target(i) <= s13_Target(i);
				end if;
			end loop;
		end if;
	end process;			
	

	---------------------------------------
	-- 60s tick 
	---------------------------------------	
--	process(iRst,iClk)
--	begin
--		if(iRst = '1') then
--			i_time60Cnt <= 0;
--			s_60sTick <= '0';
--		elsif(iClk'event and iClk = '1') then
--			if(iTick1S = '1') then
--				if(i_time60Cnt = 59) then
--					s_60sTick <= '1';
--					i_time60Cnt <= 0;
--				else
--					s_60sTick <= '0';
--					i_time60Cnt <= i_time60Cnt + 1;
--				end if;				
--			else
--				s_60sTick <= '0';
--				i_time60Cnt <= i_time60Cnt;
--			end if;		
--		end if;
--	end process;	
	
	---------------------------------------
	-- Calculate heating time 
	---------------------------------------	
	process(iRst,iClk)
	begin
		if(iRst = '1') then
			us8_heatTimeCnt <= ((others => '0'), (others => '0'), 
				(others => '0'),(others => '0'));
			s8_heatTimeReg <= ((others => '0'), (others => '0'), 
				(others => '0'),(others => '0'));
		elsif(iClk'event and iClk = '1') then
			s_Tick1s_dly <= iTick1s;
			for i in 0 to 3 loop
			--	if(iTick1S = '1') then	
				if(iTick40ms = '1') then				
					if(iRkSt(i) = '0') then
						us8_heatTimeCnt(i) <= us8_heatTimeCnt(i) + 1;
					else
						us8_heatTimeCnt(i) <= us8_heatTimeCnt(i);
					end if;
					s8_heatTimeReg(i) <= s8_heatTimeReg(i);
			--	elsif(s_60sTick = '1') then
				elsif(s_Tick1s_dly = '1' and us4_opCnt = conv_unsigned(9,4)) then
					us8_heatTimeCnt(i) <= (others => '0');
					s8_heatTimeReg(i) <= conv_std_logic_vector(us8_heatTimeCnt(i),8);
				else
					us8_heatTimeCnt(i) <= us8_heatTimeCnt(i);
					s8_heatTimeReg(i) <= s8_heatTimeReg(i);
				end if;			
			end loop;			
		end if;
	end process;		
	oHeatTime <= s8_heatTimeReg;
	
end Behavioral;

