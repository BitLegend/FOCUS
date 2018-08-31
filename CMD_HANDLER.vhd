----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:41:00 04/28/2017 
-- Design Name: 
-- Module Name:    CMD_HANDLER - Behavioral 
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
library work;
use work.mytypes.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CMD_HANDLER is
    Port ( iRst 			: in  STD_LOGIC;
           iClk 			: in  STD_LOGIC;
		   -- 1ms tick
		   iTick            : in  STD_LOGIC;
           ----------- RS422 data -----------
		   iRxRdy 			: in  STD_LOGIC;
           iData 			: in  STD_LOGIC_VECTOR (7 downto 0);
		   ----------- command signal -----------
		   oCmd             : out STD_LOGIC_VECTOR(7 downto 0);
		   ----------- command parameters -----------
		   oFocusPos        : out  STD_LOGIC_VECTOR (11 downto 0);
		   oParas           : out  a3of8;
		   oScaleParas      : out  a8of16;
       oOffParas        : out  a2of16;
		   oCtrlParas       : out  a3of16;
		   oHeatMode        : out  a4of8;
		   oHeatSenSel      : out  a4of8;
		   oHeatDuty        : out  a4of8;
		   oHeatTarget      : out  a4of12;
		   ----------- output parameters -----------
		   oDataVal         : out STD_LOGIC;
		   oReturn          : out STD_LOGIC;
		   -- reference to MyTypes.vhd : RS422 state 
		   oState           : out STD_LOGIC_VECTOR(7 downto 0));
end CMD_HANDLER;

architecture Behavioral of CMD_HANDLER is

--=============================================================================
--  Signal definition
--=============================================================================	
	-- State definition
	Type STATE_FSM is (IDLE, JUDGE, CMD, DATA2, DATA6, DATA19, DATA4, DATA12, 
	    CHECK, INVALIDCMD, CHECKERR, OVERTIME, VALOUT);
	signal pr_state, nx_state : STATE_FSM := IDLE;

	--command signal
	signal s8_Cmd	        :  STD_LOGIC_VECTOR(7 downto 0) := (others =>'0');

	--output parameters
	signal s12_FocusPos     :  STD_LOGIC_VECTOR (11 downto 0) := (others =>'0');
	signal s8_Paras         :  a3of8 := (c4_PiezClose&c4_PiezClose, c4_PiezClose&c4_PiezClose, c8_TempImg);
	signal s16_ScaleParas   :  a8of16 := (c16_PiezoUpX,c16_PiezoDwX,c16_PiezoUpY,c16_PiezoDwY,c16_ScaleEUVX,c16_ScaleXX,c16_ScaleEUVY,c16_ScaleXY);
														
  signal s16_OffParas     :  a2of16 := (c16_offsetX,c16_offsetY); 
	signal s16_CtrlParas    :  a3of16 := (c_ParaXI,c_ParaYI,c_ParaZI);
	
	signal s8_HeatMode      :  a4of8 := (c8_close, c8_open, c8_close, c8_open);
	signal s8_HeatSenSel    :  a4of8 := (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);
	signal s8_HeatDuty      :  a4of8 := (c4_SelfHeat&X"0", c4_SelfHeat&X"0", c4_SelfHeat&X"0",
							 			c4_SelfHeat&X"0");
	signal s12_HeatTarget   :  a4of12 := (c12_tmpNorTar, c12_tmpNorTar, c12_tmpClrTar,
										c12_tmpClrTar);

	--command signal 
	signal s8_CmdReg        :  STD_LOGIC_VECTOR(7 downto 0) := (others =>'0');
	--output parameters
	signal s12_FocusPosReg  :  STD_LOGIC_VECTOR (11 downto 0) := (others =>'0');
	signal s8_HeatParas     :  a12of8 := ( (others => '0'),  (others => '0'),  (others => '0'),  (others => '0'),
									c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1,
									 (others => '0'), (others => '0'), (others => '0'),(others => '0'));
	signal s8_ParasReg      :  a19of8 := (c4_PiezClose&c4_PiezClose, c4_PiezClose&c4_PiezClose, c8_TempImg,c16_PiezoUpX(15 downto 8),
														c16_PiezoUpX(7 downto 0),c16_PiezoDwX(15 downto 8),c16_PiezoDwX(7 downto 0),c16_PiezoUpY(15 downto 8),
														c16_PiezoUpY(7 downto 0),c16_PiezoDwY(15 downto 8),c16_PiezoDwY(7 downto 0),c16_ScaleEUVX(15 downto 8),
														c16_ScaleEUVX(7 downto 0),c16_ScaleXX(15 downto 8),c16_ScaleXX(7 downto 0),c16_ScaleEUVY(15 downto 8),
														c16_ScaleEUVY(7 downto 0),c16_ScaleXY(15 downto 8),c16_ScaleXY(7 downto 0));
  signal s8_OffParasReg   :  a4of8 := (c16_offsetX(15 downto 8),c16_offsetX(7 downto 0),c16_offsetY(15 downto 8),c16_offsetY(7 downto 0));                          
  signal s8_CtrlParasReg  :  a6of8 := (c_ParaXI(15 downto 8),c_ParaXI(7 downto 0),
								c_ParaYI(15 downto 8),c_ParaYI(7 downto 0),c_ParaZI(15 downto 8),c_ParaZI(7 downto 0));
	signal s8_Check         :  STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	-- output register
	signal s8_State         :  STD_LOGIC_VECTOR(7 downto 0) := (others => '0');	
	signal s_DataVal        :  STD_LOGIC := '0';
	signal s_Return         :  STD_LOGIC := '0';
	-- Overtime counter
	signal i_OverCnt        : integer range 0 to 80001 := 0;
	signal s_Overtime       : STD_LOGIC := '0';
	
	-- Data counter
	signal i_DataCnt        : integer range 0 to 23 := 0;
	
