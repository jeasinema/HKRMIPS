/*-----------------------------------------------------
 File Name : id_j.v
 Purpose :
 Creation Date : 18-10-2016
 Last Modified : Wed Oct 19 14:21:16 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_J_V__
`define __ID_J_V__

`timescale 1ns/1ps

`include "../defs.v"

module id_j(/*autoarg*/
    //Inputs
    clk, rst_n, inst_code, 

    //Outputs
    inst, address
);

    input wire clk;
    input wire rst_n;

    input wire[31:0] inst_code;
    output reg[7:0] inst;
    output wire[25:0] address;

    assign address = inst_code[25:0];

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
