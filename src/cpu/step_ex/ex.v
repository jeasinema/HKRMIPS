/*-----------------------------------------------------
 File Name : ex.v
 Purpose : step_ex, exec instructions
 Creation Date : 18-10-2016
 Last Modified : Wed Nov 16 19:45:13 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __EX_V__
`define __EX_V__
`default_nettype none
`timescale 1ns/1ns

`include "../defs.v"

module ex(/*autoarg*/
    //Inputs
    clk, rst_n, exception_flush, inst, inst_type,
    reg_s, reg_t, reg_d, reg_s_val, reg_t_val,
    immediate, shift, jump_addr, return_addr,
    reg_cp0_val, reg_hilo_val,

    //Outputs
    mem_access_type, mem_access_size, mem_access_signed,
    mem_access_addr, val_output, bypass_reg_addr,
    overflow, stall_for_mul_cycle, is_priv_inst,
    inst_syscall, inst_eret, inst_tlbwi,
    inst_tlbp, cp0_write_enable, cp0_write_addr,
    cp0_read_addr, cp0_sel, reg_hilo_o, hilo_write_enable
);

    input wire clk;
    input wire rst_n;
    input wire exception_flush;

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
    input wire[15:0] immediate;
    input wire[4:0] shift;
    input wire[25:0] jump_addr;
    // output by branch_jump.v, maybe need to put in reg_31 under some circumstances
    input wire[31:0] return_addr;

    // for reg bypass mux, defined in defs.v
    output reg[1:0] mem_access_type;
    // for mmu, defined in defs.v
    output reg[2:0] mem_access_size;
    // for mm, decide if we get signed/unsigned data
    output reg mem_access_signed;
    // mem access address in step_mm
    output reg[31:0] mem_access_addr;

    // ex result
    output reg[31:0] val_output;
    // address of the reg(store the val of result in ex), which should be bypass to mux and mm
    output reg[4:0] bypass_reg_addr;

    // for spec instructions
    output reg overflow;
    // stall the pipeline when ex do multi-cycle jobs like div
    output reg stall_for_mul_cycle;
    // set if inst is a priority instruction(should be handle by cp0)
    output reg is_priv_inst;
    // for SYSCALL ERET TLBWI TLBP
    output wire inst_syscall;
    output wire inst_eret;
    // we_tlb
    output wire inst_tlbwi;
    // probe_tlb
    output wire inst_tlbp;

    // for CP0 access instructions: MTC0 MFC0
    // MTC0: need to enable that, pass to cp0 in *step_wb*
    output reg cp0_write_enable;
    // MTC0: write reg addr in CP0, passed in wb
    output reg[4:0] cp0_write_addr;
    // MFC0: read reg addr in CP0, passed in ex(combinantial logic)
    output reg[4:0] cp0_read_addr;
    // MF/TC0: sel for CP0, passed in ex(combinantial logic)
    output reg[2:0] cp0_sel;
    // MFC0: reg read result, passed in ex(combinantial logic)
    input wire[31:0] reg_cp0_val;

    // for DIV/MULT(U) MF/TLO/HI, can get from mm/wb/reg, decided by we
    input wire[63:0] reg_hilo_val;
    output reg[63:0] reg_hilo_o;
    output reg hilo_write_enable;

    // essential signals for exec:
    // sign-extended 32bit width immediate
    wire[31:0] sign_ext_immediate;
    wire sign_bit_immediate;
    // zero-extended 32bit width immediate
    wire[31:0] zero_ext_immediate;
    // for multi_cycle_calc
    wire multi_cycle_done;
    wire[63:0] multi_cycle_result;

    // intermediate variables for add/sub/slt
    wire[31:0] op1_i;
    wire[31:0] op2_i;
    wire[31:0] op2_i_mux;
    wire[31:0] op1_i_not;
    wire[31:0] result_sum;
    wire ov_sum;
    wire op1_lt_op2;
    // intermediate variables for mul/mult/multu
    wire[31:0] opdata1_mult;
    wire[31:0] opdata2_mult;
    wire[63:0] hilo_temp;
    reg[63:0] mulres;
    // intermediate variables for madd/maddu/msub/msubu
    reg[63:0] hilo_temp_for_madd_msub;

    // assign area
    assign inst_syscall = (inst == `INST_SYSCALL);
    assign inst_eret = (inst == `INST_ERET);
    assign inst_tlbwi = (inst == `INST_TLBWI);
    assign inst_tlbp = (inst == `INST_TLBP);
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

    // assign variables for add/sub/slt
    assign op1_i = reg_s_val;
    assign op2_i = ((inst == `INST_SLT) ||
                    (inst == `INST_SLTU) ||
                    (inst == `INST_ADD) ||
                    (inst == `INST_ADDU) ||
                    (inst == `INST_SUB) ||
                    (inst == `INST_SUBU) ||
                    (inst == `INST_MULT) ||
                    (inst == `INST_MULTU) ||
                    (inst == `INST_MUL)) ? reg_t_val :
                   (((inst == `INST_SLTI) ||
                    (inst == `INST_SLTIU) ||
                    (inst == `INST_ADDI) ||
                    (inst == `INST_ADDIU)) ? sign_ext_immediate : 32'h0);
    assign op2_i_mux = ((inst == `INST_SUB) ||
                        (inst == `INST_SUBU) ||
                        (inst == `INST_SLT) ||
                        (inst == `INST_SLTI)) ?
                        (~op2_i) + 1 : op2_i;
    assign result_sum = op1_i + op2_i_mux;
    assign ov_sum = ((!op1_i[31] && !op2_i[31]) && result_sum[31]) || ((op1_i[31] && op2_i_mux[31]) && (!result_sum[31]));
    assign op1_lt_op2 = ((inst == `INST_SLT) || (inst == `INST_SLTI)) ?
                        ((op1_i[31] && !op2_i[31]) ||
                         (!op1_i[31] && !op2_i[31] && result_sum[31]) ||
                         (op1_i[31] && op2_i[31] && result_sum[31])) :
                        (op1_i < op2_i);
    assign op1_i_not = ~op1_i;

    // assign variables for mul/mult/multu
    assign opdata1_mult = ((inst == `INST_MUL) || (inst == `INST_MULT) ||
                           (inst == `INST_MADD) || (inst == `INST_MSUB)) && (op1_i[31] == 1'b1) ? (~op1_i + 1) : op1_i;
    assign opdata2_mult = ((inst == `INST_MUL) || (inst == `INST_MULT) ||
                           (inst == `INST_MADD) || (inst == `INST_MSUB)) && (op2_i[31] == 1'b1) ? (~op2_i + 1) : op2_i;
    assign hilo_temp = opdata1_mult * opdata2_mult;

    // get MUL/MULT/MULTU result from hilo_temp;
    always @ (*) begin
        if(!rst_n) begin
            mulres <= 64'h0;
        end else if ((inst == `INST_MUL) || (inst == `INST_MULT) ||
                     (inst == `INST_MADD) || (inst == `INST_MSUB)) begin
            if(op1_i[31] ^ op2_i[31] == 1'b1) begin
                mulres <= ~hilo_temp + 1;
            end else begin
                mulres <= hilo_temp;
            end
        end else begin
              mulres <= hilo_temp;
        end
    end

    multi_cycle multi_cycle_calc(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

    .exception_flush            (exception_flush                ), // input
    .inst                       (inst[7:0]                      ), // input
    .op1                        (reg_s_val[31:0]                ), // input
    .op2                        (reg_t_val[31:0]                ), // input
    .hilo_i                     (reg_hilo_val[63:0]             ), // input

    .result                     (multi_cycle_result[63:0]       ), // output
    .multi_cycle_done           (multi_cycle_done               )  // output
    );

    // normal instructions, without mem access, branch, jump
    always @(*)
    begin
        val_output <= 32'b0;
        bypass_reg_addr <= 5'h0;
        overflow <= 1'b0;  // just set it to correct val later
        cp0_write_enable <= 1'b0;
        cp0_write_addr <= 5'b0;
        cp0_read_addr <= 5'b0;
        cp0_sel <= 3'b0;
        reg_hilo_o <= 64'b0;
        hilo_write_enable <= 1'b0;
        stall_for_mul_cycle <= !multi_cycle_done;
        if (!rst_n) begin
            val_output <= 32'h0;
            bypass_reg_addr <= 5'h0;
        end else begin
            case(inst)
            `INST_ADDU,
            `INST_SUBU:
            begin
                val_output <= result_sum;
                bypass_reg_addr <= reg_d;
            end
            `INST_ADD,
            `INST_SUB:
            begin
                if (ov_sum == 1'b1) begin
                    overflow <= 1'b1;
                    val_output <= 32'b0;
                    bypass_reg_addr <= 5'h0;
                end
                else begin
                    overflow <= 1'b0;
                    val_output <= result_sum;
                    bypass_reg_addr <= reg_d;
                end
            end
            `INST_ADDIU:
            begin
                val_output <= result_sum;
                bypass_reg_addr <= reg_t;
            end
            `INST_ADDI:
            begin
                if (ov_sum == 1'b1) begin
                    overflow <= 1'b1;
                    val_output <= 32'b0;
                    bypass_reg_addr <= 5'h0;
                end
                else begin
                    overflow <= 1'b0;
                    val_output <= result_sum;
                    bypass_reg_addr <= reg_t;
                end
            end
            `INST_AND:
            begin
                val_output <= reg_s_val & reg_t_val;
                bypass_reg_addr <= reg_d;
            end
            `INST_ANDI:
            begin
                val_output <= reg_s_val & zero_ext_immediate;
                bypass_reg_addr <= reg_t;
            end
            `INST_MADD,
            `INST_MADDU,
            `INST_MSUB,
            `INST_MSUBU,
            `INST_DIV,
            `INST_DIVU:
            begin
                reg_hilo_o <= multi_cycle_result;
                hilo_write_enable <= multi_cycle_done;
                val_output <= 32'h0;
                bypass_reg_addr <= 5'h0;
            end
            `INST_MULT,
            `INST_MULTU:
            begin
                hilo_write_enable <= 1'b1;
                reg_hilo_o <= mulres;
                bypass_reg_addr <= 5'h0;
                val_output <= 32'h0;
            end
            `INST_MUL:
            begin
                val_output <= mulres[31:0];
                bypass_reg_addr <= reg_d;
            end
            `INST_SLT,
            `INST_SLTU:
            begin
                val_output <= op1_lt_op2;
                bypass_reg_addr <= reg_d;
            end
            `INST_SLTI,
            `INST_SLTIU:
            begin
                val_output <= op1_lt_op2;
                bypass_reg_addr <= reg_t;
            end
            `INST_CLZ:
            begin
                val_output <= op1_i[31] ? 0 : op1_i[30] ? 1 : op1_i[29] ? 2 :
                              op1_i[28] ? 3 : op1_i[27] ? 4 : op1_i[26] ? 5 :
                              op1_i[25] ? 6 : op1_i[24] ? 7 : op1_i[23] ? 8 :
                              op1_i[22] ? 9 : op1_i[21] ? 10 : op1_i[20] ? 11 :
                              op1_i[19] ? 12 : op1_i[18] ? 13 : op1_i[17] ? 14 :
                              op1_i[16] ? 15 : op1_i[15] ? 16 : op1_i[14] ? 17 :
                              op1_i[13] ? 18 : op1_i[12] ? 19 : op1_i[11] ? 20 :
                              op1_i[10] ? 21 : op1_i[9] ? 22 : op1_i[8] ? 23 :
                              op1_i[7] ? 24 : op1_i[6] ? 25 : op1_i[5] ? 26 :
                              op1_i[4] ? 27 : op1_i[3] ? 28 : op1_i[2] ? 29 :
                              op1_i[1] ? 30 : op1_i[0] ? 31 : 32;
                bypass_reg_addr <= reg_d;
            end
            `INST_CLO:
            begin
                val_output <= op1_i_not[31] ? 0 : op1_i_not[30] ? 1 : op1_i_not[29] ? 2 :
                              op1_i_not[28] ? 3 : op1_i_not[27] ? 4 : op1_i_not[26] ? 5 :
                              op1_i_not[25] ? 6 : op1_i_not[24] ? 7 : op1_i_not[23] ? 8 :
                              op1_i_not[22] ? 9 : op1_i_not[21] ? 10 : op1_i_not[20] ? 11 :
                              op1_i_not[19] ? 12 : op1_i_not[18] ? 13 : op1_i_not[17] ? 14 :
                              op1_i_not[16] ? 15 : op1_i_not[15] ? 16 : op1_i_not[14] ? 17 :
                              op1_i_not[13] ? 18 : op1_i_not[12] ? 19 : op1_i_not[11] ? 20 :
                              op1_i_not[10] ? 21 : op1_i_not[9] ? 22 : op1_i_not[8] ? 23 :
                              op1_i_not[7] ? 24 : op1_i_not[6] ? 25 : op1_i_not[5] ? 26 :
                              op1_i_not[4] ? 27 : op1_i_not[3] ? 28 : op1_i_not[2] ? 29 :
                              op1_i_not[1] ? 30 : op1_i_not[0] ? 31 : 32;
                bypass_reg_addr <= reg_d;
            end
            `INST_OR:
            begin
                val_output <= reg_s_val | reg_t_val;
                bypass_reg_addr <= reg_d;
            end
            `INST_ORI:
            begin
                val_output <= reg_s_val | zero_ext_immediate;
                bypass_reg_addr <= reg_t;
            end
            `INST_XOR:
            begin
                val_output <= reg_s_val ^ reg_t_val;
                bypass_reg_addr <= reg_d;
            end
            `INST_XORI:
            begin
                val_output <= reg_s_val ^ zero_ext_immediate;
                bypass_reg_addr <= reg_t;
            end
            `INST_NOR:
            begin
                val_output <= ~(reg_s_val | reg_t_val);
                bypass_reg_addr <= reg_d;
            end
            `INST_LUI:
            begin
                val_output <= {immediate, 16'h0};
                bypass_reg_addr <= reg_t;
            end
            `INST_SLL:
            begin
                val_output <= reg_t_val << shift;
                bypass_reg_addr <= reg_d;
            end
            `INST_SLLV:
            begin
                val_output <= reg_t_val << reg_s_val[4:0];
                bypass_reg_addr <= reg_d;
            end
            `INST_SRA:
            begin
                val_output <= ({32{reg_t_val[31]}} << (6'd32 - {1'b0, shift})) | (reg_t_val >> shift);
                bypass_reg_addr <= reg_d;
            end
            `INST_SRAV:
            begin
                val_output <= ({32{reg_t_val[31]}} << (6'd32 - {1'b0, reg_s_val[4:0]})) | (reg_t_val >> reg_s_val[4:0]);
                bypass_reg_addr <= reg_d;
            end
            `INST_SRL:
            begin
                val_output <= reg_t_val >> shift;
                bypass_reg_addr <= reg_d;
            end
            `INST_SRLV:
            begin
                val_output <= reg_t_val >> reg_s_val[4:0];
                bypass_reg_addr <= reg_d;
            end
            `INST_MFHI:
            begin
                val_output <= reg_hilo_val[63:32];
                bypass_reg_addr <= reg_d;
            end
            `INST_MTHI:
            begin
                reg_hilo_o <= {reg_s_val, reg_hilo_val[31:0]};
                hilo_write_enable <= 1'b1;
                val_output <= 32'h0;
                bypass_reg_addr <= 5'b0;
            end
            `INST_MFLO:
            begin
                val_output <= reg_hilo_val[31:0];
                bypass_reg_addr <= reg_d;
            end
            `INST_MTLO:
            begin
                reg_hilo_o <= {reg_hilo_val[63:32], reg_s_val};
                hilo_write_enable <= 1'b1;
                val_output <= 32'h0;
                bypass_reg_addr <= 5'b0;
            end
            `INST_MOVZ:
            begin
                val_output <= reg_s_val;
                if (reg_t_val == 0)
                begin
                    bypass_reg_addr <= reg_d;
                end
                else begin
                    bypass_reg_addr <= 5'h0;
                end
            end
            `INST_MOVN:
            begin
                val_output <= reg_s_val;
                if (reg_t_val != 0)
                begin
                    bypass_reg_addr <= reg_d;
                end
                else begin
                    bypass_reg_addr <= 5'h0;
                end
            end
            // need to put mem target register
           `INST_LB, `INST_LH, `INST_LWL, `INST_LW, `INST_LBU, `INST_LHU, `INST_LWR:   // `INST_LL
            begin
                val_output  <= reg_t_val;
                bypass_reg_addr <= reg_t;
            end
           `INST_SB, `INST_SH, `INST_SWL, `INST_SW, `INST_SWR:                         // `INST_SC
            begin
                val_output  <= reg_t_val;
                bypass_reg_addr <= reg_t;
            end
            `INST_MFC0:
            begin
                cp0_read_addr <= reg_d;
                cp0_sel <= immediate[2:0];
                val_output <= reg_cp0_val;
                bypass_reg_addr <= reg_t;
            end
            `INST_MTC0:
            begin
                cp0_write_enable <= 1'b1;
                cp0_write_addr <= reg_d;
                cp0_sel <= immediate[2:0];
                val_output <= reg_t_val;
                bypass_reg_addr <= 5'b0;
            end
            // instruction that need to put return address to specific reg, branch or jump works are done in step_id/branch_jump.v
            `INST_BGEZAL,
            `INST_BLTZAL,
            `INST_JAL:
            begin
                val_output <= return_addr;
                bypass_reg_addr <= 5'd31; // need to put return address into reg_31
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
    end

    // set mem access addr and direction
    always @(*)
    begin
        case(inst)
        `INST_LB,
        `INST_LBU,
        `INST_LH,
        `INST_LHU,
        `INST_LW,
        `INST_LWL,
        `INST_LWR:
        begin
            mem_access_addr <= reg_s_val + sign_ext_immediate;
            mem_access_type <= `MEM_ACCESS_TYPE_M2R;
        end
        `INST_SB,
        `INST_SH,
        `INST_SW,
        `INST_SWL,
        `INST_SWR:
        begin
            mem_access_addr <= reg_s_val + sign_ext_immediate;
            mem_access_type <= `MEM_ACCESS_TYPE_R2M;
        end
        default:
        begin
            mem_access_addr <= 32'h0;
            mem_access_type <= `MEM_ACCESS_TYPE_R2R;
        end
        endcase
    end

    // set mem access type
    always @(*)
    begin
        case(inst)
        `INST_LB,
        `INST_LBU,
        `INST_SB:
                mem_access_size <= `MEM_ACCESS_LENGTH_BYTE;
        `INST_LH,
        `INST_LHU,
        `INST_SH:
                mem_access_size <= `MEM_ACCESS_LENGTH_HALF;
        `INST_LWL,
        `INST_SWL:
                mem_access_size <= `MEM_ACCESS_LENGTH_LEFT_WORD;
        `INST_LWR,
        `INST_SWR:
                mem_access_size <= `MEM_ACCESS_LENGTH_RIGHT_WORD;
        // LW & SW
        default:
                mem_access_size <= `MEM_ACCESS_LENGTH_WORD;
        endcase
    end

    // set mem access signed/unsigned (whether need to do signed-extension)
    always @(*)
    begin
        case(inst)
        `INST_LB,
        `INST_LH,
        `INST_LW,
        `INST_LWL,
        `INST_LWR,
        `INST_SB,
        `INST_SH,
        `INST_SW,
        `INST_SWL,
        `INST_SWR:
            mem_access_signed <= 1'b1;
        `INST_LBU,
        `INST_LHU:
            mem_access_signed <= 1'b0;
        default: mem_access_signed <= 1'b1;
        endcase
    end

    // manage priority instructions(cp0)
    always @(*)
    begin
        case(inst)
        `INST_MFC0,
        `INST_MTC0,
        `INST_WAIT,
        `INST_TLBWI,
        `INST_TLBP,
        `INST_ERET:
            is_priv_inst <= 1'b1;
        default:
            is_priv_inst <= 1'b0;
        endcase
    end


endmodule

`endif
