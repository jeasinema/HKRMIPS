/*-----------------------------------------------------
 File Name : cp0.v
 Purpose : top file of cp0
 Creation Date : 18-10-2016
 Last Modified : Wed Nov 16 19:46:41 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __CP0_V__
`define __CP0_V__
`default_nettype none
`timescale 1ns/1ns

module cp0(/*autoarg*/
    //Inputs
    clk, rst_n, rd_addr, rd_sel, we, wr_addr,
    wr_sel, data_i, hardware_int, clean_exl,
    en_exp_i, exp_epc, exp_bd, exp_code,
    exp_bad_vaddr, exp_badv_we, exp_asid,
    exp_asid_we, we_probe, probe_result,
    debugger_rd_addr, debugger_rd_sel,

    //Outputs
    data_o, timer_int, user_mode, ebase,
    epc, tlb_config, allow_int, software_int_o,
    interrupt_mask, special_int_vec, boot_exp_vec,
    asid, in_exl, debugger_data_o
);

    // CP0 registers
    `define CP0_Index {5'd0,3'd0}
    `define CP0_EntryLo0 {5'd2,3'd0}
    `define CP0_EntryLo1 {5'd3,3'd0}
    `define CP0_Context {5'd4,3'd0}
    `define CP0_BadVAddr {5'd8,3'd0}
    `define CP0_Count {5'd9,3'd0}
    `define CP0_EntryHi {5'd10,3'd0}
    `define CP0_Compare {5'd11,3'd0}
    `define CP0_Status {5'd12,3'd0}
    `define CP0_Cause {5'd13,3'd0}
    `define CP0_EPC {5'd14,3'd0}
    `define CP0_PRId {5'd15,3'd0}
    `define CP0_EBase {5'd15,3'd1}
    `define CP0_Config {5'd16,3'd0}
    `define CP0_Config1 {5'd16,3'd1}

    input wire clk;
    input wire rst_n;

    // reg read info, passed in ex
    input wire[4:0] rd_addr;
    input wire[2:0] rd_sel;
    // read cp0 reg val, directly pass to ex
    output wire[31:0] data_o;
    // reg wirte info, passed in wb
    input wire we;
    input wire[4:0] wr_addr;
    input wire[2:0] wr_sel;
    input wire[31:0] data_i;

    // hardware_int = hardware_int_in + timer_int
    input wire[5:0] hardware_int;
    output reg timer_int;

    // for exception and mmu
    output wire user_mode;  // 2mmu
    output wire[19:0] ebase;  // 2exp, for exp pc addr(different in MIPS32R1/R2)
    output wire[31:0] epc;  // 2exp, ouput the return addr store in reg_epc
    output wire[83:0] tlb_config;  // 2mmu
    output wire allow_int; // 2exp, reg_status
    output wire[1:0] software_int_o; // 2exp, 2 software interrupts
    output wire[7:0] interrupt_mask; // 2exp, about the diablling
    output wire special_int_vec; // CAUSE_IV 2exp, for exp pc_addr
    output wire boot_exp_vec; // STATUS_BEV 2exp, for exp_pc_addr
    // gnenrate@if, pass to exp@mm, directly pass to mmu
    output wire[7:0] asid; // 2exp
    output wire in_exl;  // STATUS_EXL 2exp, exp occurs or not

    // about exp
    input wire clean_exl; // from exp, clean in_exl when exp end
    input wire en_exp_i; // from exp, decided if exp occurs(need to set some bits in reg status)
    input wire[31:0] exp_epc; // from exp, store the return addr when exp/interrupt occurs, write into reg_epc
    input wire exp_bd;  // whether exp occurs in delayslot, pass@mm, pass to exp at the same time
    input wire[4:0] exp_code; // from exp, need to set in reg status
    // about mem access exp
    input wire[31:0] exp_bad_vaddr; // from exp
    input wire exp_badv_we;  // from exp
    input wire[7:0] exp_asid;  // frome exp
    input wire exp_asid_we;  // frome exp

    input wire we_probe; // from TLBP@ex, pass@wb
    input wire[31:0] probe_result; // from TLBP@mmu, pass@wb

    input wire[4:0] debugger_rd_addr;
    input wire[2:0] debugger_rd_sel;
    output wire[31:0] debugger_data_o;

    // cp0 register heap
    reg[31:0] cp0_regs_Status;
    reg[31:0] cp0_regs_Cause;
    reg[31:0] cp0_regs_Count;
    reg[31:0] cp0_regs_Compare;
    reg[31:0] cp0_regs_Context;
    reg[31:0] cp0_regs_EPC;
    reg[31:0] cp0_regs_EBase;
    reg[31:0] cp0_regs_EntryLo1;
    reg[31:0] cp0_regs_EntryLo0;
    reg[31:0] cp0_regs_EntryHi;
    reg[31:0] cp0_regs_Index;
    reg[31:0] cp0_regs_BadVAddr;
    reg[31:0] cp0_regs_Config;

    // cp0 reg access addr(normal vs. debugger)
    wire[7:0] rd_addr_internal[0:1];
    // cp0 output addr(normal vs. debugger)
    reg[31:0] data_o_internal[0:1];

    /// for timer interrupt, useless, using reg_count instead
    reg[7:0] timer_count;

    assign rd_addr_internal[0] = {rd_addr,rd_sel};
    assign data_o = data_o_internal[0];
    assign rd_addr_internal[1] = {debugger_rd_addr,debugger_rd_sel};
    assign debugger_data_o = data_o_internal[1];

    assign user_mode = cp0_regs_Status[4:1]==4'b1000;
    assign ebase = {2'b10, cp0_regs_EBase[29:12]};
    assign epc = cp0_regs_EPC;
    assign tlb_config = {
        cp0_regs_EntryHi[7:0],
        cp0_regs_EntryLo1[0] & cp0_regs_EntryLo0[0],
        cp0_regs_EntryHi[31:13],
        cp0_regs_EntryLo1[29:6],
        cp0_regs_EntryLo1[2:1],
        cp0_regs_EntryLo0[29:6],
        cp0_regs_EntryLo0[2:1],
        cp0_regs_Index[3:0]
    };
    assign allow_int = cp0_regs_Status[2:0]==3'b001; // cpu not run in kernel mode, interrupts is enable, exp/interrupts occurs, cpu into kernel mode
    assign software_int_o = cp0_regs_Cause[9:8];  // for two software interrupts(10, 01)
    assign interrupt_mask = cp0_regs_Status[15:8];  // control the enabling of all the interrupts
    assign special_int_vec = cp0_regs_Cause[23];  // (CAUSE_IV)exp vector offset: special(+0x200) or genaral(+0x180)
    assign boot_exp_vec = cp0_regs_Status[22];  // (STATUS_BEV)exp vector location: normal or bootsrap
    assign asid = cp0_regs_EntryHi[7:0];
    assign in_exl = cp0_regs_Status[1];  // (STATUS_EXL) exception occurs or not


    // output reg value
    // 2 mode: normal / debugger
    genvar read_i;
    generate
    for (read_i = 0; read_i < 2; read_i=read_i+1) begin : cp0_read

        always @(*) begin
            if (!rst_n) begin
                data_o_internal[read_i] <= 32'b0;
            end
            else
                case(rd_addr_internal[read_i])
                `CP0_Compare: begin
                    data_o_internal[read_i] <= cp0_regs_Compare;
                end
                `CP0_Count: begin
                    data_o_internal[read_i] <= cp0_regs_Count;
                end
                `CP0_EBase: begin
                    data_o_internal[read_i] <= {2'b10, cp0_regs_EBase[29:12], 12'b0};
                end
                `CP0_EPC: begin
                    data_o_internal[read_i] <= cp0_regs_EPC;
                end
                `CP0_BadVAddr: begin
                    data_o_internal[read_i] <= cp0_regs_BadVAddr;
                end
                `CP0_Cause: begin
                    data_o_internal[read_i] <= {cp0_regs_Cause[31],7'b0,cp0_regs_Cause[23],7'b0, hardware_int, cp0_regs_Cause[9:8], 1'b0, cp0_regs_Cause[6:2], 2'b00};
                end
                `CP0_Status: begin
                    data_o_internal[read_i] <= cp0_regs_Status;
                end
                `CP0_Context: begin
                    data_o_internal[read_i] <= {cp0_regs_Context[31:4], 4'b0};
                end
                `CP0_EntryHi: begin
                    data_o_internal[read_i] <= {cp0_regs_EntryHi[31:13], 5'b0, cp0_regs_EntryHi[7:0]};
                end
                `CP0_EntryLo0: begin
                    data_o_internal[read_i] <= {2'b0, cp0_regs_EntryLo0[29:6], 3'b0, cp0_regs_EntryLo0[2:0]};
                end
                `CP0_EntryLo1: begin
                    data_o_internal[read_i] <= {2'b0, cp0_regs_EntryLo1[29:6], 3'b0, cp0_regs_EntryLo1[2:0]};
                end
                `CP0_Index: begin
                    data_o_internal[read_i] <= {cp0_regs_Index[31], 27'b0, cp0_regs_Index[3:0]};
                end
                `CP0_PRId: begin
                    data_o_internal[read_i] <= {8'b0, 8'b1, 16'h8000}; //MIPS32 4Kc
                end
                `CP0_Config: begin
                    data_o_internal[read_i] <= {1'b1, 21'b0, 3'b1, 4'b0, cp0_regs_Config[2:0]}; //Release 1, standard tlb
                end
                `CP0_Config1: begin
                    data_o_internal[read_i] <= {1'b0, 6'd15, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 3'd0, 7'd0}; // 16 tlb entries, no cache
                end
                default:
                    data_o_internal[read_i] <= 32'b0;
                endcase
        end

    end //for
    endgenerate

    // write_enable register, only some bits are writeable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cp0_regs_Count <= 32'b0;
            cp0_regs_Compare <= 32'b0;
            cp0_regs_Status <= 32'h10400004; //BEV=1,ERL=1 is required
            cp0_regs_EBase <= 32'h80000000;
            cp0_regs_Cause[9:8] <= 2'b0;
            cp0_regs_Cause[23] <= 1'b0;
            timer_int <= 1'b0;
            timer_count <= 'b0;
        end
        else begin
            cp0_regs_Count <= cp0_regs_Count+1'b1;
            timer_count <= timer_count + 'b1;
            if(cp0_regs_Compare != 32'b0 && cp0_regs_Compare==cp0_regs_Count)
                timer_int <= 1'b1;
            if(we) begin
                case({wr_addr,wr_sel})
                `CP0_Compare: begin
                    timer_int <= 1'b0;
                    cp0_regs_Compare <= data_i;
                end
                `CP0_Count: begin
                    cp0_regs_Count <= data_i;
                end
                `CP0_EBase: begin
                    cp0_regs_EBase[29:12] <= data_i[29:12]; //only bits 29..12 is writable
                end
                `CP0_EPC: begin
                    cp0_regs_EPC <= data_i;
                end
                `CP0_Cause: begin
                    cp0_regs_Cause[9:8] <= data_i[9:8];
                    cp0_regs_Cause[23] <= data_i[23]; //IV
                end
                `CP0_Status: begin
                    cp0_regs_Status[28] <= data_i[28]; //CU0, cp0 accessiable
                    cp0_regs_Status[22] <= data_i[22]; //BEV
                    cp0_regs_Status[15:8] <= data_i[15:8]; //IM(interrupt mask)
                    cp0_regs_Status[4] <= data_i[4]; //UM(user/kernel mode)
                    cp0_regs_Status[2:0] <= data_i[2:0]; //ERL(if error), EXL(if exp), IE(enable interrupts)
                end
                `CP0_EntryHi: begin
                    cp0_regs_EntryHi[31:13] <= data_i[31:13];
                    cp0_regs_EntryHi[7:0] <= data_i[7:0];
                end
                `CP0_EntryLo0: begin
                    cp0_regs_EntryLo0[29:6] <= data_i[29:6];
                    cp0_regs_EntryLo0[2:0] <= data_i[2:0];
                end
                `CP0_EntryLo1: begin
                    cp0_regs_EntryLo1[29:6] <= data_i[29:6];
                    cp0_regs_EntryLo1[2:0] <= data_i[2:0];
                end
                `CP0_Index: begin
                    cp0_regs_Index[3:0] <= data_i[3:0];
                end
                `CP0_Context: begin
                    cp0_regs_Context[31:23] <= data_i[31:23];
                end
                `CP0_Config: begin
                    cp0_regs_Config[2:0] <= data_i[2:0];
                end

                endcase
            end
            // for TLBP, wrire in result from mmu
            if(we_probe)
                cp0_regs_Index <= probe_result;
            // exp occurs
               if(en_exp_i) begin
                if(exp_badv_we)
                    cp0_regs_BadVAddr <= exp_bad_vaddr;
                cp0_regs_Context[22:4] <= exp_bad_vaddr[31:13];
                cp0_regs_EntryHi[31:13] <= exp_bad_vaddr[31:13];
                if(exp_asid_we)
                    cp0_regs_EntryHi[7:0] <= exp_asid;
                cp0_regs_Status[1] <= 1'b1;  // set STATUS_EXL
                cp0_regs_Cause[31] <= exp_bd; // set whether exp occurs in deleyslot
                cp0_regs_Cause[6:2] <= exp_code;  // set exp code
                cp0_regs_EPC <= exp_epc;  // store return addr
            end
            // for ERET, back from exp
            if(clean_exl) begin
                cp0_regs_Status[1] <= 1'b0;  // clean STATUS_EXL
            end
        end
    end

endmodule

`endif
