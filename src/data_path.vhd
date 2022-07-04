----------------------------------------------------------------------------------
-- Company: UERGS
-- Engineer: Joao Leonardo Fragoso
-- 
-- Create Date:    19:04:44 06/26/2012 
-- Design Name:    K and S Modeling
-- Module Name:    data_path - rtl 
-- Description:    RTL Code for the K and S datapath
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
--          0.02 - Moving Vivado 2017.3
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
library work;
use work.k_and_s_pkg.all;
use IEEE.STD_LOGIC_SIGNED.all; -- 
use ieee.NUMERIC_STD.all;

entity data_path is
  port (
    rst_n               : in  std_logic;
    clk                 : in  std_logic;
    branch              : in  std_logic;
    pc_enable           : in  std_logic;
    ir_enable           : in  std_logic;
    addr_sel            : in  std_logic;
    c_sel               : in  std_logic;
    operation           : in  std_logic_vector (1 downto 0);
    write_reg_enable    : in  std_logic;
    flags_reg_enable    : in  std_logic;
    decoded_instruction : out decoded_instruction_type;
    zero_op             : out std_logic;
    neg_op              : out std_logic;
    unsigned_overflow   : out std_logic;
    signed_overflow     : out std_logic;
    ram_addr            : out std_logic_vector (4 downto 0);
    data_out            : out std_logic_vector (15 downto 0);
    data_in             : in  std_logic_vector (15 downto 0)
  );
end data_path;

architecture rtl of data_path is

  signal zero_f : std_logic;
  signal neg_f : std_logic;
  signal unof_f : std_logic;
  signal sof_f : std_logic;
  signal ALU1 : std_logic_vector (15 downto 0);
  signal alu_result : std_logic_vector (16 downto 0);
  signal bus_a : std_logic_vector (15 downto 0);
  signal bus_b : std_logic_vector (15 downto 0);
  signal bus_c : std_logic_vector (15 downto 0);
  signal a_addr : std_logic_vector (1 downto 0);
  signal b_addr : std_logic_vector (1 downto 0);
  signal c_addr : std_logic_vector (1 downto 0);
  signal reg0 : std_logic_vector (15 downto 0);
  signal reg1 : std_logic_vector (15 downto 0);
  signal reg2 : std_logic_vector (15 downto 0);
  signal reg3 : std_logic_vector (15 downto 0);
  signal mem_addr: std_logic_vector (4 downto 0);
  signal instruction : std_logic_vector (15 downto 0);
  signal program_counter : std_logic_vector (4 downto 0);
  signal program_counter1 : std_logic_vector (4 downto 0);

