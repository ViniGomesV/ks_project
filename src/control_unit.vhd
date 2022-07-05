----------------------------------------------------------------------------------
-- Company: UERGS
-- Engineer: Joao Leonardo Fragoso
-- 
-- Create Date:    19:08:01 06/26/2012 
-- Design Name:    K and S modeling
-- Module Name:    control_unit - rtl 
-- Description:    RTL Code for K and S control unit
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--          0.02 - moving to Vivado 2017.3
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library work;
use work.k_and_s_pkg.all;

entity control_unit is
  port (
    rst_n               : in  std_logic;
    clk                 : in  std_logic;
    branch              : out std_logic;
    pc_enable           : out std_logic;
    ir_enable           : out std_logic;
    write_reg_enable    : out std_logic;
    addr_sel            : out std_logic;
    c_sel               : out std_logic;
    operation           : out std_logic_vector (1 downto 0);
    flags_reg_enable    : out std_logic;
    decoded_instruction : in  decoded_instruction_type;
    zero_op             : in  std_logic;
    neg_op              : in  std_logic;
    unsigned_overflow   : in  std_logic;
    signed_overflow     : in  std_logic;
    ram_write_enable    : out std_logic;
    halt                : out std_logic
    );
end control_unit;

architecture rtl of control_unit is

type STATE is (
FETCH,
DECODE,
NOP,
HALT_I,
LOAD,
WB_LOAD,
STORE,
MOVE,
EX_WB,
BRANCH_I,
BNEG,
BNNEG,
BZERO,
BNZERO,
PROG_COUNTER
);



signal estado_atual : STATE;
signal prox_estado : STATE;
begin

mudanca_estado : process (clk)
    begin
    if (clk'event and clk = '1') then
        if (rst_n = '1') then 
            estado_atual <= prox_estado;
        else
            estado_atual <= FETCH;
        end if;        
    end if;        
    end process;
    
instrucao : process (estado_atual)
    begin
    case (estado_atual) is

        when FETCH =>
            prox_estado <= DECODE;
            ir_enable <= '1';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';
            halt <= '0';
            
        when DECODE =>
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';
            case (decoded_instruction) is
            when I_NOP =>
                prox_estado <= NOP;
            when I_HALT =>
                prox_estado <= HALT_I;
            when I_LOAD =>
                prox_estado <= LOAD;
            when I_STORE =>
                prox_estado <= STORE;
                operation <= "00";
            when I_MOVE =>
                prox_estado <= MOVE;
            when I_ADD =>
                prox_estado <= EX_WB;
                operation <= "00";
            when I_SUB =>
                prox_estado <= EX_WB;
                operation <= "01";
            when I_AND =>
                prox_estado <= EX_WB;
                operation <= "10";
            when I_OR =>
                prox_estado <= EX_WB;
                operation <= "11";
            when I_BRANCH =>
                prox_estado <= BRANCH_I;
            when I_BNEG =>
                prox_estado <= BNEG;
            when I_BNNEG =>
                prox_estado <= BNNEG;
            when I_BZERO =>
                prox_estado <= BZERO;
            when I_BNZERO =>
                prox_estado <= BNZERO;
            when others =>
                prox_estado <= BNZERO;
            end case;
        
        when NOP =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
      
        when HALT_I =>
            halt <= '1';
            prox_estado <= HALT_I; 

        when LOAD =>
            prox_estado <= WB_LOAD;
            ir_enable <= '0';
            addr_sel <= '1'; 
            c_sel <= '1'; 
            pc_enable <= '0';
            branch <= '0'; 
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';     
        when WB_LOAD =>
            prox_estado <= PROG_COUNTER;
            write_reg_enable <= '1'; 
        when STORE =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '1';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            ram_write_enable <= '1';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';   
        when MOVE =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '1'; 
            operation <= "11";   
        when EX_WB =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            ram_write_enable <= '0';
            flags_reg_enable <= '1';
            write_reg_enable <= '1';  
        when BRANCH_I =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '1';
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';       
        when BNEG =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            if (neg_op = '1') then
                branch <= '1';
            else
                branch <= '0';
            end if;
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0'; 
            halt <= '0';   
        when BNNEG =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            if (neg_op = '1') then
                branch <= '0';
            else
                branch <= '1';
            end if;
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0'; 
            halt <= '0';   
        when BZERO =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            if (zero_op = '1') then
                branch <= '1';
            else
                branch <= '0';
            end if;
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0'; 
            halt <= '0';   
        when BNZERO =>
            prox_estado <= PROG_COUNTER;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            if (zero_op = '1') then
                branch <= '0';
            else
                branch <= '1';
            end if;
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0'; 
            halt <= '0';  
        when PROG_COUNTER =>
            prox_estado <= FETCH;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '1';
            branch <= '0';
            ram_write_enable <= '0';
            flags_reg_enable <= '0';
            write_reg_enable <= '0';
            halt <= '0';       
        when others =>
            prox_estado <= FETCH;
            ir_enable <= '0';
            addr_sel <= '0';
            c_sel <= '0';
            pc_enable <= '0';
            branch <= '0';
            halt <= '0';    
        end case;     
    end process;
    
end rtl;

