/*-----------------------------------------------------
 File Name : tlb_top.v
 Purpose : top file of tlb converter
 Creation Date : 21-10-2016
 Last Modified : Wed Nov 16 19:44:46 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __TLB_TOP_V__
`define __TLB_TOP_V__
`default_nettype none
`timescale 1ns/1ns

module tlb_top(/*autoarg*/
    //Inputs
    clk, rst_n, tlb_config, tlbwi, tlbp,
    data_addr_virtual, inst_addr_virtual,
    asid,

    //Outputs
    data_addr_physic, inst_addr_physic, tlbp_result,
    data_miss, inst_miss, data_dirty, inst_dirty,
    inst_valid, data_valid
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
    input wire[7:0] asid;

    // tlb-converted address output
    output wire[31:0] data_addr_physic;
    output wire[31:0] inst_addr_physic;

    // query result for TLBP
    output wire[31:0] tlbp_result;
    // exceptions
    output wire data_miss;
    output wire inst_miss;
    output wire data_dirty;
    output wire inst_dirty;
    output wire inst_valid;
    output wire data_valid;


    wire[18:0] tlb_entry_vpn2;
    wire[3:0] tlb_entry_index;
    wire[7:0] tlb_entry_ASID;
    wire tlb_entry_G;

    wire[23:0] tlb_entry_PFN0;
    wire tlb_entry_D0;
    wire tlb_entry_V0;

    wire[23:0] tlb_entry_PFN1;
    wire tlb_entry_D1;
    wire tlb_entry_V1;

    assign {
        tlb_entry_ASID, //[79:72]
        tlb_entry_G,    //71
        tlb_entry_vpn2, //[70:52]
        tlb_entry_PFN1, //[51:28]
        tlb_entry_D1, tlb_entry_V1,//27,26
        tlb_entry_PFN0,//[25:2]
        tlb_entry_D0, tlb_entry_V0, //1, 0
        tlb_entry_index
    } = tlb_config;

    reg[79:0] tlb_entries[0:15];

    tlb conv4inst(
        .tlb_entry0(tlb_entries[0]),
        .tlb_entry1(tlb_entries[1]),
        .tlb_entry2(tlb_entries[2]),
        .tlb_entry3(tlb_entries[3]),
        .tlb_entry4(tlb_entries[4]),
        .tlb_entry5(tlb_entries[5]),
        .tlb_entry6(tlb_entries[6]),
        .tlb_entry7(tlb_entries[7]),
        .tlb_entry8(tlb_entries[8]),
        .tlb_entry9(tlb_entries[9]),
        .tlb_entry10(tlb_entries[10]),
        .tlb_entry11(tlb_entries[11]),
        .tlb_entry12(tlb_entries[12]),
        .tlb_entry13(tlb_entries[13]),
        .tlb_entry14(tlb_entries[14]),
        .tlb_entry15(tlb_entries[15]),

        .phy_addr(inst_addr_physic),
        .virt_addr(inst_addr_virtual),
        .miss(inst_miss),
        .asid(asid),
        .match_which(),
        .valid(inst_valid),
        .dirt(inst_dirty)
    );

    tlb conv4data(
        .tlb_entry0(tlb_entries[0]),
        .tlb_entry1(tlb_entries[1]),
        .tlb_entry2(tlb_entries[2]),
        .tlb_entry3(tlb_entries[3]),
        .tlb_entry4(tlb_entries[4]),
        .tlb_entry5(tlb_entries[5]),
        .tlb_entry6(tlb_entries[6]),
        .tlb_entry7(tlb_entries[7]),
        .tlb_entry8(tlb_entries[8]),
        .tlb_entry9(tlb_entries[9]),
        .tlb_entry10(tlb_entries[10]),
        .tlb_entry11(tlb_entries[11]),
        .tlb_entry12(tlb_entries[12]),
        .tlb_entry13(tlb_entries[13]),
        .tlb_entry14(tlb_entries[14]),
        .tlb_entry15(tlb_entries[15]),

        .phy_addr(data_addr_physic),
        .virt_addr(data_addr_virtual),
        .miss(data_miss),
        .asid(asid),
        .match_which(),
        .valid(data_valid),
        .dirt(data_dirty)
    );

    tlb for_tlbp(
        .tlb_entry0(tlb_entries[0]),
        .tlb_entry1(tlb_entries[1]),
        .tlb_entry2(tlb_entries[2]),
        .tlb_entry3(tlb_entries[3]),
        .tlb_entry4(tlb_entries[4]),
        .tlb_entry5(tlb_entries[5]),
        .tlb_entry6(tlb_entries[6]),
        .tlb_entry7(tlb_entries[7]),
        .tlb_entry8(tlb_entries[8]),
        .tlb_entry9(tlb_entries[9]),
        .tlb_entry10(tlb_entries[10]),
        .tlb_entry11(tlb_entries[11]),
        .tlb_entry12(tlb_entries[12]),
        .tlb_entry13(tlb_entries[13]),
        .tlb_entry14(tlb_entries[14]),
        .tlb_entry15(tlb_entries[15]),

        .phy_addr(),
        .virt_addr({tlb_config[74:56], {13{1'b0}}}),
        .miss(tlbp_result[31]),
        .asid(asid),
        .match_which(tlbp_result[3:0]),
        .valid(),
        .dirt()
    );

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            tlb_entries[0] <= 80'd0;
            tlb_entries[1] <= 80'd0;
            tlb_entries[2] <= 80'd0;
            tlb_entries[3] <= 80'd0;
            tlb_entries[4] <= 80'd0;
            tlb_entries[5] <= 80'd0;
            tlb_entries[6] <= 80'd0;
            tlb_entries[7] <= 80'd0;
            tlb_entries[8] <= 80'd0;
            tlb_entries[9] <= 80'd0;
            tlb_entries[10] <= 80'd0;
            tlb_entries[11] <= 80'd0;
            tlb_entries[12] <= 80'd0;
            tlb_entries[13] <= 80'd0;
            tlb_entries[14] <= 80'd0;
            tlb_entries[15] <= 80'd0;
        end else begin
            if (tlbwi)
            begin
                tlb_entries[tlb_entry_index] [79:0] <= tlb_config[83:4];
            end
        end
    end

endmodule

`endif
