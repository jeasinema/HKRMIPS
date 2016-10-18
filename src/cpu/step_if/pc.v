/*-----------------------------------------------------
 File Name : pc.v
 Purpose : program counter in step_if
 Creation Date : 18-10-2016
 Last Modified : Tue Oct 18 14:56:02 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __PC_V__
`define __PC_V__

`timescale 1ns/1ps

module pc(/*autoarg*/
    //Inputs
    clk, rst_n, pc_enable, do_branch, branch_address, 
    do_exception, exception_address, do_debug, 
    debug_reset, debug_address, 

    //Outputs
    pc_address
);


    parameter PC_INITIAL_VAL = 32'hbfc00000;
    parameter PC_EXCEPTION_BASE = 32'hfffffffc;
    parameter PC_BRANCH_BASE = 32'hfffffffc;

    input wire clk;
    input wire rst_n;
    input wire pc_enable;
    
    input wire do_branch;
    input wire[31:0] branch_address;
    
    input wire do_exception;
    input wire[31:0] exception_address;

    input wire do_debug;
    input wire debug_reset;
    input wire[31:0] debug_address;
    
    output reg[31:0] pc_address;
    
    always @(posedge clk or negedge rst_n)
    begin
        // reset pc address to init val
        if (!rst_n)
            pc_address <= PC_INITIAL_VAL;
        // reset when debug
        else if (debug_reset)
            pc_address <= PC_INITIAL_VAL;
        // jump to target addr when exception occurs
        else if (do_exception)
            pc_address <= exception_address & PC_EXCEPTION_BASE;
        // jump to target addr when debug
        else if (do_debug)
            pc_address <= debug_address;
        // now only work when pc is enable (not stall)
        else if (pc_enable)
        begin
            // jump to target addr when branch
            if (do_branch)
                pc_address <= branch_address & PC_BRANCH_BASE;
            // normal condition, += 4
            else 
                pc_address <= pc_address + 32'd4;
        end
    end
    
    // for debug output
    always @(posedge clk) $display("PC=%x", pc_address);

endmodule

`endif
