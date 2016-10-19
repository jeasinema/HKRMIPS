/*-----------------------------------------------------
 File Name : defs.v
 Purpose : some basic macros for cpu
 Creation Date : 18-10-2016
 Last Modified : Wed Oct 19 12:54:45 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __DEFS_V__
`define __DEFS_V__

`timescale 1ns/1ps

// specify the instruction type
// used for id
`define INST_TYPE_R 2'd0
`define INST_TYPE_I 2'd1
`define INST_TYPE_J 2'd2
`define INST_TYPE_INVALID 2'd3

// specify the instructions
// used for id
`define INST_ADDIU 8'd0
`define INST_ADDU 8'd1
`define INST_AND 8'd2
`define INST_ANDI 8'd3
`define INST_BEQ 8'd4
`define INST_BEQZ 8'd5
`define INST_BGEZ 8'd6
`define INST_BGTZ 8'd7
`define INST_BLEZ 8'd8
`define INST_BLTZ 8'd9
`define INST_BNE 8'd10
`define INST_BNEZ 8'd11
`define INST_BREAK 8'd12
`define INST_DIVU 8'd13
`define INST_ERET 8'd14
`define INST_J 8'd15
`define INST_JAL 8'd16
`define INST_JALR 8'd17
`define INST_JR 8'd18
`define INST_LB 8'd19
`define INST_LBU 8'd20
`define INST_LH 8'd21
`define INST_LHU 8'd22
`define INST_LUI 8'd23
`define INST_LW 8'd24
`define INST_LWL 8'd25
`define INST_LWR 8'd26
`define INST_MFC0 8'd27
`define INST_MFHI 8'd28
`define INST_MFLO 8'd29
`define INST_MTC0 8'd30
`define INST_MTHI 8'd31
`define INST_MTLO 8'd32
`define INST_MULT 8'd33
`define INST_NEGU 8'd34
`define INST_NOR 8'd35
`define INST_OR 8'd36
`define INST_ORI 8'd37
`define INST_SB 8'd38
`define INST_SH 8'd39
`define INST_SLL 8'd40
`define INST_SLLV 8'd41
`define INST_SLT 8'd42
`define INST_SLTI 8'd43
`define INST_SLTIU 8'd44
`define INST_SLTU 8'd45
`define INST_SRA 8'd46
`define INST_SRAV 8'd47
`define INST_SRL 8'd48
`define INST_SRLV 8'd49
`define INST_SUBU 8'd50
`define INST_SW 8'd51
`define INST_SWL 8'd52
`define INST_SWR 8'd53
`define INST_SYSCALL 8'd54
`define INST_TLBWI 8'd55
`define INST_XOR 8'd56
`define INST_XORI 8'd57

`define INST_INVALID 8'hff

// specify the type how an instruction accesses register and memory
// used for mm and reg_bypass_mux
`define ACCESS_TYPE_R2R 2'd0 // inst that set register value in EX 
`define ACCESS_TYPE_R2M 2'd1 // inst that put register value to memory in MM 
`define ACCESS_TYPE_M2R 2'd2 // inst that put memory value to register in MM  

// specify the type how an instruction accesses memory
// used for mm
`define MEM_ACCESS_WORD 3'd0
`define MEM_ACCESS_HALF 3'd1
`define MEM_ACCESS_BYTE 3'd2
`define MEM_ACCESS_LEFT 3'd3
`define MEM_ACCESS_RIGHT 3'd4

`endif
