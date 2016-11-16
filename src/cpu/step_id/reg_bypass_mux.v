/*-----------------------------------------------------
 File Name : reg_bypass_mux.v
 Purpose : an mux interface for regs, used for bypass
 Creation Date : 18-10-2016
 Last Modified : Sun Nov  6 15:59:40 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __REG_BYPASS_MUX_V__
`define __REG_BYPASS_MUX_V__
`default_nettype none
`include "../defs.v"

`timescale 1ns/1ns

module reg_bypass_mux(/*autoarg*/
    //Inputs
    clk, rst_n, reg_addr, val_from_regs, 
    addr_from_ex, val_from_ex, access_type_from_ex, 
    addr_from_mm, val_from_mm, access_type_from_mm, 
    addr_from_wb, val_from_wb, write_enable_from_wb, 

    //Outputs
    val_output
);

    input wire clk;
    input wire rst_n;
    
    // input an reg addr for val
    input wire[4:0] reg_addr;
    
    // val from real regs heap
    input wire[31:0] val_from_regs;
    
    // reg addr info used for bypass from ex
    input wire[4:0] addr_from_ex;
    input wire[31:0] val_from_ex;
    input wire[1:0] access_type_from_ex;
    
    // reg addr info used for bypass from mm
    input wire[4:0] addr_from_mm;
    input wire[31:0] val_from_mm;
    input wire[1:0] access_type_from_mm;
    
    // reg addr info used for bypass from wb
    input wire[4:0] addr_from_wb;
    input wire[31:0] val_from_wb;
    // we = 0 is equal with mem_access_type == R2M (reg_val is useless)
    input wire write_enable_from_wb;
    //input wire write_enable_from_wb;
    
    // final output of reg val (from real regs heap or bypass)
    output reg[31:0] val_output;

    always @(*) 
    begin
        if (reg_addr == 5'b0)
            val_output <= 32'b0;
        else if (reg_addr == addr_from_ex && access_type_from_ex == `MEM_ACCESS_TYPE_R2R)
            val_output <= val_from_ex;
        else if (reg_addr == addr_from_mm && (access_type_from_mm == `MEM_ACCESS_TYPE_R2R || access_type_from_mm == `MEM_ACCESS_TYPE_M2R))
            val_output <= val_from_mm;
        else if(reg_addr == addr_from_wb && write_enable_from_wb)
            val_output <= val_from_wb;
        else
            val_output <= val_from_regs;
    end

endmodule

`endif
