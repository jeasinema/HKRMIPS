/*-----------------------------------------------------
 File Name : tlb_top.v
 Purpose : top file of tlb converter
 Creation Date : 21-10-2016
 Last Modified : Fri Oct 21 16:22:31 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __TLB_TOP_V__
`define __TLB_TOP_V__

`timescale 1ns/1ps

module tlb_top(/*autoarg*/
    //Inputs
    clk, rst_n, tlb_config, tlbwi, tlbp, 
    data_addr_virtual, inst_addr_virtual, 
    asid, 

    //Outputs
    data_addr_physic,, inst_addr_physic,, 
    tlbp_result, data_miss, inst_miss, data_dirty, 
    inst_dirty, inst_valid, data_valid
);

    input wire clk;
    input wire rst_n;

    // config by cp0 
    input wire[83:0] tlb_config;
    // TLBWI TLBP
    input wire tlbwi, tlbp;
    // virtual address
    input wire[31:0] data_addr_virtual; 
    input wire[31:0] inst_addr_virtual;
    input wire asid;

    // tlb-converted address output 
    output wire[31:0] data_addr_physic,
    output wire[31:0] inst_addr_physic,
   
    // query result for TLBP
    output wire[31:0] tlbp_result;
    // exceptions
    output wire data_miss;
    output wire inst_miss;
    output wire data_dirty;
    output wire inst_dirty;
    output wire inst_valid;
    output wire data_valid;


    // TODO:@lyr tlb_converter, ref to naivemips
    always @(*)
    begin

    end

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin

        end

    end

endmodule

`endif