begin

	---------------------------------------
	-- Data counter
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			i_DataCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = DATA2 or pr_state = DATA4 or pr_state = DATA19 or pr_state = DATA12 or pr_state = DATA6) then
				if(iRxRdy = '1') then
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
	-- Overtime counter
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			i_OverCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = IDLE) then
				i_OverCnt <= 0;
			else			
				if(iRxRdy = '1') then
					i_OverCnt <= 0;
				else
					i_OverCnt <= i_OverCnt + 1;
				end if;
			end if;
		end if;
	end process;
	-- Generate overtime signal
	s_Overtime <= '1' when i_OverCnt = 80000 else
				'0';

	---------------------------------------
	-- Output register assign
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s8_Cmd <= X"00";
			s12_FocusPos     <= (others =>'0');
			s8_Paras         <= (c4_PiezClose&c4_PiezClose, c4_PiezClose&c4_PiezClose, c8_TempImg);
			s16_ScaleParas   <= (c16_PiezoUpX,c16_PiezoDwX,c16_PiezoUpY,c16_PiezoDwY,c16_ScaleEUVX,
								c16_ScaleXX,c16_ScaleEUVY,c16_ScaleXY);		
      s16_OffParas     <= (c16_offsetX,c16_offsetY); 
			s8_HeatMode      <= (c8_close, c8_open, c8_close, c8_open);			
			s8_HeatSenSel    <= (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);			
			s8_HeatDuty      <= (c4_SelfHeat&X"0", c4_SelfHeat&X"0", c4_SelfHeat&X"0",
							 	c4_SelfHeat&X"0");		
			s12_HeatTarget   <= (c12_tmpNorTar, c12_tmpNorTar, c12_tmpClrTar,
										c12_tmpClrTar);	
			oDataVal         <= '0';	
			oReturn          <= '0';			
		elsif(iClk'event and iClk = '1') then
			if(s_DataVal = '1' ) then 
				oDataVal         <= '1';
				s8_Cmd			 <= s8_CmdReg;
				s12_FocusPos     <= s12_FocusPosReg;
				s8_Paras         <= a3of8(s8_ParasReg(0 to 2));
				s16_ScaleParas(0) <= s8_ParasReg(3)&s8_ParasReg(4);
				s16_ScaleParas(1) <= s8_ParasReg(5)&s8_ParasReg(6);
				s16_ScaleParas(2) <= s8_ParasReg(7)&s8_ParasReg(8);
				s16_ScaleParas(3) <= s8_ParasReg(9)&s8_ParasReg(10);
				s16_ScaleParas(4) <= s8_ParasReg(11)&s8_ParasReg(12);
				s16_ScaleParas(5) <= s8_ParasReg(13)&s8_ParasReg(14);
				s16_ScaleParas(6) <= s8_ParasReg(15)&s8_ParasReg(16);
				s16_ScaleParas(7) <= s8_ParasReg(17)&s8_ParasReg(18);
				s16_OffParas(0)   <= s8_OffParasReg(0)&s8_OffParasReg(1);
        s16_OffParas(1)   <= s8_OffParasReg(2)&s8_OffParasReg(3);
        
        s16_CtrlParas(0) <= s8_CtrlParasReg(0)&s8_CtrlParasReg(1);
				s16_CtrlParas(1) <= s8_CtrlParasReg(2)&s8_CtrlParasReg(3);
				s16_CtrlParas(2) <= s8_CtrlParasReg(4)&s8_CtrlParasReg(5);
				
				s8_HeatMode      <= a4of8(s8_HeatParas(0 to 3));
				s8_HeatSenSel    <= a4of8(s8_HeatParas(4 to 7));
				-- CCD zhu
				if(s8_HeatParas(0)= c8_close) then
					s8_HeatDuty(0) <= s8_HeatDuty(0);
					s12_HeatTarget(0)   <= s8_HeatParas(8)&"0000";
				elsif(s8_HeatParas(0)= c8_open) then
					s8_HeatDuty(0) <= s8_HeatParas(8);
					s12_HeatTarget(0)  <= s12_HeatTarget(0);
				else
					s8_HeatDuty(0) <= s8_HeatDuty(0);
					s12_HeatTarget(0)  <= s12_HeatTarget(0);
				end if;
				-- CCD bei
				if(s8_HeatParas(1)= c8_close) then
					s8_HeatDuty(1) <= s8_HeatDuty(1);
					s12_HeatTarget(1)   <= s8_HeatParas(9)&"0000";
				elsif(s8_HeatParas(1)= c8_open) then
					s8_HeatDuty(1) <= s8_HeatParas(9);
					s12_HeatTarget(1)  <= s12_HeatTarget(1);
				else
					s8_HeatDuty(1) <= s8_HeatDuty(1);
					s12_HeatTarget(1)  <= s12_HeatTarget(1);
				end if;		
				-- CCD self clear zhu
				if(s8_HeatParas(2)= c8_close) then
					s8_HeatDuty(2) <= s8_HeatDuty(2);
					s12_HeatTarget(2)   <= s8_HeatParas(10)&"0000";
				elsif(s8_HeatParas(2)= c8_open) then
					s8_HeatDuty(2) <= s8_HeatParas(10);
					s12_HeatTarget(2)  <= s12_HeatTarget(2);
				else
					s8_HeatDuty(2) <= s8_HeatDuty(2);
					s12_HeatTarget(2)  <= s12_HeatTarget(2);
				end if;		

				-- CCD self clear bei
				if(s8_HeatParas(3)= c8_close) then
					s8_HeatDuty(3) <= s8_HeatDuty(3);
					s12_HeatTarget(3)   <= s8_HeatParas(11)&"0000";
				elsif(s8_HeatParas(3)= c8_open) then
					s8_HeatDuty(3) <= s8_HeatParas(11);
					s12_HeatTarget(3)  <= s12_HeatTarget(3);
				else
					s8_HeatDuty(3) <= s8_HeatDuty(3);
					s12_HeatTarget(3)  <= s12_HeatTarget(3);
				end if;		
			else
				oDataVal         <= '0';
				s8_Cmd           <= s8_Cmd;
				s12_FocusPos     <= s12_FocusPos;
				s8_Paras         <= s8_Paras;
				s16_ScaleParas   <= s16_ScaleParas;
        s16_OffParas     <= s16_OffParas;
				s16_CtrlParas    <= s16_CtrlParas;
				s8_HeatMode      <= s8_HeatMode;
				s8_HeatSenSel    <= s8_HeatSenSel;
				s8_HeatDuty      <= s8_HeatDuty;
				s12_HeatTarget   <= s12_HeatTarget;				
				
			end if;
			if(s_Return = '1') then
				oReturn          <= '1';
			else
				oReturn          <= '0';
			end if;
		end if;
	end process;
	---------------------------------------
	-- Output assign
	---------------------------------------			
	oCmd          <= s8_Cmd; 
	----------- 
	oFocusPos     <= s12_FocusPos;
	oParas        <= s8_Paras;
	oScaleParas   <= s16_ScaleParas;
  oOffParas     <= s16_OffParas;
	oCtrlParas    <= s16_CtrlParas;
	oHeatMode     <= s8_HeatMode;
	oHeatSenSel   <= s8_HeatSenSel;
	oHeatDuty     <= s8_HeatDuty;
	oHeatTarget   <= s12_HeatTarget;
	-----------   
	oState        <= s8_State;
				
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
	process(pr_state, iRxRdy,iData,s_Overtime,i_DataCnt,s8_Check)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iRxRdy = '1' and iData = X"7E") then
					nx_state <= JUDGE;
				else
					nx_state <= IDLE;
				end if;
			when JUDGE =>
				if(iRxRdy = '1' and iData = X"7E") then
					nx_state <= CMD;
				elsif(iRxRdy = '1' and iData /= X"7E") then
					nx_state <= IDLE;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= JUDGE;
				end if;
			when CMD =>
				if(iRxRdy = '1') then
					case iData is
						when c8_RePara | c8_SelfClrOp | c8_SelfClrCl | c8_Wait |
							 c8_Stablize | c8_StabDis | c8_AdjDis | c8_StabEn |
							 c8_AdjEn =>
							nx_state <= CHECK;
						when c8_AdjFocus =>
							nx_state <= DATA2;
						when c8_ParaSet =>
							nx_state <= DATA19;
						when c8_OffParaSet =>
							nx_state <= DATA4;
            when c8_HeatParaSet =>
							nx_state <= DATA12;
						when c8_CtrParaSet =>
							nx_state <= DATA6;
						when others =>
							nx_state <= INVALIDCMD;
					end case;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;				
				else 
					nx_state <= CMD;
				end if;
			when INVALIDCMD =>
				nx_state <= IDLE;
			when CHECK =>
				if(iRxRdy = '1' and s8_Check = iData) then
					nx_state <= VALOUT;
				elsif(iRxRdy = '1' and s8_Check /= iData) then	
					nx_state <= CHECKERR;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= CHECK;
				end if;
			when CHECKERR =>
				nx_state <= IDLE;
			when DATA2 =>
				if(i_DataCnt = 2) then
					nx_state <= CHECK;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= DATA2;
				end if;
			when DATA19 =>
				if(i_DataCnt = 19) then
					nx_state <= CHECK;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= DATA19;
				end if;	
      when DATA4 =>
				if(i_DataCnt = 4) then
					nx_state <= CHECK;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= DATA4;
				end if;		  
			when DATA12 =>
				if(i_DataCnt = 12) then
					nx_state <= CHECK;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= DATA12;
				end if;				
			when DATA6 =>
				if(i_DataCnt = 6) then
					nx_state <= CHECK;
				elsif(s_Overtime = '1') then
					nx_state <= OVERTIME;
				else
					nx_state <= DATA6;
				end if;						
			when VALOUT =>
				nx_state <= IDLE;
			when OVERTIME =>
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
			s_Return <= '0';
			s_DataVal <= '0';
			s8_Check <= X"00";
			s8_State <= X"00";
			s8_CmdReg <= X"00";     
			s12_FocusPosReg <= (others =>'0');		
			s8_ParasReg     <= (c4_PiezClose&c4_PiezClose, c4_PiezClose&c4_PiezClose, c8_TempImg,c16_PiezoUpX(15 downto 8),
														c16_PiezoUpX(7 downto 0),c16_PiezoDwX(15 downto 8),c16_PiezoDwX(7 downto 0),c16_PiezoUpY(15 downto 8),
														c16_PiezoUpY(7 downto 0),c16_PiezoDwY(15 downto 8),c16_PiezoDwY(7 downto 0),c16_ScaleEUVX(15 downto 8),
														c16_ScaleEUVX(7 downto 0),c16_ScaleXX(15 downto 8),c16_ScaleXX(7 downto 0),c16_ScaleEUVY(15 downto 8),
														c16_ScaleEUVY(7 downto 0),c16_ScaleXY(15 downto 8),c16_ScaleXY(7 downto 0));
      s8_OffParasReg   <=  (c16_offsetX(15 downto 8),c16_offsetX(7 downto 0),c16_offsetY(15 downto 8),c16_offsetY(7 downto 0));     
			s8_HeatParas <= (c8_close, c8_open, c8_close, c8_open,
							c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1,
							c12_tmpNorTar(11 downto 4), (others => '0'),c12_tmpClrTar(11 downto 4),(others => '0'));
      s8_CtrlParasReg <= (c_ParaXI(15 downto 8),c_ParaXI(7 downto 0),
								c_ParaYI(15 downto 8),c_ParaYI(7 downto 0),c_ParaZI(15 downto 8),c_ParaZI(7 downto 0));     
		elsif(iClk'event and iClk = '1') then
			
			s_Return <= '0';
			s_DataVal <= '0';
			s8_Check <= s8_Check;
			s8_State <= s8_State;
			s8_CmdReg <= s8_CmdReg;     
			s12_FocusPosReg <= s12_FocusPosReg;		
			s8_ParasReg <= s8_ParasReg;	
			s8_HeatParas  <= s8_HeatParas;			
	  	s8_OffParasReg	<= s8_OffParasReg;
      s8_CtrlParasReg <= s8_CtrlParasReg;
			case pr_state is 
				when IDLE  | JUDGE =>
				when CMD =>
					if(iRxRdy = '1') then
						s8_CmdReg <= iData;
						s8_Check <= iData;
					else
						s8_CmdReg <= s8_CmdReg;
					end if;
				when INVALIDCMD =>
					s8_State <= c8_ivalidCmd;
					s_Return <= '1';
				when CHECK =>
				when CHECKERR =>
					s8_State <= c8_checkErr;
					s_Return <= '1';	
				when DATA2 =>
					if(iRxRdy = '1') then
						s8_Check <= s8_Check XOR iData;
						if(i_DataCnt = 0) then
							s12_FocusPosReg(11 downto 8) <= iData(3 downto 0);
						elsif(i_DataCnt = 1) then
							s12_FocusPosReg(7 downto 0) <= iData;
						else
							s12_FocusPosReg <= s12_FocusPosReg;
						end if;
					else
						s12_FocusPosReg <= s12_FocusPosReg;
						s8_Check <= s8_Check;
					end if;
				when DATA19 =>
					if(iRxRdy = '1') then
						s8_Check <= s8_Check XOR iData;
						s8_ParasReg(i_DataCnt) <= iData;						
					else
						s8_ParasReg <= s8_ParasReg;
						s8_Check <= s8_Check;
					end if;
        when DATA4 =>
					if(iRxRdy = '1') then
						s8_Check <= s8_Check XOR iData;
						s8_OffParasReg(i_DataCnt) <= iData;						
					else
						s8_OffParasReg <= s8_OffParasReg;
						s8_Check <= s8_Check;
					end if;
				when DATA12 =>
					if(iRxRdy = '1') then
						s8_Check <= s8_Check XOR iData;
						s8_HeatParas(i_DataCnt) <= iData;	
					else
						s8_HeatParas <= s8_HeatParas;
						s8_Check <= s8_Check;
					end if;
				when DATA6 =>
					if(iRxRdy = '1') then
						s8_Check <= s8_Check XOR iData;
						s8_CtrlParasReg(i_DataCnt) <= iData;						
					else
						s8_CtrlParasReg <= s8_CtrlParasReg;
						s8_Check <= s8_Check;
					end if;				
				when VALOUT =>
					s8_State <= X"00";
					s_Return <= '1';	
					s_DataVal <= '1';		
				when OVERTIME =>
					s8_State <= c8_overtime;
					s_Return <= '1';						
				when others =>					
			end case;
		end if;
	end process;	
	
end Behavioral;

