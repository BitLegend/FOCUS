----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Wang Peng
-- 
-- Create Date:    11:31:25 01/19/2017 
-- Design Name: 
-- Module Name:    SPI_MASTER - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--                  SPI主设备逻辑，适用于TLV2548
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SPI_MASTER is
	Generic (		
		N        : positive := 16;-- serial word length  		
		CPOL     : STD_LOGIC := '0';-- SPI mode set (polarity)                                          
		CPHA     : STD_LOGIC := '0';-- SPI mode set (phase)   
		-- SPI clock divisor, if assigned to 8 ,then for 80MHz iClk, result in 5MHz SCLK
		SPI_2X_CLK_DIV : positive := 8);                                       
    Port ( iClk                : in   STD_LOGIC;                                
           iRst                : in   STD_LOGIC;                                
		   ----------- SPI interface -----------                               
           oSpiSsel            : out  STD_LOGIC;-- Enable line                               
           oSpiSclk            : out  STD_LOGIC;-- SPI clock                               
           oSpiMOSI            : out  STD_LOGIC;-- Master data output                               
           iSpiMISO            : in   STD_LOGIC;-- Master data input                                
		   ---------- inner interface ----------                               
           iWr                 : in   STD_LOGIC;                                
           iData               : in   STD_LOGIC_VECTOR (N-1 downto 0);           
           oDataVal            : out  STD_LOGIC;                                
           oData               : out  STD_LOGIC_VECTOR (N-1 downto 0));          
end SPI_MASTER;                                                                
    
architecture Behavioral of SPI_MASTER is                                       
	-- state definition
	TYPE states is (IDLE, START, SEND_DATA, LAST_BIT, STOP);
	signal pr_state, nx_state : states := IDLE;	
	-- SPI core clock counter and tick
	signal i_clkCnt            : integer range SPI_2X_CLK_DIV-1 downto 0 := 0;
	signal s_spiTick           : STD_LOGIC := '0';	
	-- SPI core clock 
	signal s_coreClk           : STD_LOGIC := '0';-- SPI clock positive	
	signal s_coreClk_n         : STD_LOGIC := '1';-- SPI clock negative	
	signal s_coreCe            : STD_LOGIC := '0';-- SPI clock edge signal
	signal s_coreCe_n          : STD_LOGIC := '1';-- SPI clock edge signal
	-- SPI interface signal
	signal s_spiClk            : STD_LOGIC := CPOL;-- SPI interface output clock
	signal s_spiClk_reg        : STD_LOGIC := CPOL;-- SPI clock output register
	signal s_spiSsel_reg       : STD_LOGIC := '1';-- SPI enable register
	-- SPI data sample and update
	signal s_smpCe             : STD_LOGIC := '1';-- Sampling enable
	signal s_fsmCe             : STD_LOGIC := '1';-- FSM state jump enable
	-- SPI wren 
	signal s_wrEn              : STD_LOGIC := '0';
	signal s_wrAck             : STD_LOGIC := '0';
	-- SPI clock enable
	signal s_sclkCe            : STD_LOGIC := '0';
	signal s_sclkEna_reg       : STD_LOGIC := '0';
	-- Data register
	signal sN_di_reg           : STD_LOGIC_VECTOR (N-1 downto 0) := (others => '0');   
	signal s_miso_reg          : STD_LOGIC;-- register MISO
	signal sN_sh               : STD_LOGIC_VECTOR (N-1 downto 0) := (others => '0');-- Shifter for input and output data
	signal sN_do_reg           : STD_LOGIC_VECTOR (N-1 downto 0) := (others => '0'); 
	-- Data number counter
	signal i_dataCnt           : integer range N-1 downto 0 := 0;
begin                                                                          
--=============================================================================
--  Generate SPI clock
--=============================================================================
	---------------------------------------
	-- Generate 2X spi clock tick 
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(i_clkCnt = SPI_2X_CLK_DIV-1) then
				i_clkCnt <= 0;
				s_spiTick <= '1';
			else
				i_clkCnt <= i_clkCnt + 1;
				s_spiTick <= '0';
			end if;
		end if;
	end process;
	---------------------------------------
	-- Generate spi core clock and edge signal 
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(s_spiTick = '1') then
				-- Flip the clock signal
				s_coreClk <= s_coreClk_n;
				s_coreClk_n <= not s_coreClk_n;
				-- Update the edge signal at tick time
				s_coreCe <= s_coreClk_n;
				s_coreCe_n <= not s_coreClk_n;
			else
				s_coreCe <= '0';
				s_coreCe_n <= '0';
			end if;
		end if;
	end process;	
