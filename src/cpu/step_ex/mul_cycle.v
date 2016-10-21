/*-----------------------------------------------------
 File Name : mul_cycle.v
 Purpose : for multi_cycle inst: MUL/DIV
 Creation Date : 18-10-2016
 Last Modified : Fri Oct 21 20:14:33 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __MUL_CYCLE_V__
`define __MUL_CYCLE_V__

`timescale 1ns/1ps

`include "../defs.v"

module mul_cycle(/*autoarg*/);


    parameter DIV_CYCLES = 36;

    input wire clk;
    input wire rst_n;
    //input wire exception_flush;
    
    input wire[7:0] inst;
    input wire[31:0] op1;
    input wire[31:0] op2;
    input wire[63:0] hilo_i;

    output reg[63:0] result;
    output reg mul_done;

    wire flag_unsigned;
    wire[31:0] abs_op1, abs_op2;


    assign flag_unsigned = (inst == `INST_DIVU || inst == `INST_MULTU);
    assign abs_opa1 = (flag_unsigned ||!operand1[31]) ? operand1 : -operand1;
    assign abs_opa2 = (flag_unsigned ||!operand2[31]) ? operand2 : -operand2;



    div_uu #(.z_width(64)) div_uu0(
        .clk (clk),
        .ena (inst == `INST_DIV || inst == `INST_DIVU),
        .z   ({32'h0,abs_opa1}),
        .d   (abs_opa2),
        .q   (tmp_quotient),
        .s   (tmp_remain),
        .div0(),
        .ovf ()
    );

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
