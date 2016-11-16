/*-----------------------------------------------------
 File Name : mmu_top.v
 Purpose : top file of mmu
 Creation Date : 21-10-2016
 Last Modified : Sun Oct 30 00:39:30 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __MMU_TOP_V__
`define __MMU_TOP_V__
`default_nettype none
`timescale 1ns/1ns

module mmu_top(/*autoarg*/
    //Inputs
    clk, rst_n, data_addr_i, inst_addr_i, 
    data_enable, inst_enable, user_mode, 
    tlb_config, tlbwi, tlbp, asid, 

    //Outputs
    data_addr_o, inst_addr_o, tlbp_result, 
    data_uncached, inst_uncached, data_exp_miss, 
    inst_exp_miss, data_exp_illegal, inst_exp_illegal, 
    data_exp_dirty, data_exp_invalid, inst_exp_invalid
);

    input wire clk;
    input wire rst_n;
 
    // origin mem access address for data, from mem_access_address in mm
    input wire[31:0] data_addr_i;
    // origin mem access address for instructions, from pc_addr in pc
    input wire[31:0] inst_addr_i;
    // for data_mem_map, output by mm
    input wire data_enable;
    // for inst_mem_map, default is 1
    input wire inst_enable;
    // decided by cp0
    input wire user_mode;
    input wire[83:0] tlb_config;
    // TLBWI TLBP, output by ex 
    input wire tlbwi;
    input wire tlbp;
	// asid code for tlb, output by cp0
    input wire[7:0] asid;

    // converted address data/inst bus
	output wire[31:0] data_addr_o;
	output wire[31:0] inst_addr_o;

    // for tlbp
    output wire[31:0] tlbp_result;

    // exception related
	output wire data_uncached;
    output wire inst_uncached;
    output wire data_exp_miss;
    output wire inst_exp_miss;
    output wire data_exp_illegal;
    output wire inst_exp_illegal;
    output wire data_exp_dirty;
    output wire data_exp_invalid;
    output wire inst_exp_invalid;
    
    wire data_miss, inst_miss;
    // inst_dirty is useless, because we cannot write on mem area stored instructions.
    wire inst_dirty, data_dirty;
    wire data_valid, inst_valid;
    
    // using tlb only when access memeoy in useg0
    wire data_using_tlb, inst_using_tlb;
    wire[31:0] data_addr_direct, data_addr_tlb;
    wire[31:0] inst_addr_direct, inst_addr_tlb;

    assign data_addr_o = data_using_tlb ? data_addr_tlb : data_addr_direct;
    assign inst_addr_o = inst_using_tlb ? inst_addr_tlb : inst_addr_direct;

    assign data_exp_miss = (data_miss && data_using_tlb);
    assign data_exp_dirty = (data_dirty || !data_using_tlb);
    assign data_exp_invalid = (~data_valid & data_using_tlb);
    assign inst_exp_miss = (inst_miss && inst_using_tlb);
    assign inst_exp_invalid = (~inst_valid & inst_using_tlb);
    
    // 1. decided whether using tlb 
    // 2. if not-using tlb, calculate physical address
    mem_map mem_map_data(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
        // raw mem address
    .addr_i                     (data_addr_i[31:0]              ), // input
    .mem_access_enable          (data_enable                    ), // input
    .user_mode                  (user_mode                      ), // input

        // 0 when using tlb, convert when using kseg0/kseg1
    .addr_o                     (data_addr_direct[31:0]         ), // output
        // is invalid when access kernel memory area(vol3.p22)
    .is_invalid                 (data_exp_illegal               ), // output
    .using_tlb                  (data_using_tlb                 ), // output
    .is_uncached                (data_uncached                  )  // output
    );

    mem_map mem_map_inst(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input
        // raw mem address
    .addr_i                     (inst_addr_i[31:0]              ), // input
    .mem_access_enable          (inst_enable                    ), // input
    .user_mode                  (user_mode                      ), // input
        // 0 when using tlb, convert when using kseg0/kseg1
    .addr_o                     (inst_addr_direct[31:0]         ), // output
        // is invalid when access kernel memory area(vol3.p22)
    .is_invalid                 (inst_exp_illegal               ), // output
    .using_tlb                  (inst_using_tlb                 ), // output
    .is_uncached                (inst_uncached                  )  // output
    );
    
    tlb_top tlb(/*autoinst*/
    .clk                        (clk                            ), // input
    .rst_n                      (rst_n                          ), // input

        // config by cp0 
    .tlb_config                 (tlb_config[83:0]               ), // input
        // TLBWI TLBP
    .tlbwi                      (tlbwi                          ), // input
	 .tlbp                       (tlbp                          ), // input
        // virtual address
    .data_addr_virtual          (data_addr_i[31:0]              ), // input
    .inst_addr_virtual          (inst_addr_i[31:0]              ), // input
    .asid                       (asid                           ), // input

        // tlb-converted address output 
    .data_addr_physic           (data_addr_tlb[31:0]            ), // output
    .inst_addr_physic           (inst_addr_tlb[31:0]            ), // output
   
        // query result for TLBP
    .tlbp_result                (tlbp_result[31:0]              ), // output
        // exceptions
    .data_miss                  (data_miss                      ), // output
    .inst_miss                  (inst_miss                      ), // output
    .data_dirty                 (data_dirty                     ), // output
    .inst_dirty                 (inst_dirty                     ), // output
    .inst_valid                 (inst_valid                     ), // output
    .data_valid                 (data_valid                     )  // output

    );

endmodule

`endif
