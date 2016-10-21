/*-----------------------------------------------------
 File Name : hkr_mips.v
 Purpose : top file for cpu
 Creation Date : 18-10-2016
 Last Modified : Fri Oct 21 16:47:05 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __HKR_MIPS_V__
`define __HKR_MIPS_V__

`timescale 1ns/1ps

`include "defs.v"

module hkr_mips(/*autoarg*/);

    input wire clk;
    input wire rst_n;


    regs main_regs(/*autoinst*/);

    mmu_top main_mmu(/*autoinst*/);

    pc unique_pc(/*autoinst*/);
    
    id step_id(/*autoinst*/);
    
    reg_bypass_mux reg_bypass_mux_s(/*autoinst*/);
    
    reg_bypass_mux reg_bypass_mux_t(/*autoinst*/);
    
    branch_jump branch_jump_detector(/*autoinst*/);
    
    ex step_ex(/*autoinst*/);
    
    mm step_mm(/*autoinst*/);
    
    wb step_wb(/*autoinst*/);

endmodule

`endif
