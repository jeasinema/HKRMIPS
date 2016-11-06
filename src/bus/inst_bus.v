/*-----------------------------------------------------
 File Name : inst_bus.v
 Purpose : device (only sram) bus for instructions
 Creation Date : 18-10-2016
 Last Modified : Tue Nov  1 10:42:00 2016
 Created By :  Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __INST_BUS_V__
`define __INST_BUS_V__

`timescale 1ns/1ns

module inst_bus(/*autoarg*/
    //Inputs
    clk, rst_n, dev_access_addr, dev_ram_byte_enable, 
    dev_access_read, dev_access_write, dev_access_write_data, 
    ram_stall, 

    //Outputs
    dev_access_read_data, inst_bus_stall, 
    bootrom_addr, data_from_bootrom, ram_addr, 
    read_data_from_ram, write_data_to_ram, 
    ram_byte_enable, ram_read_enable, ram_write_enable
);

    parameter BOOT_ADDR_PREFIX = 12'h1fc;

    input wire clk;
    input wire rst_n;
    
    // dev access interface
    input wire[31:0] dev_access_addr;
    input wire[3:0] dev_ram_byte_enable;
    input wire dev_access_read;
    input wire dev_access_write;
    input wire dev_access_write_data;
    output reg dev_access_read_data;
    output wire inst_bus_stall;

    // bootrom
    output wire[12:0] bootrom_addr;
    output wire[31:0] data_from_bootrom;

    // sram
    output wire[23:0] ram_addr;
    output wire[31:0] read_data_from_ram;
    output wire[31:0] write_data_to_ram;
    output wire[3:0] ram_byte_enable;
    output reg ram_read_enable;
    output reg ram_write_enable;
    input wire ram_stall;

    assign bootrom_addr = dev_access_addr[12:0];
    assign ram_byte_enable = 4'b1111;
    assign write_data_to_ram = dev_access_write_data;
    assign ram_addr = dev_access_addr[23:0];
    assign inst_bus_stall = ram_stall;

    always @(*)
    begin
        ram_read_enable <= 1'b0;
        ram_write_enable <= 1'b0;
        if (dev_access_addr[31:24] == 8'h00) begin
            ram_read_enable <= dev_access_read;
            ram_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_ram;
        end else if (dev_access_addr[31:20] == BOOT_ADDR_PREFIX) begin
            dev_access_read_data <= data_from_bootrom;
        end
    end

endmodule

`endif
