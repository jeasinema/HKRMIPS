/*-----------------------------------------------------
 File Name : fake_rom.v
 Purpose : a fake rom for test
 Creation Date : 18-10-2016
 Last Modified : Mon Oct 31 14:41:53 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __FAKE_ROM_V__
`define __FAKE_ROM_V__

`timescale 1ns/1ns

module fake_rom(/*autoarg*/
    //Inputs
    clk, rst_n, address, 

    //Outputs
    data
);

    input wire clk;
    input wire rst_n;

    input wire [31:0] address;
    output wire [31:0] data;

    reg[31:0] rom[0:2047];

    assign data = rom[address[31:2]];  // align with word

endmodule

`endif
