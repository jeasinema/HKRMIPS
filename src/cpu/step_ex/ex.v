/*-----------------------------------------------------
 File Name : ex.v
 Purpose :
 Creation Date : 18-10-2016
 Last Modified : Tue Oct 18 16:59:20 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __X_V__
`define __X_V__

`timescale 1ns/1ps

module ex(/*autoarg*/);

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
