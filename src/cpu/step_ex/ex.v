/*-----------------------------------------------------
 File Name : ex.v
 Purpose : step_ex, exec instructions
 Creation Date : 18-10-2016
 Last Modified : Thu Oct 20 11:20:06 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __EX_V__
`define __EX_V__

`timescale 1ns/1ps

`include "../defs.v"

module ex(/*autoarg*/);

    input wire clk;
    input wire rst_n;
    // input wire exception_flush;

    // decoded instruction
    // inst 
    input wire[7:0] inst;
    input wire[1:0] inst_type;
    // operands
    input wire[4:0] reg_s;
    input wire[4:0] reg_t;
    input wire[4:0] reg_d;
    input wire[31:0] reg_s_val;
    input wire[31:0] reg_t_val;
    input wire[31:0] immediate;  
    // output by branch_jump.v, maybe need to put in reg_31 under some circumstances
    input wire[31:0] return_addr;
    //others
    //input wire[31:0] reg_cp0_value;

    // for reg bypass mux, defined in defs.v
    output reg[1:0] mem_access_type;
    // for mmu, defined in defs.v
    output reg[1:0] mem_access_size;
    // ex result
    output reg[31:0] val_output;
    // mem access address in step_mm
    output reg[31:0] mem_access_addr;
    // address of the reg(store the val of result in ex), which should be bypass to mux
    output reg[4:0] bypass_reg_addr; 
    output reg overflow;
    // stall the pipeline when ex do multi-cycle jobs like div
    output reg stall_for_mul_cycle;
    // set if inst is a priority instruction(should be handle by cp0)
    output reg is_priv_inst;
    
    // @jzh14, signals following are your jobs now.
    //output reg we_cp0;
    //output reg[4:0] cp0_wr_addr;
    //output reg[4:0] cp0_rd_addr;
    //output reg[2:0] cp0_sel;
    //output wire syscall;
    //output wire eret;
    //output wire we_tlb;
    //output wire probe_tlb;
    //input wire[31:0] reg_cp0_value;
    //input wire[63:0] reg_hilo_value;
    //output reg[63:0] reg_hilo_o;
    //output reg we_hilo;

    // essentail signals for exec:
    // sign-extended 32bit width immediate
    wire[31:0] sign_ext_immediate;
    wire sign_bit_immediate;
    // zero-extended 32bit width immediate
    wire[31:0] zero_ext_immediate;
    // ...


    
    // assign area
    assign sign_bit_immediate = immediate[15];
    assign sign_ext_immediate = { 
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                sign_bit_immediate,
                                immediate
                                };
    assign zero_ext_immediate = { 16'b0, immediate};


    // normal instructions, without mem access, branch, jump
    always @(*)
    begin
        overflow <= 1'b0;  // just set it to correct val later
        case(inst):
        `INST_ADDU:
        `INST_ADDIU:
        begin
            
        end
        `INST_AND:
        `INST_ANDI:
        begin

        end
        `INST_DIVU:
        begin

        end
        `INST_MULT:
        begin
            
        end
        `INST_SUBU:
        begin

        end
        `INST_SLT:
        `INST_SLTU:  
        `INST_SLTI:
        `INST_SLTIU:
        begin

        end
        `INST_OR:
        `INST_ORI:
        begin

        end
        `INST_XOR:
        `INST_XORI:
        begin

        end
        `INST_NOR:
        begin
            
        end
        `INST_LUI:
        begin

        end
        `INST_SLL: 
        `INST_SLLV:
        begin

        end
        `INST_SRA: 
        `INST_SRAV:
        begin

        end
        `INST_SRL: 
        `INST_SRLV:
        begin

        end
        `INST_MFHI:
        begin

        end
        `INST_MTHI:
        begin

        end
        `INST_MFLO:
        begin

        end
        `INST_MTLO:
        begin

        end
        `INST_SYSCALL:
        begin

        end
        `INST_BREAK:
        begin

        end
        // need to put mem target register 
       `INST_LB, `INST_LH, `INST_LWL, `INST_LW, `INST_LBU, `INST_LHU, `INST_LWR:   // `INST_LL
        begin
            val_output  <= reg_t_val;
            reg_addr <= reg_t; 
        end
       `INST_SB, `INST_SH, `INST_SWL, `INST_SW, `INST_SWR:                         // `INST_SC
        begin
            val_output  <= reg_t_val;
            reg_addr <= reg_t; 
        end
        default:
        begin
            val_output <= 32'h0;
            bypass_reg_addr <= 5'h0;
        end
        endcase
    end

    // instruction that need to put return address to specific reg, branch or jump works are done in step_id/branch_jump.v
    always @(*)
    begin
        case(inst):
        // `INST_BAL:
        // `INST_BGEZAL:
        // `INST_BGEZALL:
        // `INST_BLTZAL:
        // `INST_BLTZALL:
        `INST_JAL:
        begin
            val_output <= return_addr;
            bypass_reg_addr <= 5'b31; // need to put return address into reg_31 
        end
        `INST_JALR:
        begin
            val_output <= return_addr;
            bypass_reg_addr <= reg_d; // need to put return address into selected reg
        end
        default:
        begin
            val_output <= 32'h0;
            bypass_reg_addr <= 5'h0;
        end
        endcase
    end

    // set mem access addr and direction
    always @(*)
    begin
        case(inst):
        `INST_LB:
        `INST_LBU:
        `INST_LH:
        `INST_LHU:
        `INST_LW:
        `INST_LWL:
        `INST_LWR:
        begin
            mem_access_addr <= reg_s_val + sign_ext_immediate; 
            mem_access_type <= `MEM_ACCESS_TYPE_M2R;
        end
        `INST_SB:
        `INST_SH:
        `INST_SW:
        `INST_SWL:
        `INST_SWR:
        begin
            mem_access_addr <= reg_s_val + sign_ext_immediate; 
            mem_access_type <= `MEM_ACCESS_TYPE_R2M;
        end
        default:
        begin
            mem_access_addr <= 32'h0;
            mem_access_type <= `MEN_ACCESS_TYPE_R2R;
        end
        endcase
    end

    // set mem access type
    always @(*)
    begin
        case(inst):
        `INST_LB:
        `INST_LBU:
        `INST_SB:
                mem_access_sz <= `MEM_ACCESS_LENGTH_BYTE;
        `INST_LH:
        `INST_LHU:
        `INST_SH:
                mem_access_sz <= `MEM_ACCESS_LENGTH_HALF;
        `INST_LWL:
        `INST_SWL:
                mem_access_sz <= `MEM_ACCESS_LENGTH_LEFT_WORD;
        `INST_LWR:
        `INST_SWR:
                mem_access_sz <= `MEM_ACCESS_LENGTH_RIGHT_WORD;
        // LW & SW
        default:
                mem_access_sz <= `MEM_ACCESS_LENGTH_WORD;
        endcase
    end

    // manage priority instructions(cp0)
    always @(*)
    begin
        case(inst):
        `INST_MFC0:
        `INST_MTC0:
        `INST_WAIT:
        `INST_TLBWI:
        `INST_TLBP:
        `INST_ERET:
            is_priv_inst <= 1'b1;
        default:
            is_priv_inst <= 1'b0;
        endcase
    end


endmodule

`endif
