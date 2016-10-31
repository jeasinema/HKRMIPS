/*-----------------------------------------------------
 File Name : data_bus.v
 Purpose : device bus for ram, uart, vga, etc.
 Creation Date : 31-10-2016
 Last Modified : Mon Oct 31 15:16:18 2016
 Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
-----------------------------------------------------*/
`ifndef __DATA_BUS_V__
`define __DATA_BUS_V__

`timescale 1ns/1ps

module data_bus(/*autoarg*/
    //Inputs
    clk, rst_n, dev_access_addr, dev_access_read, 
    dev_access_write, dev_access_write_data, 
    read_data_from_uart, ram_stall, rom_stall, 

    //Outputs
    dev_access_read_data, data_bus_stall, 
    uart_addr, write_data_to_uart, uart_write_enable, 
    uart_read_enable, ticker_addr, write_data_to_ticker, 
    read_data_from_ticker, ticker_write_enable, 
    ticker_read_enable, gpio_addr, write_data_to_gpio, 
    read_data_from_gpio, gpio_write_enable, 
    gpio_read_enable, gpu_addr, write_data_to_gpu, 
    read_data_from_gpu, gpu_write_enable, 
    gpu_read_enable, ram_addr, write_data_to_ram, 
    read_data_from_ram, ram_enable, ram_write_enable, 
    ram_read_enable, rom_addr, write_data_to_rom, 
    read_data_from_rom, rom_enable, rom_write_enable, 
    rom_read_enable
);

    parameter RAM_BASE_ADDR = 8'h00;
    parameter GPU_BASE_ADDR = 8'h1b;
    parameter UART_BASE_ADDR = 28'h1fd003f;
    parameter GPIO_BASE_ADDR = 24'h1fd004;
    parameter TICKER_BASE_ADDR = 24'h1fd005;
    parameter ROM_BASE_ADDR = 8'h1e;
    
    input wire clk;
    input wire rst_n;

    // dev access interface  
    input wire[31:0] dev_access_addr;
    input wire dev_access_read;
    input wire dev_access_write;
    input wire[31:0] dev_access_write_data;
    output wire[31:0] dev_access_read_data;
    output wire data_bus_stall;

    // uart
    output wire[3:0] uart_addr;
    output wire[31:0] write_data_to_uart;
    input wire[31:0] read_data_from_uart;
    output reg uart_write_enable;
    output reg uart_read_enable;

    // ticker
    output wire[7:0] ticker_addr;
    output wire[31:0] write_data_to_ticker;
    output wire[31:0] read_data_from_ticker;
    output reg ticker_write_enable;
    output reg ticker_read_enable;

    // gpio
    output wire[7:0] gpio_addr;
    output wire[31:0] write_data_to_gpio;
    output wire[31:0] read_data_from_gpio;
    output reg gpio_write_enable;
    output reg gpio_read_enable;

    // vga(gpu)
    output wire[23:0] gpu_addr;
    output wire[31:0] write_data_to_gpu;
    output wire[31:0] read_data_from_gpu;
    output reg gpu_write_enable;
    output reg gpu_read_enable;
    
    // sram 
    output wire[23:0] ram_addr;
    output wire[31:0] write_data_to_ram;
    output wire[31:0] read_data_from_ram;
    output wire[3:0] ram_enable;
    output reg ram_write_enable;
    output reg ram_read_enable;
    input wire ram_stall;
  
    // flash(rom)
    output wire[23:0] rom_addr;
    output wire[31:0] write_data_to_rom;
    output wire[31:0] read_data_from_rom;
    output wire[3:0] rom_enable;
    output reg rom_write_enable;
    output reg rom_read_enable;
    input wire rom_stall;

    assign uart_addr = dev_access_addr[3:0];
    assign write_data_to_uart = dev_access_write_data;

    assign ticker_addr = dev_access_addr[7:0];
    assign write_data_to_ticker = dev_access_write_data;

    assign gpio_addr = dev_access_addr[7:0];
    assign write_data_to_gpio = dev_access_write_data;
    
    assign gpu_addr = dev_access_addr[23:0];
    assign write_data_to_gpu = dev_access_write_data;

    assign ram_enable = 4'b1111;
    assign ram_addr = dev_access_addr[23:0];
    assign write_data_to_ram = dev_access_write_data;
   
    assign rom_enable = 4'b1111;
    assign rom_addr = dev_access_addr[23:0];
    assign write_data_to_rom = dev_access_write_data;

    always @(*)
    begin
        uart_write_enable <= 1'b0;
        uart_read_enable <= 1'b0;
        ticker_write_enable <= 1'b0;
        ticker_read_enable <= 1'b0;
        gpio_write_enable <= 1'b0;
        gpio_read_enable <= 1'b0;
        gpu_write_enable <= 1'b0;
        gpu_read_enable <= 1'b0;
        ram_write_enable <= 1'b0;
        ram_read_enable <= 1'b0;
        rom_write_enable <= 1'b0;
        rom_read_enable <= 1'b0;
        data_bus_stall <= 1'b0;
        dev_access_read_data <= 32'b0;
        if (dev_access_addr[31:24] == RAM_BASE_ADDR) begin
            ram_read_enable <= dev_access_read;
            ram_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_ram;
            data_bus_stall <= ram_stall;
        end if (dev_access_addr[31:24] == ROM_BASE_ADDR) begin
            rom_read_enable <= dev_access_read;
            rom_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_rom;
            data_bus_stall <= rom_stall;
        end if (dev_access_addr[31:24] == GPU_BASE_ADDR) begin
            gpu_read_enable <= dev_access_read;
            gpu_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_gpu;
        end if (dev_access_addr[31:4] == UART_BASE_ADDR) begin
            uart_read_enable <= dev_access_read;
            uart_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_uart;
        end if (dev_access_addr[31:8] == GPIO_BASE_ADDR) begin
            gpio_read_enable <= dev_access_read;
            gpio_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_gpio;
        end if (dev_access_addr[31:8] == PLL_BASE_ADDR) begin
            ticker_read_enable <= dev_access_read;
            ticker_write_enable <= dev_access_write;
            dev_access_read_data <= read_data_from_ticker;
        end
    end

`endif
