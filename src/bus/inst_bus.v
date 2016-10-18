/*-----------------------------------------------------
 File Name : inst_bus.v
 Purpose : device (only sram) bus for instructions
 Creation Date : 18-10-2016
 Last Modified : Tue Oct 18 14:27:17 2016
 Created By :  Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __INST_BUS_V__
`define __INST_BUS_V__

`timescale 1ns/1ps

module inst_bus(/*autoarg*/);

    input wire clk;
    input wire rst_n;

    input wire[31:0] mmu_output_address;
    input wire[31:0]  

    always @(*)
    begin

    end

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin

        end

    end

endmodule

`endif
