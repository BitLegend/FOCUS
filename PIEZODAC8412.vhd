----------------------------------------------------------------------------------
-- Company: 
-- Engineer:  Wang Peng
-- 
-- Create Date:    11:36:58 12/01/2016 
-- Design Name: 
-- Module Name:    DAC8412 - Behavioral 
-- Project Name:   X-EUV
-- Target Devices: 
-- Tool versions: 
-- Description: 
--				take about 2.1 us
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

entity PIEZO_DAC8412 is
    Port ( iRst              : in   STD_LOGIC;
           iClk              : in   STD_LOGIC;
		   ----------------- input data ---------------------------
           iDB_A             : in   STD_LOGIC_VECTOR (11 downto 0);
           iDB_B             : in   STD_LOGIC_VECTOR (11 downto 0);
           iDB_C             : in   STD_LOGIC_VECTOR (11 downto 0);
           iDB_D             : in   STD_LOGIC_VECTOR (11 downto 0);
           iWr               : in   STD_LOGIC;
		   ----------------- DAC8412 port ---------------------------
           oDA_DB            : out  STD_LOGIC_VECTOR (11 downto 0);
           oDA_A             : out  STD_LOGIC_VECTOR (1 downto 0);
           oDA_CS            : out  STD_LOGIC;
           oDA_LDAC          : out  STD_LOGIC);
end PIEZO_DAC8412;

architecture Behavioral of PIEZO_DAC8412 is
--******************************Signal Definition******************************
	Type STATE_FSM is (IDLE, WR_A, WRA_W, WRA_H, WRB_W, WRB_H, WRC_W, WRC_H,
					   WRD_W, LDA, LDT);
	signal pr_state, nx_state : STATE_FSM := IDLE;
	-- Register output signal
	signal s12_DB    : STD_LOGIC_VECTOR (11 downto 0) := X"800";
	-- Counters
	signal s3_hCnt   : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
	signal s5_wCnt   : STD_LOGIC_VECTOR (4 downto 0) := (others => '0');
--****************************END Signal Definition****************************
begin
	-- Combinational logic
	oDA_DB <= s12_DB;

--******************************Counter ***************************************
	-----------------------------
	-- CS high time counter
	-----------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s3_hCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(nx_state = WR_A or nx_state = WRA_H or nx_state = WRB_H or 
				nx_state = WRC_H) then
				s3_hCnt <= s3_hCnt + 1;
			else
				s3_hCnt <= (others => '0');
			end if;
		end if;
	end process;
	-----------------------------
	-- CS low and LDAC low time counter
	-----------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s5_wCnt <= (others => '0');
		elsif(iClk'event and iClk = '1') then
			if(nx_state = WRA_W or nx_state = WRB_W or nx_state = WRC_W or 
				nx_state = WRD_W or nx_state = LDA or nx_state = LDT) then
				s5_wCnt <= s5_wCnt + 1;
			else
				s5_wCnt <= (others => '0');
			end if;
		end if;
	end process;
--****************************END Counter *************************************

--*************************State Machine **************************************
	-----------------------------
	-- State register
	-----------------------------
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			pr_state <= IDLE;
		elsif(iClk'event and iClk = '1') then
			pr_state <= nx_state;
		end if;
	end process;
	-----------------------------
	-- Next state function
	-----------------------------
	process(pr_state, iWr, s3_hCnt, s5_wCnt)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(iWr = '1') then
					nx_state <= WR_A;
				else
					nx_state <= IDLE;
				end if;
			when WR_A =>
				if(s3_hCnt = B"100") then
					nx_state <= WRA_W;
				else
					nx_state <= WR_A;
				end if;
			when WRA_W =>
				if(s5_wCnt = B"01110") then
					nx_state <= WRA_H;
				else
					nx_state <= WRA_W;
				end if;		
			when WRA_H =>
				if(s3_hCnt = B"100") then
					nx_state <= WRB_W;
				else
					nx_state <= WRA_H;
				end if;
			when WRB_W =>
				if(s5_wCnt = B"01110") then
					nx_state <= WRB_H;
				else
					nx_state <= WRB_W;
				end if;		
			when WRB_H =>
				if(s3_hCnt = B"100") then
					nx_state <= WRC_W;
				else
					nx_state <= WRB_H;
				end if;
			when WRC_W =>
				if(s5_wCnt = B"01110") then
					nx_state <= WRC_H;
				else
					nx_state <= WRC_W;
				end if;		
			when WRC_H =>
				if(s3_hCnt = B"100") then
					nx_state <= WRD_W;
				else
					nx_state <= WRC_H;
				end if;
			when WRD_W =>
				if(s5_wCnt = B"00101") then
					nx_state <= LDA;
				else
					nx_state <= WRD_W;
				end if;				
			when LDA =>
				if(s5_wCnt = B"01110") then
					nx_state <= LDT;
				else
					nx_state <= LDA;
				end if;			
			when LDT =>
				if(s5_wCnt = B"10110") then
					nx_state <= IDLE;
				else
					nx_state <= LDT;
				end if;			
			when others =>
				nx_state <= IDLE;
		end case;
	end process;
	-----------------------------
	-- Output function
	-----------------------------
	process(iClk, iRst, pr_state)
	begin
		if(iRst = '1') then
			oDA_CS <= '1';
			oDA_LDAC <= '1';
			s12_DB <= X"800";
			oDA_A <= B"11";
		elsif(iClk'event and iClk = '1') then
			oDA_CS <= '1';
			oDA_LDAC <= '1';
			s12_DB <= s12_DB;
			oDA_A <= B"11";		
			case pr_state is 
				when IDLE =>				
				when WR_A =>
					s12_DB <= iDB_A;
					oDA_A <= B"00";		
					
				when WRA_W =>
					oDA_CS <= '0';
					s12_DB <= iDB_A;
					oDA_A <= B"00";		
					
				when WRA_H =>
					if(s3_hCnt = "001") then
						s12_DB <= iDB_A;
						oDA_A <= B"00";		
					else
						s12_DB <= iDB_B;
						oDA_A <= B"01";	
					end if;				
					
				when WRB_W =>
					oDA_CS <= '0';
					s12_DB <= iDB_B;
					oDA_A <= B"01";		
					
				when WRB_H =>
					if(s3_hCnt = "001") then
						s12_DB <= iDB_B;
						oDA_A <= B"01";		
					else
						s12_DB <= iDB_C;
						oDA_A <= B"10";	
					end if;			
					
				when WRC_W =>
					oDA_CS <= '0';
					s12_DB <= iDB_C;
					oDA_A <= B"10";		
					
				when WRC_H =>
					if(s3_hCnt = "001") then
						s12_DB <= iDB_C;
						oDA_A <= B"10";		
					else
						s12_DB <= iDB_D;
						oDA_A <= B"11";	
					end if;		

				when WRD_W =>
					oDA_CS <= '0';
					s12_DB <= iDB_D;

				when LDA =>
					oDA_CS <= '0';
					oDA_LDAC <= '0';
					s12_DB <= iDB_D;

				when LDT =>
					oDA_LDAC <= '0';
					s12_DB <= iDB_D;

				when others =>


			end case;
			
		end if;
	end process;
--*************************END State Machine **********************************
end Behavioral;

