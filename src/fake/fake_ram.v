/*-----------------------------------------------------
 File Name : fake_ram.v
 Purpose : a fake ram for test
 Creation Date : 18-10-2016
 Last Modified : Wed Nov 16 19:47:13 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __FAKE_RAM_V__
`define __FAKE_RAM_V__

`timescale 1ns/1ns

module fake_ram(/*autoarg*/
    //Inputs
    clk, rst_n, address, data_i, rd, wr,
    byte_enable,

    //Outputs
    data_o
);

    input wire clk;
    input wire rst_n;

    input wire [29:0] address;
    input wire [31:0] data_i;
    output reg [31:0] data_o;
    input wire rd;
    input wire wr;
    input wire [3:0] byte_enable;

    reg[31:0] ram[0:(1024*1-1)];

    parameter MEM_ADDR_WIDTH = 10;

    genvar i,j;
    always @(*) begin
        data_o <= 32'hzzzzzzzz;
        if(wr) begin
            if(byte_enable[0])
                ram[address][7:0] <= data_i[7:0];
            if(byte_enable[1])
                ram[address][15:8] <= data_i[15:8];
            if(byte_enable[2])
                ram[address][23:16] <= data_i[23:16];
            if(byte_enable[3])
                ram[address][31:24] <= data_i[31:24];
        end
        else if (rd) begin
            data_o[7:0] <= byte_enable[0] ? ram[address][7:0] : 8'hzz;
            data_o[15:8] <= byte_enable[1] ? ram[address][15:8] : 8'hzz;
            data_o[23:16] <= byte_enable[2] ? ram[address][23:16] : 8'hzz;
            data_o[31:24] <= byte_enable[3] ? ram[address][31:24] : 8'hzz;
        end
    end

endmodule

`endif
