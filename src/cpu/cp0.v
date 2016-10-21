/*-----------------------------------------------------
 File Name : cp0.v
 Purpose : top file of cp0
 Creation Date : 18-10-2016
 Last Modified : Fri Oct 21 17:02:43 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __CP0_V__
`define __CP0_V__

`timescale 1ns/1ps

module cp0(/*autoarg*/);

    input wire clk;
    input wire rst_n;

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
