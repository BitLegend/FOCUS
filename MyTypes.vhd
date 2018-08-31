--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;

package MyTypes is

	-- Measurement AD(TLV2548) and multiplexer output data type definition
	TYPE madDataOut IS ARRAY (0 to 15) OF STD_LOGIC_VECTOR(11 downto 0);
	TYPE a12of8     IS ARRAY(0 to 11) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a14of8     IS ARRAY(0 to 13) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a20of8     IS ARRAY(0 to 19) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a6of8      IS ARRAY(0 to 5) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a4of8      IS ARRAY(0 to 3) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a3of8      IS ARRAY(0 to 2) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a4of4      IS ARRAY(0 to 3) OF STD_LOGIC_VECTOR (3 downto 0);	
	TYPE a4of12     IS ARRAY(0 to 3) OF STD_LOGIC_VECTOR (11 downto 0);
	TYPE a4of13     IS ARRAY(0 to 3) OF STD_LOGIC_VECTOR (12 downto 0);	
	TYPE a29of8     IS ARRAY(0 to 28) OF STD_LOGIC_VECTOR (7 downto 0);
	TYPE a8of8      IS ARRAY(0 to 7) OF STD_LOGIC_VECTOR (7 downto 0);	
	TYPE a23of8     IS ARRAY(0 to 22) OF STD_LOGIC_VECTOR (7 downto 0);	
	TYPE a19of8     IS ARRAY(0 to 18) OF STD_LOGIC_VECTOR (7 downto 0);	
	TYPE a10of16    IS ARRAY(0 to 9) OF STD_LOGIC_VECTOR (15 downto 0);		
	TYPE a2of16     IS ARRAY(0 to 1) OF STD_LOGIC_VECTOR (15 downto 0);
	TYPE a8of16     IS ARRAY(0 to 7) OF STD_LOGIC_VECTOR (15 downto 0);
	TYPE a3of16     IS ARRAY(0 to 2) OF STD_LOGIC_VECTOR (15 downto 0);		
