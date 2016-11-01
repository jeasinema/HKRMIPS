/*-----------------------------------------------------
 File Name : hkr_mips.v
 Purpose : top file for cpu
 Creation Date : 18-10-2016
 Last Modified : Mon Oct 31 23:34:46 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __HKR_MIPS_V__
`define __HKR_MIPS_V__

`timescale 1ns/1ps

`include "defs.v"

module hkr_mips(/*autoarg*/
    //Inputs
    clk, rst_n, hardware_int_in, ibus_read_data, 
    ibus_stall, dbus_read_data, dbus_stall, 

    //Outputs
    ibus_addr, ibus_read, ibus_write, ibus_write_data, 
    ibus_uncached, ibus_byte_en, dbus_addr, 
    dbus_read, dbus_write, dbus_write_data, 
    dbus_uncached, dbus_byte_en
);

    input wire clk;
    input wire rst_n;
    
    // external interrupts input 
    input wire[4:0] hardware_int_in;

    // inst_bus
    output wire[31:0] ibus_addr;
    output wire ibus_read, ibus_write;
    output wire[31:0] ibus_write_data; 
    output wire ibus_uncached;          
    output wire[3:0] ibus_byte_en;
    input wire[31:0] ibus_read_data;
    input wire ibus_stall;

    // data_bus
    output wire[31:0] dbus_addr;
    output wire dbus_read, dbus_write;
    output wire[31:0] dbus_write_data;
    output wire dbus_uncached;           
    output wire[3:0] dbus_byte_en;
    input wire[31:0] dbus_read_data;
    input wire[31:0] dbus_stall;
    
    // for interrupts
    wire[5:0] hardware_int;
    wire[1:0] software_int;
    wire timer_int;

    assign hardware_int[5] = timer_int; 
    assign hardware_int[4:0] = hardware_int_in; 

    // step_if
    wire[31:0] if_pc_addr;
    wire[31:0] if_inst_code;
    // step_if about inst mem access exp
    wire[7:0] if_asid;
    wire if_in_exl;
    wire if_iaddr_exp_miss;   
    wire if_iaddr_exp_illegal;
    wire if_iaddr_exp_invalid;

    assign if_in_exl = cp0_in_exl;
    assign if_asid = cp0_asid;

    // step_id & branch_jump_detector
    reg[31:0] id_pc_addr;
    wire[31:0] id_reg_s_val_from_regs;
    wire[31:0] id_reg_t_val_from_regs;
    wire id_is_branch;
    wire[31:0] id_branch_addr;
    reg id_is_real_inst;
    reg id_in_delayslot;
    // step_id inst decode input
    reg[31:0] id_inst_code;
    // step_id inst decode output
    wire[31:0] id_inst;
    wire[1:0] id_inst_type;
    wire[4:0] id_reg_s_addr;      
    wire[4:0] id_reg_t_addr;     
    wire[4:0] id_reg_d_addr;      
    wire[31:0] id_reg_s_val;
    wire[31:0] id_reg_t_val;
    wire[15:0] id_immediate; 
    wire[4:0] id_shift;
    wire[25:0] id_jump_addr; 
    wire[31:0] id_return_addr;
    // step_id about inst mem access exp
    reg[7:0] id_iaddr_exp_asid;
    reg id_iaddr_exp_exl;
    reg id_iaddr_exp_miss;
    reg id_iaddr_exp_illegal;
    reg id_iaddr_exp_invalid;

    // step_ex & reg_hilo
    reg[31:0] ex_pc_addr;
    reg ex_is_real_inst; 
    reg ex_in_delayslot;
    // step_ex inst ex input
    reg[31:0] ex_inst;
    reg[1:0] ex_inst_type;
    reg[4:0] ex_reg_s_addr;
    reg[4:0] ex_reg_t_addr;
    reg[4:0] ex_reg_d_addr;
    reg[31:0] ex_reg_s_val;
    reg[31:0] ex_reg_t_val;
    reg[15:0] ex_immediate;
    reg[4:0] ex_shift;
    reg[25:0] ex_jump_addr;
    reg[31:0] ex_return_addr;
    // step_ex inst ex output
    wire[31:0] ex_reg_val_o;
    wire[4:0] ex_bypass_reg_addr;
    wire[31:0] ex_mem_access_addr;
    wire[1:0] ex_mem_access_type;
    wire[2:0] ex_mem_access_size;
    wire ex_mem_access_signed;
    // step_ex about exp
    wire ex_overflow;              
    wire ex_is_priv_inst;         
    wire ex_inst_syscall;          
    wire ex_inst_eret;             
    wire ex_inst_tlbwi;            
    wire ex_inst_tlbp;             
    // step_ex about inst mem access exp
    reg[7:0] ex_iaddr_exp_asid;
    reg ex_iaddr_exp_exl; 
    reg ex_iaddr_exp_miss;
    reg ex_iaddr_exp_illegal;
    reg ex_iaddr_exp_invalid;
    // step_ex about cp0
    wire[31:0] ex_reg_cp0_i;
    wire ex_cp0_write_enable;      
    wire[4:0] ex_cp0_write_addr;
    wire[4:0] ex_cp0_read_addr;
    wire[2:0] ex_cp0_sel;
    // step_ex about hilo
    wire[63:0] ex_reg_hilo_i;
    wire[63:0] ex_reg_hilo_o;
    wire ex_hilo_write_enable;     
    wire[63:0] hilo_val_from_reg;
    
    // step_mm
    reg[31:0] mm_pc_addr;
    reg mm_is_real_inst;         
    reg mm_in_delayslot;          
    // step_mm about reg
    reg[31:0] mm_reg_val_i;
    wire[31:0] mm_reg_val_o;
    reg[4:0] mm_reg_addr_i;
    wire[4:0] mm_bypass_reg_addr;
    // step_mm mem access input
    reg[1:0] mm_mem_access_type;
    reg[2:0] mm_mem_access_size;
    reg mm_mem_access_signed;      
    reg[31:0] mm_mem_access_addr_i;  // virtual address from ex
    wire[31:0] mm_mem_access_data_i;  // data read from sram 
    // step_mm mem access output
    wire[3:0] mm_mem_byte_en;
    wire mm_mem_access_read;        
    wire mm_mem_access_write;
    wire[3:0] mm_mem_access_byte_enable;
    wire[31:0] mm_mem_access_addr_o;  //aligned virtual address to mmu
    wire[31:0] mm_mem_access_data_o;  // data written to sram
    // step_mm about exp(data mem access exp)
    reg mm_invalid_inst;         
    reg mm_overflow;             
    reg mm_is_priv_inst; 
    reg mm_inst_syscall;         
    reg mm_inst_eret;            
    reg mm_inst_tlbwi;            
    reg mm_inst_tlbp;             
    wire mm_alignment_err;          
    wire mm_daddr_exp_dirty;
    wire mm_daddr_exp_miss;   
    wire mm_daddr_exp_illegal;
    wire mm_daddr_exp_invalid;
    // step_mm about inst mem access exp
    reg mm_iaddr_exp_exl;
    reg[7:0] mm_iaddr_exp_asid;
    reg mm_iaddr_exp_miss;       
    reg mm_iaddr_exp_illegal;  
    reg mm_iaddr_exp_invalid;   
    // step_mm about cp0
    reg mm_cp0_write_enable;      
    reg[4:0] mm_cp0_write_addr;
    reg[2:0] mm_cp0_sel;
    wire[31:0] mm_tlbp_result;
    // step_mm about hilo
    reg[63:0] mm_reg_hilo;
    reg mm_hilo_write_enable;              

    // step_wb
    // step_mm about reg
    reg[31:0] wb_reg_val_i;         
    wire[31:0] wb_reg_val_o;         
    reg[4:0] wb_reg_addr_i;
    wire[4:0] wb_bypass_reg_addr;
    reg[1:0] wb_mem_access_type;  // decided wb_reg_write_enable
    wire wb_reg_write_enable;         
    // step_mm about exp
    reg wb_inst_tlbp;             
    reg wb_inst_tlbwi;            
    // step_mm about cp0
    reg wb_cp0_write_enable;      
    reg[4:0] wb_cp0_write_addr;
    reg[2:0] wb_cp0_sel;
    reg[31:0] wb_tlbp_result;
    // step_mm about hilo
    reg[63:0] wb_reg_hilo;
    reg wb_hilo_write_enable;   
    
    // cp0
    wire cp0_allow_int;           
    wire cp0_clean_exl;
    wire cp0_exp_en;
    wire cp0_exp_bd;
    wire cp0_exp_asid_we; 
    wire cp0_badv_we;             
    wire[4:0] cp0_exp_code;
    wire[7:0] cp0_exp_asid;
    wire[31:0] cp0_exp_badv;
    wire[31:0] cp0_exp_epc;
    wire[19:0] cp0_ebase;
    wire[31:0] cp0_epc;
    wire[83:0] cp0_tlb_config;
    wire cp0_user_mode;
    wire[7:0] cp0_interrupt_mask;
    wire cp0_special_int_vec;
    wire cp0_boot_exp_vec;
    wire[7:0] cp0_asid;
    wire cp0_in_exl;

    // for flush & stall
    // flush
    wire flush;
    wire debugger_flush;
    wire exception_flush;
    wire[31:0] exception_new_pc;
    assign flush = debugger_flush | exception_flush;
    // stall 
    reg en_pc, en_ifid, en_idex, en_exmm, en_mmwb;
    wire debugger_stall; // stall for debug
    wire ex_stall;  // stall for div MSUB MADD
    wire mm_stall;  // stall for SB SL

    // for debugger
    wire debugger_pc_reset;
    wire[31:0] debugger_pc_addr;
    // debugger about jump
    wire[4:0] debugger_reg_addr;
    wire[31:0] debugger_reg_val;
    // debugger about mem access
    wire debugger_mem_read;
    wire[31:0] debugger_mem_addr;
    wire[31:0] debugger_mem_data;
    // debugger about cp0/hilo
    wire[31:0] debugger_cp0_val;
    wire[4:0] debugger_cp0_addr;
    wire[63:0] debugger_hilo_val;
    // debugger host
    wire[7:0] debugger_host_cmd;
    wire[31:0] debugger_host_param;
    wire[31:0] debugger_host_result;
    wire debugger_host_cmd_en;
    wire[2:0] debugger_rd_sel;
    wire[4:0] debugger_rd_addr;
    wire[31:0] debugger_data_o;
    
    // inst_bus related assignments
    assign ibus_read = ~(if_iaddr_exp_miss | if_iaddr_exp_illegal | if_iaddr_exp_invalid);
    assign ibus_write = 1'b0;
    assign ibus_write_data = 32'b0;
    assign ibus_byte_en = 4'b1111;
    assign if_inst_code = ibus_read ? ibus_read_data : 32'b0;
    assign debugger_mem_data = if_inst_code;

    // data_bus related assignments
    assign dbus_read = mm_mem_access_read && !flush;
    assign dbus_write = mm_mem_access_write && !flush;
    assign dbus_write_data = mm_mem_access_data_o;
    assign dbus_byte_en = mm_mem_byte_en;
    assign mm_mem_access_data_i = dbus_read_data;

    assign wb_reg_val_o = wb_reg_val_i;
    assign wb_bypass_reg_addr = wb_reg_addr_i;

    // for hilo reg bypass
    assign ex_reg_hilo_i = mm_hilo_write_enable ? mm_reg_hilo : 
            (wb_hilo_write_enable ? wb_reg_hilo : hilo_val_from_reg);

    
    assign mm_stall = dbus_stall;
    always @(*) begin
        if (!rst_n) begin
            {en_pc,en_ifid,en_idex,en_exmm,en_mmwb} <= 5'b11111;
        end else if(mm_stall || debugger_stall) begin
            {en_pc,en_ifid,en_idex,en_exmm,en_mmwb} <= 5'b00000;
        end else if(ex_stall) begin
            {en_pc,en_ifid,en_idex,en_exmm,en_mmwb} <= 5'b00001;
        end else if(ex_mem_access_type == `MEM_ACCESS_TYPE_M2R &&   // data hazard, need to block 
          (ex_bypass_reg_addr == id_reg_s_addr || ex_bypass_reg_addr == id_reg_t_addr)) begin
            {en_pc,en_ifid,en_idex,en_exmm,en_mmwb} <= 5'b00011;
        end else begin
            {en_pc,en_ifid,en_idex,en_exmm,en_mmwb} <= 5'b11111;
        end
    end

    regs main_regs(/*autoinst*/
    .clk                        (clk                                            ), // input
    .rst_n                      (rst_n                          ), // input

        // infos of writing reg operation
    .write_enable               (wb_reg_write_enable                   ), // input
    .write_addr                 (wb_bypass_reg_addr[4:0]                ), // input
    .write_val                  (wb_reg_val_o[31:0]                ), // input
    
        // output for reg_s in common, used in ex
    .read_addr1                 (id_reg_s_addr[4:0]                ), // input
    .read_val1                  (id_reg_s_val_from_regs[31:0]                ), // output

        // output for reg_t in common, used in ex
    .read_addr2                 (id_reg_t_addr[4:0]                ), // input
    .read_val2                  (id_reg_t_val_from_regs[31:0]                ), // output
 
        // output for debugger
    .read_addr3                 (debugger_rd_addr[4:0]                ), // input
    .read_val3                  (debugger_reg_val[31:0]                )  // output
    );

    mmu_top unique_mmu(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
 
        // origin mem access address for data, from mem_access_address in mm
    .data_addr_i                (mm_mem_access_addr_o[31:0]             ), // input
        // origin mem access address for instructions, from pc_addr in pc
    .inst_addr_i                (debugger_mem_read ? debugger_mem_addr : if_pc_addr ), // input
        // for data_mem_map, output by mm
    .data_enable                (mm_mem_access_read || mm_mem_access_write                    ), // input
        // for inst_mem_map, default is 1
    .inst_enable                (1'b1 | debugger_mem_read                    ), // input
        // decided by cp0
    .user_mode                  (cp0_user_mode                      ), // input
    .tlb_config                 (cp0_tlb_config[83:0]               ), // input
        // TLBWI TLBP, output by ex 
    .tlbwi                      (wb_inst_tlbwi                          ), // input
    .tlbp                       (mm_inst_tlbp                           ), // input
    	// asid code for tlb, output by cp0
    .asid                       (cp0_asid[7:0]                      ), // input

        // converted address data/inst bus
    .data_addr_o                (dbus_addr[31:0]              ), // output
    .inst_addr_o                (ibus_addr[31:0]              ), // output

    .tlbp_result                (mm_tlbp_result[31:0]                    ), // output
        // exception related
    .data_uncached              (dbus_uncached                  ), // output
    .inst_uncached              (ibus_uncached                  ), // output
    .data_exp_miss              (mm_daddr_exp_miss                  ), // output
    .inst_exp_miss              (if_iaddr_exp_miss                  ), // output
    .data_exp_illegal           (mm_daddr_exp_illegal               ), // output
    .inst_exp_illegal           (if_iaddr_exp_illegal               ), // output
    .data_exp_dirty             (mm_daddr_exp_dirty                 ), // output
    .data_exp_invalid           (mm_daddr_exp_invalid               ), // output
    .inst_exp_invalid           (if_iaddr_exp_invalid               )  // output
    );
    
    cp0 unique_cp0(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

        // reg read info, passed in ex
    .rd_addr                    (ex_cp0_read_addr[4:0]                   ), // input
    .rd_sel                     (ex_cp0_sel[2:0]                    ), // input
        // read cp0 reg val, directly pass to ex
    .data_o                     (ex_reg_cp0_i[31:0]                   ), // output
        // reg wirte info, passed in wb
    .we                         (wb_cp0_write_enable                             ), // input
    .wr_addr                    (wb_cp0_write_addr[4:0]                   ), // input
    .wr_sel                     (wb_cp0_sel[2:0]                    ), // input
    .data_i                     (wb_reg_val_o[31:0]                   ), // input
        // hardware_int = hardware_int_in + timer_int 
    .hardware_int               (hardware_int[5:0]              ), // input
    .timer_int                  (timer_int                      ), // output
        // for exception and mmu
    .user_mode                  (cp0_user_mode                      ), // output
    .ebase                      (cp0_ebase[19:0]                    ), // output
    .epc                        (cp0_epc[31:0]                      ), // output
    .tlb_config                 (cp0_tlb_config[83:0]               ), // output
    .allow_int                  (cp0_allow_int                      ), // output
    .software_int_o             (software_int[1:0]            ), // output
    .interrupt_mask             (cp0_interrupt_mask[7:0]            ), // output
    .special_int_vec            (cp0_special_int_vec                ), // output
    .boot_exp_vec               (cp0_boot_exp_vec                   ), // output
        // gnenrate@if, pass to exp@mm, directly pass to mmu
    .asid                       (cp0_asid[7:0]                      ), // output
    .in_exl                     (cp0_in_exl                         ), // output
        // about exp
    .clean_exl                  (cp0_clean_exl                      ), // input
    .en_exp_i                   (cp0_exp_en                      ), // input
    .exp_epc                    (cp0_exp_epc[31:0]                  ), // input
    .exp_bd                     (cp0_exp_bd                         ), // input
    .exp_code                   (cp0_exp_code[4:0]                  ), // input
        // about mem access exp
    .exp_bad_vaddr              (cp0_exp_badv[31:0]            ), // input
    .exp_badv_we                (cp0_badv_we                    ), // input
    .exp_asid                   (cp0_exp_asid[7:0]                  ), // input
    .exp_asid_we                (cp0_exp_asid_we                    ), // input

    .we_probe                   (wb_inst_tlbp                       ), // input
    .probe_result               (wb_tlbp_result[31:0]             ), // input

    .debugger_rd_addr           (debugger_rd_addr[4:0]          ), // input
    .debugger_rd_sel            (debugger_rd_sel[2:0]           ), // input
    .debugger_data_o            (debugger_data_o[31:0]          )  // output

    );

    pc unique_pc(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    .pc_enable                  (en_pc & ~flush                      ), // input
    
    .do_branch                  (id_is_branch                      ), // input
    .branch_addr                (id_branch_addr[31:0]              ), // input
    
    .do_exception               (exception_flush                   ), // input
    .exception_addr             (exception_new_pc[31:0]           ), // input

    .do_debug                   (debugger_flush                       ), // input
    .debug_reset                (debugger_pc_reset                    ), // input
    .debug_addr                 (debugger_pc_addr[31:0]               ), // input
    
    .pc_addr                    (if_pc_addr[31:0]                  )  // output
    );

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n) begin
            id_inst_code <= 32'b0;
            id_pc_addr <= 32'b0;
            id_is_real_inst <= 1'b0;
            id_in_delayslot <= 1'b0;
            id_iaddr_exp_miss <= 1'b0;
            id_iaddr_exp_illegal <= 1'b0;
            id_iaddr_exp_invalid <= 1'b0;
            id_iaddr_exp_asid <= 8'b0;
            id_iaddr_exp_exl <= 1'b0;
        end else if (en_ifid && !flush) begin  // normal stall
            id_inst_code <= if_inst_code;
            id_pc_addr <= if_pc_addr;
            id_is_real_inst <= 1'b1;
            id_in_delayslot <= id_is_branch;
            id_iaddr_exp_miss <= if_iaddr_exp_miss;
            id_iaddr_exp_illegal <= if_iaddr_exp_illegal;
            id_iaddr_exp_invalid <= if_iaddr_exp_invalid;
            id_iaddr_exp_asid <= if_asid;
            id_iaddr_exp_exl <= if_in_exl;   
        end else if (en_idex || flush) begin // flush the pipeline 
            id_inst_code <= 32'b0;
            id_pc_addr <= 32'b0;
            id_is_real_inst <= 1'b0;
            id_in_delayslot <= 1'b0;
            id_iaddr_exp_miss <= 1'b0;
            id_iaddr_exp_illegal <= 1'b0;
            id_iaddr_exp_invalid <= 1'b0;
            id_iaddr_exp_asid <= 8'b0;
            id_iaddr_exp_exl <= 1'b0; 
        end
    end

    id step_id(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // full 32bit inst
    .inst_code                  (id_inst_code[31:0]                ), // input
        // pass pc_value
    .pc_addr                    (id_pc_addr[31:0]                  ), // input

        // inst mark at defs.v
    .inst                       (id_inst[7:0]                      ), // output
        // inst type in defs.v
    .inst_type                  (id_inst_type[1:0]                 ), // output

        // output operands
    .reg_s                      (id_reg_s_addr[4:0]                     ), // output
    .reg_t                      (id_reg_t_addr[4:0]                     ), // output
    .reg_d                      (id_reg_d_addr[4:0]                     ), // output
    .immediate                  (id_immediate[15:0]                ), // output
    .shift                      (id_shift[4:0]                     ), // output
    .jump_addr                  (id_jump_addr[25:0]                )  // output

    );

    reg_bypass_mux reg_bypass_mux_s(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // input an reg addr for val
    .reg_addr                   (id_reg_s_addr[4:0]                  ), // input
    
        // val from real regs heap
    .val_from_regs              (id_reg_s_val_from_regs[31:0]            ), // input
    
        // reg addr info used for bypass from ex
    .addr_from_ex               (ex_bypass_reg_addr[4:0]              ), // input
    .val_from_ex                (ex_reg_val_o[31:0]              ), // input
    .access_type_from_ex        (ex_mem_access_type[1:0]       ), // input
    
        // reg addr info used for bypass from mm
    .addr_from_mm               (mm_bypass_reg_addr[4:0]              ), // input
    .val_from_mm                (mm_reg_val_o[31:0]              ), // input
    .access_type_from_mm        (mm_mem_access_type[1:0]       ), // input
    
        // reg addr info used for bypass from wb
    .addr_from_wb               (wb_bypass_reg_addr[4:0]              ), // input
    .val_from_wb                (wb_reg_val_o[31:0]              ), // input
        // we = 0 is equal with mem_access_type == R2M (reg_val is useless)
    .write_enable_from_wb       (wb_reg_write_enable           ), // input
        // final output of reg val (from real regs heap or bypass)
    .val_output                 (id_reg_s_val[31:0]               )  // output
    );

    reg_bypass_mux reg_bypass_mux_t(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // input an reg addr for val
    .reg_addr                   (id_reg_t_addr[4:0]                  ), // input
    
        // val from real regs heap
    .val_from_regs              (id_reg_t_val_from_regs[31:0]            ), // input
    
        // reg addr info used for bypass from ex
    .addr_from_ex               (ex_bypass_reg_addr[4:0]              ), // input
    .val_from_ex                (ex_reg_val_o[31:0]              ), // input
    .access_type_from_ex        (ex_mem_access_type[1:0]       ), // input
    
        // reg addr info used for bypass from mm
    .addr_from_mm               (mm_bypass_reg_addr[4:0]              ), // input
    .val_from_mm                (mm_reg_val_o[31:0]              ), // input
    .access_type_from_mm        (mm_mem_access_type[1:0]       ), // input
    
        // reg addr info used for bypass from wb
    .addr_from_wb               (wb_bypass_reg_addr[4:0]              ), // input
    .val_from_wb                (wb_reg_val_o[31:0]              ), // input
        // we = 0 is equal with mem_access_type == R2M (reg_val is useless)
    .write_enable_from_wb       (wb_reg_write_enable           ), // input
        //input wire write_enable_from_wb;
    
        // final output of reg val (from real regs heap or bypass)
    .val_output                 (id_reg_t_val[31:0]               )  // output
    );

    branch_jump branch_jump_detector(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
 
        // get from pc.v, used for calculate return/branch address
    .pc_addr                    (id_pc_addr[31:0]                  ), // input
        // parallel with id.v and ex.v, so directly get inst_code instead of inst
    .inst_code                  (id_inst_code[31:0]                ), // input
        // get operands from mux, reg_addr was generated by id.v
    .reg_s_value                (id_reg_s_val[31:0]              ), // input
    .reg_t_value                (id_reg_t_val[31:0]              ), // input
    
        // used by pc.v
    .do_branch                  (id_is_branch                      ), // output
    .branch_addr                (id_branch_addr[31:0]              ), // output
        // used by ex.v, store it in specific reg
    .return_addr                (id_return_addr[31:0]              )  // output
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_inst <= `INST_NOP;
            ex_inst_type <= `MEM_ACCESS_TYPE_R2R;
            ex_reg_s_addr <= 5'b0;
            ex_reg_t_addr <= 5'b0;
            ex_reg_d_addr <= 5'b0;
            ex_reg_s_val <= 32'b0;
            ex_reg_t_val <= 32'b0;
            ex_immediate <= 16'b0;
            ex_return_addr <= 32'b0;
            ex_jump_addr <= 26'b0;
            ex_shift <= 5'b0;
            ex_in_delayslot <= 1'b0;
            ex_pc_addr <= 32'b0;
            ex_is_real_inst <= 1'b0;
            ex_iaddr_exp_miss <= 1'b0;
            ex_iaddr_exp_illegal <= 1'b0;
            ex_iaddr_exp_invalid <= 1'b0;
            ex_iaddr_exp_asid <= 8'b0;
            ex_iaddr_exp_exl <= 1'b0;
        end
        else if(en_idex && !flush) begin
            ex_inst <= id_inst;
            ex_inst_type <= id_inst_type;
            ex_reg_s_addr <= id_reg_s_addr;
            ex_reg_t_addr <= id_reg_t_addr;
            ex_reg_d_addr <= id_reg_d_addr;
            ex_reg_s_val <= id_reg_s_val;
            ex_reg_t_val <= id_reg_t_val;
            ex_immediate <= id_immediate;
            ex_return_addr <= id_return_addr;
            ex_jump_addr <= id_jump_addr;
            ex_shift <= id_shift;
            ex_in_delayslot <= id_in_delayslot;
            ex_pc_addr <= id_pc_addr;
            ex_is_real_inst <= id_is_real_inst;
            ex_iaddr_exp_miss <= id_iaddr_exp_miss;
            ex_iaddr_exp_illegal <= id_iaddr_exp_illegal;
            ex_iaddr_exp_invalid <= id_iaddr_exp_invalid;
            ex_iaddr_exp_asid <= id_iaddr_exp_asid;
            ex_iaddr_exp_exl <= id_iaddr_exp_exl;
        end else if(en_exmm || flush) begin
            ex_inst <= `INST_NOP;
            ex_inst_type <= `MEM_ACCESS_TYPE_R2R;
            ex_reg_s_addr <= 5'b0;
            ex_reg_t_addr <= 5'b0;
            ex_reg_d_addr <= 5'b0;
            ex_reg_s_val <= 32'b0;
            ex_reg_t_val <= 32'b0;
            ex_immediate <= 16'b0;
            ex_return_addr <= 32'b0;
            ex_jump_addr <= 26'b0;
            ex_shift <= 5'b0;
            ex_in_delayslot <= 1'b0;
            ex_pc_addr <= 32'b0;
            ex_is_real_inst <= 1'b0;
            ex_iaddr_exp_miss <= 1'b0;
            ex_iaddr_exp_illegal <= 1'b0;
            ex_iaddr_exp_invalid <= 1'b0;
            ex_iaddr_exp_asid <= 8'b0;
            ex_iaddr_exp_exl <= 1'b0;
        end
    end

    ex step_ex(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    .exception_flush            (exception_flush                ), // input
        // decoded instruction
        // inst 
    .inst                       (ex_inst[7:0]                      ), // input
    .inst_type                  (ex_inst_type[1:0]                 ), // input
        // operands
    .reg_s                      (ex_reg_s_addr[4:0]                     ), // input
    .reg_t                      (ex_reg_t_addr[4:0]                     ), // input
    .reg_d                      (ex_reg_d_addr[4:0]                     ), // input
    .reg_s_val                  (ex_reg_s_val[31:0]                ), // input
    .reg_t_val                  (ex_reg_t_val[31:0]                ), // input
    .immediate                  (ex_immediate[15:0]                ), // input
    .shift                      (ex_shift[4:0]                     ), // input
    .jump_addr                  (ex_jump_addr[25:0]                ), // input
        // output by branch_jump.v, maybe need to put in reg_31 under some circumstances
    .return_addr                (ex_return_addr[31:0]              ), // input

        // for reg bypass mux, defined in defs.v
    .mem_access_type            (ex_mem_access_type[1:0]           ), // output
        // for mmu, defined in defs.v
    .mem_access_size            (ex_mem_access_size[2:0]           ), // output
        // for mm, decide if we get signed/unsigned data
    .mem_access_signed          (ex_mem_access_signed         ), // output
        // mem access address in step_mm
    .mem_access_addr            (ex_mem_access_addr[31:0]          ), // output

        // ex result
    .val_output                 (ex_reg_val_o[31:0]               ), // output
        // address of the reg(store the val of result in ex), which should be bypass to mux and mm
    .bypass_reg_addr            (ex_bypass_reg_addr[4:0]           ), // output

        // for spec instructions
    .overflow                   (ex_overflow                       ), // output
        // stall the pipeline when ex do multi-cycle jobs like div
    .stall_for_mul_cycle        (ex_stall            ), // output
        // set if inst is a priority instruction(should be handle by cp0)
    .is_priv_inst               (ex_is_priv_inst                   ), // output
        // for SYSCALL ERET TLBWI TLBP
    .inst_syscall               (ex_inst_syscall                   ), // output
    .inst_eret                  (ex_inst_eret                      ), // output
        // we_tlb
    .inst_tlbwi                 (ex_inst_tlbwi                     ), // output
        // probe_tlb
    .inst_tlbp                  (ex_inst_tlbp                      ), // output

        // for CP0 access instructions: MTC0 MFC0
        // MTC0: need to enable that, pass to cp0 in *step_wb*
    .cp0_write_enable           (ex_cp0_write_enable               ), // output
        // MTC0: write reg addr in CP0, passed in wb
    .cp0_write_addr             (ex_cp0_write_addr[4:0]            ), // output
        // MFC0: read reg addr in CP0, passed in ex(combinantial logic)
    .cp0_read_addr              (ex_cp0_read_addr[4:0]             ), // output
        // MF/TC0: sel for CP0, passed in ex(combinantial logic)
    .cp0_sel                    (ex_cp0_sel[2:0]                   ), // output
        // MFC0: reg read result, passed in ex(combinantial logic)
    .reg_cp0_val                (ex_reg_cp0_i[31:0]              ), // input
    
        // for DIV/MULT(U) MF/TLO/HI, can get from mm/wb/reg, decided by we
    .reg_hilo_val               (ex_reg_hilo_i[63:0]             ), // input
    .reg_hilo_o                 (ex_reg_hilo_o[63:0]               ), // output
    .hilo_write_enable          (ex_hilo_write_enable              )  // output
    );

    hilo hilo_reg(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    .we                         (wb_hilo_write_enable                            ), // input
    .hilo_i                     (wb_reg_hilo[63:0]                   ), // input
    .hilo_o                     (hilo_val_from_reg[63:0]                   )  // output
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mm_mem_access_type <= `MEM_ACCESS_TYPE_M2R;
            mm_mem_access_size <= `MEM_ACCESS_LENGTH_WORD;
            mm_reg_val_i <= 32'b0;
            mm_reg_addr_i <= 5'b0;
            mm_mem_access_addr_i <= 32'b0;
            mm_reg_hilo <= 64'b0;
            mm_hilo_write_enable <= 1'b0;
            mm_mem_access_signed <= 1'b1;
            mm_cp0_write_enable <= 1'b0;
            mm_cp0_write_addr <= 5'b0;
            mm_cp0_sel <= 3'b0;
            mm_overflow <= 1'b0;
            mm_in_delayslot <= 1'b0;
            mm_pc_addr <= 32'b0;
            mm_is_real_inst <= 1'b0;
            mm_inst_eret <= 1'b0;
            mm_inst_syscall <= 1'b0;
            mm_invalid_inst <= 1'b0;
            mm_iaddr_exp_miss <= 1'b0;
            mm_iaddr_exp_illegal <= 1'b0;
            mm_iaddr_exp_invalid <= 1'b0;
            mm_iaddr_exp_asid <= 8'b0;
            mm_iaddr_exp_exl <= 1'b0;
            mm_inst_tlbwi <= 1'b0;
            mm_inst_tlbp <= 1'b0;
            mm_is_priv_inst <= 1'b0;
        end
        else if(en_exmm && !flush) begin
            mm_mem_access_type <= ex_mem_access_type;
            mm_mem_access_size <= ex_mem_access_size;
            mm_reg_val_i <= ex_reg_val_o;
            mm_reg_addr_i <=  ex_bypass_reg_addr;
            mm_mem_access_addr_i <= ex_mem_access_addr;
            mm_reg_hilo <= ex_reg_hilo_o;
            mm_hilo_write_enable <= ex_hilo_write_enable;
            mm_mem_access_signed <= ex_mem_access_signed;
            mm_cp0_write_enable <= ex_cp0_write_enable;
            mm_cp0_write_addr <= ex_cp0_write_addr;
            mm_cp0_sel <= ex_cp0_sel;
            mm_overflow <= ex_overflow;
            mm_in_delayslot <= ex_in_delayslot;
            mm_pc_addr <= ex_pc_addr;
            mm_is_real_inst <= ex_is_real_inst;
            mm_inst_eret <= ex_inst_eret;
            mm_inst_syscall <= ex_inst_syscall;
            mm_invalid_inst <= ex_inst == `INST_INVALID;
            mm_iaddr_exp_miss <= ex_iaddr_exp_miss;
            mm_iaddr_exp_illegal <= ex_iaddr_exp_illegal;
            mm_iaddr_exp_invalid <= ex_iaddr_exp_invalid;
            mm_iaddr_exp_asid <= ex_iaddr_exp_asid;
            mm_iaddr_exp_exl <= ex_iaddr_exp_exl;
            mm_inst_tlbwi <= ex_inst_tlbwi;
            mm_inst_tlbp <= ex_inst_tlbp;
            mm_is_priv_inst <= ex_is_priv_inst;
        end else if(en_mmwb || flush) begin
            mm_mem_access_type <= `MEM_ACCESS_TYPE_R2R;
            mm_mem_access_size <= `MEM_ACCESS_LENGTH_WORD;
            mm_reg_val_i <= 32'b0;
            mm_reg_addr_i <= 5'b0;
            mm_mem_access_addr_i <= 32'b0;
            mm_reg_hilo <= 64'b0;
            mm_hilo_write_enable <= 1'b0;
            mm_mem_access_signed <= 1'b1;
            mm_cp0_write_enable <= 1'b0;
            mm_cp0_write_addr <= 5'b0;
            mm_cp0_sel <= 3'b0;
            mm_overflow <= 1'b0;
            mm_in_delayslot <= 1'b0;
            mm_pc_addr <= 32'b0;
            mm_is_real_inst <= 1'b0;
            mm_inst_eret <= 1'b0;
            mm_inst_syscall <= 1'b0;
            mm_invalid_inst <= 1'b0;
            mm_iaddr_exp_miss <= 1'b0;
            mm_iaddr_exp_illegal <= 1'b0;
            mm_iaddr_exp_invalid <= 1'b0;
            mm_iaddr_exp_asid <= 8'b0;
            mm_iaddr_exp_exl <= 1'b0;
            mm_inst_tlbwi <= 1'b0;
            mm_inst_tlbp <= 1'b0;
            mm_is_priv_inst <= 1'b0;
        end
    end

    mm step_mm(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
        // input wire exception_flush;
    
    .mem_access_type            (mm_mem_access_type[1:0]           ), // input
    .mem_access_size            (mm_mem_access_size[2:0]           ), // input
        // mem_access_signed in ex.v
    .mem_access_signed          (mm_mem_access_signed              ), // input
        // mem_access_addr in ex.v
    .mem_access_addr_i          (mm_mem_access_addr_i[31:0]                   ), // input
        // val_output in ex.v
    .data_i                     (mm_reg_val_i[31:0]                   ), // input
        // bypass_reg_addr in ex.v, useless
    .reg_addr_i                 (mm_reg_addr_i[4:0]          ), // input
        // receive mem access result from sram
    .mem_access_data_i          (mm_mem_access_data_i[31:0]       ), // input

        // output mem access result from sram, used by wb and mux
    .data_o                     (mm_reg_val_o[31:0]                   ), // output
        // use by mux, equal with reg_addr_i, but 1 clock late
    .bypass_reg_addr_mm         (mm_bypass_reg_addr[4:0]        ), // output
        // output address written to sram, equals with aligned addr_i, but 1 clock late;
    .mem_access_addr_o          (mm_mem_access_addr_o[31:0]          ), // output
        // output data wirtten to sram
    .mem_access_data_o          (mm_mem_access_data_o[31:0]      ), // output
        // mem access: read or write, enable write/read operation
    .mem_access_read            (mm_mem_access_read                ), // output
    .mem_access_write           (mm_mem_access_write               ), // output
    .mem_access_byte_en         (mm_mem_access_byte_enable[3:0]              ), // output
        //output reg[3:0] mem_byte_en;
        // LH/SH:addr[0] != 0 LW/SW:addr[1:0] != 2'b0 
    .alignment_err              (mm_alignment_err                  )  // output
    );
    
    exception exception_detector(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

        // exp about memory access
        // illegal -> access kernel mode addr. invalid-> tlb error
        // occurs@if by mmu
    .iaddr_exp_miss             (mm_iaddr_exp_miss                 ), // input
    .iaddr_exp_invalid          (mm_iaddr_exp_invalid              ), // input
    .iaddr_exp_illegal          (mm_iaddr_exp_illegal || (mm_pc_addr[1:0] != 2'b00)   ), // input
        // occurs@mm by mmu  
    .daddr_exp_miss             (mm_daddr_exp_miss                 ), // input
    .daddr_exp_invalid          (mm_daddr_exp_invalid              ), // input
    .daddr_exp_illegal          (mm_daddr_exp_illegal || mm_alignment_err             ), // input
    .daddr_exp_dirty            (mm_mem_access_write & ~mm_daddr_exp_dirty ), // input
    	// common exp
    .data_we                    (mm_mem_access_write                        ), // input
    .invalid_inst               (mm_invalid_inst                   ), // input
    .syscall                    (mm_inst_syscall                        ), // input
    .eret                       (mm_inst_eret                           ), // input
    .overflow                   (mm_overflow                       ), // input
    .restrict_priv_inst         (mm_is_priv_inst && cp0_user_mode            ), // input
        // interrupts 
    .interrupt_mask             (cp0_interrupt_mask[7:0]        ),
    .hardware_int               (hardware_int[5:0]              ), // input
    .software_int               (software_int[1:0]              ), // input
 	
    	// for calculate return addr
    .pc_value                   (mm_pc_addr[31:0]                 ), // input
    .in_delayslot               (mm_in_delayslot                   ), // input
    	// enable/diable interrupts
    .allow_int                  (cp0_allow_int                      ), // input
    .is_real_inst               (mm_is_real_inst                   ), // input

    	// about mem access exp, some need to be stored in CP0_BadVAddr/Context/EntryHi
    .mem_access_vaddr           (mm_mem_access_addr_o[31:0]         ), // input
    .if_asid                    (mm_iaddr_exp_asid[7:0]                   ), // input   // inst/data memory exp use different asid/exl in different pipeline step 
    .mm_asid                    (cp0_asid[7:0]                   ), // input

        // for calculate exp new pc
    .ebase_in                   (cp0_ebase[19:0]                 ), // input
    .epc_in                     (cp0_epc[31:0]                   ), // input
    .special_int_vec            (cp0_special_int_vec                ), // input
    .boot_exp_vec               (cp0_boot_exp_vec                   ), // input
    .if_exl                     (mm_iaddr_exp_exl                         ), // input
    .mm_exl                     (cp0_in_exl                         ), // input

    .flush                      (exception_flush                          ), // output
    .cp0_in_exp                 (cp0_exp_en                    ), // output
    .cp0_clean_exl              (cp0_clean_exl                  ), // output
    .exp_epc                    (cp0_exp_epc[31:0]                  ), // output
    .exp_code                   (cp0_exp_code[4:0]                  ), // output
        // 2cp0, about mem access exp, need to be written in cp0 regs
    .exp_bad_vaddr              (cp0_exp_badv[31:0]            ), // output
    .cp0_badv_we                (cp0_badv_we                    ), // output
    .exp_asid                   (cp0_exp_asid[7:0]                  ), // output
    .cp0_exp_asid_we            (cp0_exp_asid_we                ), // output

    .exception_new_pc           (exception_new_pc[31:0]         )  // output
    );
    assign cp0_exp_bd = mm_in_delayslot;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_mem_access_type <= `MEM_ACCESS_TYPE_R2R;
            wb_reg_val_i <= 32'b0;
            wb_reg_addr_i <= 5'b0;
            wb_reg_hilo <= 64'b0;
            wb_hilo_write_enable <= 1'b0;
            wb_cp0_write_enable <= 1'b0;
            wb_cp0_write_addr <= 5'b0;
            wb_inst_tlbwi <= 1'b0;
            wb_cp0_sel <= 3'b0;
            wb_inst_tlbp <= 1'b0;
            wb_tlbp_result <= 32'b0;
        end
        else if(en_mmwb && !flush) begin
            wb_mem_access_type <= mm_mem_access_type;
            wb_reg_val_i <= mm_reg_val_o;
            wb_reg_addr_i <= mm_bypass_reg_addr;
            wb_reg_hilo <= mm_reg_hilo;
            wb_hilo_write_enable <= mm_hilo_write_enable;
            wb_cp0_write_enable <= mm_cp0_write_enable;
            wb_cp0_write_addr <= mm_cp0_write_addr;
            wb_inst_tlbwi <= mm_inst_tlbwi;
            wb_cp0_sel <= mm_cp0_sel;
            wb_inst_tlbp <= mm_inst_tlbp;
            wb_tlbp_result <= mm_tlbp_result;
        end else begin
            wb_mem_access_type <= `MEM_ACCESS_TYPE_R2R;
            wb_reg_val_i <= 32'b0;
            wb_reg_addr_i <= 5'b0;
            wb_reg_hilo <= 64'b0;
            wb_hilo_write_enable <= 1'b0;
            wb_cp0_write_enable <= 1'b0;
            wb_cp0_write_addr <= 5'b0;
            wb_inst_tlbwi <= 1'b0;
            wb_cp0_sel <= 3'b0;
            wb_inst_tlbp <= 1'b0;
            wb_tlbp_result <= 32'b0;
        end
    end

    wb step_wb(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
    
        // mem_access_type in mm.v, but 1 clock late
    .mem_access_type            (wb_mem_access_type[1:0]           ), // input
        // data_o in mm
    .data_i                     (wb_reg_val_i[31:0]                   ), // input
        // bypass_reg_addr_mm in mm.v, but 1 clock late
    .bypass_reg_addr_wb         (wb_bypass_reg_addr[4:0]        ), // input

        // for regs
    .reg_write_enable           (wb_reg_write_enable               )  // output
    );

endmodule

`endif
