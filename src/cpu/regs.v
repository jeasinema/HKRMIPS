/*-----------------------------------------------------
 File Name : regs.v
 Purpose : mips register heap
 Creation Date : 18-10-2016
 Last Modified : Fri Oct 21 12:52:07 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __REGS_V__
`define __REGS_V__

`timescale 1ns/1ps

module regs(/*autoarg*/
    //Inputs
    clk, rst_n, write_enable, write_addr, 
    write_val, read_addr1, read_addr2, read_addr3, 

    //Outputs
    read_val1, read_val2, read_val3
);

    input wire clk;
    input wire rst_n;

    // infos of writing reg operation
    input wire write_enable;
    input wire[4:0] write_addr;
    input wire[31:0] write_val;
    
    // output for reg_s in common, used in ex
    input wire[4:0] read_addr1;
    output reg[31:0] read_val1;

    // output for reg_t in common, used in ex
    input wire[4:0] read_addr2;
    output reg[31:0] read_val2;
 
    // output for debugger
    input wire[4:0] read_addr3;
    output reg[31:0] read_val3;
   
    // registers heap
    reg[31:0] registers[0:31];

    always @(posedge clk or negedge rst_n) 
    begin
        // reset to init val
        if (!rst_n)   
        begin
            registers[0] <= 32'b0;
            registers[1] <= 32'b0;
            registers[2] <= 32'b0;
            registers[3] <= 32'b0;
            registers[4] <= 32'b0;
            registers[5] <= 32'b0;
            registers[6] <= 32'b0;
            registers[7] <= 32'b0;
            registers[8] <= 32'b0;
            registers[9] <= 32'b0;
            registers[10] <= 32'b0;
            registers[11] <= 32'b0;
            registers[12] <= 32'b0;
            registers[13] <= 32'b0;
            registers[14] <= 32'b0;
            registers[15] <= 32'b0;
            registers[16] <= 32'b0;
            registers[17] <= 32'b0;
            registers[18] <= 32'b0;
            registers[19] <= 32'b0;
            registers[20] <= 32'b0;
            registers[21] <= 32'b0;
            registers[22] <= 32'b0;
            registers[23] <= 32'b0;
            registers[24] <= 32'b0;
            registers[25] <= 32'b0;
            registers[26] <= 32'b0;
            registers[27] <= 32'b0;
            registers[28] <= 32'b0;
            registers[29] <= 32'b0;
            registers[30] <= 32'b0;
            registers[31] <= 32'b0;
        end
        // write registers, reg0 is kept as 0
        else if (write_enable && write_addr!=5'h0) 
        begin
            registers[write_addr] <= write_val;
        end
    end

    always @(*)
    begin
        // when reset, get 0
        if (!rst_n)
            read_val1 <= 32'b0;
        // when access reg0, get 0
        else if (read_addr1 == 32'b0)
            read_val1 <= 32'b0;
        // when access reg now is being written, get val for write
        else if (read_addr1 == write_addr && write_enable)
            read_val1 <= write_val;
        // normal condition
        else 
            read_val1 <= registers[read_addr1];
    end

    always @(*)
    begin
        // when reset, get 0
        if (!rst_n)  
            read_val2 <= 32'b0;
        // when access reg0, get 0
        else if (read_addr2 == 32'b0)
            read_val2 <= 32'b0;
        // when access reg now is being written, get val for write
        else if (read_addr2 == write_addr && write_enable)
            read_val2 <= write_val;
        // normal condition
        else 
            read_val2 <= registers[read_addr2];
    end
    
    always @(*)
    begin
        // when reset, get 0
        if (!rst_n)  
            read_val3 <= 32'b0;
        // when access reg0, get 0
        else if (read_addr3 == 32'b0)
            read_val3 <= 32'b0;
        // when access reg now is being written, get val for write
        else if (read_addr3 == write_addr && write_enable)
            read_val3 <= write_val;
        // normal condition
        else 
            read_val3 <= registers[read_addr3];
    end

endmodule

`endif
