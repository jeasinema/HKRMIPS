/*-----------------------------------------------------
 File Name : wb.v
 Purpose : step_wb
 Creation Date : 18-10-2016
 Last Modified : Wed Nov 16 19:46:52 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __WB_V__
`define __WB_V__
`default_nettype none
`timescale 1ns/1ns

`include "../defs.v"

module wb(/*autoarg*/
    //Inputs
    clk, rst_n, mem_access_type, data_i,
    bypass_reg_addr_wb,

    //Outputs
    reg_write_enable
);

    input wire clk;
    input wire rst_n;

    // mem_access_type in mm.v, but 1 clock late
    input wire[1:0] mem_access_type;
    // data_o in mm
    input wire[31:0] data_i;
    // bypass_reg_addr_mm in mm.v, but 1 clock late
    input wire[4:0] bypass_reg_addr_wb;

    // for regs
    output wire reg_write_enable;

    assign reg_write_enable = (mem_access_type == `MEM_ACCESS_TYPE_M2R) || (mem_access_type == `MEM_ACCESS_TYPE_R2R);

endmodule

`endif
