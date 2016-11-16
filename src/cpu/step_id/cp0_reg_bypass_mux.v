/*-----------------------------------------------------
 File Name : cp0_reg_bypass_mux.v
 Purpose : bypass value for regs in cp0
 Creation Date : 29-10-2016
 Last Modified : Wed Nov 16 19:45:35 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __CP0_REG_BYPASS_MUX_V__
`define __CP0_REG_BYPASS_MUX_V__

`timescale 1ns/1ns

module cp0_reg_bypass_mux(/*autoarg*/
    //Inputs
    clk, rst_n, reg_cp0_addr, reg_cp0_sel,
    val_from_cp0, ex_cp0_write_enable, ex_cp0_write_addr,
    ex_cp0_sel, val_from_ex, mm_cp0_write_enable,
    mm_cp0_write_addr, mm_cp0_sel, val_from_mm,
    wb_cp0_write_enable, wb_cp0_write_addr,
    wb_cp0_sel, val_from_wb,

    //Outputs
    val_output
);

    input wire clk;
    input wire rst_n;

    input wire[4:0] reg_cp0_addr;
    input wire[2:0] reg_cp0_sel;

    input wire val_from_cp0;

    input wire ex_cp0_write_enable;
    input wire[4:0] ex_cp0_write_addr;
    input wire[2:0] ex_cp0_sel;
    input wire[31:0] val_from_ex;

    input wire mm_cp0_write_enable;
    input wire mm_cp0_write_addr;
    input wire mm_cp0_sel;
    input wire val_from_mm;

    input wire wb_cp0_write_enable;
    input wire wb_cp0_write_addr;
    input wire wb_cp0_sel;
    input wire val_from_wb;

    output reg[31:0] val_output;

    always @(*)
    begin
        if (reg_cp0_addr == ex_cp0_write_addr && reg_cp0_sel == ex_cp0_sel && ex_cp0_write_enable == 1'b1)
            val_output <= val_from_ex;
        else if (reg_cp0_addr == mm_cp0_write_addr && reg_cp0_sel == mm_cp0_sel && mm_cp0_write_enable == 1'b1)
            val_output <= val_from_mm;
        else if (reg_cp0_addr == wb_cp0_write_addr && reg_cp0_sel == wb_cp0_sel && wb_cp0_write_enable == 1'b1)
            val_output <= val_from_wb;
        else
            val_output <= val_from_cp0;
    end

endmodule

`endif