-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants

	-- Synchronization header
	constant c8_synHeader		:   STD_LOGIC_VECTOR (7 downto 0):=X"7E";
                                                    
	--command signal                                 
	constant c8_RePara			:   STD_LOGIC_VECTOR (7 downto 0):=X"C3";
	constant c8_SelfClrOp		:   STD_LOGIC_VECTOR (7 downto 0):=X"33";	
	constant c8_SelfClrCl		:   STD_LOGIC_VECTOR (7 downto 0):=X"3B";
	constant c8_AdjFocus		:   STD_LOGIC_VECTOR (7 downto 0):=X"2E";
	constant c8_Wait		  	:   STD_LOGIC_VECTOR (7 downto 0):=X"E2";
	constant c8_Stablize		:   STD_LOGIC_VECTOR (7 downto 0):=X"B6";
	constant c8_OffParaSet  :   STD_LOGIC_VECTOR (7 downto 0):=X"6B";
	constant c8_ParaSet			:   STD_LOGIC_VECTOR (7 downto 0):=X"3C";
	constant c8_HeatParaSet	:   STD_LOGIC_VECTOR (7 downto 0):=X"47";
	constant c8_StabDis	    :   STD_LOGIC_VECTOR (7 downto 0):=X"74";
	constant c8_AdjDis	    :   STD_LOGIC_VECTOR (7 downto 0):=X"D1";
	constant c8_StabEn	    :   STD_LOGIC_VECTOR (7 downto 0):=X"9E";
	constant c8_AdjEn	     	:   STD_LOGIC_VECTOR (7 downto 0):=X"E9";
	constant c8_CtrParaSet  :   STD_LOGIC_VECTOR (7 downto 0):=X"1D";
	
	constant c4_sensor1     : STD_LOGIC_VECTOR (7 downto 0) := X"41";
	constant c4_sensor2     : STD_LOGIC_VECTOR (7 downto 0) := X"42";	
	-- Heating and piezo control open loop and close loop
	constant c8_open        : STD_LOGIC_VECTOR (7 downto 0) := X"4B";
	constant c8_close       : STD_LOGIC_VECTOR (7 downto 0) := X"44";	

	constant c4_PiezOpen    : STD_LOGIC_VECTOR (3 downto 0) := X"B";
	constant c4_PiezClose   : STD_LOGIC_VECTOR (3 downto 0) := X"4";	
	-- Stabilizing according to imaging state and temperature ?
	constant c8_TempImg     : STD_LOGIC_VECTOR (7 downto 0) := X"44";
	constant c8_TempnImgn   : STD_LOGIC_VECTOR (7 downto 0) := X"bb";		
  constant c8_TempImgn    : STD_LOGIC_VECTOR (7 downto 0) := X"55";
  constant c8_TempnImg    : STD_LOGIC_VECTOR (7 downto 0) := X"5e";
	-- stop heating when temperature out of scope ?
	constant c4_SelfHeat    : STD_LOGIC_VECTOR (3 downto 0) := X"5";
	constant c4_CenHeat     : STD_LOGIC_VECTOR (3 downto 0) := X"a";	
	-- CCD state and channel parameters
	constant c8_Imging      : STD_LOGIC_VECTOR (7 downto 0) := X"5A";
	constant c8_ImgStop     : STD_LOGIC_VECTOR (7 downto 0) := X"A5";	

	constant c8_ChanEUV     : STD_LOGIC_VECTOR (7 downto 0) := X"45";
	constant c8_ChanX       : STD_LOGIC_VECTOR (7 downto 0) := X"58";	
	-- Piezo driver temperature threshold
	constant c12_PiDrTemUP  : STD_LOGIC_VECTOR (11 downto 0) := X"056";	
	-- RS422 state
	constant c8_ivalidCmd   : STD_LOGIC_VECTOR (7 downto 0) := X"55";
	constant c8_checkErr    : STD_LOGIC_VECTOR (7 downto 0) := X"5e";
	constant c8_overtime    : STD_LOGIC_VECTOR (7 downto 0) := X"ee";	

	-- Piezo scope:  sign data 
	constant c16_PiezoUpX 	 : STD_LOGIC_VECTOR(15 downto 0) := X"0e61"; --4.493
	constant c16_PiezoDwX 	 : STD_LOGIC_VECTOR(15 downto 0) := X"0420"; --1.289
	constant c16_PiezoUpY 	 : STD_LOGIC_VECTOR(15 downto 0) := X"0e3f"; --4.45
	constant c16_PiezoDwY 	 : STD_LOGIC_VECTOR(15 downto 0) := X"03b0"; --1.152

	-- settable
	-- Piezo XY scale parameter
	constant c16_ScaleEUVX 	 : STD_LOGIC_VECTOR(15 downto 0) := X"20eb";
	constant c16_ScaleXX  	 : STD_LOGIC_VECTOR(15 downto 0) := X"13bf";
	constant c16_ScaleEUVY 	 : STD_LOGIC_VECTOR(15 downto 0) := X"d94a";
	constant c16_ScaleXY  	 : STD_LOGIC_VECTOR(15 downto 0) := X"e8c8";
	-- settable	
	-- Piezo XY offset
	constant c16_offsetX 	 : STD_LOGIC_VECTOR(15 downto 0) := X"0940"; --2.891
	constant c16_offsetY  	 : STD_LOGIC_VECTOR(15 downto 0) := X"08f6";	--2.801		
	-- settable
	-- Piezo open loop multiplier parameter : unsigned number fraction length 8
	constant c_ParaOpA   	 : STD_LOGIC_VECTOR(7 downto 0) := X"b2"; -- 0.6953
	constant c_ParaOpB  	 : STD_LOGIC_VECTOR(7 downto 0) := X"b2";	
	constant c_ParaOpC  	 : STD_LOGIC_VECTOR(7 downto 0) := X"80";	-- 0.5	
	-- settable
	-- Piezo XYZ control parameter : I item (default value)(signed number)
	constant c_ParaXI   	 : STD_LOGIC_VECTOR(15 downto 0) := X"0624"; --
	constant c_ParaYI  	     : STD_LOGIC_VECTOR(15 downto 0) := X"0624"; --	
	constant c_ParaZI    	 : STD_LOGIC_VECTOR(15 downto 0) := X"0106"; 
	-- Piezo XYZ control parameter : I item (the upper limit)(signed number)
	constant c_ParaXIUp   	 : STD_LOGIC_VECTOR(15 downto 0) := X"1892"; 
	constant c_ParaYIUp      : STD_LOGIC_VECTOR(15 downto 0) := X"1892";	
	constant c_ParaZIUp   	 : STD_LOGIC_VECTOR(15 downto 0) := X"0106"; 
	-- Piezo XYZ control parameter : I item (the lower limit) not + 1 (signed number)
	constant c_ParaXILw   	 : STD_LOGIC_VECTOR(15 downto 0) := X"0000"; 
	constant c_ParaYILw      : STD_LOGIC_VECTOR(15 downto 0) := X"0000";	
	constant c_ParaZILw   	 : STD_LOGIC_VECTOR(15 downto 0) := X"0000"; 	
	-- Default value
	constant c12_adjPos     : STD_LOGIC_VECTOR (11 downto 0) := X"87b"; --2.65
	constant c12_stbXPos    : STD_LOGIC_VECTOR (11 downto 0) := c16_PiezoDwX(11 downto 0);
	constant c12_stbYPos    : STD_LOGIC_VECTOR (11 downto 0) := c16_PiezoDwY(11 downto 0);
	constant c12_tmpNorTar  : STD_LOGIC_VECTOR (11 downto 0) := X"2A9"; -- -60 centi degree
	constant c12_tmpClrTar  : STD_LOGIC_VECTOR (11 downto 0) := X"BD7"; -- 30  centi degree
	constant c2_stabEn      : STD_LOGIC_VECTOR (1 downto 0) := "11";--obit stab 1bit adj


	
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;
-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--

end MyTypes;

package body MyTypes is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end MyTypes;
