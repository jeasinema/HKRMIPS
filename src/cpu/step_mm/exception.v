/*-----------------------------------------------------
 File Name : exception.v
 Purpose : exception detector and handler
 Creation Date : 21-10-2016
 Last Modified : Fri Oct 28 20:15:42 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __EXCEPTION_V__
`define __EXCEPTION_V__

`timescale 1ns/1ns

module exception(/*autoarg*/
    //Inputs
    clk, rst_n, iaddr_exp_miss, iaddr_exp_invalid, 
    iaddr_exp_illegal, daddr_exp_miss, daddr_exp_invalid, 
    daddr_exp_illegal, daddr_exp_dirty, data_we, 
    invalid_inst, syscall, eret, overflow, 
    restrict_priv_inst, interrupt_mask, hardware_int, 
    software_int, pc_value, in_delayslot, 
    allow_int, is_real_inst, mem_access_vaddr, 
    if_asid, mm_asid, ebase_in, epc_in, special_int_vec, 
    boot_exp_vec, if_exl, mm_exl, 

    //Outputs
    flush, cp0_in_exp, cp0_clean_exl, exp_epc, 
    exp_code, exp_bad_vaddr, cp0_badv_we, 
    exp_asid, cp0_exp_asid_we, exception_new_pc
);


    parameter NORMAL_EXP_BASEADDR = 32'hBFC00200;

    input wire clk;
    input wire rst_n;

    // exp about memory access
    // illegal -> access kernel mode addr. invalid-> tlb error
    // occurs@if by mmu
    input wire iaddr_exp_miss;  
    input wire iaddr_exp_invalid;
    input wire iaddr_exp_illegal;
    // occurs@mm by mmu  
    input wire daddr_exp_miss;
    input wire daddr_exp_invalid;
    input wire daddr_exp_illegal;
    input wire daddr_exp_dirty;
	// common exp
    input wire data_we; // distinguish whether read/write exp(have different exp code)
    input wire invalid_inst; // invalid exp
    input wire syscall;  // syscall exp
    input wire eret; // return from exp, not real exp
    input wire overflow;  // overflow exp
    input wire restrict_priv_inst;
    // interrupts 
    input wire[7:0] interrupt_mask;
	input wire[5:0] hardware_int;
    input wire[1:0] software_int;
 	
	// for calculate return addr
    input wire[31:0] pc_value;
    input wire in_delayslot; 
	// enable/diable interrupts
    input wire allow_int; // control signal from cp0 
    input wire is_real_inst;  // disable interrupt on blob

	// about mem access exp, some need to be stored in CP0_BadVAddr/Context/EntryHi
    input wire[31:0] mem_access_vaddr;
    input wire[7:0] if_asid; 
    input wire[7:0] mm_asid;

    // for calculate exp new pc
	input wire[19:0] ebase_in; 
    input wire[31:0] epc_in;
    input wire special_int_vec; //cp0 reg CAUSE_IV, decided interrupt use exp vector(0x180)/interrupt vector(0x200)
    input wire boot_exp_vec;  // cp0 reg STATUS_BEV, decided exp vector base
    input wire if_exl;  // if in now in exception(kernel mode), disable all exception(exp pc will not changed)
    input wire mm_exl;

    output reg flush;  // when into exp, flush pipeline 
    output reg cp0_in_exp; // 2cp0, whether now is in exp 
    output reg cp0_clean_exl;  // 2cp0, quit exp, clean the status_exl bit
    output reg[31:0] exp_epc;  // 2cp0, store exp return addr
    output reg[4:0] exp_code;  // 2cp0, exp_code
    // 2cp0, about mem access exp, need to be written in cp0 regs
    output reg[31:0] exp_bad_vaddr; 
    output reg cp0_badv_we;
    output reg[7:0] exp_asid;
    output reg cp0_exp_asid_we;

    output reg[31:0] exception_new_pc;  // 2pc, exp handler(service code) addr
    
    wire[31:0] exception_base;
    // different in MIPS32R1/2
    assign exception_base = boot_exp_vec ? NORMAL_EXP_BASEADDR : {ebase_in, 12'b0};  // MIPS32R2
    //assign exception_base = boot_exp_vec ? NORMAL_EXP_BASEADDR : 32'h8000000;  // MIPS32R1

    always @(*) begin
        exp_asid <= 8'b0;
        cp0_in_exp <= 1'b1;
        cp0_clean_exl <= 1'b0;
        cp0_badv_we <= 1'b0;
        cp0_exp_asid_we <= 1'b0;
        flush <= 1'b1;
        exp_epc <= in_delayslot ? (pc_value-32'd4) : pc_value;  // -4/origin
        exp_bad_vaddr <= 32'b0;
        exception_new_pc <= exception_base + 32'h180;  // default is 0x180
        // handle interrupts
        if(is_real_inst && allow_int && ({hardware_int,software_int} & interrupt_mask)!=8'h0) begin
            if(special_int_vec)
                exception_new_pc <= exception_base + 32'h200;
            exp_code <= 5'h00;
            $display("Exception: Interrupt=%x",{hardware_int,software_int});
        end
        // handle mem access exps
        // AdEL
        else if(iaddr_exp_illegal) begin 
            exp_bad_vaddr <= pc_value;
            cp0_badv_we <= 1'b1;
            exp_code <= 5'h04; 
            $display("Exception: Instruction address illegal");
        end
        // TLBL
        else if(iaddr_exp_miss) begin
            if(!if_exl)
                exception_new_pc <= exception_base + 32'h0;
            exp_asid <= if_asid;
            cp0_exp_asid_we <= 1'b1;
            exp_bad_vaddr <= pc_value;
            cp0_badv_we <= 1'b1;
            exp_code <= 5'h02; 
            $display("Exception: Instruction TLB miss");
        end
        // TLBL
        else if(iaddr_exp_invalid) begin
            exp_asid <= if_asid;
            cp0_exp_asid_we <= 1'b1;
            exp_bad_vaddr <= pc_value;
            cp0_badv_we <= 1'b1;
            exp_code <= 5'h02; 
            $display("Exception: Instruction TLB invalid");
        end
        // AdEL(when read) / AdES(when write)
        else if(daddr_exp_illegal) begin
            exp_bad_vaddr <= mem_access_vaddr;
            cp0_badv_we <= 1'b1;
            exp_code <= data_we ? 5'h05 : 5'h04;
            $display("Exception: Data address illegal, WE=%d",data_we);
        end
        // TLBS(when read) / TLBL(when write)
        else if(daddr_exp_miss) begin
            if(!mm_exl)
                exception_new_pc <= exception_base + 32'h0;
            exp_asid <= mm_asid;
            cp0_exp_asid_we <= 1'b1;
            exp_bad_vaddr <= mem_access_vaddr;
            cp0_badv_we <= 1'b1;
            exp_code <= data_we ? 5'h03 : 5'h02;
            $display("Exception: Data TLB miss, WE=%d",data_we);
        end
        // TLBS(when read) / TLBL(when write)
        else if(daddr_exp_invalid) begin
            exp_asid <= mm_asid;
            cp0_exp_asid_we <= 1'b1;
            exp_bad_vaddr <= mem_access_vaddr;
            cp0_badv_we <= 1'b1;
            exp_code <= data_we ? 5'h03 : 5'h02; //TLBS : TLBL
            $display("Exception: Data TLB invalid, WE=%d",data_we);
        end
        // Mod 
        else if(daddr_exp_dirty) begin
            exp_asid <= mm_asid;
            cp0_exp_asid_we <= 1'b1;
            exp_bad_vaddr <= mem_access_vaddr;
            cp0_badv_we <= 1'b1;
            exp_code <= 5'h1; //Mod
            $display("Exception: Data TLB Mod");
        end
        // handle other exps
        // Sys (trap)
        else if(syscall) begin
            exp_code <= 5'h08;
            $display("Exception: Syscall");
        end
        // RI
        else if(invalid_inst) begin
            exp_code <= 5'h0a;
            $display("Exception: RI");
        end
        // CpU
        else if(restrict_priv_inst) begin
            exp_code <= 5'h0b;
            $display("Exception: CpU");
        end
        // Ov
        else if(overflow) begin
            exp_code <= 5'h0c;
            $display("Exception: Ov");
        end
        // return from exps
        else if(eret) begin    
            exp_code <= 5'h00;
            cp0_in_exp <= 1'b0;
            cp0_clean_exl <= 1'b1;
            exception_new_pc <= epc_in;
            $display("Pseudo Exception: ERET");
        end
        else begin
            cp0_in_exp <= 1'b0;
            flush <= 1'b0;
            exp_code <= 5'h00;
        end
    end
endmodule

`endif
