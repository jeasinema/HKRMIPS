/*-----------------------------------------------------
 File Name : mem_map.v
 Purpose : virtual memory map convert (vol3.p11-16)
 Creation Date : 21-10-2016
 Last Modified : Sat Oct 22 18:20:43 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __MEM_MAP_V__
`define __MEM_MAP_V__

`timescale 1ns/1ns

module mem_map(/*autoarg*/
    //Inputs
    clk, rst_n, addr_i, mem_access_enable, 
    user_mode, 

    //Outputs
    addr_o, is_invalid, using_tlb, is_uncached
);

    input wire clk;
    input wire rst_n;

    // raw mem address
    input wire[31:0] addr_i;
    input wire mem_access_enable;
    input wire user_mode;

    // 0 when using tlb, convert when using kseg0/kseg1
    output reg[31:0] addr_o;
    output wire is_invalid;
    output reg using_tlb;
    output wire is_uncached;
    
    // is invalid when access kernel memory area(vol3.p22)
    assign is_invalid = (mem_access_enable & user_mode & addr_i[31]);  
    // kseg1 uncached, vol3.p16
    assign is_uncached = (addr_i[31:29] == 3'b101);

    always @(*)
    begin
        using_tlb <= 1'b0;
        addr_o <= 32'b0;
        if (mem_access_enable)
        begin
            case (addr_i[31:29])
            // kseg2
            3'b110,
            // kseg3
            3'b111,
            // useg
            3'b000,
            3'b001,
            3'b010,
            3'b011:
                using_tlb <= 1'b1;
            // keseg0
            3'b100,
            // kseg1
            3'b101:
                // clear most 3 significant bits vol3.p16
                addr_o <= {3'b0, addr_i[28:0]};
            endcase
        end
    end

endmodule

`endif
