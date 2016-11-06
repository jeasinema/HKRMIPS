/*-----------------------------------------------------
 File Name : pc.v
 Purpose : program counter in step_if
 Creation Date : 18-10-2016
 Last Modified : Thu Oct 27 12:27:50 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __PC_V__
`define __PC_V__

`timescale 1ns/1ns

module pc(/*autoarg*/
    //Inputs
    clk, rst_n, pc_enable, do_branch, branch_addr, 
    do_exception, exception_addr, do_debug, 
    debug_reset, debug_addr, 

    //Outputs
    pc_addr
);


    parameter PC_INITIAL_VAL = 32'hbfc00000;    // reset interrupt vector is 32'hBFC00000, ref to vol3P30
    parameter PC_EXCEPTION_BASE = 32'hfffffffc;  // need to be aligned with word
    parameter PC_BRANCH_BASE = 32'hfffffffc;  // need to be aligned with word

    input wire clk;
    input wire rst_n;
    input wire pc_enable;
    
    input wire do_branch;
    input wire[31:0] branch_addr;
    
    input wire do_exception;
    input wire[31:0] exception_addr;

    input wire do_debug;
    input wire debug_reset;
    input wire[31:0] debug_addr;
    
    output reg[31:0] pc_addr;
    
    always @(posedge clk or negedge rst_n)
    begin
        // reset pc address to init val
        if (!rst_n)
            pc_addr <= PC_INITIAL_VAL;
        // reset when debug
        else if (debug_reset)
            pc_addr <= PC_INITIAL_VAL;
        // jump to target addr when exception occurs
        else if (do_exception)
            pc_addr <= exception_addr & PC_EXCEPTION_BASE;
        // jump to target addr when debug
        else if (do_debug)
            pc_addr <= debug_addr;
        // now only work when pc is enable (not stall)
        else if (pc_enable)
        begin
            // jump to target addr when branch
            if (do_branch)
                pc_addr <= branch_addr & PC_BRANCH_BASE;
            // normal condition, += 4
            else 
                pc_addr <= pc_addr + 32'd4;
        end
    end
    
    // for debug output
    always @(posedge clk) $display("PC=%x", pc_addr);

endmodule

`endif
