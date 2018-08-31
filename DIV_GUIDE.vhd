--------------------------------------------------------------------------------
--     This file is owned and controlled by Xilinx and must be used           --
--     solely for design, simulation, implementation and creation of          --
--     design files limited to Xilinx devices or technologies. Use            --
--     with non-Xilinx devices or technologies is expressly prohibited        --
--     and immediately terminates your license.                               --
--                                                                            --
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"          --
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                --
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION        --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION            --
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS              --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE       --
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY               --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS        --
--     FOR A PARTICULAR PURPOSE.                                              --
--                                                                            --
--     Xilinx products are not intended for use in life support               --
--     appliances, devices, or systems. Use in such applications are          --
--     expressly prohibited.                                                  --
--                                                                            --
--     (c) Copyright 1995-2007 Xilinx, Inc.                                   --
--     All rights reserved.                                                   --
--------------------------------------------------------------------------------
-- You must compile the wrapper file Div_Guide.vhd when simulating
-- the core, Div_Guide. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
Library XilinxCoreLib;
-- synthesis translate_on
ENTITY Div_Guide IS
	port (
	clk: IN std_logic;
	dividend: IN std_logic_VECTOR(16 downto 0);
	divisor: IN std_logic_VECTOR(16 downto 0);
	quotient: OUT std_logic_VECTOR(16 downto 0);
	remainder: OUT std_logic_VECTOR(14 downto 0);
	rfd: OUT std_logic);
END Div_Guide;

ARCHITECTURE Div_Guide_a OF Div_Guide IS
-- synthesis translate_off
component wrapped_Div_Guide
	port (
	clk: IN std_logic;
	dividend: IN std_logic_VECTOR(16 downto 0);
	divisor: IN std_logic_VECTOR(16 downto 0);
	quotient: OUT std_logic_VECTOR(16 downto 0);
	remainder: OUT std_logic_VECTOR(14 downto 0);
	rfd: OUT std_logic);
end component;

-- Configuration specification 
	for all : wrapped_Div_Guide use entity XilinxCoreLib.div_gen_v1_0(behavioral)
		generic map(
			divclk_sel => 8,
			exponent_width => 8,
			bias => 0,
			c_has_sclr => 0,
			latency => 1,
			c_has_ce => 0,
			c_has_aclr => 0,
			c_sync_enable => 0,
			fractional_width => 15,
			mantissa_width => 8,
			signed_b => 1,
			fractional_b => 1,
			algorithm_type => 1,
			divisor_width => 17,
			dividend_width => 17);
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_Div_Guide
		port map (
			clk => clk,
			dividend => dividend,
			divisor => divisor,
			quotient => quotient,
			remainder => remainder,
			rfd => rfd);
-- synthesis translate_on

END Div_Guide_a;