--=============================================================================
--  Generate selected output clock, sample and state jump signal
--=============================================================================
	-- Select SPI clock
	SpiClk_Cpol_0: if(CPOL = '0') generate
	begin
		s_spiClk <= s_coreClk;
	end generate;
	SpiClk_Cpol_1: if(CPOL = '1') generate
	begin
		s_spiClk <= s_coreClk_n;
	end generate;
	-- Select sample enable 
	Smp_Cpha_0: if(CPHA = '0') generate
	begin
		s_smpCe <= s_coreCe;
	end generate;
	Smp_Cpha_1: if(CPHA = '1') generate
	begin
		s_smpCe <= s_coreCe_n;
	end generate;	
	-- Select FSM clock enable
	Fsm_Cpha_0: if(CPHA = '0') generate
	begin
		s_fsmCe <= s_coreCe_n;
	end generate;
	Fsm_Cpha_1: if(CPHA = '1') generate
	begin
		s_fsmCe <= s_coreCe;
	end generate;		

	---------------------------------------
	-- Register input data  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iWr = '1') then
				sN_di_reg <= iData;
			else
				sN_di_reg <= sN_di_reg;
			end if;
		end if;
	end process;		
	---------------------------------------
	-- Register MISO data  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(s_smpCe = '1') then
				s_miso_reg <= iSpiMISO;
			else
				s_miso_reg <= s_miso_reg;
			end if;
		end if;
	end process;		
	---------------------------------------
	-- Wren control  
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(iWr = '1') then
				s_wrEn <= '1';
			elsif(s_wrAck = '1') then
				s_wrEn <= '0';
			else
				s_wrEn <= s_wrEn;
			end if;
		end if;
	end process;	
	---------------------------------------
	-- Shift and count data   
	---------------------------------------
	process(iClk)
	begin
		if(iClk'event and iClk = '1') then
			if(pr_state = START and s_wrEn = '1') then
				sN_sh <= sN_di_reg;
			elsif(pr_state = SEND_DATA and s_fsmCe = '1') then
				sN_sh(N-1 downto 1) <= sN_sh(N-2 downto 0);
				sN_sh(0) <= s_miso_reg;
			else
				sN_sh <= sN_sh;
			end if;
		end if;
		-- Count the number of data
		if(iClk'event and iClk = '1') then
			if(pr_state = SEND_DATA and s_fsmCe = '1') then
				i_dataCnt <= i_dataCnt + 1;
			elsif(pr_state /= SEND_DATA) then
				i_dataCnt <= 0;
			else
				i_dataCnt <= i_dataCnt;
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
			if(s_fsmCe = '1') then
				pr_state <= nx_state;
			end if;
		end if;
	end process;
	---------------------------------------
	-- Next state function
	---------------------------------------
	process(pr_state,i_dataCnt,s_wrEn)
	begin
		nx_state <= IDLE;
		case pr_state is
			when IDLE =>
				if(s_wrEn = '1') then
					nx_state <= START;
				else
					nx_state <= IDLE;
				end if;
			when START =>
				nx_state <= SEND_DATA;
			when SEND_DATA =>
				if(i_dataCnt = (N-2)) then 
					nx_state <= LAST_BIT;
				else
					nx_state <= SEND_DATA;
				end if;
			when LAST_BIT =>
				nx_state <= STOP;
			when STOP =>
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
			s_sclkEna_reg <= '0';
			s_spiSsel_reg <= '1';
			oSpiMOSI <= '0';
			sN_do_reg <= (others => '0');
			oDataVal <= '0';
			s_wrAck <= '0';
		elsif(iClk'event and iClk = '1') then
			s_sclkEna_reg <= '0';
			s_spiSsel_reg <= '1';
			oSpiMOSI <= sN_sh(N-1);
			sN_do_reg <= sN_do_reg;
			oDataVal <= '0';
			s_wrAck <= '0';
			case pr_state is 
				when IDLE =>
					s_sclkEna_reg <= '0';
					s_spiSsel_reg <= '1';
					sN_do_reg <= sN_do_reg;
					oDataVal <= '0';
				when START =>
					s_spiSsel_reg <= '0';
					if(s_fsmCe = '1') then
						s_wrAck <= '1';
					else
						s_wrAck <= '0';
					end if;
				when SEND_DATA =>
					s_sclkEna_reg <= '1';
					s_spiSsel_reg <= '0';
				when LAST_BIT =>
					s_sclkEna_reg <= '1';
					s_spiSsel_reg <= '0';
					if(s_fsmCe = '1') then
						sN_do_reg(N-1 downto 1) <= sN_sh(N-2 downto 0);
						sN_do_reg(0) <= s_miso_reg;
					else
						sN_do_reg <= sN_do_reg;
					end if;
				when STOP =>
					s_spiSsel_reg <= '0';
					s_sclkEna_reg <= '0';
					if(s_fsmCe = '1') then
						oDataVal <= '1';
					else
						oDataVal <= '0';
					end if;
				when others =>
					
			end case;
		end if;
	end process;	
--=============================================================================
--  SPI clock output
--=============================================================================	
	process(iClk, iRst)
	begin
		if(iRst = '1') then
			s_spiClk_reg <= '0';
		elsif(iClk'event and iClk = '1') then
			if(s_sclkEna_reg = '1') then
				s_spiClk_reg <= s_spiClk;
			else
				s_spiClk_reg <= CPOL;
			end if;
		end if;
	end process;	
--=============================================================================
--  output assignment
--=============================================================================		
	oSpiSclk <= s_spiClk_reg;-- SPI clock output
	oData <= sN_do_reg;
	oSpiSsel <= s_spiSsel_reg;
	
end Behavioral;                                                                
