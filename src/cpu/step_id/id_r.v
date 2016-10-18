/*-----------------------------------------------------
 File Name : id_r.v
 Purpose : decode R-type inst
 Creation Date : 18-10-2016
 Last Modified : Tue Oct 18 19:52:42 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_R_V__
`define __ID_R_V__

`timescale 1ns/1ps

module id_r(/*autoarg*/);

    input wire clk;
    input wire rst_n;
    
    input wire[31:0] inst_code;
    output reg[7:0] inst;
    output wire[4:0] reg_s;
    output wire[4:0] reg_t;
    output wire[4:0] reg_d;
    output wire[4:0] shift;
     

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
