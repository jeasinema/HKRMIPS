/*-----------------------------------------------------
 File Name : id_j.v
 Purpose :
 Creation Date : 18-10-2016
 Last Modified : Thu Oct 20 10:49:06 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_J_V__
`define __ID_J_V__
`default_nettype none
`timescale 1ns/1ns

`include "../defs.v"

module id_j(/*autoarg*/
    //Inputs
    clk, rst_n, inst_code, 

    //Outputs
    inst, addr
);

    input wire clk;
    input wire rst_n;

    input wire[31:0] inst_code;
    output reg[7:0] inst;
    output wire[25:0] addr;

    assign addr = inst_code[25:0];

    always @(*)
    begin
        case (inst_code[31:26]) 
        6'h02: inst <= `INST_J;
        6'h03: inst <= `INST_JAL;
        default: inst <= `INST_INVALID;
        endcase
    end

endmodule

`endif
