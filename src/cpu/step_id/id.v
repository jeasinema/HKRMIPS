/*-----------------------------------------------------
 File Name : id.v
 Purpose : top file of step_id
 Creation Date : 18-10-2016
 Modified : Tue Oct 18 17:56:55 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_V__
`define __ID_V__

`include "../defs.v"

`timescale 1ns/1ns

module id(/*autoarg*/
    //Inputs
    clk, rst_n, inst_code, pc_addr,

    //Outputs
    inst, inst_type, reg_s, reg_t, reg_d, 
    immediate, shift, jump_addr
);

    input wire clk;
    input wire rst_n;
    
    // full 32bit inst
    input wire[31:0] inst_code;
    // pass pc_value
    input wire[31:0] pc_addr;

    // inst mark at defs.v
    output reg[7:0] inst;
    // inst type in defs.v
    output reg[1:0] inst_type;

    // output operands
    output reg[4:0] reg_s;
    output reg[4:0] reg_t;
    output wire[4:0] reg_d;
    output reg[15:0] immediate;
    output reg[4:0] shift;  // only for SLL SRA
    output reg[25:0] jump_addr;  // only for J JAL

    // R-INST
    wire[7:0] id_r_inst;
    wire[4:0] id_r_reg_s;
    wire[4:0] id_r_reg_t;
    wire[4:0] id_r_reg_d;
    wire[4:0] id_r_shift;
    id_r id_r_decode(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
    .inst_code                  (inst_code[31:0]                ), // input
    .inst                       (id_r_inst[7:0]                 ), // output
    .reg_s                      (id_r_reg_s[4:0]                ), // output
    .reg_t                      (id_r_reg_t[4:0]                ), // output
    .reg_d                      (id_r_reg_d[4:0]                ), // output
    .shift                      (id_r_shift[4:0]                )  // output
    
        // decode the 32-bit width inst code     
    );

    // I_INST
    wire[7:0] id_i_inst;
    wire[4:0] id_i_reg_s;
    wire[4:0] id_i_reg_t;
    wire[15:0] id_i_immediate;
    id_i id_i_decode(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .inst_code                  (inst_code[31:0]                ), // input
    .inst                       (id_i_inst[7:0]                 ), // output
    .reg_s                      (id_i_reg_s[4:0]                ), // output
    .reg_t                      (id_i_reg_t[4:0]                ), // output
    .immediate                  (id_i_immediate[15:0]           )  // output

        // decode the 32bit width inst code
    );
    
    // J_INST
    wire[7:0] id_j_inst;
    wire[25:0] id_j_addr;
    id_j id_j_decode(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .inst_code                  (inst_code[31:0]                ), // input
    .inst                       (id_j_inst[7:0]                 ), // output
    .addr                    (id_j_addr[25:0]             )  // output
    );  

    always @(*)
    begin
        if (id_i_inst != `INST_INVALID)
            inst_type <= `INST_TYPE_I;
        else if (id_r_inst != `INST_INVALID)
            inst_type <= `INST_TYPE_R;
        else if (id_j_inst != `INST_INVALID)
            inst_type <= `INST_TYPE_J;
        else
            inst_type <= `INST_TYPE_INVALID;
    end
    
    always @(*)
    begin
        case (inst_type)
        `INST_TYPE_R:
        begin
            inst <= id_r_inst;
            reg_s <= id_r_reg_s;
            reg_t <= id_r_reg_t;
            immediate <= id_r_shift;
            shift <= id_r_shift;
            jump_addr <= 26'b0;
        end
        `INST_TYPE_I:
        begin
            inst <= id_i_inst;
            reg_s <= id_i_reg_s;
            reg_t <= id_i_reg_t;
            immediate <= id_i_immediate;
            shift <= 5'b0;
            jump_addr <= 26'b0;
        end
        `INST_TYPE_J:
        begin
            inst <= id_j_inst;
            reg_s <= 5'b0;
            reg_t <= 5'b0;
            immediate <= 16'b0;
            shift <= 5'b0;
            jump_addr <= id_j_addr;
        end
        default:
        begin
            inst <= `INST_INVALID;
            reg_s <= 5'b0;
            reg_t <= 5'b0;
            immediate <= 16'b0;
            shift <= 5'b0;
            jump_addr <= 26'b0;
        end
        endcase
    end
    assign reg_d = id_r_reg_d;  // MTC0/MFC0 are I-type, but still have reg_d

endmodule

`endif
