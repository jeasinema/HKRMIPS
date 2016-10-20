/*-----------------------------------------------------
 File Name : id_r.v
 Purpose : decode R-type inst
 Creation Date : 18-10-2016
 Last Modified : Wed Oct 19 14:26:47 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __ID_R_V__
`define __ID_R_V__

`timescale 1ns/1ps

`include "../defs.v"

module id_r(/*autoarg*/
    //Inputs
    clk, rst_n, inst_code, 

    //Outputs
    inst, reg_s, reg_t, reg_d, shift
);

    input wire clk;
    input wire rst_n;
    
    input wire[31:0] inst_code;
    output reg[7:0] inst;
    output wire[4:0] reg_s;
    output wire[4:0] reg_t;
    output wire[4:0] reg_d;
    output wire[4:0] shift;
    
    // decode the 32-bit width inst code     
    assign reg_s = inst_code[25:21];
    assign reg_t = inst_code[20:16];
    assign reg_d = inst_code[15:11];
    assign shift = inst_code[10:6];

    always @(*)
    begin
        // R-Type:SPECIAL
        if (inst_code[31:26] == 6'b000000) 
        begin
            case (inst_code[5:0])
            6'h00: inst <= `INST_SLL; 
            6'h02: inst <= `INST_SRL; 
            6'h03: inst <= `INST_SRA; 
            6'h04: inst <= `INST_SLLV;
            6'h06: inst <= `INST_SRLV;
            6'h07: inst <= `INST_SRAV;
            6'h08: inst <= `INST_JR;
            6'h09: inst <= `INST_JALR;
            6'h0a: inst <= `INST_MOVZ;
            6'h0b: inst <= `INST_MOVN;
            6'h0c: inst <= `INST_SYSCALL;
            6'h0d: inst <= `INST_BREAK;
            6'h10: inst <= `INST_MFHI;
            6'h11: inst <= `INST_MTHI;
            6'h12: inst <= `INST_MFLO;
            6'h13: inst <= `INST_MTLO;
            6'h18: inst <= `INST_MULT;
            6'h19: inst <= `INST_MULTU;
            6'h1a: inst <= `INST_DIV;
            6'h1b: inst <= `INST_DIVU;
            6'h20: inst <= `INST_ADD;
            6'h21: inst <= `INST_ADDU;
            6'h21: inst <= `INST_SUB;
            6'h23: inst <= `INST_SUBU;
            6'h24: inst <= `INST_AND;
            6'h25: inst <= `INST_OR;
            6'h26: inst <= `INST_XOR;
            6'h27: inst <= `INST_NOR;
            6'h2a: inst <= `INST_SLT;
            6'h2b: inst <= `INST_SLTU;  
            default: inst <= `INST_INVALID; 
            endcase
        end
        // R-Type:SPECIAL2
        else if (inst_code[31:26] == 6'b011100)  
        begin
            case (inst_code[5:0])
            6'h02: inst <= `INST_MUL;
            6'h20: inst <= `INST_CLZ;
            6'h21: inst <= `INST_CLO;
            default: inst <= `INST_INVALID; 
            endcase
        end   
        else 
            inst <= `INST_INVALID;
    end

endmodule

`endif
