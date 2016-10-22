/*-----------------------------------------------------
 File Name : tlb.v
 Purpose :
 Creation Date : 21-10-2016
 Last Modified : Fri Oct 21 16:06:23 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __X_V__
`define __X_V__

`timescale 1ns/1ps

module tlb(/*autoarg*/
    //inputs
    tlb_entry0,  tlb_entry1,  tlb_entry2,  tlb_entry3,
    tlb_entry4,  tlb_entry5,  tlb_entry6,  tlb_entry7,
    tlb_entry8,  tlb_entry9,  tlb_entry10, tlb_entry11,
    tlb_entry12, tlb_entry13, tlb_entry14, tlb_entry15,

    virt_addr, asid,

    //output
    phy_addr, miss, valid, match_which, dirt
    );

    wire[15:0] matched;
    wire[79:0] tlb_entries[0:15];
    wire[23:0] PFN;

    assign tlb_entries[0]  = tlb_entry0;
    assign tlb_entries[1]  = tlb_entry1;
    assign tlb_entries[2]  = tlb_entry2;
    assign tlb_entries[3]  = tlb_entry3;
    assign tlb_entries[4]  = tlb_entry4;
    assign tlb_entries[5]  = tlb_entry5;
    assign tlb_entries[6]  = tlb_entry6;
    assign tlb_entries[7]  = tlb_entry7;
    assign tlb_entries[8]  = tlb_entry8;
    assign tlb_entries[9]  = tlb_entry9;
    assign tlb_entries[10] = tlb_entry10;
    assign tlb_entries[11] = tlb_entry11;
    assign tlb_entries[12] = tlb_entry12;
    assign tlb_entries[13] = tlb_entry13;
    assign tlb_entries[14] = tlb_entry14;
    assign tlb_entries[15] = tlb_entry15;

    assign PFN[23:0] = virt_addr[12] ? tlb_entries[match_which][51:28] : tlbEntries[match_which][25:2];
    assign dirt = virt_addr[12] ? tlb_entries[match_which][27] : tlbEntries[match_which][1];
    assign valid = virt_addr[12] ? tlb_entries[match_which][26] : tlbEntries[match_which][0];
 
    assign miss = matched == 16'd0;

    assign phy_addr[11:0] = virt_addr[11:0];
    assign phy_addr[31:12] = PFN[19:0];

    integer i;
    for (i = 0; i < 15; i = i + 1)
    begin
        assign matched[i] = tlb_entries[i][70:52] == virt_addr[31:13] &&
                (tlb_entries[i][79:72] == asid || tlb_entries[i][71]);
    end

    always @(*)
    begin
      if(matched[0]) begin
        match_which <= 4'd0;
      end else if(matched[1]) begin
        match_which <= 4'd1;
      end else if(matched[2]) begin
        match_which <= 4'd2;
      end else if(matched[3]) begin
        match_which <= 4'd3;
      end else if(matched[4]) begin
        match_which <= 4'd4;
      end else if(matched[5]) begin
        match_which <= 4'd5;
      end else if(matched[6]) begin
        match_which <= 4'd6;
      end else if(matched[7]) begin
        match_which <= 4'd7;
      end else if(matched[8]) begin
        match_which <= 4'd8;
      end else if(matched[9]) begin
        match_which <= 4'd9;
      end else if(matched[10]) begin
        match_which <= 4'd10;
      end else if(matched[11]) begin
        match_which <= 4'd11;
      end else if(matched[12]) begin
        match_which <= 4'd12;
      end else if(matched[13]) begin
        match_which <= 4'd13;
      end else if(matched[14]) begin
        match_which <= 4'd14;
      end else if(matched[15]) begin
        match_which <= 4'd15;
      end else begin
        match_which <= 4'd0;
      end
    end
endmodule

`endif
