----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:27:19 05/10/2017 
-- Design Name: 
-- Module Name:    CENTRAL_CTRL - Behavioral 
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

entity CENTRAL_CTRL is
    Port ( iRst 			: in  STD_LOGIC;
           iClk 			: in  STD_LOGIC;
		   iTick1s          : in  STD_LOGIC;
		   iTick2ms         : in  STD_LOGIC;
		   ---------- Command data ----------
           iDataVal 		: in  STD_LOGIC;
		   iCmd             : in  STD_LOGIC_VECTOR(7 downto 0);
		   ----------- command parameters -----------
		   iFocusPos        : in  STD_LOGIC_VECTOR (11 downto 0);
		   iParas           : in  a3of8;
		   iHeatMode        : in  a4of8;
		   iHeatSenSel      : in  a4of8;
		   iHeatDuty        : in  a4of8;
		   iHeatTarget      : in  a4of12;		   
		   ----------- CCD image state and channel -----------
		   iCCDVal	        : in STD_LOGIC;
		   iCCDState        : in STD_LOGIC_VECTOR(7 downto 0);
		   iCCDChan         : in STD_LOGIC_VECTOR(7 downto 0);
		   ----------- Piezo Driver temperature -----------
		   iPiezDrTemper	: in STD_LOGIC_VECTOR(11 downto 0);
		   ---------- Guide data ----------
		   iPiezoX          : in STD_LOGIC_VECTOR(11 downto 0);
		   iPiezoY          : in STD_LOGIC_VECTOR(11 downto 0);
		   ---------- Heat control ----------
		   oHeatMode        : out  a4of8;
		   oHeatSenSel      : out  a4of8;
		   oHeatDuty        : out  a4of8;
		   oHeatTarget      : out  a4of12;		
		   ---------- Relay control ---------
		   oSWF             : out  STD_LOGIC; -- High active
		   oSWO             : out  STD_LOGIC; -- High active
		   ---------- Piezo control ---------
		   -- bit0 for stabilization, bit1 for adjust focal plane
		   oEnStab       	: out  STD_LOGIC_VECTOR(1 downto 0); -- Is stabilization and adjust enabled
           -- bit0 for channel A, 0 : open-loop; 1 : close-loop		  
		   oClose       	: out  STD_LOGIC_VECTOR(2 downto 0); -- Is close loop controlled
		   oSetDataA     	: out  STD_LOGIC_VECTOR(11 downto 0); -- X direction	
		   oSetDataB     	: out  STD_LOGIC_VECTOR(11 downto 0); -- Y direction	
		   oSetDataC     	: out  STD_LOGIC_VECTOR(11 downto 0); -- Z direction	
		   ------------ state --------------
		   -- 111:Initial; 001:RDY;  010:ADJ; 011:STAB; 100:SELCLR; 101: SW and pre
		   oSt              : out  STD_LOGIC_VECTOR(2 downto 0)
		   );
end CENTRAL_CTRL;

architecture Behavioral of CENTRAL_CTRL is
	-- State definition
	Type STATE_FSM is (INITIAL,RDY_PR,RDY,SELCLR_PR,SELCLR_SW,SELCLR,SELCLR_END,
						STAB,ADJ_PR,ADJ);
	signal pr_state, nx_state : STATE_FSM := INITIAL;
	
	-- signal definition
	-- output register
	
	signal s12_SetDataA     :  STD_LOGIC_VECTOR (11 downto 0) := c12_stbXPos;	
	signal s12_SetDataB     :  STD_LOGIC_VECTOR (11 downto 0) := c12_stbYPos;	
	signal s12_SetDataC     :  STD_LOGIC_VECTOR (11 downto 0) := c12_adjPos;
	signal s3_Close         :  STD_LOGIC_VECTOR(2 downto 0) := "111";
	signal s8_HeatMode      :  a4of8 := (c8_open, c8_open, c8_open, c8_open);
	signal s8_HeatSenSel    :  a4of8 := (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);
	signal s8_HeatDuty      :  a4of8 := ((others => '0'), (others => '0'), (others => '0'),
							 			(others => '0'));
	signal s12_HeatTarget   :  a4of12 := (c12_tmpNorTar, c12_tmpNorTar, c12_tmpClrTar,
										c12_tmpClrTar);	
	-- relay control
	signal s_Swf            :  STD_LOGIC := '0';
	signal s_Swo            :  STD_LOGIC := '0';
	-- piezo control
	signal s2_EnStab        :  STD_LOGIC_VECTOR (1 downto 0) := c2_stabEn;
	-- Self-stabilization control
	signal s_IsSelfImg      : STD_LOGIC := '1';
  signal s_IsSelfTemp      : STD_LOGIC := '1';
	-- switch counter
	signal i_SwCnt          :  integer range 0 to 100 := 0;
	-- state monitor
	signal s3_St            : STD_LOGIC_VECTOR(2 downto 0);
	-- FSM state definition
	constant c_Ini    		: STD_LOGIC_VECTOR(2 downto 0) := "111";
	constant c_Rdy   		: STD_LOGIC_VECTOR(2 downto 0) := "001";
	constant c_ADJ  		: STD_LOGIC_VECTOR(2 downto 0) := "010";
	constant c_STAB   		: STD_LOGIC_VECTOR(2 downto 0) := "011";
	constant c_SELCLR 		: STD_LOGIC_VECTOR(2 downto 0) := "100";
	constant c_SW     		: STD_LOGIC_VECTOR(2 downto 0) := "101";	
	

