/*-----------------------------------------------------
 File Name : mul_cycle.v
 Purpose : for multi_cycle inst: MUL/DIV
 Creation Date : 18-10-2016
 Last Modified : Sat Oct 22 13:36:41 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __MUL_CYCLE_V__
`define __MUL_CYCLE_V__

`timescale 1ns/1ps

`include "../defs.v"

module multi_cycle(/*autoarg*/
    //Inputs
    clk, rst_n, inst, op1, op2, hilo_i, 

    //Outputs
    result, multi_cycle_done
);


    parameter DIV_CYCLES = 36;

    input wire clk;
    input wire rst_n;
    //input wire exception_flush;
    
    input wire[7:0] inst;
    input wire[31:0] op1;
    input wire[31:0] op2;
    input wire[63:0] hilo_i;

    output reg[63:0] result;
    output reg multi_cycle_done;

    wire flag_unsigned;
    wire[31:0] abs_op1, abs_op2;
    // for DIV/DIVU
    wire[31:0] raw_quotient, raw_remainder;
    wire[31:0] quotient, remainder;

    reg[DIV_CYCLES:0] div_stage;
    wire div_done;
    
    // for MADD/MADDU/MSUB/MSUBU
    reg cycle_count;

    // get operands
    assign flag_unsigned = (inst == `INST_DIVU);
    assign abs_op1 = (flag_unsigned ||!op1[31]) ? op1 : -op1;
    assign abs_op2 = (flag_unsigned ||!op2[31]) ? op2 : -op2;
    // do multiply
    assign raw_mul_result = abs_op1 * abs_op2;
    assign mul_result = (flag_unsigned || !(op1[31]^op2[31])) ? raw_mul_result : -raw_mul_result;
    // do divide
    assign quotient = (flag_unsigned || !(op1[31]^op2[31])) ? raw_quotient : -raw_quotient;
    assign remainder = (flag_unsigned || !(op1[31]^op2[31])) ? raw_remainder : -raw_remainder;

    assign div_done = div_stage[0];

    div_uu #(.z_width(64)) div_uu0(
        .clk (clk),
        .ena (inst == `INST_DIV || inst == `INST_DIVU),
        .z   ({32'h0,abs_op1}),
        .d   (abs_op2),
        .q   (raw_quotient),
        .s   (raw_remain),
        .div0(),
        .ovf ()
    );

    always @(*)
    begin
        case (inst)
        `INST_DIV,
        `INST_DIVU:
        begin
            multi_cycle_done <= div_done;
            result <= {remainder, quotient};
        end
        `INST_MADD,
        `INST_MADDU,
        `INST_MSUB,
        `INST_MSUBU:
        begin
            multi_cycle_done <= ~cycle_count;
        end
        //`INST_MSUB:
        //    result <= hilo_i - mul_result;
        //`INST_MADD:
        //    result <= hilo_i + mul_result;
        default:
            result <= 64'b0;
        endcase
    end

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            div_stage <= 'b0;
        end
        // start counting 
        else if (cycle_count != 1'b0) begin
            cycle_count <= 1'b0;
        end
        // counter init
        else if ((inst == `INST_MADD) ||
                 (inst == `INST_MADDU) ||
                 (inst == `INST_MSUB) ||
                 (inst == `INST_MSUBU)) begin
            cycle_count <= 1'b1;
        end
        // start counting 
        else if (div_stage != 'b0)
            div_stage <= div_stage >> 1;
        // counter init
        else if (inst == `INST_DIV || inst == `INST_DIVU)
            div_stage <= 'b1 << (DIV_CYCLES-1);
    end

endmodule

`endif
