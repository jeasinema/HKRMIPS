/*-----------------------------------------------------
 File Name : id_i.v
 Purpose :  decode I-type instructions
 Creation Date : 18-10-2016
 Last Modified : Sun Nov  6 20:51:17 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_I_V__
`define __ID_I_V__
`default_nettype none
`timescale 1ns/1ns

`include "../defs.v"

module id_i(/*autoarg*/
    //Inputs
    clk, rst_n, inst_code, 

    //Outputs
    inst, reg_s, reg_t, immediate
);

    input wire clk;
    input wire rst_n;

    input wire[31:0] inst_code;
    output reg[7:0] inst;
    output wire[4:0] reg_s;
    output wire[4:0] reg_t;
    output wire[15:0] immediate;

    // decode the 32bit width inst code
    assign reg_s = inst_code[25:21];
    assign reg_t = inst_code[20:16];
    assign immediate = inst_code[15:0];

    always @(*)
    begin
        case (inst_code[31:26])
        // I-Type: REGIMM
        6'h01:
        begin
            case (inst_code[20:16])  // reg_t
            5'h00: inst <= `INST_BLTZ;
            5'h01: inst <= `INST_BGEZ;
            5'h10: inst <= `INST_BLTZAL;
            5'h11: inst <= `INST_BGEZAL;
            default: inst <= `INST_INVALID;
            endcase
        end
        6'h04: inst <= `INST_BEQ;
        6'h05: inst <= `INST_BNE;
        6'h06: inst <= `INST_BLEZ;
        6'h07: inst <= `INST_BGTZ;
        6'h08: inst <= `INST_ADDI;
        6'h09: inst <= `INST_ADDIU;
        6'h0a: inst <= `INST_SLTI;
        6'h0b: inst <= `INST_SLTIU;
        6'h0c: inst <= `INST_ANDI;
        6'h0d: inst <= `INST_ORI;
        6'h0e: inst <= `INST_XORI;
        6'h0f: inst <= `INST_LUI;
        // I-Type: CP0 
        6'h10: 
        begin
            if (inst_code[25:21] == 5'h0)   //reg_s
                inst <= `INST_MFC0;
            else if (inst_code[25:21] == 5'h4)
                inst <= `INST_MTC0;
            // reg_s = CO
            else if (inst_code[25] == 1'b1)
            begin
                case (inst_code[5:0])
                6'h02: inst <= `INST_TLBWI;
                6'h08: inst <= `INST_TLBP;
                6'h18: inst <= `INST_ERET;
                6'h20: inst <= `INST_WAIT;
                default: inst <= `INST_INVALID;
                endcase
            end
            else 
                inst <= `INST_INVALID;
        end
        6'h20: inst <= `INST_LB;
        6'h21: inst <= `INST_LH;
        6'h22: inst <= `INST_LWL;
        6'h23: inst <= `INST_LW;
        6'h24: inst <= `INST_LBU;
        6'h25: inst <= `INST_LHU;
        6'h26: inst <= `INST_LWR;
        6'h28: inst <= `INST_SB;
        6'h29: inst <= `INST_SH;
        6'h2a: inst <= `INST_SWL;
        6'h2b: inst <= `INST_SW;
        6'h2e: inst <= `INST_SWR;        
        default: inst <= `INST_INVALID;
        endcase
    end

endmodule

`endif
