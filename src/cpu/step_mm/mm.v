/*-----------------------------------------------------
 File Name : mm.v
 Purpose : step_mm  
 Creation Date : 18-10-2016
 Last Modified : Fri Oct 28 22:03:32 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __MM_V__
`define __MM_V__

`timescale 1ns/1ps

`include "../defs.v"

module mm(/*autoarg*/
    //Inputs
    clk, rst_n, mem_access_type, mem_access_size, 
    mem_access_signed, mem_access_addr_i, 
    data_i, reg_addr_i, mem_access_data_i, 

    //Outputs
    data_o, bypass_reg_addr_mm, mem_access_addr_o, 
    mem_access_data_o, mem_access_read, mem_access_write, 
    alignment_err
);

    input wire clk;
    input wire rst_n;
    
    input wire[1:0] mem_access_type;
    input wire[2:0] mem_access_size;
    // mem_access_signed in ex.v
    input wire mem_access_signed;
    // mem_adccess_addr in ex.v
    input wire[31:0] mem_access_addr_i;
    // val_output in ex.v
    input wire[31:0] data_i;
    // bypass_reg_addr in ex.v, useless
    input wire[4:0] reg_addr_i;
    // receive mem access result from sram
    input wire[31:0] mem_access_data_i;

    
    // output mem access result from sram, used by wb and mux
    output reg[31:0] data_o;
    // use by mux, equal with reg_addr_i, but 1 clock late
    output wire[4:0] bypass_reg_addr_mm;
    // output address written to sram, equals with mem_access_addr_i, but 1 clock late;
    output wire[31:0] mem_access_addr_o;
    // output data wirtten to sram
    output wire[31:0] mem_access_data_o;  
    // mem access: read or write, enable write/read operation
    output reg mem_access_read;
    output reg mem_access_write;
    //output reg[3:0] mem_byte_en;
    // LH/SH:addr[0] != 0 LW/SW:addr[1:0] != 2'b0 
    output wire alignment_err;

    // some instruction need alignment
    reg[31:0] aligned_addr;
    // used by LB/LH LBU/LHU
    wire[7:0] val_byte, sign_byte; 
    wire[15:0] val_half, sign_half;
    // used by MEM_ACCESS_LENGTH_LEFT/RIGHT_WORD(LWL LWR SWL SWR)
    wire[4:0] left_shift;
    wire[4:0] right_shift;
    wire[31:0] left_mask;
    wire[31:0] right_mask;

    assign mem_access_addr_o = aligned_addr;
    assign bypass_reg_addr_mm = reg_addr_i;
    assign alignment_err = (mem_access_type == `MEM_ACCESS_TYPE_M2R || mem_access_type == `MEM_ACCESS_TYPE_R2M) && 
                           ((mem_access_size == `MEM_ACCESS_LENGTH_HALF && mem_access_addr_i[0] != 1'b0) ||
                            (mem_access_size == `MEM_ACCESS_LENGTH_WORD && mem_access_addr_i[1:0] != 2'b0));
    assign sign_byte = val_byte[7];
    assign sign_half = val_half[15];
    // for SWL
    assign left_shift = (2'd3 - mem_access_addr_i[1:0]) << 3;  
    // for SWR
    assign right_shift = (mem_access_addr_i[1:0]) << 3; 
    // for LWL
    assign left_mask = {32{1'b1}} << left_shift;
    // for LWR
    assign right_mask = {32{1'b1}} >> right_shift;

    // get val_byte/val_half
    always @(*)
    begin
        val_byte <= 8'b0;
        val_half <= 16'b0;
        case (mem_access_size)
        `MEM_ACCESS_LENGTH_BYTE:
        begin
            case (mem_access_addr_i[1:0])
            2'b00: val_byte <= mem_access_data_i[7:0];
            2'b01: val_byte <= mem_access_data_i[15:8];
            2'b10: val_byte <= mem_access_data_i[23:16];
            2'b11: val_byte <= mem_access_data_i[31:24];
            endcase
        end
        `MEM_ACCESS_LENGTH_HALF:
        begin
            val_half <= (mem_access_addr_i[1] == 1'b0 ? mem_access_data_i[15:0] : mem_access_data_i[31:16]);
        end
        default:
        begin
            val_byte <= 8'b0;
            val_half <= 16'b0;
        end
        endcase
    end

    // value&address alignment
    always @(*)
    begin
        aligned_addr <= mem_access_addr_i;
        case (mem_access_type)
        `MEM_ACCESS_TYPE_M2R:
        begin
            mem_access_read <= 1'b1;
            mem_access_write <= 1'b0;
            aligned_addr <= mem_access_addr_i & 32'hfffffffc;  // M2R, must aligned with word
            case (mem_access_size)
            `MEM_ACCESS_LENGTH_BYTE:
                data_o <= mem_access_signed ? {{24{sign_byte}}, val_byte} : {24'b0, val_byte};
            `MEM_ACCESS_LENGTH_HALF: 
                data_o <= mem_access_signed ? {{16{sign_half}}, val_half} : {16'b0, val_half};
            `MEM_ACCESS_LENGTH_WORD: 
                data_o <= mem_access_data_i;
            `MEM_ACCESS_LENGTH_LEFT_WORD: 
                data_o <= (mem_access_data_i << left_shift) | data_i & ~left_mask;
            `MEM_ACCESS_LENGTH_RIGHT_WORD: 
                data_o <= (mem_access_data_i >> right_shift) | data_i & ~right_mask;
            default: 
                data_o <= 32'b0;
            endcase
            mem_access_data_o <= 32'b0;
        end
        `MEM_ACCESS_TYPE_R2M:
        begin
            mem_access_read <= 1'b0;
            mem_access_write <= 1'b1;
            aligned_addr <= mem_access_addr_i & 32'hfffffffc;  
            // TODO: first stall and read then write
            // need to keep memory word alignment
            case (mem_access_size)
            `MEM_ACCESS_LENGTH_BYTE: 
                mem_access_data_o <= {data_i[7:0], data_i[7:0], data_i[7:0], data_i[7:0]};
            `MEM_ACCESS_LENGTH_HALF: 
                mem_access_data_o <= {data_i[15:0],data_i[15:0]}; 
            `MEM_ACCESS_LENGTH_WORD: 
                mem_access_data_o <= data_i;
            `MEM_ACCESS_LENGTH_LEFT_WORD: 
                mem_access_data_o <= data_i>>left_shift;
            `MEM_ACCESS_LENGTH_RIGHT_WORD: 
                mem_access_data_o <= data_i<<right_shift;
            default: 
                mem_access_data_o <= 32'b0;
            endcase
            data_o <= data_i;
        end
        default:
        begin
            mem_access_read <= 1'b0;
            mem_access_write <= 1'b0;
            mem_access_data_o <= 32'b0;
            data_o <= data_i;
        end
        endcase
    end

endmodule

`endif
