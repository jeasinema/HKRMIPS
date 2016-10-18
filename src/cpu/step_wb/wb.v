/*-----------------------------------------------------
 File Name : wb.v
 Purpose :
 Creation Date : 18-10-2016
 Last Modified : Tue Oct 18 17:00:05 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __X_V__
`define __X_V__

`timescale 1ns/1ps

module wb(/*autoarg*/);

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