begin

  ALU : process (bus_a, bus_b,bus_c,operation,alu_result)
    begin
    case operation is

    when "00" => --or
        bus_c <= (bus_a) or (bus_b);
        unof_f <= '0';
        if(bus_c < 0) then
            neg_f <= '1';
        else
            neg_f <= '0';
        end if;
    when "01" => -- add
        bus_c <= (bus_a) + (bus_b);
        --overflow             
        if(bus_c < 0) then
            sof_f <= '1';
            neg_f <= '1';
        else
            sof_f <= '0';
            neg_f <= '0';
        end if;
        --carry
        alu_result <= ('0' & bus_a) + ('0' & bus_b);
        unof_f <= alu_result(16);
    when "10" => -- sub
        bus_c <= (bus_a) - (bus_b);
        --overflow             
        if(bus_c < 0) then
            sof_f <= '1';
            neg_f <= '1';
        else
            sof_f <= '0';
            neg_f <= '0';
        end if;
        --carry
        alu_result <= ('0' & bus_a) - ('0' & bus_b);
        unof_f <= alu_result(16);
    when "11" => -- and
        bus_c <= (bus_a) and (bus_b);
        unof_f <= '0';
        if(bus_c < 0) then
            neg_f <= '1';
        else
            neg_f <= '0';
        end if;
    when others =>
        bus_c <= (bus_a) + (bus_b);
    end case;
    
    if (bus_c = x"0000") then
        zero_f <= '1';
    else
        zero_f <= '0';
    end if;
    
    end process;
    

    ALU_OP : process (clk,bus_a,bus_b)  
    begin
    if (clk'event and clk = '1') then
        if (operation = "00") then
            bus_c <= bus_a or bus_b;
        else if (operation = "01") then
            bus_c <= bus_a + bus_b;
        else if (operation = "10") then
            bus_c <= bus_a - bus_b;
        else if (operation = "11") then
            bus_c <= bus_a and bus_b;
        end if;
        end if;
        end if;
        end if;
    end if;
    end process;

    flag_reg: process (clk, zero_f, neg_f, unof_f, sof_f, flags_reg_enable)
    begin
    if (clk'event and clk = '1' and flags_reg_enable = '1') then
        zero_op <= zero_f;
        neg_op <= neg_f;
        unsigned_overflow <= unof_f;
        signed_overflow <= sof_f;
    end if;
    end process;

    Reg_File : process(a_addr,b_addr,c_addr,write_reg_enable,bus_c,reg0,reg1,reg2,reg3,bus_a, clk)
    begin
    
        if (write_reg_enable = '1') then
            case c_addr is
            when "00" =>
                reg0 <= bus_c;
            when "01" =>
                reg1 <= bus_c;
            when "10" =>
                reg2 <= bus_c;
            when "11" =>
                reg3 <= bus_c;
            when others =>
                null;
            end case;
        end if; 
        
        case a_addr is
        when "00" =>
            bus_a <= reg0;
        when "01" =>
            bus_a <= reg1;
        when "10" =>
            bus_a <= reg2;
        when "11" =>
            bus_a <= reg3;
        when others =>
            bus_a <= reg0;
        end case;
        
        case b_addr is
        when "00" =>
            bus_b <= reg0;
        when "01" =>
            bus_b <= reg1;
        when "10" =>
            bus_b <= reg2;
        when "11" =>
            bus_b <= reg3;
        when others =>
            bus_b <= reg3;
        end case;
        
        data_out <= bus_a;
   
    end process;

    DECODE : process(instruction)
        begin
        case instruction(15 downto 7) is
        when "100000010" =>
            decoded_instruction <= I_LOAD;
            c_addr <= instruction(6 downto 5);
            mem_addr <= instruction(4 downto 0);  
        when "100000100" =>
            decoded_instruction <= I_STORE;
            a_addr <= instruction(6 downto 5);
            mem_addr <= instruction(4 downto 0);  
        when "100100010" =>
            decoded_instruction <= I_MOVE;
            c_addr <= instruction(1 downto 0);
            b_addr <= instruction(3 downto 2);
            a_addr <= instruction(1 downto 0);
        when "101000010" =>
            decoded_instruction <= I_ADD;
            c_addr <= instruction(5 downto 4);
            b_addr <= instruction(1 downto 0);
            a_addr <= instruction(3 downto 2);
        when "101000100" =>
            decoded_instruction <= I_SUB;
            c_addr <= instruction(5 downto 4);
            b_addr <= instruction(1 downto 0);
            a_addr <= instruction(3 downto 2);
        when "101000110" =>
            decoded_instruction <= I_AND;
            c_addr <= instruction(5 downto 4);
            b_addr <= instruction(3 downto 2);
            a_addr <= instruction(1 downto 0);
        when "101001000" =>
            decoded_instruction <= I_OR;  
            c_addr <= instruction(5 downto 4);
            b_addr <= instruction(3 downto 2);
            a_addr <= instruction(1 downto 0);
                         
        when "000000010" =>
            decoded_instruction <= I_BRANCH; 
            mem_addr <= instruction(4 downto 0); 
        when "000000100" =>
            decoded_instruction <= I_BZERO;
            mem_addr <= instruction(4 downto 0); 
        when "000000110" =>
            decoded_instruction <= I_BNEG;
            mem_addr <= instruction(4 downto 0); 
        when "000010100" =>
            decoded_instruction <= I_BNNEG;
            mem_addr <= instruction(4 downto 0); 
        when "000010110" =>
            decoded_instruction <= I_BNZERO;
            mem_addr <= instruction(4 downto 0); 
        
        when others =>
            if (instruction = "1111111111111111") then
            decoded_instruction <= I_HALT;
            else
            decoded_instruction <= I_NOP;
            mem_addr <= instruction(4 downto 0);
            end if;
        end case;        
    end process;

    IR : process(data_in, ir_enable, clk)
        begin
        if (rst_n = '1') then
            if (ir_enable = '1') then
            instruction <= data_in;
            end if;
        end if;
    end process;

    branch_s : process(branch, mem_addr, program_counter)
    begin
    if (branch = '1') then
        program_counter1 <= mem_addr;
    else
        program_counter1 <= program_counter + "00001";
    end if;
    end process;

    PC : process(program_counter1, pc_enable, clk, rst_n)
    begin
    if (clk'event and clk = '1') then
        if (pc_enable = '1') then
            program_counter <= program_counter1;
        elsif
        (rst_n = '0') then
            program_counter <= "00000";    
        end if;
        
    end if;
    end process;

    addr_s : process(addr_sel, mem_addr, program_counter)
    begin
    if (addr_sel = '0') then
        ram_addr <= program_counter;
    else
        ram_addr <= mem_addr;     
    end if;
    end process;

    c_sel1: process(ALU1, data_in, c_sel)
    begin
    if (c_sel = '1') then
        bus_c <= data_in;
    else
        bus_c <= ALU1;
    end if;
    end process;


end rtl;