begin
	---------------------------------------
	-- Disable and enable piezo control
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s2_EnStab <= c2_stabEn;
		elsif(iClk'event and iClk = '1') then
			if(iDataVal = '1') then
				case iCmd is
					when c8_StabDis =>
						s2_EnStab(0) <= '0';
						s2_EnStab(1) <= s2_EnStab(1);
					when c8_AdjDis =>
						s2_EnStab(0) <= s2_EnStab(0);
						s2_EnStab(1) <= '0';
					when c8_StabEn =>
						s2_EnStab(0) <= '1';
						s2_EnStab(1) <= s2_EnStab(1);
					when c8_AdjEn =>
						s2_EnStab(0) <= s2_EnStab(0);
						s2_EnStab(1) <= '1';	
					when others =>
						s2_EnStab <= s2_EnStab;
				end case;
			else
				s2_EnStab <= s2_EnStab;
			end if;
		end if;
	end process;
	
	---------------------------------------
	-- counter to determine duration of switch mode 
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			i_SwCnt <= 0;
		elsif(iClk'event and iClk = '1') then
			if(pr_state = RDY_PR or pr_state = SELCLR_PR or pr_state = SELCLR_SW
				or pr_state = SELCLR_END or pr_state = ADJ_PR) then
				if(iTick2ms = '1') then
					i_SwCnt <= i_SwCnt + 1;
				else
					i_SwCnt <= i_SwCnt;
				end if;
			else
				i_SwCnt <= 0;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Output assign
	---------------------------------------	
	oHeatMode        <=  s8_HeatMode;
	oHeatSenSel      <=  s8_HeatSenSel;
	oHeatDuty        <=  s8_HeatDuty;
	oHeatTarget      <=  s12_HeatTarget;
	oSWF             <=  s_Swf;
	oSWO             <=  s_Swo;
	oEnStab       	 <=  s2_EnStab;
	oClose       	 <=  s3_Close;
	oSetDataA     	 <=  s12_SetDataA;
	oSetDataB     	 <=  s12_SetDataB;
	oSetDataC     	 <=  s12_SetDataC;
	oSt              <=  s3_St;
	
--=============================================================================
--  State Machine
--=============================================================================		
	---------------------------------------
	-- State register
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			pr_state <= INITIAL;
		elsif(iClk'event and iClk = '1') then
			pr_state <= nx_state;
		end if;
	end process;
	---------------------------------------
	-- Next state process
	---------------------------------------
	process(pr_state,iDataVal,iCmd,i_SwCnt)
	begin
		nx_state <= INITIAL;
		case pr_state is
			when INITIAL =>
				nx_state <= STAB;
			when RDY_PR =>
				if(i_SwCnt = 99) then 
					nx_state <= RDY;
				else
					nx_state <= RDY_PR;
				end if;
			when RDY =>
				if(iDataVal = '1') then
					case iCmd is
						when c8_SelfClrOp =>
							nx_state <= SELCLR_PR;
						when c8_AdjFocus =>
							nx_state <= ADJ_PR;
						when c8_Stablize =>
							nx_state <= STAB;
						when others =>
							nx_state <= RDY;	
					end case;
				else
					nx_state <= RDY;
				end if;				
			when SELCLR_PR =>
				if(i_SwCnt = 49) then 
					nx_state <= SELCLR_SW;
				else
					nx_state <= SELCLR_PR;
				end if;
			when SELCLR_SW =>
				if(i_SwCnt = 99) then 
					nx_state <= SELCLR;
				else
					nx_state <= SELCLR_SW;
				end if;
			-- can only transfer to wait state		
			when SELCLR =>
				if(iDataVal = '1') then
					case iCmd is
						when c8_SelfClrCl | c8_Wait =>
							nx_state <= SELCLR_END;
						-- when c8_AdjFocus =>
							-- nx_state <= ADJ_PR;
						-- when c8_Stablize =>
							-- nx_state <= STAB;
						when others =>
							nx_state <= SELCLR;	
					end case;
				else
					nx_state <= SELCLR;
				end if;					
			when SELCLR_END =>
				if(i_SwCnt = 49) then 
					nx_state <= RDY_PR;
				else
					nx_state <= SELCLR_END;
				end if;
			when ADJ_PR =>
				if(i_SwCnt = 49) then 
					nx_state <= ADJ;
				else
					nx_state <= ADJ_PR;
				end if;
			when ADJ =>
				if(iDataVal = '1') then
					case iCmd is
						when c8_Wait =>
							nx_state <= RDY;
						when c8_Stablize =>
							nx_state <= STAB;
						when others =>
							nx_state <= ADJ;	
					end case;
				else
					nx_state <= ADJ;
				end if;								
			when STAB =>
				if(iDataVal = '1') then
					case iCmd is
						when c8_Wait =>
							nx_state <= RDY;
						when c8_AdjFocus =>
							nx_state <= ADJ_PR;
						when others =>
							nx_state <= STAB;	
					end case;
				else
					nx_state <= STAB;
				end if;						
			
			when others =>
				nx_state <= INITIAL;
		end case;
	end process;
	---------------------------------------
	-- Output process
	---------------------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s3_St <= (others => '0');
			s12_SetDataA <= c12_stbXPos;
			s12_SetDataB <= c12_stbYPos;
			s12_SetDataC <= c12_adjPos;
			s3_Close <= (others => '1');
			s8_HeatMode <= (c8_open, c8_open, c8_open, c8_open);
			s8_HeatSenSel <= (c4_sensor1, c4_sensor1, c4_sensor1,c4_sensor1);
			s8_HeatDuty <= ((others => '0'), (others => '0'), (others => '0'),
							 			(others => '0'));
			s12_HeatTarget <= (c12_tmpNorTar, c12_tmpNorTar, c12_tmpClrTar,
										c12_tmpClrTar);	
			s_Swf <= '0';
			s_Swo <= '0';
			s_IsSelfImg <= '1';
      s_IsSelfTemp <= '1';
		elsif(iClk'event and iClk = '1') then
			s12_SetDataA <= s12_SetDataA;
			s12_SetDataB <= s12_SetDataB;
			s12_SetDataC <= s12_SetDataC;
			s3_Close <= s3_Close;
			s_IsSelfImg <= s_IsSelfImg;
      s_IsSelfTemp <= s_IsSelfTemp;
			s8_HeatMode <= s8_HeatMode;
			s8_HeatSenSel <= iHeatSenSel;
			s8_HeatDuty <= s8_HeatDuty;
			s12_HeatTarget <= iHeatTarget;	
			s_Swf <= '0';
			s_Swo <= '0';	
			s3_St <= "000";			
			case pr_state is 
				when INITIAL =>
					s3_St <= c_Ini;
					s8_HeatMode <= (c8_open, c8_open, c8_open, c8_open);
					s8_HeatDuty <= ((others => '0'), (others => '0'), (others => '0'),
							 			(others => '0'));						
				when RDY_PR =>
					s3_St <= c_SW;
					-- make sure relay position 
					s_Swf <= '1';
				when RDY =>
					s3_St <= c_Rdy;
					s8_HeatMode(0 to 1) <= iHeatMode(0 to 1);
					s8_HeatMode(2 to 3) <= (c8_open,c8_open);					
					s8_HeatDuty(0 to 1) <= iHeatDuty(0 to 1);
					s8_HeatDuty(2 to 3) <= (X"00", X"00");	
					s12_SetDataA <= c12_stbXPos;
					s12_SetDataB <= c12_stbYPos;					
				when SELCLR_PR =>	
					s3_St <= c_SW;				
					s8_HeatMode <= (c8_open, c8_open, c8_open, c8_open);
					s8_HeatDuty <= ((others => '0'), (others => '0'), (others => '0'),
							 			(others => '0'));
				when SELCLR_SW =>
					s3_St <= c_SW;	
					s_Swo <= '1';
				when SELCLR =>
					s3_St <= c_SELCLR;
					s8_HeatMode(2 to 3) <= iHeatMode(2 to 3);
					s8_HeatMode(0 to 1) <= (c8_open,c8_open);					
					s8_HeatDuty(2 to 3) <= iHeatDuty(2 to 3);
					s8_HeatDuty(0 to 1) <= (X"00", X"00");					
				when SELCLR_END =>
					s3_St <= c_SW;	
					s8_HeatMode <= (c8_open, c8_open, c8_open, c8_open);
					s8_HeatDuty <= ((others => '0'), (others => '0'), (others => '0'),
							 			(others => '0'));
				when ADJ_PR =>	
					s3_St <= c_SW;					
				when ADJ =>
				
					s8_HeatMode(0 to 1) <= iHeatMode(0 to 1);
					s8_HeatMode(2 to 3) <= (c8_open,c8_open);					
					s8_HeatDuty(0 to 1) <= iHeatDuty(0 to 1);
					s8_HeatDuty(2 to 3) <= (X"00", X"00");	
					s3_St <= c_ADJ;
					s12_SetDataC <= iFocusPos;
					if(iParas(1)(3 downto 0) = c4_PiezOpen) then
						s3_Close(2) <= '0';
					elsif(iParas(1)(3 downto 0) = c4_PiezClose) then
						s3_Close(2) <= '1';
					else
						s3_Close(2) <= s3_Close(2);
					end if;
					s3_Close(1 downto 0) <= s3_Close(1 downto 0);
				when STAB =>
					s3_St <= c_STAB;
					s8_HeatMode(0 to 1) <= iHeatMode(0 to 1);
					s8_HeatMode(2 to 3) <= (c8_open,c8_open);					
					s8_HeatDuty(0 to 1) <= iHeatDuty(0 to 1);
					s8_HeatDuty(2 to 3) <= (X"00", X"00");		
					if(s_IsSelfTemp = '1') then
						if(iPiezDrTemper < c12_PiDrTemUP) then
							s12_SetDataA <= s12_SetDataA;
							s12_SetDataB <= s12_SetDataB;	
						else
              if(s_IsSelfImg = '1') then
							  s12_SetDataA <= iPiezoX;
							  s12_SetDataB <= iPiezoY;
							  case iCCDState is
								  when c8_Imging =>
									  s12_SetDataA <= iPiezoX;
									  s12_SetDataB <= iPiezoY;									
								  when c8_ImgStop =>
									  s12_SetDataA <= s12_SetDataA;
									  s12_SetDataB <= s12_SetDataB;	
								  when others =>
							  end case;
              else
                s12_SetDataA <= iPiezoX;
							  s12_SetDataB <= iPiezoY; 
              end if;
						end if;
					else						
             if(s_IsSelfImg = '1') then
							  s12_SetDataA <= iPiezoX;
							  s12_SetDataB <= iPiezoY;
							  case iCCDState is
								  when c8_Imging =>
									  s12_SetDataA <= iPiezoX;
									  s12_SetDataB <= iPiezoY;									
								  when c8_ImgStop =>
									  s12_SetDataA <= s12_SetDataA;
									  s12_SetDataB <= s12_SetDataB;	
								  when others =>
							  end case;
              else
                s12_SetDataA <= iPiezoX;
							  s12_SetDataB <= iPiezoY; 
              end if;					
					end if;
					-- set self control or not 						
         	s_IsSelfImg <= s_IsSelfImg;
          s_IsSelfTemp <= s_IsSelfTemp;
          case iParas(2) is
            when c8_TempImg =>
              s_IsSelfImg   <= '1';
              s_IsSelfTemp  <= '1';
            when c8_TempnImgn =>
              s_IsSelfImg   <= '0';
              s_IsSelfTemp  <= '0';
            when c8_TempImgn =>
              s_IsSelfImg   <= '0';
              s_IsSelfTemp  <= '1';
            when c8_TempnImg =>
              s_IsSelfImg   <= '1';
              s_IsSelfTemp  <= '0';
            when others =>

          end case;

 
					-- set piezo open and close control
					if(iParas(0)(3 downto 0) = c4_PiezOpen) then
						s3_Close(0) <= '0';
					elsif(iParas(0)(3 downto 0) = c4_PiezClose) then
						s3_Close(0) <= '1';
					else
						s3_Close(0) <= s3_Close(0);
					end if;
					if(iParas(0)(7 downto 4) = c4_PiezOpen) then
						s3_Close(1) <= '0';
					elsif(iParas(0)(7 downto 4) = c4_PiezClose) then
						s3_Close(1) <= '1';
					else
						s3_Close(1) <= s3_Close(1);
					end if;
	
					s3_Close(2) <= s3_Close(2);					
				when others =>		
					
			end case;
		end if;
	end process;	









end Behavioral;

